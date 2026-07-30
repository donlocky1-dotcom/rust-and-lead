# Prompts für die Oberfläche

Alles hier ist **optional**. Jede Oberfläche funktioniert schon: Sie zeichnet sich selbst aus
Flächen, Rahmen und Zeichen. Liegt eine Datei am richtigen Ort, wird sie genommen — fehlt sie,
passiert nichts Schlimmes. Du kannst also in beliebiger Reihenfolge liefern und jederzeit
aufhören.

**Ablage:** alles nach `godot/assets/ui/`, exakt unter dem angegebenen Dateinamen, PNG mit
Alphakanal.

---

## Der gemeinsame Stilsatz

Damit die Teile als **ein** Satz wirken, muss dieser Block in **jedem** Prompt stehen. Er trägt
die Welt (verrußter Steampunk-Western), das Material (Rost, Messing, Leder, gebleichtes Holz)
und die Machart (flach, lesbar, kein Foto).

> *Grim-dark steampunk western game UI asset. Rusted iron, tarnished brass, worn leather,
> sun-bleached bone and soot-stained parchment. Muted palette: rust orange, brass ochre, bone
> white, gun-metal grey — no bright saturated colours, no neon, no purple magic glow. Hand-painted
> flat illustration with subtle painted texture, readable at small size, crisp silhouette. Plain
> transparent background. No text, no letters, no numbers, no logos, no watermark, no border
> frame around the image, no drop shadow outside the object.*

Zwei Dinge, die erfahrungsgemäß schiefgehen, wenn man sie nicht ausdrücklich verbietet:

* **Schrift.** Bildgeneratoren malen gern erfundene Buchstaben auf Schilder und Knöpfe. Alle
  Beschriftungen setzt das Spiel selbst — steht Schrift im Bild, ist die Datei unbrauchbar.
* **Eigener Rahmen und Schlagschatten.** Die Oberfläche rahmt selbst. Ein zweiter Rahmen im Bild
  ergibt einen doppelten, ein Schlagschatten außen ergibt eine graue Kante auf transparentem
  Grund.

---

## Priorität 1 — die Sprechtafel

Das ist die Oberfläche, die man ab jetzt bei **jedem** Gespräch sieht. Sie hat den größten
Effekt pro Bild.

### 1.1 Drei Bildnisse — `portrait_mabel.png`, `portrait_silas.png`, `portrait_doc.png`

**512×512, quadratisch, gerader Anschnitt Kopf und Schultern.** Sie sitzen links in der
Sprechtafel und sagen in einem Blick, wer redet.

Wichtig für alle drei: *Square portrait bust, head and shoulders, facing the viewer three-quarters,
dark neutral background inside the square (NOT transparent — this one is a filled square), warm
rim light from the upper left, painted illustration in the style of a Diablo character portrait.*

* **Mabel** — *A woman in her late fifties, Wild-West saloon keeper, grey hair in a tight bun,
  weathered friendly face with deep laugh lines, dark red neckerchief, heavy leather apron over a
  faded green work shirt. Tired, warm, unimpressed by anything.*
* **Silas** — *A wiry man in his forties, frontier blacksmith, soot-smeared face, a brass
  jeweller's loupe strapped over his right eye, leather apron with iron rivets, rolled sleeves,
  forearms scarred by sparks. Sharp, calculating, slightly amused.*
* **Doc** — *A gaunt man in his sixties, frontier physician, thin white hair, round smoked-glass
  spectacles, high buttoned collar, stained white coat over a waistcoat, a brass syringe in his
  breast pocket. Cold, precise, faintly disgusted.*

### 1.2 Rahmen der Tafel — `dialog_frame.png`

**1236×280, 9-Patch.** Der Kasten, in dem der Text steht.

*A horizontal parchment panel set into a riveted iron frame: aged soot-stained paper, slightly
uneven edges, a thin tarnished brass inlay line running just inside the iron border, four heavy
rivets in the corners. The paper area is flat and empty — it must stay readable under dark text.*

**Achtung 9-Patch:** Die äußeren **24 px** an allen vier Seiten müssen den Rahmen enthalten, die
Mitte muss ruhig und annähernd einfarbig bleiben. Godot streckt die Mitte; liegt dort ein Motiv,
verzerrt es.

### 1.3 Rahmen des Bildnisses — `portrait_frame.png`

**160×160, transparente Mitte.** Liegt über dem Bildnis.

*A square frame of riveted dark iron with a thin brass inner edge, four corner rivets, slightly
battered. The centre of the image is fully transparent — only the frame band itself is painted,
about 14 pixels wide.*

---

## Priorität 2 — die Knöpfe

Die Knöpfe benutzen bisher Godots Standarddesign: grau, rechteckig, aus einem anderen Spiel.
**Drei Bilder ersetzen alle Knöpfe im ganzen Spiel.**

* `btn_normal.png` — **192×96, 9-Patch.** *A wide horizontal button plate of brushed dark iron
  with a rivet in each corner and a faint brass edge highlight along the top, slightly worn at the
  edges. Flat, even surface in the middle.*
* `btn_hover.png` — *dasselbe Plättchen, eine Spur heller, der Messingrand deutlicher, ein warmer
  Schimmer über der Fläche.*
* `btn_disabled.png` — *dasselbe Plättchen, entsättigt und abgedunkelt, Nieten stumpf, kein
  Messingrand.*

**Alle drei müssen dasselbe Blech sein** — nur Helligkeit und Kantenglanz unterscheiden sich.
Drei verschiedene Bleche wirken beim Drücken wie ein Sprung. Rand **16 px** an allen Seiten
glatt halten (9-Patch, siehe oben).

---

## Priorität 3 — die Sinnbilder im Inventar

Sechs Stück, **je 128×128 mit Alpha**. Sie ersetzen die Zeichen ⛑ 🧥 🔫 ⚙ 🥾 ▦ im Beutel-Raster
**und** an der Puppe. Emoji sehen auf jedem Betriebssystem anders aus und brechen den Ton — ein
gemalter Helm passt zum Spiel, Apples Bauarbeiterhelm nicht.

Zusatz zum Stilsatz für alle sechs: *A single game inventory icon, flat three-quarter view, thick
readable silhouette, the object fills the square with a small margin.*

| Datei | Motiv |
|---|---|
| `icon_helmet.png` | *a riveted iron helmet with a cracked round glass visor and a leather chin strap* |
| `icon_armor.png` | *a heavy leather coat with bolted iron shoulder plates* |
| `icon_weapon.png` | *a lever-action rifle with a brass receiver and a worn wooden stock* |
| `icon_gadget.png` | *a brass pressure gauge with copper coils and a cracked dial glass* |
| `icon_boots.png` | *a pair of worn leather boots with iron toecaps and buckled straps* |
| `icon_plate.png` | *a bolted rectangular steel plate with four rivets and a scorch mark* |

---

## Priorität 4 — Kleinteile mit großer Wirkung

### `footprint.png` — 128×128

Das billigste sichtbare Bild in dieser ganzen Liste. Die Fußspur zum Quest-Ziel besteht aus
schlichten Rechtecken; mit dieser Textur werden echte Abdrücke daraus.

*A single boot sole print seen from directly above, pointing up: heel and sole separated by a
narrow waist, a cleated tread pattern of short horizontal bars. Solid white shape on a fully
transparent background, soft feathered edges. No outline, no colour — the game tints it.*

### `btn_character.png` und `btn_fire.png` — je 128×128

* **Charakter:** *a bolted iron chest plate with shoulder straps, seen from the front* — der Knopf
  oben links, der das Inventar öffnet.
* **Schuss:** *a heavy iron crosshair ring with four thick tick marks and a small centre dot,
  slightly battered* — der Daumenknopf unten rechts.

### `doll_body.png` — 430×436

Die Silhouette hinter der Puppe im Charakter-Bildschirm. Heute aus Grundformen gezeichnet.

*A full-body silhouette of a rusted humanoid automaton standing facing the viewer, arms hanging
slightly away from the body, legs together: riveted iron plates, exposed brass pistons at the
joints, a featureless helmet-like head, no face. Painted dark bronze with subtle highlights,
fully transparent background, no ground shadow. The figure is exactly centred and does not touch
the edges of the image.*

**Wichtig:** Kopf, Hände und Füße dürfen nicht bis an den Bildrand reichen — der Helm-Kasten der
Oberfläche sitzt über dem Kopf, die Stiefel unter den Füßen.

---

## Was du NICHT brauchst

Rollbalken, Reiter, Nebel-Textur, Kartensymbole, Rahmen für die Tafeln des Inventars, Ziffern,
Zahlenblöcke. Alles gezeichnet, alles plattformunabhängig, alles scharf auf jedem Gerät.

## Wie du prüfst, ob eine Datei sitzt

Datei nach `godot/assets/ui/` legen, Godot einmal starten (es importiert von selbst), ins Spiel
gehen. Sitzt sie, ist sie sofort da; sitzt sie nicht, sieht alles aus wie vorher. Es gibt keinen
Zwischenzustand mit rotem Platzhalter — das ist Absicht, damit ein halber Satz Grafiken das Spiel
nie unbenutzbar macht.
