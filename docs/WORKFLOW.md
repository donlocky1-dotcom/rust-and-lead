# Zusammenarbeit — wie wir Sachen hin und her geben

## Wer darf wohin schreiben — die Ausgangslage

Gemessen, nicht vermutet:

* Das Repo liegt unter **`s6w5jrpz7n-source`**. Das ist ein **Maschinenkonto der Arbeitssitzung**,
  nicht das Konto des Auftraggebers (`donlocky`).
* Die Mitarbeiterliste des Repos hat genau einen Eintrag: dieses Maschinenkonto, als Admin.
* Damit gilt: **`donlocky` kann lesen (das Repo ist öffentlich), aber nicht pushen.**

Das ist keine Einstellung, die sich hier drehen lässt. Der Werkzeugkasten der Sitzung kennt
„Mitarbeiter auflisten", aber kein „Mitarbeiter hinzufügen", und ein Repo unter einem anderen
Eigentümer lässt sich einer laufenden Sitzung nicht zuschalten:

    add_repo: cross-tier adds are not supported in v1 — requested "donlocky/rust-and-lead"
    but session already has repos from owner(s) [s6w5jrpz7n-source]

**Eine frühere Fassung dieses Dokuments riet „committe und pushe die Szene". Das war falsch** und
konnte gar nicht funktionieren.

## Wenn du in Godot Gebäude umstellst — der Weg, der heute geht

Derselbe wie bei den 3D-Modellen: **Datei in den Chat ziehen.**

1. In Godot umstellen und speichern
2. `godot/scenes/Rustwater.tscn` in den Chat ziehen (3,5 KB Text, geht sofort)
3. Dazuschreiben, was du geändert hast

Ich committe die Szene und pushe sie. Beim nächsten Pull hast du deinen eigenen Stand zurück —
diesmal mit allem, was ich daran geprüft habe.

Rustwater ist so gebaut, dass deine Platzierung die Wahrheit ist: Liegt die Szene vor, wird die
Stadt nicht mehr aus Zahlen gebaut, sondern geladen, und **die Kollision wird aus den
tatsächlichen Positionen abgeleitet**. Du kannst also jedes Haus anfassen, drehen, verschieben,
ohne dass jemand programmieren muss.

**Was ich dann von mir aus prüfe** (du musst es nicht ansprechen):

* Steht noch alles innerhalb der Mauer?
* Überlappen zwei Gebäude oder ihre Kollisionsflächen?
* Bleibt zwischen den Häusern genug Gasse, dass man mit Spielerradius durchkommt?
* Sind die NPCs noch erreichbar, oder steht jetzt ein Haus vor Mabel?

Diese vier Fragen beantwortet die Testsuite automatisch — ein Haus im Weg fällt beim nächsten
Testlauf auf, nicht erst beim Spielen.

## Der Weg, der das Problem dauerhaft löst

Das Projekt gehört unter das Konto des Auftraggebers, nicht unter ein Sitzungskonto.

1. Auf GitHub **Fork** von `s6w5jrpz7n-source/rust-and-lead` nach `donlocky`. Vollständige Kopie
   samt Historie, und `donlocky` ist Eigentümer.
2. **Die nächste Sitzung mit `donlocky/rust-and-lead` als Quelle starten.** Ab da schreiben beide
   Seiten in dasselbe Repo, und alles unten Beschriebene (committen, pushen, Reihenfolge beim
   Pull) gilt wieder.

Schritt 2 ist der entscheidende — in einer laufenden Sitzung lässt sich die Quelle nicht wechseln.

Ein Fork friert den Stand des Augenblicks ein: Was danach noch ins alte Repo gepusht wird, muss
nachgezogen werden. Am saubersten also forken und direkt darauf weiterarbeiten.

## Wenn ein Push scheitert (gilt ab dem Fork)

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
