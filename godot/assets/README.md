# Assets — Rust & Lead (Godot 4)

3D-Assets für die Godot-Produktion. Zielformat: **glTF/GLB** (Godots natives 3D-Format;
FBX/OBJ werden importiert, glTF/GLB ist bevorzugt). PBR-Materialien (§1 Master-GDD).

## Export aus Meshy (oder einem anderen Generator)

**Format: `GLB`.** Das ist glTF in einer einzigen Binärdatei — **Mesh, Material und alle
Texturen stecken darin**. Kein Ordner mit losen PNGs, kein Materialpfad, der beim Kopieren
bricht: eine Datei ablegen, fertig.

| Einstellung in Meshy | Wert | Warum |
| :-- | :-- | :-- |
| Format | **GLB** | Godots natives Format, Texturen eingebettet |
| Textur / PBR | **an** (Base Color + Normal + Roughness + Metallic) | Godot liest die glTF-PBR-Maps direkt; Metallic/Roughness kommen gepackt als **ORM** an — das ist normal und richtig |
| Texturauflösung | **2K**, für kleine Props 1K | Mobile-Ziel; 4K bringt auf dem Handy nichts außer Ladezeit |
| Topologie | **Quads** | im Spiel egal (die GPU trianguliert eh), aber Quads bleiben in Blender editier- und riggbar — Dreiecke sind eine Einbahnstraße |
| Polygone | Charaktere ~5–15 k Tris, Props ~1–3 k | eine Wüste voller 100-k-Modelle ruckelt auf dem Handy. **Achtung:** 1 Quad = 2 Dreiecke, das Budget zählt in Dreiecken |

**Die Objektgröße (12 cm / 120 cm) hat mit der Polygonzahl nichts zu tun.** Das ist nur eine
Maßangabe — sie skaliert das Modell, sie verfeinert es nicht. Wie fein das Netz wird, steuert
allein die Polygon-/Topologie-Einstellung beim Generieren bzw. Exportieren. Und für uns ist die
Maßangabe ohnehin gleichgültig: die `AssetRegistry` skaliert jedes Modell auf seine Zielhöhe.

Wenn ein Export trotzdem mit einer Million Dreiecken ankommt (Scan-Auflösung statt
Spielauflösung), erledigt das Aufbereitungs-Skript unten die Reduktion — texturerhaltend.
| Y-up | **an** (glTF-Standard) | Godot ist Y-up |

**Nicht** FBX (Texturen hängen je nach Exporter außen dran, Godot importiert es nur über einen
Umweg) und **nicht** OBJ (kann kein PBR, nur eine `.mtl` mit losen Bilddateien).

Wenn Meshy ein ZIP liefert: entpacken, die `.glb` daraus an den Zielpfad legen — den Rest
(`.bin`, Texturordner) braucht man bei GLB nicht. Nur falls du `.gltf` statt `.glb` exportierst,
müssen `.bin` und der Texturordner **mit umziehen**, sonst ist das Modell weiß.

### Animationen (Rigging in Meshy)

**Ja, mach das in Meshy.** Rigging + Preset-Animationen dort sind für unseren Zweck völlig
ausreichend, und der Export ist derselbe: **GLB trägt Skelett und Animationen mit** — eine Datei,
Godot legt beim Import automatisch einen `AnimationPlayer` an.

* **Wenn du mehrere Clips in einen Export packen kannst, tu das** (idle + walk am wichtigsten).
  Geht nur ein Clip pro Datei, sag Bescheid — dann trage ich die Zusatzdateien als
  Animationsbibliothek ein.
* **Clip-Namen sind egal.** Die Registry sucht über Namensteile: „Walking", „Armature|Walk",
  „laufen", „Walk_A" werden alle als *walk* erkannt (`AssetRegistry.CLIP_ALIASES`).
* **Gebraucht werden, in dieser Reihenfolge:** `idle`, `walk`, `attack`, `hit`, `death`.
  Fehlt eine Rolle, passiert nichts Schlimmes — das Modell steht dann eben still.
* **Was schon verkabelt ist:** Der Spieler schaltet beim Laufen auf *walk* und im Stehen auf
  *idle*; Gegner spielen *idle*, *walk* beim Verfolgen und *attack* im Nahkampf.
* **Quadrupeden (Bolzen, der Blechhund) rigged Auto-Rigging erfahrungsgemäß schlecht** — das
  ist auf Zweibeiner ausgelegt. Wenn Bolzen zerknautscht aussieht: lieber unanimiert liefern,
  die Bewegung kann die Szene übernehmen (Trab-Wippen per Code kostet uns fünf Zeilen).

### Nach dem Download: einmal durchs Aufbereitungs-Skript

```bash
python3 tools/prepare_meshy_glb.py ~/Downloads/Meshy_Merged_Animations.glb \
        assets/models/characters/player.glb
```

Das räumt genau die Voreinstellungen auf, die für eine Browser-Vorschau gedacht sind und im
Spiel schaden. Gemessen: Spieler-Chassis **40,7 MB → 2,3 MB**, Panzer **51,8 MB → 3,9 MB**.

* **Dreiecks-Budget** (`--max-tris`, Standard 20 000). Der Panzer kam mit **1.408.758**
  Dreiecken — das ist Scan-Auflösung; ein einziges solches Modell kostet auf dem Handy mehr als
  die restliche Szene. Reduziert wird mit Quadric Edge Collapse **mit Texturkoordinaten**, die
  Bemalung bleibt also an Ort und Stelle. Gehäutete Modelle (mit Skelett) bleiben unangetastet,
  weil dort Knochengewichte an jedem Eckpunkt hängen.
* **4k-Texturen → 2k** (und JPEG statt PNG, wenn kein echtes Alpha drin ist).
* **Selbstleuchten raus — aber nur, wo es keins sein soll.** Drei Fälle, drei Gründe:
  ist die Emissive-Textur *identisch mit der Farbtextur*, ist es Meshys Vorschau-Trick (das
  Modell reagiert dann gar nicht auf Licht); ist sie *schwarz*, sind es tote Daten; **eine echte
  Glow-Map bleibt drin** — davon lebt der Steampunk-Look.
* **metallicFactor → 0**, wenn keine Metallic-Textur dabei ist. Der glTF-Standardwert ist 1,0,
  also vollmetallisch — und ein metallisches Material ohne Spiegelungsumgebung rendert
  **schwarz**. Genau daran lag die schwarze Spielerfigur.
* **alphaMode BLEND → OPAQUE** und **doubleSided aus**: eine undurchsichtige Figur als
  transparent zu rendern kostet Sortierung und Füllrate, ohne dass man etwas davon hätte.
* Animationen bleiben unangetastet.

### Kleidung & Anbauteile (Mantel, Hut, Rucksack)

Ein Mantel kommt als **eigene Datei**, nicht in die Figur hineinmodelliert:
`models/characters/player_coat.glb`. Grund: als separates Mesh kann er sich frei bewegen —
in die Figur eingebacken würde ihn deren Rig mitverformen, und Auto-Rigging kennt keine
Stoff-Knochen.

**Wichtig beim Export:** derselbe Ursprung und derselbe Maßstab wie die Figur (also in der
Pose exportieren, in der die Figur modelliert wurde — Meshy macht das von allein, wenn der
Mantel aus derselben Figur stammt). Der Mantel wird dann am Brustknochen (`Spine`) aufgehängt
und bekommt automatisch den Schwung-Shader: der Saum zieht beim Laufen nach, hebt sich mit dem
Tempo und flattert im Wind. Kein Rigging nötig, keine Stoffsimulation.

**Was du NICHT selbst richten musst** — das macht die `AssetRegistry` beim Instanziieren:
* **Größe:** wird auf die Zielhöhe unten in der Tabelle skaliert, egal wie groß Meshy exportiert.
* **Pivot/Höhe:** die Unterkante wird auf Y = 0 gelegt. Generatoren setzen den Pivot fast immer
  in die Modellmitte — ohne diese Korrektur würde die Figur zur Hälfte im Sand stecken.
* **Blickrichtung:** falls das Modell rückwärts läuft, trage die Gradzahl in
  `AssetRegistry.YAW_DEG` ein (z. B. `"player": 180.0`) — eine Zahl statt einer Blender-Runde.

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

**Ausrichtung:**
- **+Y = oben** (glTF-Standard, kommt aus jedem Generator richtig).
- Pivot egal — die Registry legt die Unterkante des Modells auf **Y = 0**.
- **Blickrichtung = −Z** (Godot-Konvention). In Blender beim glTF-Export: `-Y forward, Z up`.
  Bei generierten Assets: notfalls über `AssetRegistry.YAW_DEG` korrigieren.
- 1 Godot-Unit = **1 Meter** (die Welt spannt 5000 × 5000 m, §1.4).

## Gesuchte Assets (Registry-Namen & Pfade)

Priorität von oben nach unten — das Erste bringt den größten sichtbaren Sprung.

| Was | Datei ablegen unter | Zielhöhe |
| :-- | :-- | :-- |
| ~~Spieler-Chassis~~ ✅ **fertig** | `models/characters/player.glb` | 1,8 m |
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
