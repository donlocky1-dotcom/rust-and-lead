# Was wir noch brauchen

Stand nach dem Handy-Test. Sortiert nach **Wirkung pro Aufwand** — oben das, was am meisten
verändert, unten das Angenehme.

Alles, was hier steht, hat im Spiel schon einen Platz: Der Code fragt über `AssetRegistry` nach
einem logischen Namen und zeichnet einen Platzhalter, solange die Datei fehlt. Du kannst also in
beliebiger Reihenfolge liefern, und nichts geht dabei kaputt.

---

## Priorität 1 — Waffen (5 fehlen von 6)

Der größte Einzelposten. `CombatData.WEAPONS` kennt fünf Waffen, im Spiel steht ein Modell:
der Karabiner. Die anderen vier sehen aus wie er, obwohl sie sich völlig anders spielen — die
Gatling schießt zwölfmal so schnell und hat 60 Schuss im Gurt.

| Datei | Waffe | Werte im Spiel | Länge |
|---|---|---|---|
| `weapons/karabiner.glb` | Blei-Karabiner | 34 Schaden, 850 ms, 10 Schuss | ✅ da |
| `weapons/gatling.glb` | Kurbel-Gatling | 6 Schaden, **70 ms**, 60 Schuss, 4,5 s Nachladen | 1,3 m |
| `weapons/voltgun.glb` | Voltgewehr | 22 Schaden, 420 ms, Blitz | 1,1 m |
| `weapons/saeure.glb` | Säurewerfer | 11 Schaden, 240 ms, Ätzschaden | 1,0 m |
| `weapons/brenner.glb` | Dampf-Brenner | 9 Schaden, 130 ms, Flamme | 1,2 m |

**Was jede braucht:** Silhouette, die man am Rücken der Figur erkennt. Die Waffe hängt beim
Laufen sichtbar am Körper — eine Gatling muss von hinten als Trommel lesbar sein, ein
Säurewerfer als Tank mit Schlauch. 3 000–6 000 Dreiecke, 1k-Textur.

## Priorität 2 — Gegner (4 fehlen von 6, plus der Hund)

Ohne Modell zeichnet die Szene eine farbige Kapsel. Man kämpft also gegen Kapseln.

| Datei | Gegner | Höhe | Prompt |
|---|---|---|---|
| `enemies/fauna.glb` | Ölfresser-Ratte | 0,6 m | ✅ da |
| `enemies/konstrukt.glb` | Konzern-Konstrukt | 2,0 m | ✅ da |
| `enemies/outlaw.glb` | Grenzgänger | 1,6 m | `PROMPTS_GEGNER.md` |
| `enemies/revolver.glb` | Revolverheld | 1,6 m | `PROMPTS_GEGNER.md` |
| `enemies/klaeffer.glb` | Kessel-Kläffer | 0,8 m | `PROMPTS_GEGNER.md` |
| `enemies/goliath.glb` | Schwerer Ernter (Boss) | 4,0 m | `PROMPTS_GEGNER.md` (vorne + hinten) |
| `characters/bolzen.glb` | Bolzen, der Blechhund | 0,7 m | fehlt noch, sag Bescheid |

Die vier Prompts stehen fertig in `docs/PROMPTS_GEGNER.md`. **Animationen wären ein Riesengewinn**
(Laufen, Angriff, Tod) — der Code sucht sie über `AssetRegistry.CLIP_ALIASES` selbst und braucht
keine bestimmten Namen; ohne Animation stehen die Gegner steif da und gleiten.

## Priorität 3 — Der Sumpf

Neu eingebaut (siehe unten), aber mit Platzhaltern bestückt. Die toten Bäume sind zwei Zylinder.

| Datei | Was | Höhe |
|---|---|---|
| `props/deadtree.glb` | Toter Moorbaum, kahl, schief, wenige krumme Äste | 5,5 m |
| `props/deadtree_b.glb` | Zweite Fassung, umgestürzt/gebrochen | 4,0 m lang |
| `props/rad_barrel.glb` | Aufgeplatztes Strahlenfass, grün auslaufend | 1,1 m |

Prompt-Bausteine für alle drei: *grim-dark steampunk western, single connected object, seen from
a high three-quarter angle roughly 45 degrees above the horizon, plain neutral mid-grey
background, no ground plane, no cast shadows, entire object centered with margin, no people, no
text, no logos, photorealistic PBR game asset, very low polygon count.* Dazu jeweils:

* **Moorbaum:** *A dead leafless swamp tree, bark peeled away to bare grey wood, trunk leaning
  and split, four or five crooked branches, roots exposed above waterline, roughly 5.5 metres
  tall and slender.*
* **Umgestürzt:** *A fallen dead tree lying broken across the ground, the trunk snapped in the
  middle with splintered ends, bark sloughing off, roughly 4 metres long.*
* **Strahlenfass:** *A burst steel drum lying on its side, the lid blown off and the seam split,
  glowing acid-green sludge running out and pooling around it, faded radiation-yellow paint
  flaking off the rust, roughly 1.1 metres tall.*

## Priorität 4 — Requisiten aus `PROMPTS_PROPS.md`

Handkarren (`props/handcart.glb`, 3,0 m) fehlt noch als einziger aus der Erstliste. Dazu die acht
Schrottteile aus `PROMPTS_SCHROTTGRUBE.md` — für die Grube nicht mehr nötig, aber als Streugut in
der Wüste und in Dungeons weiterhin nützlich.

## Priorität 5 — Gebäude

Zwei Wirtschaftsgebäude aus `TycoonManager` haben kein Modell: **Destille** und **Alchemie-Labor**.
Beide sind Ausbaustufen im Township und tauchen sonst im Ortsbild nicht auf. Prompts nach dem
Muster von `PROMPTS_GEBAEUDE.md`; Zielhöhe 6–7 m.

---

# Grafiken für die Oberfläche

Kurze Antwort: **Für das Inventar brauchst du nichts.** Es ist fertig und funktioniert mit
gezeichneten Feldern und Zeichen-Sinnbildern (⛑ 🧥 🔫 ⚙ 🥾). Das ist keine Notlösung —
Rasterfelder mit Rahmen in Seltenheitsfarbe lesen sich sauber, und die Zeichen sind auf jedem
Gerät scharf.

**Sinnvoll wären Grafiken an drei Stellen**, in dieser Reihenfolge:

### 1. Kategorie-Sinnbilder fürs Raster (6 Stück, je 128×128 PNG mit Alpha)

Ersetzen die Zeichen `⛑ 🧥 🔫 ⚙ 🥾 ▦`. Emoji sehen auf jedem Betriebssystem anders aus und
brechen den Ton — ein gemalter Helm passt zum Spiel, Apples Bauarbeiterhelm nicht.

Dateien: `ui/icon_helmet.png`, `icon_armor.png`, `icon_weapon.png`, `icon_gadget.png`,
`icon_boots.png`, `icon_plate.png`

Stil-Vorgabe für alle sechs (wichtig, dass sie als Satz wirken): *A single game inventory icon on
a fully transparent background, grim-dark steampunk western style. Rusted iron and brass, worn
leather, sun-bleached grey. Flat three-quarter view, thick readable silhouette, no background, no
frame, no text. The object fills the square with a small margin.* Dazu jeweils: `a riveted iron
helmet with a cracked glass visor` / `a heavy leather coat with iron shoulder plates` / `a lever
action rifle` / `a brass pressure gauge with copper coils` / `a pair of worn leather boots with
iron toecaps` / `a bolted steel plate`.

### 2. Knopf-Hintergründe (3 Stück, 9-Patch-fähig)

Die Knöpfe nutzen Godots Standarddesign — grau, rechteckig, unpassend. Drei Bilder ersetzen alle
Knöpfe im Spiel:

* `ui/btn_normal.png` — 96×48, gebürstetes Eisen mit Nieten in den Ecken, dunkel
* `ui/btn_hover.png` — dasselbe, eine Spur heller
* `ui/btn_disabled.png` — dasselbe, entsättigt und dunkler

*Wichtig:* Rand 12 px an allen Seiten glatt und einfarbig halten, damit Godot sie als 9-Patch
streckt. Sonst verzerren die Nieten.

### 3. Der Charakter-Knopf und der Schuss-Knopf (2 Stück, je 128×128)

`ui/btn_character.png` (eine Brustplatte oder ein Rucksack) und `ui/btn_fire.png` (ein
Fadenkreuz). Beide sind heute gezeichnet und funktionieren; ein Bild macht sie nur schöner.

**Was du NICHT brauchst:** Rahmen für die Tafeln, Rollbalken, Reiter, Nebel-Textur, Kartensymbole.
Alles gezeichnet und plattformunabhängig.

---

# Der Handy-Fehler ist behoben — und es war nicht der Knopf

Der Charakter-Knopf war da, oben links. Er war nur **winzig**: Das Projekt hatte keine
Bildschirm-Skalierung eingestellt, also zeichnete Godot die Oberfläche in echten Pixeln. Auf
einem Telefon mit 2400 px Breite ist ein 52-px-Knopf 2 % der Breite.

Behoben in `project.godot`: Bezugsauflösung 1280×720, `stretch/mode = canvas_items`,
`aspect = expand`. Damit sieht der HUD auf jedem Gerät aus wie am Computer, und ein 20:9-Telefon
bekommt den Überschuss als **zusätzliches Blickfeld** statt als kleinere Knöpfe.

Dabei ist noch ein zweiter Fehler aufgefallen, der alle Vollbild-Oberflächen betraf
(Inventar, Laden, Weltkarte, Joystick): `set_anchors_preset` setzt nur die Anker und lässt die
Ränder auf 0. Unter einem `CanvasLayer` blieben diese Bildschirme dadurch 0×0 groß — die
Abdunklung war unsichtbar, und alles mittig Verankerte zentrierte auf den Bildschirm-Nullpunkt
statt auf die Mitte. Jetzt überall `set_anchors_and_offsets_preset`.
