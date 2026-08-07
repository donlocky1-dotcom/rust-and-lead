# Prolog & Kapitel 1 — der spielbare Anfang

Was hier steht, ist der **Fluss**: wo man aufwacht, was man findet, mit wem man spricht, wohin
man geschickt wird. Die Zahlen und Tabellen dahinter stehen im MASTER_GDD (§3 Kampagne,
§4.3 NPCs, §5 Mini-Quests); dieses Blatt ist die Reihenfolge.

Stand: Der Prolog **läuft** — Aufwachen, erste Sätze, leere Hände, Truhe, Pferd, Fußspur,
Nachtwerden, Anflug auf Rustwater, Abschluss beim Betreten der Stadt. Was fehlt, ist das
**Gespräch**: Die Dialoge sind hier als Text formuliert und noch nicht als Daten verdrahtet.

---

## Der Prolog — „Was vom Menschen übrig ist"

Der Held erwacht **in der Lache am Grund der Schrottgrube**. Kein Menü, keine Erklärung. Die
Lache ist der einzige freie Fleck im Schutt — der einzige Ort, an dem man liegen kann; genau
deshalb wird sie beim Füllen ausgespart.

**0. Es ist Abendrot.** Eine Runde beginnt um **18:36** (`DayCycle.START_HOUR`). Das ist keine
Kosmetik, sondern der Bauplan des Prologs: Der Held erwacht in der Dämmerung, und während er
Richtung Rustwater geht, wird es Nacht. Zu Fuß dauert der Kilometer vier Minuten — acht
Spielstunden, Ankunft gegen **01:40**. Im Sattel reicht es gerade für die Dämmerung.

**1. Aufwachen.** Fünf Sekunden. Die Figur stemmt sich hoch (`Stand_Up1`), während die Kamera
aus 16 m Höhe in die Spielhaltung herunterkommt. Von oben, weil man am Grund einer Grube liegt:
Eine Einstellung zeigt, wo man ist — mitten im Schutt, allein, ohne Weg nach draußen im Bild.

Der Clip dauert 8,3 s, gezeigt wird das **Ende**. Die ersten Sekunden liegt die Figur nur da;
das ist als Animation richtig und als Spielanfang eine Zumutung. Wie weit hineingesprungen wird,
rechnet der Code aus der tatsächlichen Clip-Länge — beim nächsten Rig stimmt es wieder.

Dazu die ersten Sätze, in drei Schüben statt als Wand:

> *Dein Schädel dröhnt. Öl im Mund, Rost in der Nase.*
>
> *Du weißt nicht, wie du hierhergekommen bist. Und, jetzt wo du darüber nachdenkst: auch nicht,
> wer dich hergebracht hat.*
>
> *🔦 Irgendwo hier liegt eine Truhe. Danach: der Weg nach Rustwater.*

Die **Lache**, auf der er liegt, zeigt den Himmel — abends kupfern, nachts blaugrau. Ohne das
war sie ein schwarzes Loch, das die Figur verschluckte: `metallic` ohne Himmelsreflexion ist
schwarz, und der Grubengrund liegt im Schatten der 66°-Wand. Jetzt liegt der Held als Silhouette
auf einem kupfernen Spiegel.

**2. Leere Hände.** Wer den Schuss-Knopf drückt, bekommt „🚫 Leere Hände. Such dir etwas."
Das ist der erste Lehrsatz des Spiels und braucht keinen Text darüber hinaus.

**3. Die Truhe.** Steht am **Rand der Lache**, in Richtung des Lokomotivenwracks — nicht in der
Mitte: Dort liegt der Held, und die Truhe stand buchstäblich auf ihm. Die Richtung kommt aus der
Szene, wer das Wrack im Editor verschiebt, nimmt die Truhe mit. Darin liegt der **Blei-Karabiner** —
garantiert, nicht ausgewürfelt. Der Anfang einer Geschichte darf nicht auswürfeln, ob sie
stattfindet. Dazu Gold, Munition, ein Ausrüstungsteil.

> *Ein Karabiner, Lauf voller Sand. Er passt in deine Hand, als hättest du das schon tausendmal
> gemacht. Woher weißt du das?*

**4. Das Pferd.** Steht am Kraterrand, auf der Seite von Rustwater, mit Namensschild. Aus 4 m
erscheint **🐎 Aufsitzen** in der Aktionsleiste (oder `[E]`): **dreifaches Tempo, kein Schuss aus
dem Sattel.** Der Weg in die Stadt ist gut einen Kilometer weit; zu Fuß sind das vier Minuten,
im Sattel gut eine.

**5. Der Weg.** Die Fußspur führt aus der Grube nach Rustwater — und, seit die Palisade steht,
**durch das Tor** statt gegen die Mauer.

**6. Der Anblick.** Auf **95 m** übernimmt die Kamera, einmal im ganzen Spiel — **sechzehn
Sekunden**, jederzeit mit einem Tipp abbrechbar. Solange die Fahrt läuft, steht die Figur; sonst
liefe sie weiter, während die Kamera anderswo ist, und die Fahrt endete dreißig Meter hinter ihr.

Die 95 m sind gemessen, nicht geschätzt: Bei 200 m ist Rustwater nachts ein schwarzer Streifen
am Horizont. Die Nachtlichter reichen 11 bis 23 m weit; was davon auf 200 m ankommt, sind ein
paar Pixel unter der Nebelgrenze. Bei 95 m steht der Wasserturm als Silhouette im Bild, die vier
Torfackeln sind einzeln zu erkennen, und der Sand vor der Palisade glüht.

| | Etappe | Dauer | Tempo |
|---|---|---|---|
| 1 | **In seine Sicht** — auf Augenhöhe, Blick auf die Stadt | 2,8 s | steht |
| 2 | **Anflug** — über Wüste und Palisade hinauf auf Turmhöhe, in einem Zug | 2,8 s | ~34 m/s |
| 3 | **Um den Wasserturm** — 190°, dabei von 15 auf 22 m steigend | 8,4 s | ~11 m/s |
| 4 | **Zurück, Blick auf der Stadt** | 1,2 s | schnell |
| 5 | **Einschwenken** in die Ausgangshaltung | 0,8 s | — |

**Die Verteilung ist der Inhalt.** Nicht jede Etappe bekommt gleich viel, sondern so viel, wie
ihr Tempo sein soll: Der Anflug legt 95 m in 2,8 s zurück — das bleibt der schnelle Teil. Die
Umrundung bekommt mehr als die Hälfte der Fahrt und wirkt dadurch ruhig, obwohl sie sich dauernd
bewegt.

Erst waren es acht Sekunden, und das war zu schnell: 45°/s ist kein Herumfahren mehr, das ist
ein Schwenk. Verdoppelt wurde die **ganze** Fahrt, nicht nur die Umrundung — was hier zählt, ist
das Verhältnis der Etappen zueinander; wer nur eine streckt, verschiebt die Betonung, statt Zeit
zu geben.

Der Rückweg ist mit zwei Sekunden der **kürzeste** Abschnitt. Schneller als der Hinflug ist er
in Metern je Sekunde nicht, und kann es nicht sein: Die Umrundung endet auf der Seite, auf der
die Figur steht, es sind also nur noch gut 40 m nach Hause gegenüber 95 m auf dem Hinweg.

Er **endet exakt in der Ausgangshaltung** — nicht „über der Figur nachgerechnet", sondern die
beim Start gemerkte Kamera-Transform. Das ist dieselbe Zusage auch dann noch, wenn jemand
zwischendurch den Zoom verstellt hat.

**Die Richtung der Umrundung ist keine Geschmacksfrage.** Der Turm steht am *Rand* von
Rustwater, nicht in der Mitte: Von innen sieht man ihn vor leerer Wüste, von außen vor der
beleuchteten Stadt. Die Fahrt beginnt deshalb innen — Turm vor schwarzem Nichts, ein
geschlossenes Bild — und endet außen, wo er sich vor dem Ort auflöst. Andersherum finge der
Anflug mit seinem besten Bild an und arbeitete sich davon weg.

190° und nicht 360°: Eine volle Runde kommt dort wieder heraus, wo sie angefangen hat, und die
letzten neunzig Grad zeigen dasselbe Bild ein zweites Mal. Etwas mehr als eine halbe Runde
reicht für den Umschlag von „Turm vor Nichts" zu „Turm vor der Stadt".

Dazu die Zeile: *„🌙 Rustwater. Licht in der Wüste."* Der Flug merkt sich in
`GameState.saw_rustwater`, dass er gelaufen ist — er kommt nicht wieder.

**Abschluss des Prologs:** Betreten von Rustwater setzt `GameState.prolog_done = true`. Ab dann
beginnt eine Runde wieder in der Stadt; niemand soll nach dem zweiten Kapitel wieder auf der
Kippe aufwachen.

### Den Prolog noch einmal sehen

Das Spiel speichert **automatisch**. Es gibt also keinen Zustand „noch nicht gespeichert" — wer
einmal gestartet ist, fängt beim nächsten Mal mit Spielstand an.

**Der einfache Weg: `[F9]`, zweimal.** Der erste Druck fragt nach, der zweite setzt den Prolog
zurück und lädt die Szene neu. Fortschritt (Level, Gold, Quests, Nebel) bleibt; zurückgesetzt
werden nur Prolog-Marken, Uhrzeit und Waffen — mit dem Karabiner im Arm wäre „leere Hände" keine
Aussage mehr. Zweimal drücken, weil `F9` neben `F10` und `F11` liegt und ein Fehlgriff nicht
rückgängig zu machen wäre.

Dass das überhaupt möglich ist, hängt an `GameState.saw_wake`: Die Aufwach-Szene hängt an
diesem Merkmal, **nicht** daran, ob ein Spielstand geladen wurde. Sonst bekäme man sie nach dem
allerersten Start nie wieder zu sehen — auch nicht nach einem Zurücksetzen.

Für den Start von außen gibt es zusätzlich zwei Schalter:

| Schalter | Wirkung |
|---|---|
| `--prolog` | wie `[F9]`: Spielstand behalten, nur den Prolog zurücksetzen |
| `--neu` | Spielstand **löschen**. Wirklich von vorn. |

Sie stehen in den **Editor**-Einstellungen (nicht den Projekteinstellungen):
*Editor → Editor-Einstellungen → Ausführen → Main Run Args* (`editor/run/main_run_args`). Auf
der Kommandozeile direkt anhängen. Von Hand geht es auch: Die Datei heißt
`rustlead_save_0.json` und liegt im Godot-Benutzerordner (`%APPDATA%\Godot\app_userdata\Rust & Lead\`
unter Windows, `~/Library/Application Support/Godot/app_userdata/Rust & Lead/` auf dem Mac).

---

## Erste Begegnung: Mabel

Die Kette in Akt I steht schon im GDD: **Mabel → Silas → Doc → Mabel**. Der erste Dialog gehört
deshalb **Mamma „Rusty" Mabel**, der Saloon-Wirtin.

Sie ist die richtige Erste, weil sie die Einzige ist, die einen Fremden ohne Frage hereinlässt —
und weil ihre Rolle vor dem Reveal *mütterlich* ist. Der Held wird umsorgt wie ein Mensch. Genau
das macht den Reveal in Kapitel 4 zur Ohrfeige.

> **Mabel:** „Du siehst aus wie durchgekaut und wieder ausgespuckt. Setz dich, bevor du umfällst."
>
> **Mabel:** „Von der Kippe rauf, ja? Da liegen normalerweise nur Blech und Knochen. Du bist mir
> ein hübsches drittes."
>
> **Mabel:** „Namen brauch ich keinen. Wer aus dem Schrott kommt, hat meistens keinen mehr.
> Trink das hier und hör mir zu."

Danach die erste Quest, unverändert aus dem GDD:

**`q_bounty` — „Kopfgeld: Wegelagerer"** · 8 Wegelagerer · 120 💰 + Zahnrad

> **Mabel:** „Draußen sitzen Wegelagerer auf der Piste und nehmen sich, was durchkommt. Acht
> Stück, sagt der Aushang. Bring mir den Beweis, dann bring ich dir was Ordentliches zu essen."

Von da an trägt die vorhandene Kette: `q_bounty` → Silas `q_scrap` → Doc `q_rats` → Mabel
„Hinab in die Schrott-Mine", und jeder NPC weist zum nächsten.

---

## Was noch fehlt, damit das läuft

Der Prolog steht mechanisch. Was ihn zur **Erzählung** macht, fehlt noch:

| | Was | Aufwand |
|---|---|---|
| 1 | **Dialoge als Daten.** Bisher liefert `OverworldView._npc_line()` je NPC einen Satz aus einer `if`-Kette. Für eine Story braucht es mehrseitige Gespräche mit Zustand („erstes Mal", „Quest läuft", „abgabebereit") — also eine `DialogData`-Tabelle wie `QuestManager.QUESTS`, und die Sprechtafel blättert durch. | mittel |
| 2 | **Weitere skriptierte Momente.** Der Mechanismus steht (`_play_flight` für die Kamera, `_play_beats` für den Text, beides an Aufwachen und Ankunft schon verdrahtet). Was fehlt, sind die übrigen Auslöser — vor allem die Truhe. | klein |
| 3 | **Erstbegegnung mit Mabel erzwingen** — Marker über ihrem Kopf, Fußspur zu ihr statt zum Quest-Ort. (`prolog_done` wird inzwischen gesetzt.) | klein |
| 5 | **Codex/Erinnerung** — die Kinetoskop-Walzen (§8.3) sind im Backend fertig, aber im Prolog noch nicht angefasst. Die erste Walze gehört in die Grube. | klein |

Reihenfolge-Vorschlag: **1 → 3 → 4 → 2 → 5.** Ohne (1) ist alles andere Text in einer
Meldungszeile.

---

## Waffen: was er wann hat

`GameState.weapons` führt, was er **gefunden** hat. Vorher trug er alle fünf von der ersten
Sekunde an — damit ist jede Beute wertlos und die vier Schadensarten (§6.1) haben keinen Aufbau.

| Waffe | Art | woher | wann |
|---|---|---|---|
| **Blei-Karabiner** | Kinetik | Truhe in der Schrottgrube | Prolog, garantiert |
| Messing-Gatling | Kinetik | Werkstatt / Beute | Kap. 2 |
| Leydener Volt-Karabiner | Galvanik | Beute Konzern-Patrouille | Kap. 2–3 |
| Säure-Sprüher | Alchemie | Doc / Labor-Ausbau | Kap. 3 |
| Dampf-Brenner | Thermik | Mine, Boss-Beute | Kap. 3–4 |

**Es gibt keinen Umschalter mehr.** `[Tab]` schaltete früher durch eine feste Liste von fünf
Gattungen — eine zweite Wahrheit neben dem Inventar, die nichts von Seltenheiten und Werten
wusste. Angelegt wird im **Beutel**, wie jedes andere Ausrüstungsteil; `[Tab]` öffnet ihn.

Ohne Waffe: kein Schuss, kein Munitionszähler, und die Meldung sagt warum.
