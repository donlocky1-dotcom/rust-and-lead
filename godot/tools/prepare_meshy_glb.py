#!/usr/bin/env python3
"""Bereitet ein GLB aus einem Generator (Meshy & Co.) fuers Spiel auf.

Generierte Assets kommen mit Einstellungen, die fuer eine Vorschau im Browser gedacht sind
und im Spiel schaden. Dieses Skript raeumt genau diese Punkte auf — verlustfrei fuer die
Geometrie, die Animationen bleiben unberuehrt:

1. **Texturen verkleinern** (Standard: max. 2048 px). Meshy liefert 4K-PNGs; auf dem Handy
   bringt das nichts ausser Speicher und Ladezeit. Voll deckende Texturen werden zusaetzlich
   als JPEG gespeichert (PNG lohnt sich nur mit Alphakanal).
2. **Selbstleuchten entfernen.** Meshy haengt die Farbtextur zusaetzlich als *emissive* an
   (emissiveFactor 1,1,1). Damit leuchtet die Figur unabhaengig vom Licht — in einer Welt mit
   Sonne und Schatten sieht das flach und falsch aus. Auch `KHR_materials_specular` mit
   Faktoren > 1 (derselbe Aufhell-Trick) fliegt raus.
3. **alphaMode BLEND -> OPAQUE**, wenn die Textur gar kein Alpha hat. Transparente Objekte
   werden pro Frame sortiert und schreiben keine Tiefe — bei einer undurchsichtigen Figur
   erzeugt das nur Sortierfehler und Kosten.
4. **doubleSided aus.** Halbiert die Ueberzeichnung; von innen sieht man eine Figur ohnehin nie.
5. Unreferenzierte Bilder/Texturen/BufferViews werden entfernt.

Benutzung:
    python3 tools/prepare_meshy_glb.py roh.glb assets/models/characters/player.glb
    python3 tools/prepare_meshy_glb.py roh.glb ziel.glb --max-texture 1024 --keep-png
"""

from __future__ import annotations

import argparse
import io
import json
import struct
import sys
from pathlib import Path

from PIL import Image

GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942


def read_glb(path: Path) -> tuple[dict, bytes]:
    data = path.read_bytes()
    magic, version, _ = struct.unpack_from("<III", data, 0)
    if magic != GLB_MAGIC:
        sys.exit(f"{path} ist keine GLB-Datei")
    if version != 2:
        sys.exit(f"{path}: glTF-Version {version} wird nicht unterstuetzt (erwartet: 2)")
    gltf, binary, offset = None, b"", 12
    while offset < len(data):
        length, kind = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8 : offset + 8 + length]
        if kind == CHUNK_JSON:
            gltf = json.loads(chunk)
        elif kind == CHUNK_BIN:
            binary = chunk
        offset += 8 + length + (-length % 4)
    if gltf is None:
        sys.exit(f"{path}: kein JSON-Chunk gefunden")
    return gltf, binary


def write_glb(path: Path, gltf: dict, binary: bytes) -> None:
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    js += b" " * (-len(js) % 4)
    binary += b"\x00" * (-len(binary) % 4)
    total = 12 + 8 + len(js) + (8 + len(binary) if binary else 0)
    with path.open("wb") as f:
        f.write(struct.pack("<III", GLB_MAGIC, 2, total))
        f.write(struct.pack("<II", len(js), CHUNK_JSON))
        f.write(js)
        if binary:
            f.write(struct.pack("<II", len(binary), CHUNK_BIN))
            f.write(binary)


def view_bytes(gltf: dict, binary: bytes, index: int) -> bytes:
    bv = gltf["bufferViews"][index]
    start = bv.get("byteOffset", 0)
    return binary[start : start + bv["byteLength"]]


def _alpha_is_meaningful(img: Image.Image, threshold: int = 250, share: float = 0.001) -> bool:
    """Traegt der Alphakanal echte Information — oder nur Kompressionsrauschen?

    Generatoren liefern oft RGBA, in dem praktisch jedes Pixel deckend ist (ein paar hundert
    Pixel mit Alpha 254 aus der Texturbaeckerei). Solche Bilder als PNG mit Alpha zu behalten
    kostet ein Vielfaches an Speicher, ohne dass man je einen Unterschied saehe. Erst wenn ein
    nennenswerter Anteil wirklich durchscheinend ist, brauchen wir PNG.
    """
    if img.mode not in ("RGBA", "LA"):
        return False
    hist = img.getchannel("A").histogram()
    total = sum(hist)
    return total > 0 and sum(hist[:threshold]) / total > share


def shrink_image(raw: bytes, max_px: int, keep_png: bool) -> tuple[bytes, str, str]:
    """Gibt (Daten, mimeType, Beschreibung) zurueck."""
    img = Image.open(io.BytesIO(raw))
    before = f"{img.width}x{img.height}"
    if max(img.size) > max_px:
        scale = max_px / max(img.size)
        img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))),
                         Image.LANCZOS)
    has_alpha = _alpha_is_meaningful(img)
    out = io.BytesIO()
    if has_alpha or keep_png:
        img.save(out, format="PNG", optimize=True)
        mime = "image/png"
    else:
        img.convert("RGB").save(out, format="JPEG", quality=90, optimize=True)
        mime = "image/jpeg"
    note = f"{before} -> {img.width}x{img.height} {mime.split('/')[1]}"
    return out.getvalue(), mime, note


def clean_materials(gltf: dict, log: list[str]) -> None:
    for mat in gltf.get("materials", []):
        name = mat.get("name", "?")
        if "emissiveTexture" in mat or any(v > 0.0 for v in mat.get("emissiveFactor", [])):
            mat.pop("emissiveTexture", None)
            mat.pop("emissiveFactor", None)
            log.append(f"  · {name}: Selbstleuchten entfernt (reagiert jetzt auf Licht)")
        spec = mat.get("extensions", {}).get("KHR_materials_specular")
        if spec and any(v > 1.0 for v in spec.get("specularColorFactor", [])):
            mat["extensions"].pop("KHR_materials_specular")
            if not mat["extensions"]:
                mat.pop("extensions")
            log.append(f"  · {name}: ueberzogener Specular-Faktor entfernt")
        # glTF-Standard fuer metallicFactor ist 1.0 — also VOLLMETALLISCH, wenn der Exporter
        # das Feld weglaesst. Ein metallisches Material hat keine diffuse Farbe: es zeigt nur
        # Spiegelungen und wird ohne Reflexionsumgebung schwarz. Meshys Selbstleuchten
        # verdeckt das in der Vorschau; im Spiel steht dann eine schwarze Silhouette da.
        # Eine generierte Figur (Stoff, Leder, Haut) ist kein Spiegel.
        pbr = mat.setdefault("pbrMetallicRoughness", {})
        was = pbr.get("metallicFactor", 1.0)
        if "metallicRoughnessTexture" not in pbr and was > 0.5:
            pbr["metallicFactor"] = 0.0
            log.append(f"  · {name}: metallicFactor {was} -> 0.0 "
                       "(war vollmetallisch = schwarz ohne Spiegelung)")
        if mat.get("alphaMode") == "BLEND":
            mat["alphaMode"] = "OPAQUE"
            log.append(f"  · {name}: alphaMode BLEND -> OPAQUE")
        if mat.get("doubleSided"):
            mat["doubleSided"] = False
            log.append(f"  · {name}: doubleSided aus")


def drop_unused(gltf: dict, log: list[str]) -> None:
    """Entfernt Texturen/Bilder, die kein Material mehr benutzt (und remappt die Indizes)."""
    used_tex: set[int] = set()

    def collect(node) -> None:
        if isinstance(node, dict):
            if "index" in node and set(node) <= {"index", "texCoord", "scale", "strength", "extensions"}:
                used_tex.add(node["index"])
            for v in node.values():
                collect(v)
        elif isinstance(node, list):
            for v in node:
                collect(v)

    collect(gltf.get("materials", []))
    textures = gltf.get("textures", [])
    keep_tex = [i for i in range(len(textures)) if i in used_tex]
    if len(keep_tex) == len(textures):
        return
    tex_map = {old: new for new, old in enumerate(keep_tex)}
    used_img = {textures[i]["source"] for i in keep_tex if "source" in textures[i]}
    keep_img = [i for i in range(len(gltf.get("images", []))) if i in used_img]
    img_map = {old: new for new, old in enumerate(keep_img)}

    def remap(node) -> None:
        if isinstance(node, dict):
            if "index" in node and set(node) <= {"index", "texCoord", "scale", "strength", "extensions"}:
                node["index"] = tex_map[node["index"]]
            for v in node.values():
                remap(v)
        elif isinstance(node, list):
            for v in node:
                remap(v)

    remap(gltf.get("materials", []))
    gltf["textures"] = [textures[i] for i in keep_tex]
    for tex in gltf["textures"]:
        if "source" in tex:
            tex["source"] = img_map[tex["source"]]
    log.append(f"  · {len(textures) - len(keep_tex)} unbenutzte Textur(en) entfernt")
    gltf["images"] = [gltf["images"][i] for i in keep_img]


def rebuild_buffer(gltf: dict, binary: bytes, replaced: dict[int, bytes]) -> bytes:
    """Baut den Binaerchunk neu auf; nur noch referenzierte BufferViews wandern mit."""
    used: set[int] = set()
    for acc in gltf.get("accessors", []):
        if "bufferView" in acc:
            used.add(acc["bufferView"])
        sparse = acc.get("sparse")
        if sparse:
            used.add(sparse["indices"]["bufferView"])
            used.add(sparse["values"]["bufferView"])
    for img in gltf.get("images", []):
        if "bufferView" in img:
            used.add(img["bufferView"])
    keep = sorted(used)
    view_map = {old: new for new, old in enumerate(keep)}

    out = bytearray()
    new_views = []
    for old in keep:
        bv = dict(gltf["bufferViews"][old])
        data = replaced.get(old, view_bytes(gltf, binary, old))
        out += b"\x00" * (-len(out) % 4)
        bv["byteOffset"] = len(out)
        bv["byteLength"] = len(data)
        bv["buffer"] = 0
        out += data
        new_views.append(bv)

    for acc in gltf.get("accessors", []):
        if "bufferView" in acc:
            acc["bufferView"] = view_map[acc["bufferView"]]
        sparse = acc.get("sparse")
        if sparse:
            sparse["indices"]["bufferView"] = view_map[sparse["indices"]["bufferView"]]
            sparse["values"]["bufferView"] = view_map[sparse["values"]["bufferView"]]
    for img in gltf.get("images", []):
        if "bufferView" in img:
            img["bufferView"] = view_map[img["bufferView"]]

    gltf["bufferViews"] = new_views
    gltf["buffers"] = [{"byteLength": len(out)}]
    return bytes(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", type=Path)
    ap.add_argument("target", type=Path)
    ap.add_argument("--max-texture", type=int, default=2048, help="laengste Kante in Pixeln (Standard 2048)")
    ap.add_argument("--keep-png", action="store_true", help="nicht nach JPEG wandeln")
    args = ap.parse_args()

    gltf, binary = read_glb(args.source)
    log: list[str] = []
    clean_materials(gltf, log)
    drop_unused(gltf, log)

    replaced: dict[int, bytes] = {}
    for img in gltf.get("images", []):
        if "bufferView" not in img:
            continue
        raw = view_bytes(gltf, binary, img["bufferView"])
        data, mime, note = shrink_image(raw, args.max_texture, args.keep_png)
        replaced[img["bufferView"]] = data
        img["mimeType"] = mime
        log.append(f"  · Textur {img.get('name', '?')}: {note}"
                   f" ({len(raw) / 1e6:.1f} -> {len(data) / 1e6:.1f} MB)")

    binary = rebuild_buffer(gltf, binary, replaced)
    args.target.parent.mkdir(parents=True, exist_ok=True)
    write_glb(args.target, gltf, binary)

    before = args.source.stat().st_size
    after = args.target.stat().st_size
    print(f"{args.source.name} -> {args.target}")
    for line in log:
        print(line)
    print(f"  · Animationen: {len(gltf.get('animations', []))} (unveraendert)")
    print(f"  Groesse: {before / 1e6:.1f} MB -> {after / 1e6:.1f} MB "
          f"({100 * after / before:.0f} %)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
