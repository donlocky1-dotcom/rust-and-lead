# Bild-Prompts für die Prio-1-Gebäude

Fertige Prompts für **ChatGPT (DALL·E/GPT-Image) oder Gemini**. Ablauf:

1. Prompt einsetzen → **ein Bild** erzeugen lassen.
2. Bild in **Meshy → Image to 3D** hochladen (nicht Text-to-3D — aus einem Bild wird die
   Silhouette deutlich sauberer, und wir bekommen das Gebäude, das wir gesehen haben).
3. GLB exportieren, durch `godot/tools/prepare_meshy_glb.py` schicken, ablegen unter
   `godot/assets/models/buildings/`.

Die Prompts sind **englisch** — Bildmodelle sind darauf deutlich zuverlässiger. Alle enthalten
denselben Block aus vier Anforderungen, und jede davon hat einen Grund:

* **plain neutral background, no ground, no shadows** — alles, was nicht das Gebäude ist,
  landet sonst mit im 3D-Modell (ein angewachsener Bodenteller ist der häufigste Fehler).
* **three-quarter view, slightly from above** — entspricht unserer Kamera (52° Neigung) und
  zeigt zwei Fassaden plus Dach, also alles, was die Rekonstruktion braucht.
* **entire building visible, centered, margin on all sides** — angeschnittene Kanten werden
  zu Löchern.
* **no people, no text, no logos** — Schrift wird zu Matsch, Figuren zu Auswüchsen.

Maße stehen jeweils dabei: **so groß steht das Gebäude im Spiel** (die `AssetRegistry`
skaliert automatisch, die Angabe dient den Proportionen — ein 16-m-Saloon ist breit und
niedrig, kein Turm).

Stil-Kern aus dem GDD (§ Ton & Stil): **grim-dark Steampunk-Western**, Fallout/Diablo IV.
Kein Retro, kein Pixel-Look, keine Cyberpunk-Motive — Zahnräder, Dampfdruck, Messing,
Nietblech, verwittertes Holz.

---

## 1. Gatling-Saloon — 16 × 11 m Grundfläche, 7,5 m hoch

Township-Kern: Auftragsbrett, Mamma „Rusty" Mabel, ausgeschlachtete Gatling als Kronleuchter.

```
A single grim-dark steampunk western saloon building, standing alone as a 3D game asset
concept. Two-storey timber frontage with a tall false facade board, a covered porch on
rusted iron posts, swinging double doors, dusty glass windows with brass frames. Walls of
sun-bleached grey planks patched with riveted boiler plate; corrugated iron roof, a crooked
brass steam pipe and a small pressure gauge on the side wall; a hanging oil lantern by the
door. Wide and low proportions, roughly 16 metres wide, 11 metres deep, 7.5 metres tall.
Weathered, sand-worn, desert-baked, no bright colours — rust brown, bleached wood grey,
tarnished brass.
Three-quarter front view, camera slightly above eye level. Plain neutral mid-grey background,
no ground plane, no cast shadows, even soft studio lighting. Entire building visible and
centered with margin on all sides. No people, no text, no signage lettering, no logos, no
watermark. Photorealistic PBR game asset, high detail.
```

---

## 2. Eiserne Schmiede — 12 × 10 m, 6 m hoch

Silas „Kupferauge" Finchs Werkstatt: Handelsposten, Amboss, Esse.

```
A single grim-dark steampunk western blacksmith forge building, standing alone as a 3D game
asset concept. Squat and heavy: stone-and-brick lower walls, upper walls of riveted iron
plate, a wide open work bay on one side with a stone chimney and a soot-blackened brick
forge stack rising through the roof. A steam boiler with copper piping and a pressure gauge
bolted to the outer wall, a rack of iron stock leaning beside the bay, heavy timber roof
beams. Roughly 12 metres wide, 10 metres deep, 6 metres tall.
Weathered and soot-stained, rust brown, iron grey, tarnished copper accents.
Three-quarter front view, camera slightly above eye level. Plain neutral mid-grey background,
no ground plane, no cast shadows, even soft studio lighting. Entire building visible and
centered with margin on all sides. No people, no text, no logos, no watermark. Photorealistic
PBR game asset, high detail.
```

---

## 3. Wohnhütte — 5–8 m breit, 3,4–4,8 m hoch (drei Varianten)

Gebaut aus dem, was die Iron Rail übrig gelassen hat: Bahnschwellen und Kesselblech.

```
A single small grim-dark steampunk western shack, standing alone as a 3D game asset concept.
Improvised dwelling built from salvaged railway sleepers and curved boiler plate, walls
leaning slightly out of true, a lopsided corrugated iron roof weighed down with stones, a
narrow crooked door, one small window covered by a scrap-metal shutter, a short stove pipe
with a rain cap. Roughly 6 metres wide, 5 metres deep, 4 metres tall — clearly smaller than a
two-storey building.
Poor, patched, wind-scoured, desert dust in every seam; grey weathered timber, rust brown
metal, no bright colours.
Three-quarter front view, camera slightly above eye level. Plain neutral mid-grey background,
no ground plane, no cast shadows, even soft studio lighting. Entire structure visible and
centered with margin on all sides. No people, no text, no logos, no watermark. Photorealistic
PBR game asset, high detail.
```

> **Für die drei Varianten** denselben Prompt dreimal laufen lassen und je einen Satz ergänzen:
> „*The roof sags deeply on one side.*" / „*A lean-to woodshed is attached to the right wall.*" /
> „*The walls are clad entirely in overlapping rusted sheet metal.*"

---

## 4. Wasserturm — ~20 m hoch, Tank 9 × 9 × 6 m

Rustwaters Wiedererkennungs-Silhouette. Man sieht ihn, bevor man die Stadt sieht.

```
A single grim-dark steampunk western water tower, standing alone as a 3D game asset concept.
A large riveted iron water tank with a conical roof, raised high on four splayed timber legs
with diagonal cross-bracing, a narrow ladder running up one leg to a small railed catwalk
around the tank. A thick spout pipe and a valve wheel on the tank's side, streaks of rust
running down the metal from every rivet, tar sealing the seams. Tall and slender overall:
roughly 20 metres tall, the tank about 9 metres across and 6 metres high.
Weathered iron, dark tar black, sun-bleached timber, heavy rust staining.
Three-quarter view, camera at mid-height of the structure. Plain neutral mid-grey background,
no ground plane, no cast shadows, even soft studio lighting. Entire structure visible from
footings to roof, centered with margin on all sides. No people, no text, no lettering on the
tank, no logos, no watermark. Photorealistic PBR game asset, high detail.
```

> Der Teer-Schriftzug „RUSTWATER" mit tropfendem W (GDD) kommt **nicht** in den Prompt —
> Bildmodelle schreiben unbrauchbar. Den setzen wir später als eigene Textur oder Decal drauf.

---

## 5. Palisaden-Segment + Tor — Pfosten 3,2 m, Torpfeiler 5,4 m

**Modular und kachelbar** — das ist hier die eigentliche Anforderung: Das Segment muss sich
nahtlos an sich selbst anreihen lassen, weil die Stadtmauer daraus als Ring gebaut wird.
Deshalb frontal statt schräg und mit senkrechten Schnittkanten.

```
A single straight modular palisade wall segment, grim-dark steampunk western style, as a 3D
game asset concept. A row of upright timber posts of uneven height, sharpened at the top,
lashed and bolted together, reinforced with two horizontal iron straps and a diagonal brace,
patched in places with riveted scrap metal plate. The segment ends flush and vertical on both
left and right so that copies can be placed side by side seamlessly. Roughly 8 metres long
and 3.2 metres tall, a flat straight wall — not a curve, not a corner.
Weathered grey timber, rusted iron bands, desert dust.
Straight-on front view, camera at mid-height, minimal perspective. Plain neutral mid-grey
background, no ground plane, no cast shadows, even soft studio lighting. Entire segment
visible and centered with margin on all sides. No people, no text, no logos, no watermark.
Photorealistic PBR game asset, high detail.
```

Und das Tor dazu:

```
A single fortified gate for a timber palisade, grim-dark steampunk western style, as a 3D
game asset concept. Two heavy square gate towers of stacked timber and riveted iron plate,
about 5.4 metres tall, flanking a wide double gate of thick planks bound with iron straps and
studded with bolts. A crossbeam spans the towers above the opening, with a hanging lantern
and a small winch drum with chain. The opening is wide enough for a wagon.
Weathered grey timber, rusted iron, tar-sealed joints, desert dust.
Straight-on front view, camera at mid-height. Plain neutral mid-grey background, no ground
plane, no cast shadows, even soft studio lighting. Entire gate visible and centered with
margin on all sides. No people, no text, no logos, no watermark. Photorealistic PBR game
asset, high detail.
```

---

## Wenn die GLBs da sind

Aktuell steht Rustwater aus Primitiven (`OverworldView._build_township`) — Boxen mit den oben
genannten Maßen. Sobald die Dateien liegen, tausche ich Box gegen Modell; Kollision und
Beschriftung hängen an denselben Zahlen und wandern automatisch mit. Zielpfade:

```
godot/assets/models/buildings/saloon.glb
godot/assets/models/buildings/forge.glb
godot/assets/models/buildings/shack_a.glb   (b, c für die Varianten)
godot/assets/models/buildings/water_tower.glb
godot/assets/models/buildings/palisade.glb
godot/assets/models/buildings/gate.glb
```
