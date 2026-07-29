# Bild-Prompts für die Gegner

Vier der sechs Gegnertypen sind im Spiel noch graue Primitive — und Gegner sieht man häufiger
als jedes Gebäude. Ablauf wie gehabt: Bild erzeugen → **Meshy Image to 3D** → **in Meshy riggen
und animieren** → GLB durch `godot/tools/prepare_meshy_glb.py` → ablegen unter
`godot/assets/models/enemies/`.

Die Dateinamen stehen fest, die Pfade sind im `AssetRegistry` bereits eingetragen. Sobald eine
Datei liegt, ist der Gegner im Spiel — **es ist keine Code-Änderung nötig**:

| Datei | Gegner | Zielhöhe | Rolle |
| :-- | :-- | --: | :-- |
| `enemies/outlaw.glb` | Grenzgänger | 1,60 m | Nahkampf-Verfolger |
| `enemies/revolver.glb` | Revolverheld | 1,60 m | Fernkämpfer, hält Abstand |
| `enemies/klaeffer.glb` | Kessel-Kläffer | 0,80 m | sehr schneller Schwarm |
| `enemies/goliath.glb` | Schwerer Ernter | 4,00 m | Boss, langsamer Koloss |

---

## Was hier anders ist als bei Gebäuden und Requisiten

### 1. A-Pose, frontal — keine dramatische Dreiviertelansicht

Gebäude durften schräg von oben stehen. **Figuren nicht.** Die automatische Verknöcherung in
Meshy sucht Schultern, Ellbogen, Hüfte und Knie — sie findet sie zuverlässig nur, wenn die
Gliedmaßen frei vom Körper abstehen und nichts verdeckt ist. Steht die Figur dramatisch
gedreht mit angewinkeltem Arm da, verwächst das Rig, und die Laufanimation knickt später am
Ellbogen ein.

Deshalb steht in jedem Prompt: **gerade stehend, zum Betrachter, Arme leicht abgespreizt,
Beine leicht geöffnet, symmetrisch, ganzer Körper vom Scheitel bis zur Sohle im Bild.**

### 2. Keine wehenden Mäntel, keine Umhänge

Der Mantel war schon einmal ein Reinfall. Lose Stoffflächen hat der Rig nicht im Griff: Sie
gehören zu keinem Knochen und durchdringen im Lauf die Beine. Was hier geht, ist **anliegende
Kleidung** — Weste, Jacke bis zur Hüfte, meinetwegen ein knielanger Staubmantel, der eng am
Körper liegt und **vorne offen mit geraden Kanten** hängt. Alles, was flattern müsste, um gut
auszusehen, sieht animiert falsch aus.

### 3. Diese Animationen brauchen wir

Die Namen sind wichtig, nicht die genaue Auswahl: Der `AssetRegistry` findet Clips über
Namensteile (`walk`/`lauf`/`gehen` landen alle auf derselben Rolle). Nimm in Meshy je eine
Animation aus diesen Gruppen — **so, wie du es beim Spieler und den NPCs schon gemacht hast:**

| Rolle | Wonach suchen | Wofür |
| :-- | :-- | :-- |
| `idle` | Idle, Stand | steht herum, kein Ziel |
| `walk` | Walking | langsame Gegner (Konstrukt, Ernter) |
| `run` | Running | alles ab 2,6 m/s — also fast alle |
| `attack` | Attack, Shoot, Punch | Angriff |
| `hit` | Hit, Impact, Flinch | Treffer einstecken |
| `death` | Death, Dead | Tod |

`idle`, `run` und `attack` sind die drei, die man wirklich ständig sieht. `hit` und `death`
sind Kür — wenn Meshy sie hat, nimm sie mit, aber halte dich nicht damit auf.

**Für die beiden Menschen (Grenzgänger, Revolverheld) bitte dieselben Animationen wählen wie
für Spieler und NPCs.** Nicht weil das Rig geteilt würde — Meshy baut je Modell ein eigenes —
sondern damit alle Menschen im Spiel gleich gehen. Unterschiedliche Gangbilder bei gleichen
Figuren fallen sofort auf.

### 4. Silhouette bei tatsächlicher Bildschirmgröße

Die Kamera steht fest und zeigt einen Ausschnitt von rund 15 × 13 m. Ein 1,6-m-Gegner ist
damit etwa **ein Achtel der Bildhöhe** hoch, ein Kessel-Kläffer mit 0,8 m nur ein
Sechzehntel. Auf dem Handy sind das wenige hundert bzw. wenige dutzend Pixel.

Das heißt: **Umriss und Grundfarbe entscheiden, Details sind verschenkt.** Grenzgänger und
Revolverheld sind beide 1,6 m große Menschen mit Hut — die müssen sich auf den ersten Blick
unterscheiden, sonst weiß man nicht, ob man rennen oder in Deckung gehen muss. Deshalb steht
in den Prompts jeweils ein Silhouetten-Merkmal, das nur dieser eine Gegner hat.

### 5. Wenige Dreiecke — die kommen im Rudel

Kläffer erscheinen zu viert bis siebt gleichzeitig. Ziel sind **3 000–6 000 Dreiecke** für
Schwarm-Gegner, bis 15 000 für den Ernter. Das Aufbereitungs-Skript reduziert, aber je
weniger überflüssiges Geometrie-Rauschen erzeugt wird, desto besser überlebt die Form.
**1k-Texturen genügen**, außer beim Ernter.

---

## 1. Grenzgänger (`enemies/outlaw.glb`) — 1,60 m

Der Standard-Gegner der Wüste: ein verzweifelter Gesetzloser, kein Profi. Läuft dich an und
schlägt zu. **Silhouetten-Merkmal: kein Hut, sondern ein umgebundenes Tuch über dem Kopf, und
ein sperriges Nahkampfwerkzeug in der Faust.**

```
A grim-dark steampunk western desert bandit, full body character concept for a 3D game model,
standing straight and facing the viewer directly in a relaxed neutral A-pose, arms held clearly
away from the torso, legs slightly apart, symmetrical, nothing overlapping the body.
A lean, weather-beaten man in scavenged clothing: a dust-caked collarless shirt with rolled
sleeves, a patched leather work vest, canvas trousers tucked into cracked boots, and a strip of
grimy cloth wound around his head and lower face against the sand — no hat. Mismatched leather
bracers, a coil of wire and a tin canteen on his belt. In his right hand a crude close-combat
weapon: a length of iron pipe with a bolted-on blade. No firearm.
Sun-bleached greys and dirty ochre, cracked brown leather, rust on every piece of metal;
nothing polished, nothing new. Desperate and underfed, not heroic.
Clothing fits close to the body — no coat, no cape, no loose flowing fabric of any kind.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire figure visible from head to feet, centered with margin on all sides. No text, no
lettering, no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

## 2. Revolverheld (`enemies/revolver.glb`) — 1,60 m

Derselbe Menschenschlag, aber ein Könner: hält Abstand, weicht zurück, feuert auf Cooldown.
Muss **gefährlicher aussehen als der Grenzgänger und sich im Umriss klar von ihm abheben.
Silhouetten-Merkmal: breitkrempiger Hut, gerade Schultern, Patronengurt über der Brust.**

```
A grim-dark steampunk western gunslinger, full body character concept for a 3D game model,
standing straight and facing the viewer directly in a relaxed neutral A-pose, arms held clearly
away from the torso, legs slightly apart, symmetrical, nothing overlapping the body.
A hard-faced man standing upright and composed, wearing a broad-brimmed flat-crowned hat that
shades his eyes, a dark buttoned waistcoat over a collarless shirt, and a heavy bandolier of
brass cartridges slung diagonally across his chest. A low-slung gunbelt with a holstered
revolver on each hip, a second bandolier at the waist, brass-buckled leather throughout. In his
right hand a long-barrelled revolver with an ornate brass frame, held down at his side, muzzle
toward the ground.
Dark charcoal and oxblood cloth, black leather, tarnished brass and gunmetal; cleaner and
better kept than a common bandit — this one earns a living at it.
Clothing fits close to the body — no duster, no coat tails, no cape, no loose flowing fabric.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire figure visible from head to feet, centered with margin on all sides. No text, no
lettering, no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

> Der abwärts gehaltene Revolver ist Absicht: erhobene Arme verwachsen beim automatischen Rig,
> und die Schussanimation legt den Arm ohnehin selbst an.

## 3. Kessel-Kläffer (`enemies/klaeffer.glb`) — 0,80 m Schulterhöhe

Ein maschineller Hund, der im Rudel jagt — mit 138 Tempo der schnellste Gegner im Spiel.
Muss sich vom Rattenschwarm unterscheiden: **Ratte ist organisch und 0,6 m, der Kläffer ist
Blech und 0,8 m. Silhouetten-Merkmal: der Kessel auf dem Rücken mit Schlot.**

Laut Kampfsystem ist er **galvanik-anfällig** — die Kupferwicklungen sollen das erklären, ohne
dass es irgendwo geschrieben steht.

```
A grim-dark steampunk mechanical hound, full body creature concept for a 3D game model, seen
from a straight side-on profile, standing on all four legs in a neutral stance, legs straight
and clearly separated, the whole animal in sharp silhouette against the background.
A four-legged automaton the size of a large dog, built from riveted iron plate over an exposed
brass linkage skeleton. A small pot-bellied boiler sits on its back with a short stubby chimney
venting a wisp of steam, and thick copper coils wind visibly around its neck and haunches. Its
head is a blunt riveted wedge with a hinged lower jaw of iron teeth and two small glowing amber
lenses for eyes. Piston rods drive the legs; the paws are simple iron claws. A short segmented
cable tail.
Soot-blackened iron, tarnished brass, bright verdigris-green copper coils as the only colour
accent; oil stains and rust in every joint. Aggressive, lean and predatory — not cute.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire creature visible from nose to tail, centered with margin on all sides. No rider, no
people, no text, no logos, no watermark. Photorealistic PBR game asset, low polygon count,
high detail.
```

> Hier **Seitenansicht statt Frontalansicht**: Bei einem Vierbeiner verdecken sich von vorn die
> Beine gegenseitig, und genau die muss der Rig finden.

## 4. Schwerer Ernter (`enemies/goliath.glb`) — 4,00 m

Der Boss: 900 Leben, Panzerung 30, langsam. Und eine Besonderheit, die das Bild tragen muss —
**er ist von vorn immun gegen kinetischen Schaden.** Man muss ihn umlaufen und von hinten
angreifen.

Das darf nicht im Handbuch stehen, das muss man **sehen**: vorn eine massive, geschlossene
Panzerplatte, hinten offen liegende Kolben, Kühlrippen und ein glühender Kesselkern. Der Prompt
verlangt deshalb ausdrücklich beides — geschlossene Front, verwundbarer Rücken.

```
A colossal grim-dark steampunk harvester war-machine, full body concept for a 3D game boss
model, standing straight and facing the viewer directly in a neutral upright stance, arms held
clearly away from the torso, legs apart, symmetrical, nothing overlapping the body.
A four metre tall bipedal automaton built on a repurposed agricultural harvester: its entire
front is a single massive slab of riveted armour plate, thick and unbroken, with only a narrow
horizontal vision slit glowing dull amber — no opening, no gap, no exposed machinery anywhere on
the front. Heavy squat legs like hydraulic pillars end in broad splayed feet. One arm terminates
in a wide toothed threshing drum, the other in a cluster of curved reaping blades. Blackened
exhaust stacks rise from its shoulders. Its head is a small armoured turret sunk between them.
Deep rust-brown and gunmetal iron, tarnished brass fittings, dried mud and chaff caked in the
joints; enormous, slow and industrial rather than agile.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire machine visible from top to feet, centered with margin on all sides. No people for scale,
no text, no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

**Zweites Bild für den Ernter — die Rückseite:**

Bildgeneratoren zeigen immer die Schauseite. Bei einem Gegner, dessen ganze Kampfmechanik am
Unterschied zwischen vorn und hinten hängt, reicht das nicht. Erzeuge dasselbe Modell noch
einmal von hinten und gib Meshy beide Bilder — mit einem einzigen Bild erfindet es die
Rückseite, und dann ist sie genauso gepanzert wie die Front.

```
The same colossal grim-dark steampunk harvester war-machine, seen from directly behind, full
body concept for a 3D game boss model, standing straight in a neutral upright stance, legs
apart, symmetrical.
Its back is the opposite of its armoured front: completely open machinery, a glowing orange
boiler core visible deep inside the ribcage of the frame, banks of exposed cooling fins, bundled
copper piping, and long piston rods driving the hips and shoulders. Loose cables hang between
the shoulder blades. Blackened exhaust stacks rise from the shoulders. The armour plates wrap
around the flanks and stop short, leaving the spine and boiler exposed.
Deep rust-brown and gunmetal iron, tarnished brass, the boiler glow as the only bright colour.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire machine visible from top to feet, centered with margin on all sides. No people for scale,
no text, no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

---

## Nach dem Export

1. **Durch das Aufbereitungs-Skript**, wie bei allen anderen Modellen:
   ```
   python3 godot/tools/prepare_meshy_glb.py Eingabe.glb godot/assets/models/enemies/outlaw.glb --max-tris 6000
   ```
   Beim Ernter `--max-tris 15000`. Das Skript räumt Emissive-Fehler auf, setzt `metallicFactor`
   (sonst wird die Figur schwarz), verschmilzt UV-Naht-Duplikate (sonst bekommt das Modell
   Löcher wie damals der Panzer) und berechnet Normalen mit 45°-Kante.
2. **Hochladen, mehr nicht.** Die Zielhöhen stehen im `AssetRegistry`, die Skalierung passiert
   automatisch, die Kollision auch.
3. Sollten die Clips in Meshy anders heißen als erwartet, sag mir die Namen — dann trage ich sie
   wie beim Spieler in `CLIP_OVERRIDES` ein. Meist findet die Namenssuche sie von allein.
