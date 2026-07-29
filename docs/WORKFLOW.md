# Zusammenarbeit — wie wir Sachen hin und her geben

## Wenn du in Godot Gebäude umstellst

Du hast recht: Ich sehe deine lokale Kopie nicht. Ich arbeite in einem eigenen Klon, der beim
Sitzungsstart frisch von GitHub geholt wird. Was bei dir auf der Platte liegt und nicht gepusht
ist, existiert für mich nicht.

**Der Weg ist einfacher als du denkst: committe und pushe die Szene.**

Rustwater ist bewusst so gebaut, dass deine Platzierung die Wahrheit ist. Sobald
`godot/scenes/Rustwater.tscn` existiert, baut der Code die Stadt nicht mehr aus Zahlen, sondern
lädt sie — und **die Kollision wird aus den tatsächlichen Positionen abgeleitet**, nicht aus
Konstanten. Du kannst also jedes Haus anfassen, drehen, verschieben, und niemand muss
programmieren.

In GitHub Desktop:

1. Reiter **Changes** — dort steht `godot/scenes/Rustwater.tscn`
2. Kurze Zeile ins Feld **Summary**, etwa „Saloon nach Norden, Schmiede an die Gasse"
3. **Commit to main**
4. **Push origin**

Danach sage mir einfach „hab die Stadt umgestellt" — ich hole den Stand und sehe jede Position.

**Was ich dann von mir aus prüfe** (du musst es nicht ansprechen):

* Steht noch alles innerhalb der Mauer?
* Überlappen zwei Gebäude oder ihre Kollisionsflächen?
* Bleibt zwischen den Häusern genug Gasse, dass man mit Spielerradius durchkommt?
* Sind die NPCs noch erreichbar, oder steht jetzt ein Haus vor Mabel?

Diese vier Fragen beantwortet die Testsuite bereits automatisch — ein Haus im Weg fällt beim
nächsten Testlauf auf, nicht erst beim Spielen.

## Wenn ein Push scheitert

Meistens, weil Godot lokal Dateien angefasst hat. `.import`-Dateien und `.godot/` sind inzwischen
aus der Versionsverwaltung genommen, das sollte nicht mehr passieren. Falls doch: **Changes →
Rechtsklick → Discard changes** auf alles, was du nicht selbst geändert hast, dann erneut pullen.

Wichtig: `godot/project.godot` NICHT verwerfen, wenn du dort selbst etwas eingestellt hast — dann
sag es mir lieber, und ich baue es ein.

## Wenn du mir 3D-Modelle schickst

So wie bisher: als 7z-Teile in den Chat. Ich mache den Rest — Aufbereitung
(`prepare_meshy_glb.py`), Registrierung in `AssetRegistry`, Einbau, Test.

Nützlich dazu, wenn es nicht aus dem Namen hervorgeht:

* **Was ist es?** („Desert Sentinel" war ein Kaktus — ich habe es gerendert, um es zu erfahren.)
* **Wie groß soll es sein?** Meshy normiert alles auf dieselbe Kantenlänge, der Maßstab ist also
  beliebig.
* **Steht es aufrecht oder liegt es?** Danach entscheidet sich, ob ich über Höhe oder über die
  längste Kante skaliere.

## Wenn du ein Geländemodell schickst

Anderer Weg als bei Requisiten, weil Gelände die Bodenhöhe bestimmt. Der Werkzeugkasten dafür
steht in Commit `d2e10bc` und lässt sich einzeln zurückholen:

```
git checkout d2e10bc -- godot/tools/bake_heightfield.py
```

Es rastert die Oberseite des Modells in ein Höhenfeld, aus dem `WorldManager.height_at` liest —
Bild und Kollision aus derselben Quelle. Vier Fallen kenne ich inzwischen (Unterseite als
Nullpunkt, Löcher im Netz, Fensterbreite beim Weichzeichnen, Normalen bei ungleichmäßiger
Skalierung); der Weg ist also erprobt.

## Wenn dir etwas im Spiel nicht gefällt

Ein Bildschirmfoto ist mehr wert als eine Beschreibung, und du hast das bisher genau richtig
gemacht. Zwei Fälle sind besonders wertvoll:

* **„das sieht falsch aus"** — dann rendere ich dieselbe Ansicht nach und färbe Bauteile ein, bis
  klar ist, welches den Fehler macht. Mit dem bloßen Rechnen an Formeln bin ich hier schon
  zweimal in die Irre gelaufen.
* **„das war vorher besser"** — jederzeit. Ein Revert kostet fünf Minuten, und wir haben beide
  Fassungen in der Geschichte.
