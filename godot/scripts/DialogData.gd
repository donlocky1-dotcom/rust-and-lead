extends RefCounted
## Was die Leute sagen — als **Tabelle**, nicht als `if`-Kette.
##
## Vorher lieferte `OverworldView._npc_line()` je Person und Anlass EINEN Satz aus einer
## verschachtelten Bedingung. Das reicht für ein Spiel, in dem Auftraggeber Automaten sind, und
## nicht für eines, das eine Geschichte erzählt: Ein Gespräch besteht aus mehreren Sätzen, es
## hängt davon ab, ob man sich schon kennt, und es ändert sich, wenn man etwas über den anderen
## erfährt. Nichts davon lässt sich in einer Rückgabe vom Typ String unterbringen.
##
## ## Aufbau
##
## `LINES[giver][anlass]` ist eine **Liste von Zeilen** — die Sprechtafel blättert durch.
##
## | Anlass | wann |
## |---|---|
## | `erst`  | das allererste Mal, dass man diese Person anspricht |
## | `offer` | sie hat einen Auftrag zu vergeben |
## | `wait`  | der Auftrag läuft |
## | `done`  | der Auftrag ist erfüllt |
## | `idle`  | nichts zu tun |
##
## `erst` ist kein Ersatz, sondern kommt DAVOR: Wer Mabel zum ersten Mal trifft und dabei einen
## Auftrag bekommt, hört erst die Begrüßung und dann den Auftrag. Sonst müsste die Begrüßung
## entweder verlorengehen oder den Auftrag verschieben, und beides wäre falsch.
##
## ## Nach dem Reveal
##
## Steht `<anlass>_enthuellt` in der Tabelle, gilt sie, sobald `GameState.is_revealed` wahr ist
## (GDD §4: Ab Kapitel 4 wissen alle drei, dass unter dem Mantel ein Automat steckt, und reden
## anders mit einem). Fehlt sie, bleibt es beim normalen Text — nicht jede Zeile muss sich
## ändern, und eine Tabelle, die jede Variante verlangt, wird nie gefüllt.
##
## ## Warum hier und nicht im QuestManager
##
## Weil nicht jedes Gespräch an einem Auftrag hängt. Der `QuestManager` weiß, WAS zu tun ist;
## diese Tabelle weiß, WIE jemand redet. Wer beides vermischt, kann keine Person schreiben, die
## nichts zu vergeben hat — und das sind die interessanten.

const LINES: Dictionary = {
	# ── Mamma „Rusty" Mabel, Saloon-Wirtin ────────────────────────────────────
	#
	# Die erste Person im Spiel, und das ist kein Zufall: Sie ist die Einzige, die einen Fremden
	# ohne Frage hereinlässt. Ihre Rolle vor dem Reveal ist MÜTTERLICH — der Held wird umsorgt
	# wie ein Mensch. Genau das macht den Reveal in Kapitel 4 zur Ohrfeige.
	"mabel": {
		"erst": [
			"„Du siehst aus wie durchgekaut und wieder ausgespuckt. Setz dich, bevor du umfällst.“",
			"„Von der Kippe rauf, ja? Da liegen normalerweise nur Blech und Knochen. Du bist mir ein hübsches drittes.“",
			"„Namen brauch ich keinen. Wer aus dem Schrott kommt, hat meistens keinen mehr.“",
			"„Trink das hier. Und dann hör mir zu.“",
		],
		"offer": [
			"„Draußen sitzen Wegelagerer auf der Piste und nehmen sich, was durchkommt.“",
			"„Acht Stück, sagt der Aushang. Bring mir den Beweis, dann bring ich dir was Ordentliches zu essen.“",
		],
		"wait": [
			"„Die Wüste frisst Leute wie dich zum Frühstück.“",
			"„Aber du bist ja noch da. Also weiter.“",
		],
		"done": [
			"„Du bist zäher, als du aussiehst.“",
			"„Setz dich. Heute zahlst du nichts.“",
		],
		"idle": [
			"„Trink was, Fremder. Geht aufs Haus.“",
		],
		"idle_enthuellt": [
			"„Für dich hab ich Schmieröl statt Schnaps.“",
			"„Wundert dich das? Mich wundert gar nichts mehr.“",
		],
		"offer_enthuellt": [
			"„Setz dich, Kind. Aber vorher…“",
		],
	},
	# ── Silas „Kupferauge" Finch, Werkstatt ───────────────────────────────────
	#
	# Redet über Material, nie über Menschen. Sein Kupferauge sieht mehr, als ihm lieb ist —
	# vor dem Reveal ist das eine Angeberei, danach eine Feststellung.
	"silas": {
		"erst": [
			"„Neu hier. Und schon kaputt.“",
			"„Ich richte alles, was aus Metall ist. Für den Rest gibt's den Doc.“",
		],
		"offer": [
			"„Diese Stadt frisst Material.“",
			"„Bring mir Schrott, ich mach dir was daraus, das hält.“",
		],
		"wait": [
			"„Ohne Schrott keine Mauer.“",
		],
		"done": [
			"„Gute Arbeit. Das hält.“",
		],
		"idle": [
			"„Mein Auge sieht mehr als deins, Fremder.“",
		],
		"idle_enthuellt": [
			"„Chassis-Platten? Für dich zum Selbstkostenpreis.“",
			"„Reg dich nicht auf. Ich hab's vom ersten Tag an gesehen.“",
		],
	},
	# ── Gideon Cross, Fort Freedom (Rebellengilde) ────────────────────────────
	#
	# Narbiger Anfuehrer, kalter Blick (GDD §4.3). Er wirbt nicht, er rechnet vor — wer sich
	# anschliesst, soll wissen, was es kostet. Nach dem Reveal ist ein Automat fuer ihn kein
	# Skandal, sondern ein Werkzeug, das der Konzern gebaut hat und das jetzt gegen ihn laeuft.
	"gideon": {
		"erst": [
			"„Fort Freedom. Wer hier reinkommt, hat sich entschieden — oder wird es gleich.“",
			"„Der Konzern besitzt die Schienen, das Wasser und die Zeit. Wir nehmen ihm eins nach dem anderen ab.“",
			"„Ich frag dich nicht, woher du kommst. Ich frag dich, wozu du taugst.“",
		],
		"offer": [
			"„Es gibt Arbeit, und sie ist nicht sauber.“",
			"„Wer sauber bleiben will, geht zurück nach Rustwater und trinkt bei Mabel.“",
		],
		"wait": ["„Noch nicht fertig. Dann red ich auch noch nicht.“"],
		"done": [
			"„Ordentlich.“",
			"„Ein Monopol bricht man nicht mit einer Rede. Man bricht es mit Leuten wie dir.“",
		],
		"idle": ["„Wir brechen das Monopol des Konzerns — oder sterben beim Versuch.“"],
		"idle_enthuellt": [
			"„Sie haben dich gebaut, und jetzt stehst du hier.“",
			"„Das ist die beste Nachricht seit zehn Jahren.“",
		],
	},
	# ── Aufseher Quentin, Sektor 01 (Eiserne Gilde) ───────────────────────────
	#
	# Kalter Mann in makelloser Uniform. Er beleidigt nie und meint es nie freundlich; jede
	# Zeile ist eine Kostenrechnung. Nach dem Reveal spricht er vom Helden in der dritten
	# Person — ein Posten in der Bilanz, kein Gegenueber.
	"quentin": {
		"erst": [
			"„Sektor 01. Sie betreten Konzerngebiet. Das ist kein Vorwurf, das ist eine Feststellung.“",
			"„Ordnung ist Profit. Profit ist Ordnung.“",
			"„Sie werden feststellen, dass wir besser zahlen als Ideale.“",
		],
		"offer": [
			"„Ein Vorgang wartet auf Bearbeitung.“",
			"„Der Unterschied zwischen Raub und Requirierung ist ein Stempel. Wir haben den Stempel.“",
		],
		"wait": ["„Der Vorgang ist offen. Offene Vorgänge kosten.“"],
		"done": [
			"„Erledigt. Vermerkt.“",
			"„Sie sind teuer, aber Sie rechnen sich.“",
		],
		"idle": ["„Halten Sie sich an die Markierungen.“"],
		"idle_enthuellt": [
			"„Inventarnummer unbekannt. Das ist ein Verwaltungsfehler, kein Wunder.“",
			"„Man wird das nachtragen.“",
		],
	},
	# ── „Slick" Sterling, Rogue's Landing (Schmugglergilde) ───────────────────
	#
	# Grinsen unter der Gaslampe. Er redet mit einem wie mit einem Geschaeftspartner, den er
	# gerade uebervorteilt — und laesst einen das wissen, weil es dazugehoert.
	"slick": {
		"erst": [
			"„Ah. Ein neues Gesicht, und noch dazu eins mit Blut drauf.“",
			"„Rogue's Landing, Freund. Hier fragt keiner, hier bezahlt man.“",
			"„Alles hat seinen Preis. Auch Schweigen.“",
		],
		"offer": [
			"„Ich hätte da eine Ware, die den Weg nicht allein findet.“",
			"„Kein Anschlag. Ein Missverständnis, sagen wir. Missverständnisse sind billiger.“",
		],
		"wait": ["„Immer mit der Ruhe. Ware, die hetzt, wird gefunden.“"],
		"done": [
			"„Sieh an. Du lieferst.“",
			"„Ich mag Leute, die liefern. Sie leben länger.“",
		],
		"idle": ["„Reichtum kennt keine Fahnen, Freund.“"],
		"idle_enthuellt": [
			"„Du bist also gar kein Mensch. Und ich hab dir Schnaps verkauft.“",
			"„Rückerstattung gibt's trotzdem keine.“",
		],
	},
	# ── Doc, Feldscher ────────────────────────────────────────────────────────
	"doc": {
		"erst": [
			"„Blut im Haar. Setz dich, das seh ich mir an.“",
			"„…und du zuckst nicht mal. Interessant.“",
		],
		"offer": [
			"„Die Viecher kommen aus den Rohren.“",
			"„Solange die da unten sind, verarzte ich hier oben Bisse statt Wunden.“",
		],
		"wait": [
			"„Zähl die Kadaver, nicht die Stunden.“",
		],
		"done": [
			"„Eine Plage weniger.“",
		],
		"idle": [
			"„Halt dich von den Ratten fern.“",
		],
		"idle_enthuellt": [
			"„Bei dir spar ich mir das Verarzten.“",
			"„Ein Jammer. Du wärst ein guter Patient gewesen.“",
		],
	},
}


## Die Zeilen zu einem Anlass. Leere Liste, wenn es dazu nichts gibt.
##
## `enthuellt` schaltet auf die Variante nach dem Reveal um — falls es eine gibt. Der Rückfall
## auf den normalen Text ist Absicht: So kann man einzelne Sätze umschreiben, ohne jede Zeile
## des Spiels zweimal zu pflegen.
static func lines(giver: String, anlass: String, enthuellt: bool = false) -> Array:
	var wer: Dictionary = LINES.get(giver, {})
	if wer.is_empty():
		return []
	if enthuellt and wer.has(anlass + "_enthuellt"):
		return (wer[anlass + "_enthuellt"] as Array).duplicate()
	return (wer.get(anlass, []) as Array).duplicate()


## Kennt die Tabelle diese Person?
static func kennt(giver: String) -> bool:
	return LINES.has(giver)


## Alle Anlaesse, die es fuer jemanden gibt — fuer den Test, der die Tabelle abklopft.
static func anlaesse(giver: String) -> Array:
	return (LINES.get(giver, {}) as Dictionary).keys()
