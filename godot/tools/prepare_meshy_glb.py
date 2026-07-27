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


def _gray(gltf: dict, binary: bytes, tex_index: int, size: int = 128) -> Image.Image | None:
    """Graustufen-Miniatur der Textur hinter einem Textur-Index (None, wenn nicht lesbar)."""
    try:
        src = gltf["textures"][tex_index]["source"]
        raw = view_bytes(gltf, binary, gltf["images"][src]["bufferView"])
        return Image.open(io.BytesIO(raw)).convert("L").resize((size, size))
    except Exception:
        return None


def emissive_verdict(gltf: dict, binary: bytes, mat: dict) -> tuple[bool, str]:
    """Soll die Emissive-Textur raus? (entfernen?, Begruendung)

    Drei Faelle, drei verschiedene Gruende — deshalb keine pauschale Regel:
      • **identisch zur Farbtextur** -> Meshys Selbstleucht-Trick. Das Modell leuchtet dann
        unabhaengig vom Licht und sieht in einer Welt mit Sonne und Schatten flach aus.
      • **praktisch schwarz** -> tote Daten: kostet eine Texture-Einheit und Speicher, zeigt nichts.
      • **sonst** -> echte Glow-Map (Ofenglut, Lampen, Leuchtstreifen). Die BLEIBT: genau davon
        lebt der Steampunk-Look.
    """
    emissive = mat.get("emissiveTexture")
    if emissive is None:
        return (any(v > 0.0 for v in mat.get("emissiveFactor", [])), "emissiveFactor ohne Textur")
    em = _gray(gltf, binary, emissive["index"])
    if em is None:
        return (False, "")
    px = list(em.getdata())
    mean = sum(px) / len(px) / 255.0
    if mean < 0.02:
        return (True, "Emissive-Textur ist schwarz (tote Daten)")
    base = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
    if base is not None:
        bs = _gray(gltf, binary, base["index"])
        if bs is not None:
            bp = list(bs.getdata())
            diff = sum(abs(px[i] - bp[i]) for i in range(len(px))) / len(px)
            if diff < 2.0:
                return (True, "Emissive = Farbtextur (Selbstleucht-Trick)")
    return (False, "")


def clean_materials(gltf: dict, binary: bytes, log: list[str], watertight: bool = True) -> None:
    for mat in gltf.get("materials", []):
        name = mat.get("name", "?")
        drop, why = emissive_verdict(gltf, binary, mat)
        if drop:
            mat.pop("emissiveTexture", None)
            mat.pop("emissiveFactor", None)
            log.append(f"  · {name}: Selbstleuchten entfernt — {why}")
        elif "emissiveTexture" in mat:
            log.append(f"  · {name}: echte Glow-Map erkannt und BEHALTEN")
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
            if watertight:
                mat["doubleSided"] = False
                log.append(f"  · {name}: doubleSided aus (Koerper ist geschlossen)")
            else:
                log.append(f"  · {name}: doubleSided BLEIBT an — das Netz ist offen, "
                           "sonst sieht man hindurch")


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


COMPONENT_FLOAT = 5126
COMPONENT_UINT = 5125


def read_accessor(gltf: dict, binary: bytes, index: int):
    """Accessor als Liste von Tupeln (nur die Typen, die glTF-Meshes tatsaechlich benutzen)."""
    import numpy as np

    acc = gltf["accessors"][index]
    ncomp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
    dtype = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[acc["componentType"]]
    bv = gltf["bufferViews"][acc["bufferView"]]
    stride = bv.get("byteStride", 0)
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    if stride and stride != ncomp * np.dtype(dtype).itemsize:
        out = np.empty((acc["count"], ncomp), dtype=dtype)
        for i in range(acc["count"]):
            out[i] = np.frombuffer(binary, dtype=dtype, count=ncomp, offset=start + i * stride)
        return out
    return np.frombuffer(binary, dtype=dtype, count=acc["count"] * ncomp, offset=start).reshape(-1, ncomp)


def decimate(gltf: dict, binary: bytes, max_tris: int, log: list[str]) -> tuple[bytes, dict]:
    """Reduziert zu feine Meshes auf ein Budget und liefert (Binaerchunk, neue Views).

    Generatoren liefern gern 1–2 Millionen Dreiecke — das ist Scan-Aufloesung, keine
    Spielaufloesung: auf dem Handy kostet ein einziges solches Modell mehr als die gesamte
    restliche Szene. Reduziert wird mit Quadric Edge Collapse **mit Texturkoordinaten**, damit
    die Bemalung an Ort und Stelle bleibt; die Naehte werden danach wieder aufgetrennt, weil
    glTF eine UV pro Eckpunkt speichert.

    Gehaeutete Meshes bleiben unangetastet — dort haengen Knochengewichte an jedem Eckpunkt,
    die eine Reduktion mitziehen muesste.
    """
    import numpy as np
    import pymeshlab

    extra: dict[int, bytes] = {}
    for mesh in gltf.get("meshes", []):
        for prim in mesh["primitives"]:
            attrs = prim["attributes"]
            if "JOINTS_0" in attrs or "indices" not in prim:
                continue
            faces = read_accessor(gltf, binary, prim["indices"]).reshape(-1, 3).astype(np.int32)
            if faces.shape[0] <= max_tris:
                continue
            verts = read_accessor(gltf, binary, attrs["POSITION"]).astype(np.float64)
            uvs = (read_accessor(gltf, binary, attrs["TEXCOORD_0"]).astype(np.float64)
                   if "TEXCOORD_0" in attrs else None)
            before = faces.shape[0]
            last_pass = before

            ms = pymeshlab.MeshSet()
            ms.add_mesh(pymeshlab.Mesh(vertex_matrix=verts, face_matrix=faces,
                                       v_tex_coords_matrix=uvs) if uvs is not None
                        else pymeshlab.Mesh(vertex_matrix=verts, face_matrix=faces))
            if uvs is not None:
                # UVs auf die Ecken (Wedges) legen, BEVOR verschweisst wird — sonst gehen die
                # Texturkoordinaten an den Nahtstellen verloren.
                ms.compute_texcoord_transfer_vertex_to_wedge()
            # ENTSCHEIDEND: Eckpunkte verschweissen. glTF speichert eine UV je Eckpunkt und
            # spaltet ihn deshalb an jeder Textur-Naht — MeshLab sieht dann keinen Koerper,
            # sondern hunderttausende Einzelflicken mit lauter freien Raendern. Reduziert man
            # das, zerfaellt das Modell (gemessen: 59 % aller Kanten offen, Loecher zum
            # Durchsehen). Verschweisst hat dasselbe Modell 0,1 % offene Kanten.
            ms.meshing_merge_close_vertices(threshold=pymeshlab.PercentageValue(0.0001))
            # Mehrere Durchgaenge: ein einzelner Aufruf bleibt bei grossen Meshes ueber dem Ziel.
            for _ in range(8):
                if uvs is not None:
                    ms.meshing_decimation_quadric_edge_collapse_with_texture(
                        targetfacenum=max_tris, preserveboundary=True, preservenormal=True)
                else:
                    ms.meshing_decimation_quadric_edge_collapse(
                        targetfacenum=max_tris, preserveboundary=True, preservenormal=True)
                now = ms.current_mesh().face_number()
                if now <= max_tris or now > last_pass * 0.97:
                    break
                last_pass = now
            out = ms.current_mesh()
            new_v = np.asarray(out.vertex_matrix(), dtype=np.float64)
            new_f = np.asarray(out.face_matrix(), dtype=np.int64)
            new_n = _smooth_normals(new_v, new_f)
            if uvs is not None:
                wedge = np.asarray(out.wedge_tex_coord_matrix(), dtype=np.float64).reshape(-1, 3, 2)
                new_v, new_n, new_uv, new_f = _split_uv_seams(new_v, new_n, wedge, new_f)
            else:
                new_uv = None

            _write_primitive(gltf, prim, extra, new_v, new_n, new_uv, new_f)
            open_share = open_edge_share(new_v, new_f)
            log.append(f"  · Mesh '{mesh.get('name', '?')}': {before:,} -> {new_f.shape[0]:,} Dreiecke"
                       .replace(",", ".") + f", offene Kanten {100 * open_share:.1f} %")
    return binary, extra


def _is_watertight(gltf: dict, binary: bytes, extra: dict[int, bytes] | None = None,
                   limit: float = 0.02) -> bool:
    """Ist das Modell geschlossen genug, um Rueckseiten wegschneiden zu duerfen?"""
    import numpy as np

    def read(index: int):
        acc = gltf["accessors"][index]
        if extra is not None and acc["bufferView"] in extra:
            ncomp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[acc["type"]]
            dtype = {5126: np.float32, 5125: np.uint32}[acc["componentType"]]
            return np.frombuffer(extra[acc["bufferView"]], dtype=dtype).reshape(-1, ncomp)
        return read_accessor(gltf, binary, index)

    for mesh in gltf.get("meshes", []):
        for prim in mesh["primitives"]:
            if "indices" not in prim:
                continue
            faces = read(prim["indices"]).reshape(-1, 3).astype(np.int64)
            verts = read(prim["attributes"]["POSITION"]).astype(np.float64)
            if open_edge_share(verts, faces) > limit:
                return False
    return True


def open_edge_share(verts, faces) -> float:
    """Anteil der Kanten, die nur zu EINEM Dreieck gehoeren — das Mass fuer Loecher im Netz.

    Gemessen wird geometrisch verschweisst: an Textur-Nahtstellen liegen zwei Eckpunkte auf
    demselben Punkt, und die Kante dazwischen ist keine echte Oeffnung. Ein geschlossener
    Koerper liegt nahe 0; alles darueber sieht man im Spiel als Loch, sobald Rueckseiten
    weggeschnitten werden.
    """
    import numpy as np

    if faces.size == 0:
        return 0.0
    _, inv = np.unique(np.round(np.asarray(verts), 5), axis=0, return_inverse=True)
    welded = inv[np.asarray(faces)]
    edges = np.sort(np.vstack([welded[:, [0, 1]], welded[:, [1, 2]], welded[:, [2, 0]]]), axis=1)
    uniq, counts = np.unique(edges, axis=0, return_counts=True)
    return float((counts == 1).sum()) / float(len(uniq))


def _smooth_normals(verts, faces):
    """Flaechengewichtete Eckpunkt-Normalen (MeshLab liefert nach der Reduktion keine mit)."""
    import numpy as np

    normals = np.zeros_like(verts)
    tri = verts[faces]
    face_n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    for k in range(3):
        np.add.at(normals, faces[:, k], face_n)
    length = np.linalg.norm(normals, axis=1, keepdims=True)
    return normals / np.where(length < 1e-12, 1.0, length)


def _split_uv_seams(verts, normals, wedge, faces):
    """glTF speichert eine UV pro Eckpunkt — an Texturnaehten muss der Eckpunkt doppelt sein."""
    import numpy as np

    mapping: dict[tuple, int] = {}
    pos, nor, uv = [], [], []
    new_faces = np.empty_like(faces)
    for f in range(faces.shape[0]):
        for k in range(3):
            vi = int(faces[f, k])
            key = (vi, round(float(wedge[f, k, 0]), 6), round(float(wedge[f, k, 1]), 6))
            idx = mapping.get(key)
            if idx is None:
                idx = len(pos)
                mapping[key] = idx
                pos.append(verts[vi])
                nor.append(normals[vi])
                uv.append(wedge[f, k])
            new_faces[f, k] = idx
    return np.array(pos), np.array(nor), np.array(uv), new_faces


def _write_primitive(gltf: dict, prim: dict, extra: dict[int, bytes], verts, normals, uvs, faces) -> None:
    """Legt neue BufferViews/Accessoren fuer das reduzierte Mesh an und haengt das Primitive um.
    Die alten Views bleiben zurueck und werden von `rebuild_buffer` verworfen."""
    import numpy as np

    def add(data: bytes, target: int | None = None) -> int:
        idx = len(gltf["bufferViews"])
        view = {"buffer": 0, "byteOffset": 0, "byteLength": len(data)}
        if target is not None:
            view["target"] = target
        gltf["bufferViews"].append(view)
        extra[idx] = data
        return idx

    def add_accessor(view: int, count: int, kind: str, ctype: int, minmax=None) -> int:
        acc = {"bufferView": view, "componentType": ctype, "count": count, "type": kind}
        if minmax is not None:
            acc["min"], acc["max"] = minmax
        gltf["accessors"].append(acc)
        return len(gltf["accessors"]) - 1

    v32 = verts.astype(np.float32)
    prim["attributes"]["POSITION"] = add_accessor(
        add(v32.tobytes(), 34962), v32.shape[0], "VEC3", COMPONENT_FLOAT,
        (v32.min(axis=0).tolist(), v32.max(axis=0).tolist()))
    n32 = normals.astype(np.float32)
    prim["attributes"]["NORMAL"] = add_accessor(add(n32.tobytes(), 34962), n32.shape[0], "VEC3", COMPONENT_FLOAT)
    if uvs is not None:
        t32 = uvs.astype(np.float32)
        prim["attributes"]["TEXCOORD_0"] = add_accessor(add(t32.tobytes(), 34962), t32.shape[0], "VEC2", COMPONENT_FLOAT)
    for unused in ("TANGENT", "COLOR_0", "TEXCOORD_1"):
        prim["attributes"].pop(unused, None)
    idx32 = faces.astype(np.uint32).reshape(-1)
    prim["indices"] = add_accessor(add(idx32.tobytes(), 34963), idx32.shape[0], "SCALAR", COMPONENT_UINT)


def drop_unused_accessors(gltf: dict) -> None:
    """Entfernt Accessoren, auf die nichts mehr zeigt — sonst haelt das reduzierte Mesh die
    Daten des alten weiter fest (die alten Accessoren blieben stehen, ihre BufferViews galten
    als benutzt, und die Datei schrumpfte trotz Reduktion kaum)."""
    used: list[int] = []
    seen: set[int] = set()

    def use(i: int) -> None:
        if i not in seen:
            seen.add(i)
            used.append(i)

    for mesh in gltf.get("meshes", []):
        for prim in mesh["primitives"]:
            for acc in prim.get("attributes", {}).values():
                use(acc)
            if "indices" in prim:
                use(prim["indices"])
            for tgt in prim.get("targets", []):
                for acc in tgt.values():
                    use(acc)
    for skin in gltf.get("skins", []):
        if "inverseBindMatrices" in skin:
            use(skin["inverseBindMatrices"])
    for anim in gltf.get("animations", []):
        for s in anim["samplers"]:
            use(s["input"])
            use(s["output"])
    keep = sorted(seen)
    if len(keep) == len(gltf.get("accessors", [])):
        return
    remap = {old: new for new, old in enumerate(keep)}
    gltf["accessors"] = [gltf["accessors"][i] for i in keep]
    for mesh in gltf.get("meshes", []):
        for prim in mesh["primitives"]:
            prim["attributes"] = {k: remap[v] for k, v in prim.get("attributes", {}).items()}
            if "indices" in prim:
                prim["indices"] = remap[prim["indices"]]
            prim["targets"] = [{k: remap[v] for k, v in t.items()} for t in prim.get("targets", [])] \
                if "targets" in prim else prim.get("targets", [])
            if not prim.get("targets"):
                prim.pop("targets", None)
    for skin in gltf.get("skins", []):
        if "inverseBindMatrices" in skin:
            skin["inverseBindMatrices"] = remap[skin["inverseBindMatrices"]]
    for anim in gltf.get("animations", []):
        for s in anim["samplers"]:
            s["input"] = remap[s["input"]]
            s["output"] = remap[s["output"]]


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
        # `replaced` deckt sowohl ersetzte (verkleinerte Texturen) als auch NEUE Views ab
        # (reduziertes Mesh) — Letztere haben im alten Binaerchunk gar keine Daten.
        data = replaced[old] if old in replaced else view_bytes(gltf, binary, old)
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
    ap.add_argument("--max-tris", type=int, default=20000,
                    help="Dreiecks-Budget je Mesh (Standard 20000, 0 = nicht reduzieren)")
    ap.add_argument("--keep-png", action="store_true", help="nicht nach JPEG wandeln")
    args = ap.parse_args()

    gltf, binary = read_glb(args.source)
    log: list[str] = []
    # Reihenfolge mit Grund: Erst reduzieren, dann Materialien putzen. Ob `doubleSided` weg darf,
    # haengt daran, ob das FERTIGE Netz geschlossen ist — und das entscheidet die Reduktion.
    replaced: dict[int, bytes] = {}
    watertight = _is_watertight(gltf, binary)
    if args.max_tris > 0:
        binary, extra = decimate(gltf, binary, args.max_tris, log)
        replaced.update(extra)
        watertight = _is_watertight(gltf, binary, replaced)
    clean_materials(gltf, binary, log, watertight)
    drop_unused(gltf, log)
    for img in gltf.get("images", []):
        if "bufferView" not in img:
            continue
        raw = view_bytes(gltf, binary, img["bufferView"])
        data, mime, note = shrink_image(raw, args.max_texture, args.keep_png)
        replaced[img["bufferView"]] = data
        img["mimeType"] = mime
        log.append(f"  · Textur {img.get('name', '?')}: {note}"
                   f" ({len(raw) / 1e6:.1f} -> {len(data) / 1e6:.1f} MB)")

    drop_unused_accessors(gltf)
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
