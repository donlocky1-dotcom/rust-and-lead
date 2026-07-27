# Bild-Prompts für die Prio-1-Gebäude

Fertige Prompts für **ChatGPT (DALL·E/GPT-Image) oder Gemini**. Ablauf:

1. Prompt einsetzen → **ein Bild** erzeugen lassen.
2. Bild in **Meshy → Image to 3D** hochladen (nicht Text-to-3D — aus einem Bild wird die
   Silhouette deutlich sauberer, und wir bekommen das Gebäude, das wir gesehen haben).
3. GLB exportieren, durch `godot/tools/prepare_meshy_glb.py` schicken, ablegen unter
   `godot/assets/models/buildings/`.

Die Prompts sind **englisch** — Bildmodelle sind darauf deutlich zuverlässiger.

## Die drei Regeln, aus denen diese Prompts gebaut sind

**1. Aus UNSEREM Blickwinkel, nicht als Fassadenfoto.** Die Spielkamera steht 52° über dem
Horizont. Aus diesem Winkel sieht man vor allem **Dächer** — eine fein detaillierte Fassade
ist im Spiel fast unsichtbar. Deshalb steht in jedem Prompt „*seen from a high three-quarter
angle roughly 50 degrees above the horizon*", und deshalb bekommt jedes Dach eigene Sätze:
verschiedene Ebenen, geflickte Materialien, Aufbauten. Der erste Saloon-Entwurf hatte eine
schöne Fassade und eine große graue Wellblechplatte obendrauf — im Spiel wäre davon nur die
Platte zu sehen gewesen.

**2. Silhouette vor Detail.** Im ARPG erkennt man ein Gebäude an der Umrisslinie, bevor man
Details ausmacht. Jedes Haus bekommt deshalb eine gebrochene, asymmetrische Form (Anbau,
Schornstein, Aufbau) statt eines Quaders — und ein **Erkennungszeichen**, das man aus zehn
Metern liest.

**3. Grim-dark heißt nicht farblos.** In der Sonnenglut eines Kraters darf verblichenes Rot,
Ocker oder Grünspan durchkommen. Ein komplett entsättigtes Modell verschwindet im Sandboden.

Dazu in jedem Prompt derselbe Schlussblock, der die häufigsten Rekonstruktionsfehler
verhindert:

* **plain neutral background, no ground, no shadows** — sonst wächst ein Bodenteller ans Modell.
* **entire building visible, centered, margin** — angeschnittene Kanten werden zu Löchern.
* **no people, no text, no logos** — Schrift wird zu Matsch, Figuren zu Auswüchsen.

Maße stehen jeweils dabei: **so groß steht das Gebäude im Spiel.** Die `AssetRegistry`
skaliert automatisch, die Angabe steuert die Proportionen — ein 16-m-Saloon ist breit und
niedrig, kein Turm.

---

## 1. Gatling-Saloon — 16 × 11 m Grundfläche, 7,5 m hoch

Township-Kern: Auftragsbrett, Mamma „Rusty" Mabel. Die ausgeschlachtete Gatling hängt laut GDD
als Kronleuchter **drinnen** — von außen unsichtbar, deshalb wandert sie hier als Aushängeschild
über die Tür. Ohne sie ist es irgendein Western-Haus.

```
A single grim-dark steampunk western saloon building, standing alone as a 3D game asset
concept, seen from a high three-quarter angle roughly 50 degrees above the horizon, so that
both the roofs and two facades are clearly visible.
Distinctive asymmetric silhouette: a two-storey main block with a tall stepped false facade,
a deep covered porch on cast-iron columns, and a lower single-storey lean-to wing attached on
the right at a slight angle. A tall soot-blackened brick chimney rises from the wing, and a
riveted brass steam drum with pipework sits on the porch roof.
The roofs carry the eye: several different planes patched from mismatched materials —
corrugated iron, tar paper held down by planks, and wooden shingles — a dirty glass skylight,
a crooked stovepipe, and a few crates and a water barrel on the porch roof.
Above the swinging doors, mounted as a shop sign, hangs a salvaged multi-barrel gatling gun
cluster, brass and rust, unmistakable from a distance.
Walls of sun-bleached planks patched with riveted boiler plate; flaking remnants of deep red
and ochre paint on the false facade break up the grey; tarnished brass fittings.
Roughly 16 metres wide, 11 metres deep, 7.5 metres tall — wide and low, not a tower.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire building visible and centered with margin on all sides. No people, no text,
no lettering, no logos, no watermark. Photorealistic PBR game asset, high detail.
```

---

## 2. Eiserne Schmiede — 12 × 10 m, 6 m hoch

Silas' Werkstatt und unser Handelsposten. Erkennungszeichen ist die **offene Werkbucht mit
glühender Esse**: Das ist der einzige Ort in Rustwater, der von selbst leuchtet.

> Das Glühen ist nicht nur Optik — Meshy legt so etwas als **Emissive-Map** an, und unsere
> Aufbereitung erkennt eine echte Glow-Map inzwischen und behält sie (nur Meshys
> Selbstleucht-Trick fliegt raus). Die Esse glimmt im Spiel also wirklich.

```
A single grim-dark steampunk western blacksmith forge building, standing alone as a 3D game
asset concept, seen from a high three-quarter angle roughly 50 degrees above the horizon, so
that both the roof and two facades are clearly visible.
Squat, heavy and asymmetric: a stone-and-brick lower storey with upper walls of riveted iron
plate, and a wide open work bay cut into the front corner, its interior dark except for the
orange glow of a forge fire and a bed of hot coals. A massive soot-blackened brick chimney
stack rises through the roof beside the bay, and a riveted steam boiler with copper piping,
a pressure gauge and a large iron flywheel is bolted to the outer wall.
The roof carries the eye: heavy exposed timber beams under mismatched corrugated iron sheets,
one section replaced with fresh unrusted metal, a soot-stained ventilation cupola with open
louvres above the forge, and iron stock and a stack of tools leaning against the chimney.
Roughly 12 metres wide, 10 metres deep, 6 metres tall — low and broad.
Soot-stained and rust brown with tarnished copper and verdigris green accents on the pipework;
the warm forge glow is the only bright colour.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire building visible and centered with margin on all sides. No people, no text,
no lettering, no logos, no watermark. Photorealistic PBR game asset, high detail.
```

---

## 3. Wohnhütten — drei eigenständige Bauten, 5–8 m breit, 3,4–4,8 m hoch

In Rustwater stehen zehn Hütten im Ring um das Zentrum. Zehn Kopien desselben Hauses fallen
sofort auf — also drei **verschiedene Bauweisen** statt drei Varianten einer Bauweise. Jede
folgt einer eigenen Notlösung mit dem, was die Iron Rail übrig gelassen hat, und das ergibt
drei klar unterscheidbare Umrisslinien:

| | Bauweise | Silhouette | Farbe |
| :-- | :-- | :-- | :-- |
| **A** | Bahnschwellen gestapelt | **niedrig und breit**, massiv | teerschwarz |
| **B** | halbierter Kessel | **gerundet**, Tonnendach | rostorange |
| **C** | aufgeständert, mit Schlafboden | **hoch und schmal** | bleiches Holz + Segeltuch |

Nebeneinander gestellt sieht man auf einen Blick drei Häuser, nicht dreimal eins.

### A — Bahnschwellen-Kate (~7 × 5 m, 3,4 m hoch)

```
A single small grim-dark steampunk western cabin, standing alone as a 3D game asset concept,
seen from a high three-quarter angle roughly 50 degrees above the horizon, so that the roof
and two walls are clearly visible.
Built like a log cabin but from heavy salvaged railway sleepers stacked horizontally, their
ends overlapping at the corners, still black with creosote tar and studded with the old rail
spikes and fishplates. Low, squat and solid, sitting heavily on the ground; a small door of
vertical planks and one deep-set window with an iron shutter.
The roof carries the eye: a shallow single-pitch roof of overlapping tar paper strips held
down by loose sleepers laid across it, sagging in the middle between two rafters, with a
crooked stove pipe and a scattering of rocks along the lower edge.
Roughly 7 metres wide, 5 metres deep, only 3.4 metres tall — long, low and heavy.
Creosote black and dark brown timber, iron spikes bleeding orange rust stains down the walls,
pale desert dust caked along the bottom course.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire structure visible and centered with margin on all sides. No people, no text,
no lettering, no logos, no watermark. Photorealistic PBR game asset, high detail.
```

### B — Kesselhütte (~5 × 6 m, 4 m hoch)

```
A single small grim-dark steampunk western dwelling, standing alone as a 3D game asset
concept, seen from a high three-quarter angle roughly 50 degrees above the horizon, so that
the curved roof and the front are clearly visible.
Built inside a huge riveted iron boiler shell laid on its side and cut open: the walls and
roof form one continuous barrel vault of curved rusted plate, closed off at the front by a
flat wall of mismatched planks with a low door and a small round porthole window still framed
in brass. Sandbags and rubble are heaped against the lower curve on one side.
The curved roof carries the eye: hundreds of rivets along the overlapping plate seams, one
large patch of newer corrugated iron wired over a hole, a short chimney pipe punched through
the curve with a metal collar, and a rain-catching gutter of split pipe running along the edge
into a barrel.
Roughly 5 metres wide, 6 metres deep, 4 metres tall — unmistakably round-backed, never boxy.
Deep orange-brown rust over dark iron, tar smeared along the seams, brass porthole ring as the
only bright metal.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire structure visible and centered with margin on all sides. No people, no text,
no lettering, no logos, no watermark. Photorealistic PBR game asset, high detail.
```

### C — Stelzenhütte mit Schlafboden (~5 × 5 m, 4,8 m hoch)

```
A single small grim-dark steampunk western stilt shack, standing alone as a 3D game asset
concept, seen from a high three-quarter angle roughly 50 degrees above the horizon, so that
the roof, the raised floor and two walls are clearly visible.
Tall and narrow: a one-room hut raised about one metre off the ground on stacked stone piers
and two salvaged rail bogies, to keep the drifting sand out. Walls of thin sun-bleached
vertical planks with wide gaps stuffed with rags; a rickety external staircase of plank treads
climbs the side wall to a small sleeping loft added on top, its walls made of stretched
canvas tarpaulin over a timber frame. A narrow porch of two boards runs along the front.
The roof carries the eye: two separate small roofs at different heights — corrugated iron over
the loft and tar paper over the main room — a taut guy rope from the loft corner down to a
ground anchor, a lantern hook, and a bundle of firewood stored under the raised floor.
Roughly 5 metres wide, 5 metres deep, 4.8 metres tall — clearly the tallest and thinnest of
the shacks.
Pale sun-bleached silver-grey timber, dirty off-white canvas, rusted iron fittings; a strip of
faded green paint on the loft frame as the only colour.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire structure visible and centered with margin on all sides. No people, no text,
no lettering, no logos, no watermark. Photorealistic PBR game asset, high detail.
```

---

## 4. Wasserturm — ~20 m hoch, Tank 9 × 9 × 6 m

Rustwaters Wiedererkennungs-Silhouette: Man sieht ihn, bevor man die Stadt sieht. Hier ist die
Umrisslinie ohnehin die halbe Miete — der Prompt schärft sie über die **gespreizten Beine** und
den Kranz aus Rostfahnen.

```
A single grim-dark steampunk western water tower, standing alone as a 3D game asset concept,
seen from a three-quarter angle slightly above the tank, roughly 30 degrees above the horizon,
so that the conical roof and the leg structure are both clearly visible.
A large riveted iron water tank with a shallow conical roof, raised high on four splayed
timber legs with heavy diagonal cross-bracing, so the silhouette widens towards the ground. A
narrow ladder runs up one leg to a railed catwalk encircling the tank; a thick spout pipe with
a counterweight and a large iron valve wheel hangs from the tank's side.
The roof and upper tank carry the eye: overlapping iron plates with hundreds of rivets, a
small hatch standing open, a bent lightning rod, and long streaks of rust running down from
every rivet and seam onto the tar-sealed bands below.
Tall and slender overall: roughly 20 metres tall, the tank about 9 metres across and 6 metres
high — the tank must read as heavy and the legs as barely sufficient.
Weathered iron, tar black seams, sun-bleached timber, heavy orange rust staining against the
grey — the rust is the colour.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire structure visible from footings to roof, centered with margin on all sides.
No people, no text, no lettering on the tank, no logos, no watermark. Photorealistic PBR game
asset, high detail.
```

> Der Teer-Schriftzug „RUSTWATER" mit tropfendem W (GDD) kommt bewusst **nicht** in den Prompt —
> Bildmodelle schreiben unbrauchbar. Den setzen wir später als eigene Textur oder Decal drauf.

---

## 5. Palisaden-Segment + Tor — Pfosten 3,2 m, Torpfeiler 5,4 m

Hier gilt Regel 1 **nicht**: Ein kachelbares Wandstück braucht senkrechte Schnittkanten, und
die bekommt man nur aus einer nahezu frontalen Ansicht. Nur leicht von oben, damit die
Pfostenspitzen und die Wanddicke mitkommen — sonst rekonstruiert Meshy eine Fläche ohne Tiefe.

```
A single straight modular palisade wall segment, grim-dark steampunk western style, as a 3D
game asset concept, seen straight from the front with a slight downward tilt, about 20 degrees
above horizontal, so that the sharpened post tops and the thickness of the wall are visible.
A row of upright timber posts of uneven height, sharpened at the top, lashed and bolted
together, reinforced with two horizontal iron straps and one diagonal brace, patched in
places with riveted scrap metal plate and a single railway sleeper set among the posts.
The segment ends flush and vertical on both the left and the right edge, with the end posts
cut clean, so that copies can be placed side by side seamlessly. Roughly 8 metres long and
3.2 metres tall, a flat straight wall — not a curve, not a corner, no gate.
Weathered grey timber with deep cracks, rusted iron bands, desert dust caked in the joints.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire segment visible and centered with margin on all sides. No people, no text,
no logos, no watermark. Photorealistic PBR game asset, high detail.
```

Und das Tor dazu — das darf Silhouette haben, es ist der Eingang zur Stadt:

```
A single fortified gate for a timber palisade, grim-dark steampunk western style, as a 3D game
asset concept, seen straight from the front with a slight downward tilt, about 25 degrees
above horizontal.
Two heavy square gate towers of stacked timber and riveted iron plate, about 5.4 metres tall,
flanking a wide double gate of thick planks bound with iron straps and studded with bolts.
Each tower is capped with a small shed roof of corrugated iron and a railed lookout platform;
a crossbeam spans the towers above the opening, carrying a hanging oil lantern and a heavy
winch drum with chain that runs down to the gate. The opening is wide enough for a wagon.
Weathered grey timber, rusted iron, tar-sealed joints, desert dust; faded ochre paint remains
on the gate planks.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio
lighting. Entire gate visible and centered with margin on all sides. No people, no text, no
logos, no watermark. Photorealistic PBR game asset, high detail.
```

---

## Die Hebel, wenn ein Ergebnis nicht passt

| Was stört | Welchen Satz du anfasst |
| :-- | :-- |
| Zu grau | den Farbsatz („*flaking remnants of deep red and ochre paint*" o. ä.) — Farbe und Menge ändern |
| Zu brav, zu symmetrisch | den Silhouetten-Satz („*lower lean-to wing … at a slight angle*") — mehr Anbauten, stärkere Schieflage |
| Nicht wiedererkennbar | das Erkennungszeichen austauschen (Gatling, glühende Esse, Rostfahnen) |
| Dach zu leer | den „*The roof carries the eye*"-Satz erweitern |
| Falscher Blickwinkel | die Gradzahl im ersten Satz ändern |

---

## Wenn die GLBs da sind

Aktuell steht Rustwater aus Primitiven (`OverworldView._build_township`) — Boxen mit genau den
oben genannten Maßen. Sobald die Dateien liegen, tausche ich Box gegen Modell; Kollision und
Beschriftung hängen an denselben Zahlen und wandern automatisch mit. Zielpfade:

```
godot/assets/models/buildings/saloon.glb
godot/assets/models/buildings/forge.glb
godot/assets/models/buildings/shack_a.glb   (b, c für die Varianten)
godot/assets/models/buildings/water_tower.glb
godot/assets/models/buildings/palisade.glb
godot/assets/models/buildings/gate.glb
```
