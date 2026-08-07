# Drei Entwürfe: Titelbild, der erste Gegner, der Riss

Was hier steht, ist **noch nicht gebaut**. Jedes der drei Stücke hängt an etwas, das fehlt — eine
Animation, eine Entscheidung, eine Grafik —, und ein Entwurf, der das benennt, ist mehr wert als
Code, der es überspringt.

---

## 1. Der Titelbildschirm

**Damit startet das Spiel immer**, nicht nur wenn es Spielstände gibt. Das ist die eigentliche
Ansage: Ein Titelbild, das je nach Speicherstand mal da ist und mal nicht, ist kein Anfang,
sondern ein Dialogfeld.

### Was drauf muss

Gefragt war *„new game, load game, credits, tutorial — was fehlt noch?"*. Es fehlen drei Dinge,
und zwei davon sind keine Bequemlichkeit, sondern Pflicht:

| | Eintrag | warum |
|---|---|---|
| 1 | **Neues Spiel** | |
| 2 | **Spiel laden** | ausgegraut, solange es keinen Stand gibt — nicht versteckt. Ein Eintrag, der auftaucht und verschwindet, lässt den Bildschirm springen |
| 3 | **Einstellungen** | **fehlt und ist Pflicht.** Lautstärke (Gesamt / Musik / Effekte / Sprache), Sprache der Texte, Bildqualität, und auf dem Handy die Größe des Bedienfelds. Ohne Lautstärkeregler ist ein Spiel mit Schusswaffen auf einem Telefon unzumutbar |
| 4 | **Steuerung** | **fehlt.** Kann in die Einstellungen, aber besser eigen: Das Spiel läuft auf Handy *und* Tastatur, und wer am Rechner sitzt, sucht sonst blind nach `[E]`, `[R]`, `[Tab]`, `[Q]`, `[M]` |
| 5 | **Tutorial** | |
| 6 | **Credits** | |
| 7 | **Beenden** | **fehlt** — auf dem Desktop. Auf dem Handy weglassen (dort beendet man Apps anders), also plattformabhängig ein- und ausblenden |

Nicht empfohlen: ein Eintrag *„Fortsetzen"* zusätzlich zu *„Spiel laden"*. Beim ersten Start ist
er tot, und danach ist er dasselbe wie der zweite Eintrag mit einem anderen Wort.

### Was das Tutorial ist

Ein eigener Eintrag lohnt nur, wenn dahinter etwas anderes steckt als der Prolog. Vorschlag:
**derselbe Prolog, aber mit Hinweistafeln** — Bewegung, Schuss, Nachladen, Rucksack, Auftrag
annehmen. Also kein zweiter Inhalt, sondern derselbe mit eingeblendeten Sätzen. Sonst hat man
zwei Anfänge zu pflegen, und einer davon wird schlechter.

### Die Grafik

Kein gezeichnetes Titelbild, sondern **die Welt selbst**. Der Grund ist derselbe wie beim
Kraterrand: Was gezeigt wird, existiert auch — dann altert das Titelbild nicht gegen das Spiel.

> **Das Bild:** Rustwater von außen, aus der Kamerahaltung der Intro-Umrundung — 64 m Abstand,
> 30 m Höhe, Blick nach innen. **Nacht**, weil dann Esse, Torfackeln und Turmlaterne leuchten
> und der Ort aus der Dunkelheit heraussteht. Die Kamera dreht sich **sehr langsam** weiter
> (2–3°/s, also eine Runde in gut zwei Minuten): Es steht nicht still, aber es passiert auch
> nichts. Im Vordergrund unten links die Silhouette des Wasserturms als Anker.

Darüber der Titel in schwerer, schmaler Serifenschrift mit Rostkante — **RUST & LEAD** —, die
Einträge rechtsbündig darunter in einer Spalte, damit die Stadtmitte frei bleibt. Kein Kasten,
kein Panel: Die Schrift liegt direkt im Bild, mit einem weichen dunklen Verlauf dahinter, damit
sie über hellem Sand lesbar bleibt.

**Warum keine Standkamera:** Ein bewegtes Bild verrät sofort, dass es echt ist. Ein gerendertes
Standbild hätte in dem Moment gelogen, in dem jemand die Palisade umbaut.

### Was das am Code ändert

* `Main.tscn` wird der Titelbildschirm, nicht `Overworld.tscn`. Die Overworld wird von dort
  geladen.
* Der Titelbildschirm braucht eine **eigene, abgespeckte Weltinstanz** — oder er lädt die
  Overworld und schaltet HUD, Steuerung und alle Auslöser ab. Das Zweite ist weniger Code und
  mehr Risiko (jeder neue Auslöser muss daran denken); das Erste ist sauberer. **Empfehlung:**
  Overworld laden, aber über eine einzige Flagge `GameState.im_titel` alles sperren, was `_process`
  sonst anstößt — dieselbe Bauweise wie `_im_vorspann()`, die dafür schon steht.
* „Neues Spiel" muss den Prolog **wirklich** zurücksetzen — dafür gibt es `_prolog_zuruecksetzen()`
  und `SaveManager.delete_slot()` bereits.

---

## 2. Der erste Gegner

**Wann:** wenn er den Krater verlässt — nicht vorher. In der Grube geht es um ihn selbst; draußen
fängt die Welt an.

**Was fehlt:** die Schuss-Animation. Solange sie fehlt, bleibt der Kern der Szene — *er schießt
automatisch, in Nahaufnahme* — ein Entwurf.

### Der Ablauf

1. **Einer.** Genau ein Gegner, nicht das übliche Rudel. Er kommt aus dem Blech seitlich vor ihm
   heraus, langsam, und hat ihn noch nicht gesehen. Wer zum ersten Mal etwas sieht, das hier
   herumläuft, soll es *ansehen* können.
2. **Die Kamera geht näher** und setzt sich seitlich hinter seine Schulter — beide im Bild, der
   Gegner klein und deutlich. Kein Weitwinkel: Hier ist die Frage nicht *wo bin ich*, sondern
   *was ist das*.
3. **Er schießt automatisch.** Der Spieler drückt nicht. Das ist bewusst: Die Figur kann etwas,
   was der Spieler noch nicht kann, und weiß selbst nicht, woher — dieselbe Frage wie beim
   Karabiner in der Truhe (*„als hättest du das schon tausendmal gemacht"*).
4. **Der Gegner fällt.** Bis eine Sterbe-Animation da ist: `idle` weiterlaufen lassen und das
   Modell um 90° auf die Seite kippen, dazu ein kurzer Fall. Das ist ein Platzhalter und sieht
   auch so aus — besser als eine Leiche, die steht.
5. **Er beugt sich darüber**, und die Kamera fährt langsam auf den Toten zu, bis er das Bild
   füllt. Erst hier sieht man, dass in ihm etwas steckt.
6. **Erst jetzt** wird die Beute aufhebbar. Nicht vorher: Der Sinn der Szene ist, dass man es
   *lernt*, und wer vorher schon einsammeln kann, lernt nichts.

### Was er sagt

> **DER NAMENLOSE:** „…"
> „Das ging schnell. Zu schnell."
> „Ich hab nicht nachgedacht. Meine Hände schon."
> *(er beugt sich hinunter)*
> „Und was bist du gewesen?"
> „Blech über Fleisch. Oder Fleisch über Blech, wer weiß das schon."
> „Da klappert was."
> *(Kamera auf den Toten)*
> „Schrauben. Ein Kern. Und Patronen — Patronen für was?"
> „Er hat sie getragen wie einer, der weiß, dass er sie braucht."
> „Also nehm ich sie. Er braucht sie nicht mehr, und ich schon."

Die letzte Zeile ist der Punkt: **Plündern wird nicht zur Spielfunktion erklärt, sondern
begründet.** Ein Spiel, in dem man Leichen durchsucht, sollte einmal aussprechen, was das ist.

### Offene Frage

Welcher Gegner? **Kessel-Kläffer** (Schwarm, mechanisch) wäre falsch — der kommt nie allein.
**Wegelagerer** passt: menschlich genug, dass die Frage *„was bist du gewesen"* trägt, und er ist
ohnehin das Ziel des ersten Kopfgelds bei Mabel.

---

## 3. Der Riss („Ripple")

**Was:** ein Spalt quer durch die Karte, **10 m breit**, über den man zunächst nicht kommt.

### Warum das mehr ist als eine Mauer

Sektor 1 und 2 trennen schon die **Sprengtore** (Kapitel 5), Sektor 2 und 3 die **Smog-Linie**.
Beides sind Bauwerke des Konzerns — Grenzen, die jemand gezogen hat. Der Riss ist die dritte
Sorte und die interessanteste: eine Grenze, die **niemand** gezogen hat.

Das gibt ihm eine Aufgabe, die die anderen beiden nicht haben können: Er ist der erste Hinweis
darauf, dass mit dieser Welt etwas nicht stimmt — vor jeder Erklärung, wer den Krater gemacht hat.

### Wie er gebaut wird

Als **Geländeform**, nicht als Modell — aus demselben Grund wie beim Ausguck: `height_at()` ist
die einzige Wahrheit für Bodenhöhe, und ein aufgestelltes Modell wüsste nichts davon. Man liefe
hindurch, die Fußspur ginge darüber weg, Gegner ständen in der Luft.

Die vorhandenen Formen sind alle **rund** (`crater`, `dunes`). Ein Riss braucht eine neue Art:

```
{ "id": "ripple", "kind": "spalt",
  "von": [x1, y1], "bis": [x2, y2],   # Verlauf in Weltkoordinaten
  "breite": 10.0,                      # Meter
  "tiefe": 40.0,                       # tief genug, dass unten nichts zu sehen ist
  "kante": 0.8 }                       # wie scharf die Oberkante bricht
```

Das Höhenprofil ist der Abstand zur **Strecke** statt zum Mittelpunkt — sonst dieselbe Rechnung.

### Drei Dinge, die dabei zu klären sind

1. **Die Bodenkachelung.** Der Weltboden wird aus Rechtecken gekachelt, in die je Geländeform
   *ein* Loch geschnitten wird. Ein Riss quer über die Karte schneidet ein sehr langes, sehr
   schmales Loch — und der Test *„Restfläche + Löcher = Weltfläche"* wird das als Erstes prüfen.
2. **Die Steigungsgrenze reicht nicht.** Sie sperrt nur bergauf. An einem Riss läuft man
   *hinunter* — und stürbe unten. Es braucht eine echte Sperre an der Kante, und die sollte
   **sichtbar** sein: eine Fußspur, die am Rand endet, ist derselbe Fehler wie damals an der
   Palisade.
3. **Wie kommt man irgendwann hinüber?** Eine Brücke ist die naheliegende Antwort und die
   langweiligste. Besser: ein **umgekippter Zugwaggon**, der irgendwo als Steg quer darin liegt —
   dann ist das Hinüberkommen ein Ort, den man findet, und keine Freischaltung.
