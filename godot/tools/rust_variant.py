#!/usr/bin/env python3
"""Erzeugt aus einem GLB eine VERROSTETE Zweitfassung — nur die Farbtextur wird umgefaerbt.

Wozu: Die Schrottgrube braucht Dutzende verschiedener Stuecke. Modelle zu erzeugen ist teuer,
Umfaerben ist geschenkt — und Rost ist genau die Verwandlung, die aus einem Fassstapel aus
gebleichtem Holz einen Haufen korrodiertes Metall macht. Zwei Fassungen desselben Modells
nebeneinander liest niemand als Wiederholung, solange die Farbe weit genug auseinanderliegt.

Verfahren: Die Helligkeit jedes Pixels wird durch einen Rost-Farbverlauf geschickt
(dunkles Braunrot -> Rostorange -> heller Ocker) und dann mit dem Original gemischt. Ueber die
Helligkeit statt ueber den Farbton, weil das Ergebnis dann unabhaengig davon ist, welche Farbe
das Modell mitbringt: Holz, Blech und Lack landen alle im selben Rostbereich, behalten aber
ihre Struktur — Kanten, Nieten, Maserung bleiben sichtbar.

Benutzung:
    python3 tools/rust_variant.py props/barrels_lod.glb props/barrels_rust_lod.glb
    python3 tools/rust_variant.py a.glb b.glb --mix 0.85
"""

from __future__ import annotations

import argparse
import io
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from prepare_meshy_glb import read_glb, write_glb  # noqa: E402

# Stuetzstellen des Verlaufs (sRGB 0..1), von ganz dunkel nach ganz hell.
RUST_RAMP = np.array([
    [0.09, 0.05, 0.03],   # Schattenfuge, fast schwarz
    [0.28, 0.13, 0.07],   # dunkles Braunrot
    [0.48, 0.24, 0.11],   # Rost
    [0.65, 0.37, 0.17],   # frischer Rost, orange
    [0.78, 0.56, 0.34],   # abgeriebene Kante
    [0.88, 0.74, 0.55],   # Staub im Licht
])


def rusted(img: Image.Image, mix: float) -> Image.Image:
    rgb = np.asarray(img.convert("RGB"), dtype=np.float64) / 255.0
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
    # Kontrast leicht spreizen, sonst landet alles in der Mitte des Verlaufs und wird flach.
    lum = np.clip((lum - lum.mean()) * 1.25 + lum.mean(), 0.0, 1.0)
    pos = lum * (len(RUST_RAMP) - 1)
    lo = np.floor(pos).astype(int)
    hi = np.minimum(lo + 1, len(RUST_RAMP) - 1)
    f = (pos - lo)[..., None]
    ramp = RUST_RAMP[lo] * (1.0 - f) + RUST_RAMP[hi] * f
    out = ramp * mix + rgb * (1.0 - mix)
    return Image.fromarray((np.clip(out, 0.0, 1.0) * 255).astype(np.uint8))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source")
    ap.add_argument("target")
    ap.add_argument("--mix", type=float, default=0.82,
                    help="Anteil Rostfarbe gegenueber dem Original (Standard 0.82)")
    args = ap.parse_args()

    gltf, binary = read_glb(Path(args.source))
    # Nur die BASISFARBE umfaerben. Normal- und Metallic-Roughness-Textur tragen keine Farbe,
    # sondern Geometrie- und Materialdaten — wer die durch einen Farbverlauf schickt, macht
    # aus Oberflaechenstruktur Unsinn.
    ziel: set[int] = set()
    for mat in gltf.get("materials", []):
        bc = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if bc is not None:
            ziel.add(gltf["textures"][bc["index"]]["source"])
    if not ziel:
        sys.exit(f"{args.source}: keine Basisfarben-Textur gefunden")

    neu = bytearray(binary)
    for idx in sorted(ziel):
        bild = gltf["images"][idx]
        bv = gltf["bufferViews"][bild["bufferView"]]
        start, laenge = bv.get("byteOffset", 0), bv["byteLength"]
        roh = bytes(binary[start:start + laenge])
        img = rusted(Image.open(io.BytesIO(roh)), args.mix)
        puffer = io.BytesIO()
        img.save(puffer, format="JPEG", quality=88, optimize=True)
        daten = puffer.getvalue()
        if len(daten) > laenge:
            # Nicht groesser werden lassen: Der BufferView liegt mitten im Binaerblock, alles
            # dahinter wuerde sich verschieben und saemtliche Offsets waeren falsch.
            for q in (80, 70, 60, 50):
                puffer = io.BytesIO()
                img.save(puffer, format="JPEG", quality=q, optimize=True)
                daten = puffer.getvalue()
                if len(daten) <= laenge:
                    break
        if len(daten) > laenge:
            sys.exit(f"{args.source}: umgefaerbte Textur passt nicht in den BufferView")
        neu[start:start + laenge] = daten + b"\x00" * (laenge - len(daten))
        bild["mimeType"] = "image/jpeg"
        bv["byteLength"] = laenge          # Laenge bleibt, der Rest ist Fuellung
        print(f"  · Bild {idx}: verrostet ({len(daten) / 1024:.0f} kB von {laenge / 1024:.0f} kB)")

    write_glb(Path(args.target), gltf, bytes(neu))
    print(f"{args.source} -> {args.target}")


if __name__ == "__main__":
    main()
