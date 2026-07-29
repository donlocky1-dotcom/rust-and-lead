# Bild-Prompts für Requisiten (Straße, Boden, Wildnis)

Ablauf wie bei den Gebäuden: Bild erzeugen → **Meshy Image to 3D** → GLB durch
`godot/tools/prepare_meshy_glb.py` → ablegen unter `godot/assets/models/props/`.

## Was NICHT hierher gehört

**Boden- und Straßenbelag sind Texturen, keine Modelle.** Bildmodelle können keine nahtlos
kachelbaren Materialien — der Übergang bricht immer. Die hole ich als CC0-PBR-Sets von Poly
Haven (wie schon den Sandboden): gestampfte Piste, rissiger Lehm, Salzkruste, Schotter. Da
ist nichts zu generieren.

## Regeln für Requisiten

Wie bei den Gebäuden, mit zwei Zusätzen:

* **Wenig Dreiecke.** Requisiten stehen dutzendfach herum. Ziel sind 1 000–3 000 Dreiecke;
  das Aufbereitungs-Skript reduziert, aber je weniger Aufwand generiert wird, desto besser
  bleibt die Form.
* **1k-Texturen genügen.** Ein Fass ist auf dem Bildschirm 60 Pixel hoch.
* **Silhouette zählt mehr als Detail.** Aus zehn Metern erkennt man Umrisse, keine Nieten.

Maßangaben stehen dabei. Wichtig für den Einbau: alles **Flache und Langgestreckte** (Trog,
Karren, Schrotthaufen, Knochen) wird bei uns über die **längste Kante** skaliert, alles
Aufrechte (Fass, Laterne, Kaktus, Brett) über die **Höhe**. Ich trage das je Asset ein.

---

## Priorität 1 — die Straße von Rustwater

### 1. Fässer und Kisten (`props/barrels.glb`) — Stapel ~1,6 m hoch

Der Allzweck-Füller: Hausecken, Gassen, Lager, Schmugglerverstecke.

```
A small stack of grim-dark steampunk western storage containers, standing alone as a 3D game
asset concept, seen from a high three-quarter angle roughly 50 degrees above the horizon.
Three weathered wooden barrels bound with rusted iron hoops, one lying on its side, and two
rough plank crates stacked beside them, their lids nailed shut and corners reinforced with
iron brackets. One barrel has a brass tap hammered into it. The group sits tightly together as
one compact arrangement, roughly 1.6 metres wide and 1.6 metres tall.
Sun-bleached grey timber, rust brown ironwork, desert dust caked in the seams; one crate has a
faded ochre paint smear.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire group visible and centered with margin on all sides. No people, no text, no lettering,
no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

### 2. Wassertrog mit Anbindepfosten (`props/hitching_post.glb`) — 2,6 m lang

Das Möbelstück, das eine Western-Straße zur Western-Straße macht.

```
A hitching rail with a water trough, grim-dark steampunk western style, standing alone as a 3D
game asset concept, seen from a high three-quarter angle roughly 50 degrees above the horizon.
A long trough of thick planks bound with iron bands, half full of murky water, and behind it a
horizontal hitching rail on two stout posts, worn smooth in the middle from years of rope. A
riveted iron pipe with a small valve wheel feeds the trough from one end. Roughly 2.6 metres
long, 1.2 metres deep, 1.4 metres tall including the rail.
Grey weathered timber, rusted iron, dark water, sand drifted against the base.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire object visible and centered with margin on all sides. No animals, no people, no text,
no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

### 3. Gaslaterne (`props/street_lamp.glb`) — 3,6 m hoch

**Wichtig:** Die Flamme bitte leuchtend darstellen. Meshy legt so etwas als Emissive-Map an,
und unsere Aufbereitung erkennt eine echte Glow-Map inzwischen und behält sie — die Laterne
leuchtet damit im Spiel wirklich, ohne dass ich eine Lichtquelle von Hand setzen muss.

```
A steampunk western gas street lamp, standing alone as a 3D game asset concept, seen from a
three-quarter angle roughly 40 degrees above the horizon.
A tapered cast-iron post on a heavy flanged base, riveted seams, a small brass pressure valve
and a coiled copper feed pipe near the bottom, an ornamental scroll bracket at the top holding
a four-sided glass lantern head with a domed cap and a curl of vent pipe. Inside the glass, a
gas flame burns with a warm orange glow that lights the panes from within. Roughly 3.6 metres
tall, the lantern head about 0.5 metres across — slender overall.
Dark rusted iron and tarnished brass, soot-blackened glass; the flame is the only bright colour.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire lamp visible from base to cap, centered with margin on all sides. No people, no text,
no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

### 4. Auftragsbrett (`props/bounty_board.glb`) — 2,2 m hoch

Kein reines Dekor: Das Auftragsbrett am Saloon ist die Kopfgeld-Interaktion (GDD §2.2).
Es muss aus der Entfernung als „hier kann man was" lesbar sein.

```
A frontier bounty board, grim-dark steampunk western style, standing alone as a 3D game asset
concept, seen from a three-quarter angle roughly 40 degrees above the horizon.
A broad plank board on two heavy posts with a small shingled rain roof over it, the surface
covered in layered, sun-yellowed and torn paper notices nailed and pinned in overlapping rows,
their edges curling. A few rusted nails hold scraps of older papers. Roughly 1.6 metres wide,
2.2 metres tall including the posts and roof.
Grey weathered timber, yellowed paper, rusted nails and iron corner straps.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire board visible and centered with margin on all sides. The papers must have NO readable
writing, no faces, no letters or numbers of any kind — blank aged paper only. No people, no
logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

> Der Satz über die leeren Zettel ist Absicht: Bildmodelle erzeugen unleserliche Pseudoschrift,
> die aus der Nähe wie ein Fehler wirkt. Bleibt das Papier leer, sieht es aus wie verblichen.

### 5. Handkarren (`props/handcart.glb`) — 3,0 m lang

Steht in der Gasse, liegt umgekippt im Wüstensand, gehört an jede Schmiede.

```
A two-wheeled wooden handcart, grim-dark steampunk western style, standing alone as a 3D game
asset concept, seen from a high three-quarter angle roughly 50 degrees above the horizon.
A flatbed cart with low plank sides and two tall spoked wheels with iron tyres, long draw
handles resting tilted down to the ground, an iron brake lever and a coil of rope looped over
one handle. One wheel is patched with a bolted iron plate. The bed is empty. Roughly 3.0 metres
long including handles, 1.4 metres wide, 1.5 metres tall at the wheel tops.
Grey weathered timber, rusted iron tyres and fittings, dust in every joint.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire cart visible and centered with margin on all sides. No animals, no people, no text,
no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

---

## Priorität 2 — die Wüste dazwischen

Die 5000 m zwischen den Orten sind derzeit leerer Sand mit ein paar Felsen. Diese drei füllen
sie, ohne dass etwas den Weg versperrt.

### 6. Kaktus-Gruppe (`props/cactus.glb`) — 2,6 m hoch

```
A group of desert cacti, grim-dark western style, standing alone as a 3D game asset concept,
seen from a three-quarter angle roughly 45 degrees above the horizon.
One tall columnar cactus with two upraised arms, flanked by two shorter ones and a low cluster
of stubby paddles at the base, all growing from the same clump. Ribbed trunks with dense
spines, dried and shrivelled at the lower third, one arm broken off and hanging. Roughly
2.6 metres tall and 1.4 metres across.
Dusty grey-green flesh, brown dead patches, pale spines — muted and sun-scorched, not lush.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire clump visible and centered with margin on all sides. No flowers, no people, no text,
no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

### 7. Schrotthaufen (`props/scrap_heap.glb`) — 3,2 m lang

Doppelt nützlich: Wüsten-Dekor **und** die sichtbare Quelle des Materials „Schrott", das die
Sammel-Quest verlangt.

```
A heap of industrial scrap, grim-dark steampunk western style, standing alone as a 3D game
asset concept, seen from a high three-quarter angle roughly 50 degrees above the horizon.
A low pile of discarded machine parts half sunk into the ground: a cracked boiler drum, bent
iron plate, a large toothed gear leaning against the drum, coils of wire, a broken piston rod
and a length of rail. Everything deeply rusted and fused together by weather. Roughly 3.2
metres long, 2.4 metres deep, 1.5 metres tall — clearly a pile, not a structure.
Deep orange-brown rust over dark iron, sand drifted into the gaps, a few brass fittings still
showing.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire heap visible and centered with margin on all sides. No people, no text, no logos, no
watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

### 8. Tierskelett (`props/bones.glb`) — 1,8 m lang

Das billigste Mittel, um „lebensfeindliche Wüste" zu sagen. Ein Modell, viele Drehungen.

```
A bleached animal skeleton lying on the ground, grim-dark western style, standing alone as a
3D game asset concept, seen from a high three-quarter angle roughly 55 degrees above the
horizon, looking down at it.
The long-horned skull of a large grazing beast resting on its side, attached to a partial
ribcage and a few scattered vertebrae and leg bones lying loosely around it, half buried in
drifted sand. Sun-bleached, cracked and pitted, one horn broken short. Roughly 1.8 metres long
and 0.9 metres wide, lying flat — nothing standing upright.
Bone white to pale sand colour, grey weathering in the cracks.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire skeleton visible and centered with margin on all sides. No blood, no flesh, no people,
no text, no logos, no watermark. Photorealistic PBR game asset, low polygon count, high detail.
```

---

## Stand: was davon liegt im Spiel

| Prompt | Datei | Eingebaut |
|---|---|---|
| 1. Fässer und Kisten | `props/barrels.glb`, `barrels_b`, `barrels_c` | Bahnsteig, Krater |
| 2. Wassertrog mit Anbindepfosten | `props/hitching_post.glb` | Bahnsteig |
| 3. Gaslaterne | `props/street_lamp.glb` | Bahnsteig (mit eigenem Licht) |
| 4. Auftragsbrett | `props/bounty_board.glb` | — steht bereit, Platzierung offen |
| 5. Handkarren | — | fehlt noch |
| 6. Kaktus-Gruppe | `props/cactus.glb` | Wüstenstreuung (sperrt den Weg) |
| 7. Schrotthaufen | `props/scrap_heap.glb`, `scrap_heap_b` | Krater, Wüstenstreuung |
| 8. Tierskelett | `props/bones.glb`, `bones_b` | Wüstenstreuung, Krater |

Dazu, außerhalb dieser Liste: `buildings/bahnhof.glb` — die Bahnsteighalle. Sie ersetzt die
sechs Platzhalter-Kisten, aus denen jeder Bahnhof bisher bestand.

**Zur Laterne:** Der Prompt bittet um eine leuchtende Flamme, und das Bild hat sie — aber nur
in der Farbtextur. Meshys Emissive-Map kam schwarz heraus, die Aufbereitung hat sie
folgerichtig als tote Daten verworfen. Das Licht setzt jetzt der Code (`_dress_station`), was
ohnehin besser ist: So leuchtet die Laterne nicht nur selbst, sondern beleuchtet den Bahnsteig.

**Zum Auftragsbrett:** Die Zettel sind erwartungsgemäß leer — der Satz im Prompt hat gewirkt.
Wo es steht, entscheidest du; laut GDD §2.2 gehört es an den Saloon.

**Dreiecksbudget:** Die Rohdateien kamen mit 160 000 bis 1,8 Mio. Dreiecken (490 MB
zusammen). Nach `prepare_meshy_glb.py` sind es 4 000 bis 30 000 und 17,5 MB — bei 0,0 %
offenen Kanten, also ohne Löcher im Netz.

---

## Was ich parallel dazu selbst mache

* **Boden- und Straßentexturen** von Poly Haven holen und einbauen (gestampfte Piste für die
  Routen, rissiger Lehm für den Stadtplatz, Salzkruste für die Salzpfanne).
* Die bereits vorhandenen CC0-Props einsetzen, die noch ungenutzt herumliegen:
  Munitionskiste, Werkzeugwagen, Metallregal, Industrie-Wandlampe.
* Die Streu-Logik erweitern, damit Requisiten sinnvoll landen: an Hauswänden statt mittig in
  der Gasse, Kakteen und Knochen nur draußen, Schrott gehäuft entlang der Bahntrasse.
