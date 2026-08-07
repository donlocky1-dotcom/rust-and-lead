# Prolog & Kapitel 1 — der spielbare Anfang

Was hier steht, ist der **Fluss**: wo man aufwacht, was man findet, mit wem man spricht, wohin
man geschickt wird. Die Zahlen und Tabellen dahinter stehen im MASTER_GDD (§3 Kampagne,
§4.3 NPCs, §5 Mini-Quests); dieses Blatt ist die Reihenfolge.

Stand: der Prolog steht mechanisch (Start in der Grube, leere Hände, Truhe, Fußspur, Pferd).
Die **Dialoge** sind hier als Text formuliert und noch nicht im `QuestManager` verdrahtet.

---

## Der Prolog — „Was vom Menschen übrig ist"

Der Held erwacht **in der Lache am Grund der Schrottgrube**. Kein Menü, keine Erklärung. Die
Lache ist der einzige freie Fleck im Schutt — der einzige Ort, an dem man liegen kann; genau
deshalb wird sie beim Füllen ausgespart.

**0. Es ist Abendrot.** Eine Runde beginnt um **18:36** (`DayCycle.START_HOUR`). Das ist keine
Kosmetik, sondern der Bauplan des Prologs: Der Held erwacht in der Dämmerung, und während er
Richtung Rustwater geht, wird es Nacht. Zu Fuß dauert der Kilometer vier Minuten — acht
Spielstunden, Ankunft gegen **01:40**. Im Sattel reicht es gerade für die Dämmerung.

**1. Aufwachen.** Kamerafahrt von oben auf die Figur, dann in die Spielkamera. Erste Meldung:

> *Dein Schädel dröhnt. Öl im Mund, Rost in der Nase. Du weißt nicht, wie du hierhergekommen
> bist — und, jetzt wo du darüber nachdenkst: auch nicht, wer dich hergebracht hat.*

**2. Leere Hände.** Wer den Schuss-Knopf drückt, bekommt „🚫 Leere Hände. Such dir etwas."
Das ist der erste Lehrsatz des Spiels und braucht keinen Text darüber hinaus.

**3. Die Truhe.** Steht am Grund der Grube, in Sichtweite. Darin liegt der **Blei-Karabiner** —
garantiert, nicht ausgewürfelt. Der Anfang einer Geschichte darf nicht auswürfeln, ob sie
stattfindet. Dazu Gold, Munition, ein Ausrüstungsteil.

> *Ein Karabiner, Lauf voller Sand. Er passt in deine Hand, als hättest du das schon tausendmal
> gemacht. Woher weißt du das?*

**4. Das Pferd.** Steht am Kraterrand, auf der Seite von Rustwater, mit Namensschild. `[E]`
sitzt auf: **dreifaches Tempo, kein Schuss aus dem Sattel.** Der Weg in die Stadt ist gut einen
Kilometer weit; zu Fuß sind das vier Minuten, im Sattel gut eine.

**5. Der Weg.** Die Fußspur führt aus der Grube nach Rustwater — und, seit die Palisade steht,
**durch das Tor** statt gegen die Mauer.

**6. Der Anblick.** Auf **95 m** übernimmt die Kamera, einmal im ganzen Spiel — 12,6 Sekunden,
jederzeit mit einem Tipp abbrechbar.

Die 95 m sind gemessen, nicht geschätzt: Bei 200 m ist Rustwater nachts ein schwarzer Streifen
am Horizont. Die Nachtlichter reichen 11 bis 23 m weit; was davon auf 200 m ankommt, sind ein
paar Pixel unter der Nebelgrenze. Bei 95 m steht der Wasserturm als Silhouette im Bild, die vier
Torfackeln sind einzeln zu erkennen, und der Sand vor der Palisade glüht.

1. **In seine Sicht** (1,6 s) — auf Augenhöhe. Was er sieht, sieht der Spieler: eine
   beleuchtete Stadt in einer dunklen Wüste.
2. **Anflug** (2,2 s) über die Wüste, in Kopfhöhe bleibend, bis über den Stadtplatz.
3. **Ansetzen** (1,6 s) — hinauf auf Turmhöhe.
4. **Um den Wasserturm** (4,8 s, 220°, dabei von 15 auf 22 m steigend). Der Turm ist die
   Landmarke, an der man Rustwater von weitem erkennt; die Fahrt sagt „das ist der Ort, auf den
   du zuläufst", ohne ein Wort dafür zu brauchen.
5. **Zurück in die Spielhaltung** (2,4 s) über der Figur.

**Die Richtung der Umrundung ist keine Geschmacksfrage.** Der Turm steht am *Rand* von
Rustwater, nicht in der Mitte: Von innen sieht man ihn vor leerer Wüste, von außen vor der
beleuchteten Stadt. Die Fahrt beginnt deshalb innen — Turm vor schwarzem Nichts, ein
geschlossenes Bild — und endet außen, wo er sich vor dem Ort auflöst. Andersherum finge der
Anflug mit seinem besten Bild an und arbeitete sich davon weg.

220° und nicht 360°: Eine volle Runde kommt dort wieder heraus, wo sie angefangen hat, und die
letzten neunzig Grad zeigen dasselbe Bild ein zweites Mal.

Dazu die Zeile: *„🌙 Rustwater. Licht in der Wüste."* Der Flug merkt sich in
`GameState.saw_rustwater`, dass er gelaufen ist — er kommt nicht wieder.

**Abschluss des Prologs:** Betreten von Rustwater setzt `GameState.prolog_done = true`. Ab dann
beginnt eine Runde wieder in der Stadt; niemand soll nach dem zweiten Kapitel wieder auf der
Kippe aufwachen.

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
| 2 | **Skriptierte Momente.** Aufwachen, Truhe, Ankunft in Rustwater sollen etwas AUSLÖSEN. Braucht einen kleinen Auslöser-Mechanismus: „wenn Bedingung, dann einmalig Kamerafahrt + Text". | mittel |
| 3 | **`prolog_done` setzen** beim Betreten von Rustwater, und die Erstbegegnung mit Mabel erzwingen (Marker über ihrem Kopf, Fußspur zu ihr statt zum Quest-Ort). | klein |
| 4 | **Aufwach-Sequenz** — die Figur liegt und steht auf. Braucht einen Clip (`Stand_Up1` ist im Spieler-Rig vorhanden!) und eine Kamerafahrt. | klein |
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

Der Umschalter (`[Tab]`) läuft nur durch Gefundenes. Ohne Waffe: kein Schuss, und die Meldung
sagt warum.
