#!/usr/bin/env python3
"""Backt aus einem Gelaende-GLB ein Hoehenfeld als 16-Bit-PNG.

## Warum das noetig ist

Die Bodenhoehe der Welt kommt aus EINER Funktion: `WorldManager.height_at(x, z)`. Daraus
entsteht das sichtbare Netz und die Hoehe, auf der Spieler, Gegner und Beute stehen. Ein
Gelaendemodell hat diese Funktion nicht — legt man es einfach in die Szene, laeuft die Figur
weiter auf der alten Formelhoehe und schwebt oder versinkt.

Dieses Skript rastert deshalb die OBERSEITE des Modells in ein Hoehenfeld. Godot liest es zur
Laufzeit und beantwortet damit `height_at` — das Modell ist dann Bild UND Kollision, aus
derselben Quelle.

## Wie

Fuer jede Rasterzelle ein senkrechter Strahl von oben. Getroffen wird das HOECHSTE Dreieck an
dieser Stelle; die Unterseite eines geschlossenen Modells und alle Ueberhaenge darunter fallen
damit heraus. Das ist die Einschraenkung des Verfahrens und sie ist bewusst: Ein Hoehenfeld
kennt je Punkt genau eine Hoehe. Ueberhaengende Kanten bleiben SICHTBAR, man kann nur nicht
darunter stehen — bei einer Schrottgrube faellt das nicht auf.

Der Rand wird auf 0 heruntergezogen (`--fade`), damit das Feld nahtlos in die flache Wueste
laeuft, und Loecher im Netz werden aus der Nachbarschaft gefuellt (generierte Modelle haben
oefter eines, hier zum Beispiel ein 4 m weites in der Mitte).

Benutzung:
    python3 tools/bake_heightfield.py assets/models/environment/schrottgrube.glb \\
        assets/terrain/schrottgrube.hf --size 128 --diameter 30 --y-scale 1.7
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from prepare_meshy_glb import read_accessor, read_glb, write_glb  # noqa: E402


def transform_positions(gltf: dict, binary: bytes, mitte: np.ndarray, skal: float,
                        versatz: float, y_scale: float) -> bytes:
    """Schreibt die Eckpunkte des Modells so um, dass sie zum Hoehenfeld passen.

    Warum das ins Modell und nicht in die Szene: Feld und Modell muessen DENSELBEN Maszstab und
    denselben Nullpunkt haben, sonst laeuft die Figur neben ihrer eigenen Kollision. Zwei
    Zahlenpaare, die an verschiedenen Stellen gepflegt werden, laufen irgendwann auseinander —
    also rechnet dasselbe Werkzeug beides in einem Durchgang und legt das Ergebnis fest ab.
    Das Modell kommt danach ohne Skalierung und ohne Versatz in die Szene.
    """
    neu = bytearray(binary)
    for mesh in gltf["meshes"]:
        for prim in mesh["primitives"]:
            acc = gltf["accessors"][prim["attributes"]["POSITION"]]
            bv = gltf["bufferViews"][acc["bufferView"]]
            start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
            v = np.frombuffer(binary, dtype="<f4", count=acc["count"] * 3,
                              offset=start).reshape(-1, 3).astype(np.float64)
            v = (v - mitte) * skal
            v[:, 1] = (v[:, 1] - versatz) * y_scale
            neu[start:start + acc["count"] * 12] = v.astype("<f4").tobytes()
            acc["min"] = [float(x) for x in v.min(0)]
            acc["max"] = [float(x) for x in v.max(0)]

            # NORMALEN MITRECHNEN. Beim ersten Versuch stand das hier nicht, und das Modell sah
            # im Spiel aus wie schwarzer Lack: Die Ueberhoehung in y ist eine UNGLEICHMAESSIGE
            # Skalierung, und dabei folgen Normalen nicht derselben Matrix wie Punkte, sondern
            # ihrer inversen Transponierten. Aus (1, 1.7, 1) wird fuer Normalen (1, 1/1.7, 1);
            # der gleichmaessige Anteil `skal` fällt beim Normieren heraus.
            if y_scale != 1.0 and "NORMAL" in prim["attributes"]:
                nacc = gltf["accessors"][prim["attributes"]["NORMAL"]]
                nbv = gltf["bufferViews"][nacc["bufferView"]]
                nstart = nbv.get("byteOffset", 0) + nacc.get("byteOffset", 0)
                nn = np.frombuffer(binary, dtype="<f4", count=nacc["count"] * 3,
                                   offset=nstart).reshape(-1, 3).astype(np.float64)
                nn[:, 1] /= y_scale
                laenge = np.linalg.norm(nn, axis=1, keepdims=True)
                laenge[laenge == 0.0] = 1.0
                nn /= laenge
                neu[nstart:nstart + nacc["count"] * 12] = nn.astype("<f4").tobytes()
                # Tangenten liegen IN der Flaeche, werden also mit derselben Matrix wie Punkte
                # gestreckt — nicht mit der inversen. Das vierte Feld ist das Vorzeichen der
                # Bitangente und bleibt unberuehrt.
                if "TANGENT" in prim["attributes"]:
                    tacc = gltf["accessors"][prim["attributes"]["TANGENT"]]
                    tbv = gltf["bufferViews"][tacc["bufferView"]]
                    tstart = tbv.get("byteOffset", 0) + tacc.get("byteOffset", 0)
                    tt = np.frombuffer(binary, dtype="<f4", count=tacc["count"] * 4,
                                       offset=tstart).reshape(-1, 4).astype(np.float64)
                    tt[:, 1] *= y_scale
                    tl = np.linalg.norm(tt[:, :3], axis=1, keepdims=True)
                    tl[tl == 0.0] = 1.0
                    tt[:, :3] /= tl
                    neu[tstart:tstart + tacc["count"] * 16] = tt.astype("<f4").tobytes()
    return bytes(neu)


def top_surface(verts: np.ndarray, faces: np.ndarray, size: int) -> np.ndarray:
    """Hoechste Flaeche je Rasterzelle (NaN, wo das Netz nichts hergibt).

    Kein Strahl-Dreieck-Test je Zelle — das waere size² x faces Vergleiche. Stattdessen
    andersherum: Jedes Dreieck wird in das Raster gezeichnet (wie ein Rasterizer), und je Zelle
    bleibt die groesste Hoehe stehen. Das ist linear in der Dreieckszahl.
    """
    hoehe = np.full((size, size), -np.inf)
    mn = verts.min(0)
    mx = verts.max(0)
    spanne = np.array([mx[0] - mn[0], mx[2] - mn[2]])
    # Zellenmittelpunkte in Modellkoordinaten
    schritt = spanne / size

    for tri in faces:
        p = verts[tri]
        x0 = max(0, int(np.floor((p[:, 0].min() - mn[0]) / schritt[0])))
        x1 = min(size - 1, int(np.ceil((p[:, 0].max() - mn[0]) / schritt[0])))
        z0 = max(0, int(np.floor((p[:, 2].min() - mn[2]) / schritt[1])))
        z1 = min(size - 1, int(np.ceil((p[:, 2].max() - mn[2]) / schritt[1])))
        if x1 < x0 or z1 < z0:
            continue
        gx = mn[0] + (np.arange(x0, x1 + 1) + 0.5) * schritt[0]
        gz = mn[2] + (np.arange(z0, z1 + 1) + 0.5) * schritt[1]
        X, Z = np.meshgrid(gx, gz)
        # Baryzentrisch in der XZ-Ebene
        ax, az, bx, bz, cx, cz = p[0, 0], p[0, 2], p[1, 0], p[1, 2], p[2, 0], p[2, 2]
        den = (bz - cz) * (ax - cx) + (cx - bx) * (az - cz)
        if abs(den) < 1e-12:
            continue
        w0 = ((bz - cz) * (X - cx) + (cx - bx) * (Z - cz)) / den
        w1 = ((cz - az) * (X - cx) + (ax - cx) * (Z - cz)) / den
        w2 = 1.0 - w0 - w1
        drin = (w0 >= -1e-9) & (w1 >= -1e-9) & (w2 >= -1e-9)
        if not drin.any():
            continue
        y = w0 * p[0, 1] + w1 * p[1, 1] + w2 * p[2, 1]
        block = hoehe[z0:z1 + 1, x0:x1 + 1]
        np.maximum(block, np.where(drin, y, -np.inf), out=block)

    hoehe[np.isinf(hoehe)] = np.nan
    return hoehe


def kastenfilter(h: np.ndarray, radius: int, durchgaenge: int) -> np.ndarray:
    """Weichzeichnung mit Kastenfiltern, formerhaltend. Drei Durchgaenge ~ Gauss.

    Ueber die Summenreihe (`cumsum`), damit der Aufwand nicht mit dem Radius waechst: Die Summe
    eines Fensters ist die Differenz zweier Reihenwerte, egal wie breit es ist.

    Die Indizes sind die Stelle, an der es beim ersten Versuch schiefging. Mit einer Polsterung
    von `radius` je Seite und einer vorangestellten Null hat die Reihe `N + 2r + 1` Werte; das
    Fenster fuer Ausgabezelle i ist `kum[i + 2r + 1] - kum[i]`. Wer stattdessen `kum[breit:]`
    gegen `kum[:-breit]` rechnet, bekommt `N + 1` Werte heraus — das Feld wuechst je Durchgang.
    """
    breit = 2 * radius + 1
    for _ in range(durchgaenge):
        for achse in (0, 1):
            polster = [(0, 0), (0, 0)]
            polster[achse] = (radius, radius)
            kum = np.cumsum(np.pad(h, polster, mode="edge"), axis=achse)
            null = np.zeros_like(np.take(kum, [0], axis=achse))
            kum = np.concatenate([null, kum], axis=achse)
            n = h.shape[achse]
            vorn = np.take(kum, np.arange(breit, breit + n), axis=achse)
            hinten = np.take(kum, np.arange(0, n), axis=achse)
            h = (vorn - hinten) / breit
    return h


def fuellen(h: np.ndarray) -> int:
    """Loecher aus der Nachbarschaft schliessen (mehrere Durchgaenge, bis nichts mehr fehlt)."""
    fehlt = int(np.isnan(h).sum())
    for _ in range(400):
        luecke = np.isnan(h)
        if not luecke.any():
            break
        gepolstert = np.pad(h, 1, constant_values=np.nan)
        nachbarn = np.stack([
            gepolstert[:-2, 1:-1], gepolstert[2:, 1:-1],
            gepolstert[1:-1, :-2], gepolstert[1:-1, 2:],
        ])
        with np.errstate(invalid="ignore"):
            mittel = np.nanmean(nachbarn, axis=0)
        h[luecke] = mittel[luecke]
    # Was jetzt noch fehlt, hat keinen Nachbarn — auf 0 setzen, damit nie NaN im Spiel landet.
    h[np.isnan(h)] = 0.0
    return fehlt


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source")
    ap.add_argument("target")
    ap.add_argument("--size", type=int, default=256, help="Rasterkante (Standard 256)")
    ap.add_argument("--diameter", type=float, default=30.0,
                    help="Zielbreite des Modells in Metern (Standard 30)")
    ap.add_argument("--fade", type=float, default=0.18,
                    help="Anteil des Radius, ueber den der Rand auf 0 auslaeuft (Standard 0.18)")
    ap.add_argument("--smooth", type=float, default=0.8,
                    help="Weichzeichnung der LAUFFLAECHE in Metern. Das Modell bleibt scharf; "
                         "nur die Hoehe, auf der man steht, wird geglaettet (Standard 0.8)")
    ap.add_argument("--write-model",
                    help="Pfad, unter dem das passend umgerechnete Modell abgelegt wird. Das "
                         "Ergebnis ist in METERN und hat sein Aussenniveau bei y = 0 — es kommt "
                         "ohne Skalierung und ohne Versatz in die Szene.")
    ap.add_argument("--y-scale", type=float, default=1.0,
                    help="Tiefenueberhoehung. Generierte Krater sind flacher, als sie aussehen "
                         "sollen; 1.7 macht aus 2 m Tiefe 3,4 m (Standard 1.0)")
    args = ap.parse_args()

    gltf, binary = read_glb(Path(args.source))
    verts_all, faces_all, basis = [], [], 0
    for mesh in gltf["meshes"]:
        for prim in mesh["primitives"]:
            v = read_accessor(gltf, binary, prim["attributes"]["POSITION"]).astype(np.float64)
            f = read_accessor(gltf, binary, prim["indices"]).reshape(-1, 3).astype(np.int64)
            verts_all.append(v)
            faces_all.append(f + basis)
            basis += len(v)
    verts = np.vstack(verts_all)
    faces = np.vstack(faces_all)

    # Auf Zielgroesse bringen und mittig um (0,0) legen.
    mn, mx = verts.min(0), verts.max(0)
    breite = max(mx[0] - mn[0], mx[2] - mn[2])
    skal = args.diameter / breite
    verts = (verts - (mn + mx) / 2.0) * skal

    print(f"{Path(args.source).name}: {len(faces):,} Dreiecke, Skalierung x{skal:.3f}"
          .replace(",", "."))
    h = top_surface(verts, faces, args.size)
    leer = int(np.isnan(h).sum())

    # UNTERSEITE als Loch behandeln, nicht als Boden.
    #
    # Ein geschlossenes Modell hat unten eine Platte. Wo das Netz oben ein Loch hat — dieses
    # Modell hat ein 4 m weites in der Mitte — trifft der Strahl durch das Loch hindurch genau
    # diese Platte, und das Hoehenfeld glaubt, dort sei Boden. Gemessen entstand daraus eine
    # 88°-Kante am Lochrand: eine Falle, in der man haengenbleibt.
    #
    # Die Platte ist das tiefste Plateau des Feldes. Alles in ihrer Naehe wird zu einem Loch
    # erklaert und aus der Nachbarschaft gefuellt — der Grund der Grube laeuft dann glatt
    # ueber die Stelle hinweg.
    gueltig = ~np.isnan(h)
    unterseite = float(np.percentile(h[gueltig], 2.0))
    platte = gueltig & (h < unterseite + 0.4)
    h[platte] = np.nan
    fehlend = fuellen(h)
    print(f"  · {leer} Zellen ohne Treffer, {int(platte.sum())} auf der Unterseite "
          f"(Plateau bei {unterseite:+.2f} m) — zusammen {fehlend} gefuellt "
          f"({100.0 * fehlend / args.size ** 2:.1f} %)")

    # Aussenniveau auf 0 ziehen. Der Bezug ist der aeussere Ring der OBERSEITE.
    #
    # Erster Versuch nahm dort schlicht den Median und landete bei -1,63 m — dem Wert der
    # UNTERSEITE. Bei einem geschlossenen Modell laufen am aeussersten Rand Ober- und
    # Unterseite zusammen, und weil die Unterseite eine grosse flache Platte ist, gewinnt sie
    # die Mehrheit. Die Grube waere dadurch komplett ueber den Wuestenboden gerutscht.
    #
    # Also wird die Unterseite vorher erkannt: Sie ist das tiefste Plateau des Feldes. Alles
    # innerhalb eines halben Meters darueber zaehlt nicht als Gelaende.
    yy, xx = np.mgrid[0:args.size, 0:args.size]
    mitte = (args.size - 1) / 2.0
    rad = np.hypot(xx - mitte, yy - mitte) / mitte
    versatz = float(np.median(h[(rad > 0.90) & (rad <= 1.0)]))
    h -= versatz
    print(f"  · Aussenniveau der Oberseite {versatz:+.2f} m -> auf 0 verschoben")
    if args.y_scale != 1.0:
        h *= args.y_scale
        print(f"  · Tiefen mit x{args.y_scale:.2f} ueberhoeht")

    # Weich auf 0 auslaufen, damit die Naht zur flachen Wueste unsichtbar bleibt.
    k = np.clip((1.0 - rad) / max(args.fade, 0.001), 0.0, 1.0)
    h *= k * k * (3.0 - 2.0 * k)      # smoothstep
    h[rad >= 1.0] = 0.0

    # WEICHZEICHNEN — der wichtigste Schritt, und der am wenigsten offensichtliche.
    #
    # Die Oberflaeche des Modells IST der Schrott. Bei 12 cm Rasterweite erzeugt jedes einzelne
    # Truemmerstueck eine senkrechte Stufe; gemessen standen 4 448 Zellen ueber 70° und die
    # steilste bei 85°. Im Bild ist das genau richtig — als LAUFFLAECHE ist es unbrauchbar: Die
    # Figur wuerde bei jedem Schritt um einen halben Meter springen und an jeder Kante haengen.
    #
    # Ein Mensch, der ueber Schutt geht, folgt nicht jedem Stueck, sondern dem mittleren Niveau
    # des Haufens. Genau das liefert eine Weichzeichnung. Das Modell bleibt scharf — geglaettet
    # wird nur, worauf man steht.
    zelle_m = args.diameter / args.size
    radius = max(1, int(round(args.smooth / zelle_m)))
    h = kastenfilter(h, radius, 3)
    print(f"  · Lauffläche weichgezeichnet: {args.smooth:.2f} m (Radius {radius} Zellen)")
    # Formpruefung, weil hier schon einmal genau das schiefging: Der erste Anlauf verrechnete
    # die Fensterbreite um eins, das Feld wuchs je Durchgang um eine Zelle und war am Ende
    # 131x131 statt 128x128. Die Datei hatte 3 108 Bytes zu viel, Godot las das Raster
    # zeilenweise verschoben — im Spiel war der Krater dadurch spiegelbildlich verzerrt und am
    # Rand stand eine 2,9-m-Stufe. Ein Vergleich der Kantenlaenge haette das sofort gezeigt.
    if h.shape != (args.size, args.size):
        sys.exit(f"Weichzeichnen hat die Form veraendert: {h.shape} statt "
                 f"({args.size}, {args.size})")

    lo, hi = float(h.min()), float(h.max())
    print(f"  · Hoehen {lo:+.2f} .. {hi:+.2f} m  (Tiefe {hi - lo:.2f} m)")
    # Steilste Stelle, damit man vorher weiss, ob das begehbar ist.
    steil = max(np.abs(np.diff(h, axis=0)).max(), np.abs(np.diff(h, axis=1)).max())
    print(f"  · Steilste Stelle {np.degrees(np.arctan2(steil, zelle_m)):.1f}° "
          f"(Zellenbreite {zelle_m:.2f} m)")

    ziel = Path(args.target)
    ziel.parent.mkdir(parents=True, exist_ok=True)

    # Format: schlichte Binaerdatei, KEIN Bild.
    #
    # Ein PNG waere naheliegend, aber Godot schickt Bilder durch den Import und macht daraus
    # eine komprimierte Textur — die Quelldatei landet dann nicht im Export, und
    # `Image.load_from_file` findet nichts. Eine Datei mit unbekannter Endung wird durchgereicht
    # und laesst sich mit `FileAccess` roh lesen. Kopf: 4x int32/float32, dann size² float32
    # zeilenweise (Norden zuerst, wie im Bild).
    kopf = struct.pack("<iiff", args.size, 0, args.diameter, 0.0)
    ziel.write_bytes(kopf + h.astype("<f4").tobytes())
    print(f"{args.source} -> {ziel}  ({ziel.stat().st_size / 1024:.0f} kB, "
          f"{args.size}x{args.size} float32)")

    if args.write_model:
        modell = transform_positions(gltf, binary, (mn + mx) / 2.0, skal, versatz, args.y_scale)
        write_glb(Path(args.write_model), gltf, modell)
        print(f"  · Modell umgerechnet -> {args.write_model} "
              f"(x{skal:.3f}, y-Versatz {-versatz:+.2f} m, y x{args.y_scale:.2f})")

    # Zusaetzlich ein Graubild zum Draufschauen — spielt keine Rolle, hilft beim Pruefen.
    spanne = max(hi - lo, 0.001)
    vorschau = ziel.with_suffix(".preview.png")
    Image.fromarray(np.clip((h - lo) / spanne * 255.0, 0, 255).astype(np.uint8)).save(vorschau)


if __name__ == "__main__":
    main()
