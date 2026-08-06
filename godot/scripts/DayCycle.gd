extends RefCounted
## Die Uhr der Welt: Tageszeit, Phasen und das Licht, das dazugehört.
##
## Warum das eine eigene Datei ist und nicht drei Zeilen in `OverworldView`: An der Tageszeit
## hängt mehr als die Beleuchtung. Gegner, die nur nachts aus ihrer Höhle kommen, Quests, die
## eine Uhrzeit verlangen, Händler, die schließen — das alles muss dieselbe Uhr lesen, und zwar
## auch dort, wo es keine Szene gibt (Tests, `QuestManager`). Deshalb: reine Rechnung, keine
## Knoten, alles statisch.
##
## ## Der Tag ist kurz
##
## Ein Spieltag dauert **zwölf Minuten** Echtzeit. Das ist bewusst knapp: Wer eine Nachtquest
## hat, soll nicht eine Stunde warten, und wer die Wüste bei Abendlicht sehen will, soll sie
## heute noch sehen. Zum Vergleich: Eine Querung des Kraters zu Fuß dauert achtzehn Minuten —
## eine lange Reise führt also durch mehr als eine Tageszeit, und genau das soll sie.
##
## ## Fünf Phasen, nicht zwei
##
## „Tag" und „Nacht" wären zu grob. Die interessanten Bilder liegen dazwischen: Die Sonne steht
## tief, die Schatten sind lang, und ein Mündungsfeuer wirft zum ersten Mal Licht, das man sieht.
## Deshalb bekommen Dämmerung und Abendrot eigene Phasen — sie sind kurz und sollen es sein.

## Länge eines Spieltags in echten Sekunden.
const DAY_SEC: float = 720.0

## Uhrzeit, bei der eine neue Runde beginnt: kurz nach Sonnenaufgang. Der Prolog spielt am
## Morgen — wer auf einer Müllkippe erwacht, tut das im ersten Licht, nicht um Mitternacht.
const START_HOUR: float = 7.5

# ── Phasen ────────────────────────────────────────────────────────────────────
const NACHT: String = "nacht"
const DAEMMERUNG: String = "daemmerung"   # vor Sonnenaufgang
const TAG: String = "tag"
const ABEND: String = "abend"             # Abendrot
## Grenzen in Stunden. Zwischen `abend_ende` und `daemmerung_start` ist Nacht — der Übergang
## über Mitternacht ist deshalb der einzige, der „hinten herum" geht.
const H_DAEMMERUNG: float = 5.0
const H_TAG: float = 7.0
const H_ABEND: float = 18.5
const H_NACHT: float = 20.5

## Phase zu einer Stunde (0–24).
static func phase_at(stunde: float) -> String:
	var h: float = fposmod(stunde, 24.0)
	if h < H_DAEMMERUNG or h >= H_NACHT:
		return NACHT
	if h < H_TAG:
		return DAEMMERUNG
	if h < H_ABEND:
		return TAG
	return ABEND


## Ist es dunkel genug, dass Nachtgegner herauskommen? Dämmerung zählt mit — ein Tier, das das
## Licht scheut, wartet nicht auf Mitternacht, es wartet auf den Schatten.
static func is_dark(stunde: float) -> bool:
	var p: String = phase_at(stunde)
	return p == NACHT or p == DAEMMERUNG


## Wie hell ist es, 0 (tiefe Nacht) bis 1 (Mittag)? Weich, nicht gestuft — eine Beleuchtung, die
## an Phasengrenzen springt, liest sich als Fehler.
static func daylight(stunde: float) -> float:
	var h: float = fposmod(stunde, 24.0)
	# Sinus über den Bogen zwischen Auf- und Untergang, davor und danach null.
	var auf: float = H_DAEMMERUNG
	var unter: float = H_NACHT
	if h <= auf or h >= unter:
		return 0.0
	return sin(PI * (h - auf) / (unter - auf))


## Höhe der Sonne über dem Horizont in Grad (negativ = unter dem Horizont).
static func sun_altitude_deg(stunde: float) -> float:
	return lerpf(-14.0, 62.0, daylight(stunde))


## Richtung, aus der die Sonne scheint — wandert über den Tag von Ost nach West.
static func sun_azimuth_deg(stunde: float) -> float:
	var h: float = fposmod(stunde, 24.0)
	return lerpf(-60.0, 60.0, clampf((h - H_DAEMMERUNG) / (H_NACHT - H_DAEMMERUNG), 0.0, 1.0)) + 35.0


## Lichtfarbe. Tief stehende Sonne ist rot, hohe ist fast weiß, Nacht ist Mondblau.
static func sun_color(stunde: float) -> Color:
	var t: float = daylight(stunde)
	if t <= 0.0:
		return Color(0.62, 0.70, 0.95)          # Vollmond: kühl, aber hell
	# Unter einem Viertel Helligkeit steht sie tief: Auf- und Untergangsrot.
	var tief := Color(1.0, 0.55, 0.30)
	var hoch := Color(1.0, 0.95, 0.84)
	return tief.lerp(hoch, smoothstep(0.0, 0.55, t))


## Stärke des gerichteten Lichts. Nachts scheint der **Vollmond** — nicht als Restlicht,
## sondern als Lichtquelle: Er wirft eigene, harte Schatten und zeichnet die Landschaft in
## Blaugrau. Ein Viertel der Mittagssonne ist die Größenordnung, in der man eine Wüstennacht
## bei klarem Himmel tatsächlich erlebt; darunter sieht man nichts, darüber wird es Tag.
const MOND_ENERGIE: float = 0.42
static func sun_energy(stunde: float) -> float:
	return lerpf(MOND_ENERGIE, 1.7, daylight(stunde))


## Himmelsfarbe. Der Bronzehimmel der Story-Bibel bei Tag, tiefes Blaugrau bei Nacht.
static func sky_color(stunde: float) -> Color:
	var t: float = daylight(stunde)
	var nacht := Color(0.045, 0.055, 0.085)
	var glut := Color(0.42, 0.24, 0.16)      # Horizontglut zur Dämmerung
	var tag := Color(0.55, 0.55, 0.42)
	if t < 0.35:
		return nacht.lerp(glut, smoothstep(0.0, 0.35, t))
	return glut.lerp(tag, smoothstep(0.35, 0.75, t))


## Umgebungslicht (der Himmelsanteil, der in die Schatten fällt).
static func ambient_color(stunde: float) -> Color:
	var t: float = daylight(stunde)
	return Color(0.16, 0.20, 0.34).lerp(Color(0.62, 0.66, 0.78), smoothstep(0.0, 0.6, t))


static func ambient_energy(stunde: float) -> float:
	# Nachts DEUTLICH weniger, sonst ist die Nacht nur ein blauer Anstrich. Der Unterschied
	# zwischen Licht- und Schattenseite muss auch nachts bestehen bleiben, sonst wird alles flach.
	return lerpf(0.15, 0.32, daylight(stunde))


## Wo steht der Mond? Gegenüber der Sonne — er geht auf, wenn sie untergeht.
##
## Gebraucht für die Mondscheibe am Himmel. Sie ist kein Schmuck: Eine helle Nacht ohne
## sichtbare Quelle wirkt wie ein vergessener Regler. Man muss sehen, WOHER das Licht kommt.
static func moon_altitude_deg(stunde: float) -> float:
	return lerpf(52.0, -12.0, daylight(stunde))


static func moon_azimuth_deg(stunde: float) -> float:
	return sun_azimuth_deg(stunde) + 180.0


## Sichtbarkeit der Mondscheibe (0–1). Sie verblasst, sobald es hell wird — am Taghimmel steht
## sie nicht.
static func moon_visibility(stunde: float) -> float:
	return 1.0 - smoothstep(0.0, 0.30, daylight(stunde))


## Nebelfarbe — nachts kalt, tagsüber staubig.
static func fog_color(stunde: float) -> Color:
	return Color(0.07, 0.09, 0.14).lerp(Color(0.62, 0.62, 0.52),
		smoothstep(0.0, 0.6, daylight(stunde)))


## „06:30" — für das HUD.
static func clock_text(stunde: float) -> String:
	var h: float = fposmod(stunde, 24.0)
	return "%02d:%02d" % [int(h), int(fposmod(h * 60.0, 60.0))]


## Name der Phase, wie er im Spiel steht.
const PHASE_NAME: Dictionary = {
	NACHT: "Nacht", DAEMMERUNG: "Dämmerung", TAG: "Tag", ABEND: "Abendrot",
}
const PHASE_ICON: Dictionary = {
	NACHT: "🌙", DAEMMERUNG: "🌅", TAG: "☀", ABEND: "🌇",
}

static func phase_label(stunde: float) -> String:
	var p: String = phase_at(stunde)
	return "%s %s" % [String(PHASE_ICON[p]), clock_text(stunde)]


## Die Uhr um `delta` Sekunden Echtzeit weiterstellen.
static func advance(stunde: float, delta: float) -> float:
	return fposmod(stunde + delta * (24.0 / DAY_SEC), 24.0)
