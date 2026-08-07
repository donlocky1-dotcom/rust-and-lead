# Prolog & Kapitel 1 — der spielbare Anfang

Was hier steht, ist der **Fluss**: wo man aufwacht, was man findet, mit wem man spricht, wohin
man geschickt wird. Die Zahlen und Tabellen dahinter stehen im MASTER_GDD (§3 Kampagne,
§4.3 NPCs, §5 Mini-Quests); dieses Blatt ist die Reihenfolge.

Stand: Der Prolog **läuft**, und die **Dialoge sind Daten** (`DialogData.gd`) — Aufwachen, erste Sätze, leere Hände, Truhe, Pferd, Fußspur,
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

**1. Aufwachen.** Gut eine Minute — die Szene dauert so lange, wie der Held zu reden hat, nicht
andersherum. Eine Kamerafahrt mit fester Länge zwingt den Text in ihr Korsett, und dabei kommen
vier Halbsätze heraus.

**Die Kamera bleibt am Kopf, und zwar von vorn.** Sie fängt dicht am Gesicht an — man sieht
einen Mann im Dreck, bevor man sieht, wo er liegt. Zwei Dinge mussten dafür stimmen:

* Die Wegpunkte hängen am **Kopfknochen**, nicht an festen Punkten. Der Kopf wandert beim
  Aufstehen über anderthalb Meter durch den Raum (0,79 m im Sitzen, 1,63 m im Stehen, gemessen);
  feste Zielpunkte zielten zwangsläufig daneben — der erste Versuch punktgenau auf seine Stiefel.
* Die Versätze stehen in **seinem** Bezugssystem, nicht in Weltachsen (−Z ist vorn). Sonst hängt
  es vom Zufall der Figurendrehung ab, ob man ihr ins Gesicht oder auf den Rücken sieht — und
  beim ersten Versuch war es der Rücken. Dasselbe gilt für das Szenenlicht: Von hinten liegt
  genau das im Schatten, was die Szene zeigen soll.

Während er hochkommt, wächst der Abstand von 1,2 auf 4,2 m — der Kopf bleibt in der Bildmitte
(nachgemessen: Bildpunkt 640/360), der Ausschnitt wird weit.

**Er hält zwischendurch inne.** `Stand_Up1` ist eine durchlaufende Bewegung: jemand steht auf,
fertig. Wer nach Stunden im Schutt aufwacht, tut das nicht am Stück. Zwei **Haltepunkte**, an
denen der Clip stehenbleibt, plus ein Grundtempo unter eins — aus acht Sekunden Animation wird
eine halbe Minute Aufstehen. Das Tempo rechnet sich aus der echten Cliplänge; ein neues Rig
muss nicht neu eingestellt werden.

**Er ist beleuchtet.** Der Prolog beginnt um 18:36, und die Schrottgrube hat 66°-Wände: In
einem Krater ist tief stehendes Licht genau das, was *nicht* ankommt. Der Grubenboden bekam nur
Umgebungslicht, die Figur war eine Silhouette ohne Gesicht — im Augenblick, in dem man ihr am
nächsten ist. Deshalb hat die Szene ein eigenes Licht: warm, tief, von der Seite, wie die letzte
Sonne über dem Kraterrand. Es geht am Ende mit der Kamerafahrt unter.

**Er redet, und die Tafel läuft von selbst weiter.** Sechzehn Zeilen, jede so lange stehend,
wie sie zu lesen braucht; ein Tipp überspringt die Restzeit. Erst der Körper, dann der Ort,
dann die Frage nach ihm selbst — und die bleibt offen:

> **DER NAMENLOSE:** „…hh."
> „Mein Schädel. Als hätte mir jemand einen Kessel drübergezogen und draufgeschlagen."
> „Öl im Mund. Rost in der Nase. Und irgendwas Klebriges im Haar."
> „…das ist Blut. Meins, nehm ich an."
> „Wo bin ich hier? Blech. Fässer. Ein halber Zug."
> „Eine Kippe. Ich lieg auf einer Müllkippe, in einer Pfütze aus irgendwas."
> „Wie komm ich hierher? Denk nach. Irgendwas."
> „Nichts. Kein Weg, kein Gesicht, kein gestern."
> „Wer bringt einen Mann auf eine Halde und lässt ihn liegen? Und wofür?"
> „Wie heiße ich eigentlich."
> „…"
> „Auch das noch nicht. Gut. Später."
> „Wasser. Ich brauch Wasser, und was zu essen, und was zum Festhalten."
> „Aber zuerst muss ich mich orientieren. Ich weiß ja nicht mal, wo ich hier bin."
> „Da drüben ragt was aus dem Sand. Ein Fels, hoch genug."
> „Von da oben sehe ich vielleicht mehr als Blech und Dreck."


Dass die Frage nach dem Namen unbeantwortet stehenbleibt, ist der ganze Aufbau der Geschichte
in einem Satz.

Die letzten drei Zeilen sind der **Auftrag an den Spieler**: Er sagt selbst, dass er sich
orientieren muss, und er sagt selbst, wohin — auf den Fels. Danach zeigt die Fußspur genau
dorthin. Ohne diese Zeilen wäre die Spur eine Anweisung von außen; mit ihnen ist sie sein
eigener Entschluss.

Die **Lache**, auf der er liegt, zeigt den Himmel — abends kupfern, nachts blaugrau. Ohne das
war sie ein schwarzes Loch, das die Figur verschluckte: `metallic` ohne Himmelsreflexion ist
schwarz, und der Grubengrund liegt im Schatten der Wand.

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

**5. Der Weg.** Die Fußspur führt aus der Grube **zuerst auf den Ausguck**, danach nach
Rustwater — und dort, seit die Palisade steht, **durch das Tor** statt gegen die Mauer.

Vorher gab es während des ganzen Prologs *gar keine* Spur: Der Wegweiser hing an der verfolgten
Quest, und die erste Quest bekommt man in Rustwater — also genau dann, wenn man den Weg schon
gefunden hat.

Solange er noch draußen ist, zeigt sie auf den **Fuß der Rampe**, nicht auf den Gipfel. Der Fels
ist rundum 77° steil; eine Spur, die geradewegs nach oben weist, führt gegen eine Wand —
dasselbe Problem wie bei der Palisade, wo sie vor der Mauer endete statt durchs Tor zu gehen.
Erst wenn er am Fels steht, zeigt sie hinauf.

**5b. Der Ausguck.** Auf halbem Weg (276 m von der Grube, 255 m vor der Stadt) ragt ein
**15 m hoher Fels** aus dem Sand: flaches Plateau, ringsum steile Kante, auf der Grubenseite ein
Sporn, über den man hinaufkommt. Wer aus der Grube kommt, sieht ihn vor sich und steigt hinauf,
um sich zu orientieren.

**Ein Fels, kein Hügel** — der Unterschied steckt in drei Dingen:

* **Der Umriss ist nicht rund** (`kerb` 0,27): Der Radius schwankt je nach Richtung zwischen 18
  und 30 m, mit Vorsprüngen und Einbuchtungen. Ein Kegel liest sich als Hügel, egal wie steil er
  ist. Der größte Vorsprung liegt auf dem Aufstieg — wo ein Fels einen Sporn hat, läuft der Weg
  hinauf, und dort ist er am flachsten.
* **Die Oberkante ist eine Kante.** `smoothstep` setzt an beiden Enden waagerecht an — für eine
  ausgewaschene Erdwand richtig, für Fels falsch: Genau diese abgerundete Oberkante macht ihn im
  Bild zur Kuppel. Stattdessen `(1−u)^1,8`: am Rand am steilsten (63–74°), nach unten
  abflachend, wo sich der Sand anlegt. Das ist die Silhouette einer Tafelberg-Kuppe.
* **Er ist steinfarben.** Scheitelfarben auf dem vorhandenen Sand-Shader, über die Höhe
  eingeblendet: unten Sand, ab gut vier Metern Stein. Keine zweite Textur, kein zweites Netz.

**15 m, nicht 24.** Man will darüber stehen, nicht darauf thronen: Aus 15 m liegt Rustwater in
255 m Entfernung 3,4° unter der Waagerechten — die Kamera schaut also praktisch geradeaus unter
der Felskante hindurch in die Ebene, statt von oben auf eine Landkarte.

Und es ist **Gelände, kein 3D-Objekt** — ein *umgedrehter Krater*: dieselbe Formel, `depth`
negativ. Das Höhenprofil eines Kraters ist ein flacher Boden, eine steile Wand und ein
Sektor, in dem die Wand fehlt; Vorzeichen gedreht ergibt genau das Gesuchte. `height_at()` ist
die einzige Wahrheit für Bodenhöhe im ganzen Spiel — daran hängen Laufen, Fußspuren, Streuung,
jede Figur und jede Kiste. Ein aufgestelltes Modell wüsste davon nichts: Man liefe hindurch, die
Fußspur ginge darunter her, Gegner ständen in der Luft.

Gemessen: **Kante 63–74°, Aufstieg 38°.** Dazwischen liegt die neue **Steigungsgrenze von 45°** — bis
jetzt gab es keine, man lief die 66°-Wand der Schrottgrube hoch wie eine Fliege und ihre Rampe
war reine Deko. Gesperrt wird nur *bergauf*; wer von der Kante springt, hat sich dafür
entschieden.

**Sie startet erst ganz oben.** Der erste Auslöser fragte nur den *waagerechten* Abstand zur
Felsmitte ab — auf der Rampe steht man dort aber erst auf halber Höhe: 8,2 m über dem Sand und
knapp sieben Meter unter dem Gipfel. Die Fahrt fing an, die Kamera kreiste auf Gipfelhöhe um
einen Punkt weiter unten und lief dabei durch den Berg. Jetzt zählt die **Höhe**: innerhalb von
zwei Metern unter dem Gipfel, und die zwei Meter, weil die aufgesetzten Buckel den Standplatz
um etwa anderthalb Meter wellen.

Oben übernimmt die Kamera ein zweites Mal — **15 Sekunden im Weitwinkel** (78° statt 50°):

1. Zurück und hoch, hinter ihm (2,6 s)
2. **Um ihn herum**, 230°, von 3,5 auf 17 m steigend (7,4 s) — er bleibt in der Mitte, der ganze
   Horizont dreht sich hinter ihm
3. Schwenk über seine Schulter **hinunter ins Tal auf Rustwater** (3,2 s)
4. Zurück in die Ausgangshaltung (1,8 s)

> **DER NAMENLOSE:** „Von hier oben sieht man wenigstens etwas."
> „Wüste. Wüste. Und noch mal Wüste."
> „…da. Ganz hinten im Tal."
> „Dächer. Ein Turm. Und Licht — da lebt jemand."
> „Ein Fußmarsch. Aber der erste Weg, der irgendwohin führt."

**Warum das der richtige Ort dafür ist:** Ein Überblick, den man sich *ergeht*, ist etwas anderes
als einer, den man geschenkt bekommt. Der Held weiß nicht, wo er ist; er sucht sich den höchsten
Punkt und steigt hoch. Das ist eine Handlung, keine Zwischensequenz — die Kamera bestätigt sie
nur. Der Anflug bei 95 m (Punkt 6) bleibt davon unberührt: Der Ausguck sagt *„dahin"*, der
Anflug sagt *„da bin ich"*.

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
| 3 | **Um die Palisade** — 250°, Blick nach innen, von 24 auf 40 m steigend | 8,4 s | ~30 m/s |
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

**Umrundet wird die Palisade, nicht der Wasserturm.** Der erste Entwurf kreiste um den Turm,
weil er die Landmarke ist. Im Bild war das eine Fahrt um ein Fass: Der Turm füllte den Rahmen,
die Stadt lag als Streifen dahinter, und weil er am *Ortsrand* steht, schaute die halbe
Umrundung nach draußen in die Wüste.

Um die Mauer herum, mit dem Blick nach **innen**, zeigt jede Sekunde dasselbe Motiv aus einer
neuen Richtung: den beleuchteten Ort. Der Turm ist dabei nicht weg — er dreht sich als
Silhouette durch das Bild, so wie man ihn beim Herangehen auch sieht.

Der Radius kommt aus dem **tatsächlichen** Umriss der Palisade plus 22 m Abstand; eine feste
Zahl wäre in dem Moment falsch, in dem jemand im Editor ein Mauerstück versetzt.

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
| ~~1~~ | ~~**Dialoge als Daten.**~~ **Erledigt** — `DialogData.gd`, sechs Personen, fünf Anlässe, eigene Zeilen nach dem Reveal. |  |
| ~~3~~ | ~~**Erstbegegnung mit Mabel erzwingen**~~ **Erledigt** — die Fußspur führt in der Stadt zu ihr, bis man mit ihr geredet hat. |  |
| 1 | **Alte Dialoge als Daten (Rest).** Bisher liefert `OverworldView._npc_line()` je NPC einen Satz aus einer `if`-Kette. Für eine Story braucht es mehrseitige Gespräche mit Zustand („erstes Mal", „Quest läuft", „abgabebereit") — also eine `DialogData`-Tabelle wie `QuestManager.QUESTS`, und die Sprechtafel blättert durch. | mittel |
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
