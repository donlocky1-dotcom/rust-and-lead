# Ton

## Synthetisch, nicht gesammelt

Die Dateien hier sind **erzeugt**, nicht aufgenommen — von `tools/sfx/make_sfx.py`. Zwei Gründe:

* Ein Aufnahme-Archiv bringt **Lizenzfragen** mit, die das ganze Projekt betreffen. Eine
  einzelne falsch deklarierte Datei kann später den Vertrieb blockieren.
* Es liefert trotzdem selten genau den **Charakter**, den eine Szene braucht. Hier war der
  Charakter die Vorgabe — *peitschend* —, und der lässt sich bauen.

Deshalb liegt der Erzeuger im Projekt und nicht nur sein Ergebnis: Wer den Klang ändern will,
dreht an einer Zahl und lässt ihn neu laufen.

```
python3 tools/sfx/make_sfx.py
```

## Wie ein Gewehrschuss gebaut ist

Drei Dinge, einzeln regelbar:

1. **Der Knall** (*crack*). Die Überschall-Kugel zieht eine N-Welle hinter sich her. Das ist der
   peitschende Anteil — sehr kurz (unter 2 ms) und im Band 1–4 kHz. Wer ihn wegfiltert, bekommt
   einen Böller.
2. **Der Mündungsknall** (*blast*). Das expandierende Gas: breiter, tiefer, ~35 ms. Die Wucht.
3. **Der Nachhall.** In der Wüste kommt er von den Kraterwänden — **einzelne, späte Rückwürfe**
   statt eines gleichmäßigen Raumhalls. Mit jedem Rückwurf dumpfer, weil Luft hohe Frequenzen
   zuerst schluckt.

### Zwei Fassungen des Schusses

Der Prolog beginnt im Abendrot und endet tief in der Nacht. Nachts trägt kühle Luft weiter:

| | Rückwürfe | Länge |
|---|---|---|
| `karabiner_schuss_tag` | 4 | 1,7 s |
| `karabiner_schuss_nacht` | 6 | 2,6 s |

Umgeschaltet wird nach `DayCycle`, nicht nach einer von Hand gesetzten Uhrzeit.

### Gemessen

| Band | Anteil (erste 30 ms, Nachtfassung) |
|---|---|
| 60–250 Hz | 7,9 % — der gefühlte Stoß |
| 250–1000 Hz | 30,3 % — der Körper |
| 1–2 kHz | 20,1 % — Knall |
| 2–4 kHz | 19,2 % — Knall |
| 4–8 kHz | 10,4 % |
| 8–16 kHz | 7,2 % |

> **Ein verworfenes Maß.** Zuerst wurde der *spektrale Schwerpunkt* gemessen und lag bei 11 kHz —
> das klang nach „zu hell". Zwei Filterrunden später stand er immer noch bei 7,6 kHz, obwohl der
> Klang hörbar dunkler geworden war. Der Grund: Bei einem Transienten dominiert die Flanke selbst
> das Spektrum — ein Anschlag von 0,04 ms *ist* breitbandig, egal was danach kommt. Die
> Bandverteilung oben sagt, was der Schwerpunkt nicht sagen konnte.

## `karabiner_repetieren`

Vier Ereignisse mit **Pausen dazwischen** — genau die Pausen machen daraus eine Handlung statt
eines Rasselns:

| ab | was | Klang |
|---|---|---|
| 0 ms | Griff hoch und zurück | hell, leicht (2,6 / 4,1 kHz) |
| 135 ms | Hülse springt heraus | am dünnsten und hellsten (5,2 / 7,4 kHz) |
| 300 ms | Verschluss nach vorn | mittig (1,9 / 3,3 kHz) |
| 430 ms | verriegelt | am sattesten (1,4 / 3,0 kHz) — Masse trifft Masse |

Gespielt wird es **0,22 s nach dem Schuss**, nicht gleichzeitig: erst der Knall, dann fährt der
Verschluss. Kürzer klingt nach Automat, länger nach Ladehemmung.

## Warum `AudioStreamPlayer3D`

Die Spieler hängen an der Figur, nicht in der Welt. Godot rechnet die Entfernung zur Hörposition
selbst aus, und die Kamera wandert im Prolog bis zu 34 m weg. Ein Schuss, der aus 34 m genauso
laut ist wie aus zwei Metern, klingt wie eine Tonspur und nicht wie ein Ereignis in der Welt.

Das Repetieren bleibt dagegen **nah und trocken** (`unit_size` 4 statt 26): Es ist ein Geräusch an
der Waffe, kein Schall über die Ebene.

## Noch offen

Sprache. Der Monolog im Prolog steht als Text auf der Sprechtafel; die Tonspur dazu kommt
nach — dann wird die Standzeit jeder Zeile aus der **Cliplänge** genommen statt aus der
Zeichenzahl geschätzt (`speech_dauer()`).
