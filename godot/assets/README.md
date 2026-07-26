# Assets — Rust & Lead (Godot 4)

3D-Assets für die Godot-Produktion. Zielformat: **glTF/GLB** (Godots natives 3D-Format;
FBX/OBJ werden importiert, glTF/GLB ist bevorzugt). PBR-Materialien (§1 Master-GDD).

## So kommt ein Asset ins Spiel

**Datei am richtigen Pfad ablegen — mehr nicht.** Die `AssetRegistry`
(`scripts/AssetRegistry.gd`) sucht beim Start nach jedem Modell; ist es da, wird es benutzt,
fehlt es, zeichnet die Szene ihren Platzhalter (Kapsel/Box). Das Projekt bleibt dadurch
**immer lauffähig**, egal wie viele Assets schon fertig sind — und niemand muss Code
anfassen, wenn ein neues Modell dazukommt.

**Größe egal:** Modelle werden beim Instanziieren automatisch auf ihre Zielhöhe skaliert
(`AssetRegistry.instantiate(name, hoehe_in_metern)`), inklusive verschachtelter
glTF-Transforms. Ein Chassis darf also in Blender 200 Einheiten hoch sein — im Spiel steht
es korrekt in 1,8 m.

**Ausrichtung (wichtig — das kann die Registry nicht raten):**
- **+Y = oben**, Figur steht mit den Füßen auf **Y = 0** (Pivot am Boden, nicht in der Mitte).
- **Blickrichtung = −Z** (Godot-Konvention). In Blender beim glTF-Export: `-Y forward, Z up`.
- 1 Godot-Unit = **1 Meter** (die Welt spannt 5000 × 5000 m, §1.4).

## Gesuchte Assets (Registry-Namen & Pfade)

Priorität von oben nach unten — das Erste bringt den größten sichtbaren Sprung.

| Was | Datei ablegen unter | Zielhöhe |
| :-- | :-- | :-- |
| **Spieler-Chassis** | `models/characters/player.glb` | 1,8 m |
| Grenzgänger (organisch) | `models/enemies/outlaw.glb` | 1,6 m |
| Ölfresser-Ratte (organisch, Schwarm) | `models/enemies/fauna.glb` | ~0,6 m |
| Revolverheld (organisch, Fernkampf) | `models/enemies/revolver.glb` | 1,6 m |
| Konzern-Konstrukt (Maschine) | `models/enemies/konstrukt.glb` | 1,9 m |
| Kessel-Kläffer (Maschine, Schwarm) | `models/enemies/klaeffer.glb` | ~0,8 m |
| Schwerer Ernter / Goliath (Boss) | `models/enemies/goliath.glb` | ~4 m |
| Bolzen, der Blechhund (Begleiter) | `models/characters/bolzen.glb` | ~0,7 m |

`.gltf` funktioniert genauso — die Registry prüft beide Endungen.

**Kampf-Lesbarkeit beim Design mitdenken** (GDD §8.4): **eckig + stahlblau = Maschine**
(galvanisch verwundbar), **rund + fleischrot = organisch** (kinetisch verwundbar). Die
Silhouette soll die Waffenwahl schon vor dem ersten Schuss verraten.

## Ordnerstruktur
```
assets/
├── models/
│   ├── characters/    # Spieler-Chassis, Bolzen, NPCs
│   ├── enemies/       # Grenzgänger, Fauna, Konstrukte, Goliath, Bosse
│   ├── environment/   # Boden-/Level-Module, Gebäude, Felsen, Wände
│   ├── props/         # Palisaden, Kisten, Wracks, Dekor
│   └── items/         # Loot, Truhen, Granaten
├── textures/          # PBR-Maps (Albedo/Normal/Roughness/Metallic), falls extern
└── materials/         # wiederverwendbare .tres-Materialien
```

## Import-Hinweise
- Godot importiert glTF automatisch beim ersten Projektstart (dauert einmalig etwas).
- Kollision/NavMesh werden pro Modell im Import-Dock oder per Szene ergänzt (nicht im Mesh).
- Ein neues Modell braucht **keinen** Code-Eintrag, solange es einen der oben gelisteten
  Namen benutzt. Für zusätzliche Kategorien: Eintrag in `AssetRegistry.PATHS` ergänzen.
- Herkunft/Lizenz jeder Datei in `CREDITS.md` vermerken (auch bei CC0 gute Praxis).

## Lizenz
Assets hier sind **CC0** (Public Domain), sofern in `CREDITS.md` nicht anders vermerkt.
