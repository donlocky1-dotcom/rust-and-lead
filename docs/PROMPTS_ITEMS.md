# Bilder für das Inventar — was ich brauche

Die Ausrüstung im Beutel und an der Puppe wird bisher **gezeichnet**: farbige Kästchen mit
einem Sinnbild. Das trägt, solange es Platzhalter sind, aber ein Beutel voll gleicher Rechtecke
ist im Kampf nicht lesbar — man erkennt ein Teil an seiner Silhouette, nicht an seiner Farbe.

In der 3D-Ansicht müssen sich die Waffen **nicht** unterscheiden; dort reicht das eine
Karabiner-Modell. Es geht nur um die Bilder im Inventar.

---

## Format (für alle gleich)

* **512 × 512**, PNG mit **Alphakanal**, Motiv freigestellt
* Ansicht **von schräg oben, leicht gedreht** — nicht frontal, nicht perspektivisch verzerrt
* **Kein Rahmen, kein Hintergrund, kein Schatten unter dem Objekt.** Den Rahmen zeichnet das
  Spiel je nach Seltenheit (grau / grün / blau / gold)
* Das Motiv füllt das Quadrat zu etwa **85 %**, mittig
* Beleuchtung von links oben, harte Kanten — das Spiel ist grim-dark, keine Hochglanz-Produkte

### Was Gemini hier zuverlässig falsch macht

Steht ausführlich in `PROMPTS_UI.md`, in Kurzform:

1. **Es malt das Karo-Muster.** „Transparent background" führt zu einem gemalten Schachbrett
   statt zu Alpha. `tools/prepare_ui.py` erkennt und entfernt es — aber sag im Prompt
   trotzdem *„solid transparent background, no checkerboard pattern"*.
2. **Es malt einen Rahmen dazu.** Ausdrücklich verbieten: *„no border, no frame, no card"*.
3. **Es setzt ein Wasserzeichen** (Funkeln unten rechts). Wird automatisch geheilt.
4. **Es lässt zu viel Luft.** Wird automatisch beschnitten, kostet aber Auflösung — also
   *„object fills the frame"*.

---

## Gemeinsamer Stil-Block

> Steampunk-Western item icon, 512×512, three-quarter top-down view, object centred and filling
> the frame, weathered brass and blued steel, oil stains and rust pitting, hard directional
> light from the upper left, muted desert palette (ochre, rust, verdigris, gunmetal), no border,
> no frame, no card, no text, no shadow beneath the object, solid transparent background, no
> checkerboard pattern.

---

## 0. Mündungsfeuer (3) — schon eingebaut, wartet nur auf die Grafik

Der Blitz wird zurzeit **gezeichnet** (zwei gekreuzte additive Vierecke). Das funktioniert; mit
Sprites wird es besser. **Schwarzer Hintergrund, nicht transparent** — additiv gezeichnet ist
Schwarz automatisch unsichtbar, und damit fällt Geminis Karo-Problem ganz weg.

`muzzle.png` (und optional `muzzle_b.png`, `muzzle_c.png` mit anderer Zackenzahl):

> Muzzle flash sprite for a game, 256×256, **pure black background**, star-shaped burst of
> white-hot flame with yellow and orange edges, four irregular petals of different length, small
> sparks flying outward, seen head-on, sharp and grainy — not soft or glowy, no smoke, no gun,
> no text, no border, centred, fills the frame.

Das Spiel sucht sie unter `muzzle`; liegt keine da, zeichnet es weiter selbst.

## 1. Waffen (5) — die dringendsten

Dateiname → Motiv

| Datei | Motiv |
|---|---|
| `item_karabiner.png` | **Blei-Karabiner.** Einläufiges Unterhebel-Gewehr, Holzschaft mit Messingbeschlägen, Lauf voller Sand. Der Fund aus der Schrottgrube — er soll gebraucht aussehen, nicht kaputt. |
| `item_gatling.png` | **Messing-Gatling.** Kurzer sechsläufiger Bündel-Lauf mit Kurbel, tragbar (kein Geschütz), Messing über Stahl, Gurtkasten seitlich. |
| `item_voltgun.png` | **Leydener Volt-Karabiner.** Gewehr mit einer gläsernen Leidener Flasche als Magazin, Kupferspulen um den Lauf, blaue Funken zwischen zwei Elektroden an der Mündung. |
| `item_saeure.png` | **Säure-Sprüher.** Rückenlose Handspritze, dicker Glasbehälter mit giftgrüner Flüssigkeit, Messingdüse, Gummischlauch. |
| `item_brenner.png` | **Dampf-Brenner.** Kurzer Flammenwerfer, Kesselstück am Griff, Zündflamme an der Mündung, Ruß am Rohr. |

## 2. Munition & Verbrauch (4)

| Datei | Motiv |
|---|---|
| `item_muni.png` | Handvoll Messing-Patronen, einige aufrecht, einige liegend, ein Ledergurt darunter. |
| `item_kristall.png` | Drei blau leuchtende Ladekristalle in einem Messingclip. |
| `item_trank.png` | Heiltrank: kleine braune Apothekerflasche mit Korken, rote Flüssigkeit, handbeschriftetes Etikett. |
| `item_granate.png` | Dampfgranate: gusseiserne Kugel mit Messingventil und kurzer Zündschnur. |

## 3. Ausrüstungs-Slots (5) — je ein Bild reicht vorerst

Die Slots gibt es in vier Seltenheiten, aber die Farbe macht der Rahmen. Ein Motiv je Slot.

| Datei | Motiv |
|---|---|
| `item_helmet.png` | Lederhut mit Messing-Schutzbrille am Band, staubig. |
| `item_armor.png` | Ledermantel mit aufgenieteten Stahlplatten auf Brust und Schultern. |
| `item_gadget.png` | Messing-Taschenuhr mit offenem Deckel und sichtbarem Räderwerk. |
| `item_boots.png` | Abgetragene Reitstiefel mit Stahlkappen und Sporen. |
| `item_plate.png` | Tech-Modul: quadratische Kupferplatine mit Röhren, Zahnrad und Kabelstummeln. |

## 4. Rohstoffe (3)

| Datei | Motiv |
|---|---|
| `item_schrott.png` | Bündel Metallschrott: verbogene Bleche, ein Rohrstück, Draht. |
| `item_zahnrad.png` | Einzelnes Messingzahnrad, ein Zahn ausgebrochen. |
| `item_dampfkern.png` | Dampfkern: verschraubte Messingkugel mit Sichtfenster, in dem weißglühender Dampf steht. Das seltenste Ding im Spiel — es soll leuchten. |

## 5. Gold (1)

| Datei | Motiv |
|---|---|
| `item_gold.png` | Kleiner Haufen Münzen und ein paar Nuggets, kein Beutel. |

---

### Varianten je Gattung — später, nicht jetzt

Eine Gattung hat viele Stücke: „Rostiger Karabiner", „Reparierter Karabiner",
„Präzisions-Karabiner". Die Namen erzeugt das Spiel bereits selbst aus Seltenheit + Gattung.

**Ein Bild je Gattung reicht vorerst.** Wenn du später Varianten willst, ist die günstigste
Staffelung eine je Seltenheit — also vier Bilder je Gattung statt einem: abgerissen / brauchbar
/ gepflegt / einzigartig. Der Rahmen trägt die Farbe, das Bild trägt den Zustand.

**Gesamt: 18 Bilder.** Priorität: **Abschnitt 1 zuerst** (die fünf Waffen), danach 3, dann 4,
dann 2 und 5.

Ablage nach dem Erzeugen: alle in einen Ordner, als 7z oder einzeln in den Chat. Ich schicke sie
durch `tools/prepare_ui.py` (Karo weg, Wasserzeichen heilen, freistellen, auf 256 skalieren) und
verdrahte sie in `UiAssets` — die Namen oben sind schon die, unter denen das Spiel sie sucht.
