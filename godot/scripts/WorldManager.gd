class_name WorldManager extends RefCounted
## WorldManager — Weltgeografie, Sektoren & Progressions-Gating (Master-GDD §1.6/§1.7).
##
## Reine Logik/Daten (`class_name`, statisch — kein Autoload nötig). Alle Gate-Zustände
## werden aus `GameState` abgeleitet (Kapitel, Gilde, Gebäudestufe); es gibt keinen
## dupliziten Zustand, der auseinanderlaufen könnte.
##
## Koordinatensystem: Ursprung (0,0) SW-Ecke, X = West→Ost, Y = Süd→Nord, jeweils 0…2000 m.

# ── Sektorgrenzen (horizontale Y-Linien) ──────────────────────────────────────
const WORLD_SIZE: int = 2000
const BORDER_S1_S2_Y: int = 800     # Sprengtore (Hard Gate 1)
const BORDER_S2_S3_Y: int = 1500    # Smog-Linie (Hard Gate 2), == SMOG_LINE_Y
const SMOG_LINE_Y: int = 1500

# ── Produktions-Maßstab (Master-GDD §1.4) ─────────────────────────────────────
## Die POI-Tabelle beschreibt das RELATIVE Layout (0…2000); die Produktion spannt den
## Kraterboden auf 5000×5000 m auf. Szenen-Mapping: X → +x (Ost), Y (Nord) → −z.
const WORLD_METERS: float = 5000.0
const METERS_PER_UNIT: float = WORLD_METERS / float(WORLD_SIZE)   # = 2.5
const PLAYER_SPEED_MS: float = 4.7                                # Laufgeschwindigkeit (m/s)

## Relative Weltkoordinate (0…2000) → Godot-Szenenposition in Metern.
static func world_to_scene(rel: Vector2) -> Vector3:
	return Vector3(rel.x * METERS_PER_UNIT, 0.0, -rel.y * METERS_PER_UNIT)

## Godot-Szenenposition → relative Weltkoordinate (für Gating-/Biom-Abfragen).
static func scene_to_world(p: Vector3) -> Vector2:
	return Vector2(p.x / METERS_PER_UNIT, -p.z / METERS_PER_UNIT)

## POI-Position direkt im Szenen-Maßstab (Meter).
static func poi_scene_position(poi_id: String) -> Vector3:
	return world_to_scene(poi_position(poi_id))


# ── Topografie: Senken und Wälle als FORMEL, nicht als Modell ─────────────────
## Der Boden war bis hierher eine flache Platte bei y = 0, und die Figur bekam ihr y nie von
## irgendwoher. Ein modellierter Krater wäre deshalb Kulisse geblieben, durch die man
## hindurchspaziert.
##
## Statt Geometrie steht hier eine Funktion: `height_at(x, z)` liefert für JEDEN Punkt der Welt
## die Bodenhöhe. Aus derselben Funktion entsteht das sichtbare Netz UND die Höhe, auf der
## Spieler, Gegner und Beute stehen — eine Quelle, mehrere Verbraucher. Ein Modell mit
## getrennter Kollision läuft dagegen früher oder später auseinander.
##
## Warum keine Textur-Heightmap: Bei der festen Kamera sind 15 m Bildbreite rund 128 Pixel pro
## Meter. Ein unikal texturiertes Gelände dieser Schärfe wäre für einen 30-m-Krater schon
## 15 Megapixel und ließe sich nicht kacheln. Eine Formel kostet null Byte, ist überall exakt
## und in beide Richtungen ableitbar (Normalen ohne Nachbarschaftssuche).

## Geländeformen. `poi` verankert sie an einem Ort, alle Maße in METERN.
##  • `radius`      Rand der Senke — dort ist die Höhe wieder 0
##  • `depth`       Tiefe des Grundes
##  • `rim`         Höhe des Auswurfwalls direkt außerhalb
##  • `rim_width`   Breite des Walls als Anteil des Radius
##  • `floor`       Anteil des Radius, der FLACHER GRUND ist (0 = Schüssel ohne Boden).
##                  Der Rest dazwischen ist die Wand: je größer `floor`, desto steiler.
##  • `ramp_deg`    Richtung der Rampe (0° = Osten, 90° = Norden) — dort bleibt die Wand weg
##  • `ramp_span`   Öffnungswinkel der Rampe in Grad (Gesamtbreite, nicht halbe)
const TERRAIN: Array = [
	# Die Schrotthalde: die Grube, in der der Held erwacht. 30 m Durchmesser — groß genug für
	# eine Szene, klein genug, dass man den Rand von der Mitte aus sieht.
	#
	# Kein Trichter mehr, sondern ein LOCH: flacher Grund, steile ausgewaschene Erdwände, eine
	# aufgeworfene Lippe. Eine Schüssel liest sich aus der Iso-Perspektive als sanfte Delle;
	# erst die Wand macht daraus einen Ort, in den man hinabsteigt und aus dem man nicht
	# einfach in jede Richtung herausläuft.
	#
	# Die Rampe im Nordosten ist die einzige Stelle, an der die Wand fehlt — dort geht man
	# hinein und hinaus. Ohne sie wäre die Grube entweder ein Käfig oder man liefe eine
	# senkrechte Wand hoch wie eine Fliege.
	{ "id": "schrotthalde", "kind": "crater", "poi": "schrott_minen",
		"radius": 15.0, "depth": 5.0, "rim": 1.0, "rim_width": 0.36,
		"floor": 0.78, "ramp_deg": 55.0, "ramp_span": 70.0 },
	# Das Wellenmeer: ein Dünenfeld östlich von Rustwater, 220 m breit. Nicht an einem Ort
	# verankert, sondern frei auf der Karte — es IST die Landmarke.
	#
	# Warum überhaupt: Die Wüste ist bisher eine Tischplatte. Man läuft 900 m und die
	# Horizontlinie bewegt sich nicht. Dünen geben der Strecke einen Puls — man steigt, sieht
	# über den Kamm hinweg das nächste Tal, steigt wieder. Das kostet nichts außer der Formel.
	#
	# `wave` ist die Wellenlänge von Kamm zu Kamm, `amp` die Höhe, `skew` die Asymmetrie.
	#
	# Der erste Versuch stand bei 2,4 m auf 19 m — im Bild praktisch unsichtbar. Eine Düne
	# liest man nicht an ihrer Höhe, sondern an ihrem SCHATTEN, und der entsteht erst, wenn
	# die Leeseite steil genug ist. 5 m auf 42 m mit `skew` 0,55 ergibt eine flache Luvseite
	# (rund 13°) und eine steile Leeseite (rund 30°) — beide noch begehbar, aber mit einem
	# Schattenwurf, den man aus 100 m Entfernung sieht.
	#
	# `step` gröber als beim Krater: Bei 42 m Wellenlänge sieht man 2 m Netzauflösung nicht,
	# und ein 320-m-Feld in Kraterauflösung wären zwei Millionen Dreiecke.
	{ "id": "wellenmeer", "kind": "dunes", "x": 600, "y": 500,
		"radius": 160.0, "amp": 5.0, "wave": 42.0, "skew": 0.55,
		"dir_deg": 24.0, "step": 2.0 },
]


## Bodenhöhe an einem Punkt (Szenenmeter). Ausserhalb aller Formen exakt 0.
static func height_at(x: float, z: float) -> float:
	var h: float = 0.0
	for f in TERRAIN:
		var c: Vector3 = feature_center(f)   # Ort ODER freie Koordinate, siehe `feature_center`
		h += _feature_height(f, Vector2(x - c.x, z - c.z))
	return h


## Höhenprofil einer Form über den Abstand zur Mitte — jetzt richtungsabhängig (Rampe).
##
## Drei Abschnitte, alle mit waagerechtem Anschluss; es gibt also keine Kante, an der man
## hängenbleibt oder die als harter Knick auffällt:
##
##   1. **Grund** (0 … radius·floor): flach bei −depth. Dort liegt man beim Erwachen, dort
##      steht der Schrott, dort steht die Lache.
##   2. **Wand** (radius·floor … radius): `-depth · (1 − smoothstep(…))`, aber über eine
##      SCHMALE Spanne. Bei floor 0,78 sind das 3,3 m waagerecht auf 5 m senkrecht — im
##      Mittel 57°, an der steilsten Stelle 66°. Eine Wand, keine Böschung.
##   3. **Wall** (radius … radius·(1+rim_width)): `rim · sin²(…)`. Der Auswurf, den ein
##      Einschlag nach außen wirft. Sinus-Quadrat, weil es an beiden Enden waagerecht ansetzt.
##
## Die Rampe entsteht dadurch, dass `floor` in ihrem Sektor gegen 0 läuft — dann fällt
## Abschnitt 1 weg und Abschnitt 2 zieht sich über den ganzen Radius. Das ist exakt das alte
## Schüsselprofil (höchstens 27° bei 5 m Tiefe), nur eben nicht mehr rundum.
static func _feature_height(f: Dictionary, off: Vector2) -> float:
	if String(f.get("kind", "crater")) == "dunes":
		return _dune_height(f, off)
	var radius: float = float(f["radius"])
	var t: float = off.length() / radius
	var w: float = float(f["rim_width"])
	if t >= 1.0 + w:
		return 0.0
	if t > 1.0:
		var s: float = sin(PI * (t - 1.0) / w)
		return float(f["rim"]) * s * s
	var boden: float = _floor_share(f, off)
	if t <= boden:
		return -float(f["depth"])
	var u: float = (t - boden) / maxf(1.0 - boden, 0.0001)
	return -float(f["depth"]) * (1.0 - smoothstep(0.0, 1.0, u))


## Höhenprofil eines Dünenfelds. Zwei überlagerte Wellen und ein weicher Rand.
##
## Die Hauptwelle quer zum Wind erzeugt die Kämme. Allein sähe sie aus wie ein Wellblechdach:
## endlos gleiche, exakt parallele Rippen. Deshalb kommt eine zweite, viel längere Welle LÄNGS
## der Kämme dazu, die sie durchmoduliert — mal höher, mal flacher, mit versetzten Sätteln.
## Das ist der Unterschied zwischen „gewellt" und „Dünen".
##
## Die Höhe bleibt immer ≥ 0: Ein Dünenfeld liegt AUF der Ebene, es gräbt sich nicht ein.
## Am Rand blendet `smoothstep` es auf null aus, sonst stünde dort eine Stufe.
static func _dune_height(f: Dictionary, off: Vector2) -> float:
	var radius: float = float(f["radius"])
	var d: float = off.length()
	if d >= radius:
		return 0.0
	var a: float = deg_to_rad(float(f.get("dir_deg", 0.0)))
	var wave: float = maxf(float(f.get("wave", 20.0)), 0.1)
	# Längs = in Windrichtung (quer zu den Kämmen), quer = an den Kämmen entlang.
	var laengs: float = (off.x * cos(a) + off.y * sin(a)) / wave
	var quer: float = (-off.x * sin(a) + off.y * cos(a)) / (wave * 2.6)
	# Phasenverzerrung statt reiner Sinus: `theta + skew·sin(theta)` schiebt den Nulldurchgang
	# zur Seite und macht aus der symmetrischen Welle eine Düne — flach angeweht, steil
	# abfallend. Ohne das ist es ein Wellblechdach, egal wie hoch.
	var theta: float = TAU * laengs
	var kamm: float = 0.5 + 0.5 * sin(theta + float(f.get("skew", 0.0)) * sin(theta))
	var mod: float = 0.55 + 0.45 * sin(TAU * quer + 1.1)
	var rand: float = 1.0 - smoothstep(0.0, 1.0, d / radius)
	return float(f.get("amp", 2.0)) * kamm * mod * rand


## Wie viel des Radius ist an DIESER Stelle flacher Grund? In der Rampe: nichts.
##
## Der Übergang läuft über `smoothstep` statt hart auf den Sektor — sonst stünde links und
## rechts der Rampe je eine senkrechte Kante im Gelände, an der man entlangschrammt.
static func _floor_share(f: Dictionary, off: Vector2) -> float:
	var boden: float = float(f.get("floor", 0.0))
	if boden <= 0.0 or off.length_squared() < 0.000001:
		return boden
	var halb: float = deg_to_rad(float(f.get("ramp_span", 0.0))) * 0.5
	if halb <= 0.0:
		return boden
	var ziel: float = deg_to_rad(float(f.get("ramp_deg", 0.0)))
	# Winkel des Punktes. `off` ist (x, z); Norden ist −z, deshalb das Minus.
	var ang: float = atan2(-off.y, off.x)
	var d: float = absf(wrapf(ang - ziel, -PI, PI))
	var k: float = 1.0 - smoothstep(0.0, 1.0, clampf(d / halb, 0.0, 1.0))
	return boden * (1.0 - k)


## Normale des Bodens — aus der Formel abgeleitet statt aus Nachbardreiecken gemittelt.
static func normal_at(x: float, z: float, eps: float = 0.25) -> Vector3:
	var dx: float = height_at(x + eps, z) - height_at(x - eps, z)
	var dz: float = height_at(x, z + eps) - height_at(x, z - eps)
	return Vector3(-dx, 2.0 * eps, -dz).normalized()


## Aussenradius einer Form inklusive Wall — bis hierhin muss ein Geländeflicken reichen.
static func feature_reach(f: Dictionary) -> float:
	if String(f.get("kind", "crater")) == "dunes":
		return float(f["radius"])
	return float(f["radius"]) * (1.0 + float(f["rim_width"]))


## Mittelpunkt einer Form in Szenenmetern.
##
## Zwei Verankerungen: an einem ORT (`poi`) oder frei auf der Karte (`x`/`y` in Welteinheiten).
## Der Krater gehört zu den Schrott-Minen und muss mitwandern, wenn der Ort verschoben wird;
## ein Dünenfeld gehört nirgendwohin — es ist selbst die Landmarke.
static func feature_center(f: Dictionary) -> Vector3:
	if f.has("poi"):
		return poi_scene_position(String(f["poi"]))
	return world_to_scene(Vector2(float(f["x"]), float(f["y"])))


# ── Weltstruktur: offene Wildnis + baulich begrenzte Aktionszonen (GDD §1.4a) ──
## Gemischtes Modell statt „alles offen" oder „alles Schlauch":
##  • **Wildnis** — die Wüste zwischen den Orten ist FREI begehbar. Weite, Reisezeit,
##    Landmark-Navigation und Biom-Takt aus §1.4 bleiben vollständig erhalten.
##  • **Aktionszonen** — Städte, Basen, Dungeons und Arenen sind **baulich** begrenzt
##    (Mauern, Palisaden, Geländer, Felskanten). Dort spielt der Kampf, dort ist es eng
##    und geführt wie in mobilen Action-RPGs. Die Grenzen sind echte Objekte, keine
##    unsichtbaren Wände — die Kollision setzt die Szene über ihre Bauten.
##  • **Eisenbahn** — verbindet die Hauptorte und ersetzt später den langen Fußmarsch.
## Alle Werte in relativen Weltkoordinaten (0…2000); ×METERS_PER_UNIT ergibt Meter.

## Radius einer Aktionszone um einen POI (dort greifen bauliche Begrenzung & Stadtregeln).
const ZONE_RADIUS_HUB: float = 46.0        # ≈ 115 m — Rustwater & Fraktionsbasen
const ZONE_RADIUS_DEFAULT: float = 26.0    # ≈ 65 m  — Dungeons, Jagdgründe, Arenen
## Halbe Breite des freizuhaltenden Streifens um die Iron-Rail-Trasse, in WELTEINHEITEN
## (`on_rail`). 3 Einheiten sind 7,5 m nach jeder Seite — Schotterbett (6,2 m) plus etwas Luft.
##
## Der Vorgaenger `CORRIDOR_HALF_W` stand bei 11 Einheiten = 27,5 m JE SEITE und galt fuer alle
## Routen. Sein Kommentar las „≈ 27 m breite Piste" und meinte damit die volle Breite — der
## Zahlendreher hat die gezeichnete Piste auf 55 m aufgeblasen, breiter als der 30-m-Krater der
## Schrotthalde. Die Pisten sind inzwischen ganz raus; was bleibt, ist die Trasse.
const RAIL_CORRIDOR_HALF_W: float = 3.0

## Nachbarschaft der Orte — welcher Ort mit welchem verbunden ist.
##
## Reine Topologie, keine Optik: Gezeichnet wird davon nur noch die Iron-Rail-Trasse
## (`rail_segments`, die Teilmenge mit Bahnhof an beiden Enden). Die gestampften Pisten, die
## hier frueher auch herauskamen, gibt es nicht mehr — in einer offenen Wueste, in der man
## ohnehin quer laeuft, war eine Strasse ohne Ziel nur ein Band auf dem Boden.
const ROUTES: Array = [
	["rustwater", "rattengestruepp"], ["rustwater", "schrott_minen"], ["rustwater", "zugdepot"],
	["zugdepot", "rogues_landing"], ["rogues_landing", "fort_freedom"],
	["rogues_landing", "sektor01"], ["rogues_landing", "alchemie_raffinerie"],
	["fort_freedom", "goliath_testgelaende"], ["sektor01", "schmelzoefen_vulcan"],
	["alchemie_raffinerie", "eisernes_herz"],
]

## Bahnhöfe der Iron Rail: nur echte Knoten (GDD §1.4). Reisen zwischen ihnen ersetzt
## später den Fußmarsch; die Trasse verläuft entlang der Routen zwischen diesen Orten.
const RAIL_STATIONS: Array = ["rustwater", "zugdepot", "rogues_landing", "fort_freedom", "sektor01"]

static func has_station(poi_id: String) -> bool:
	return RAIL_STATIONS.has(poi_id)

## Trassenabschnitte der Iron Rail: alle Routen, deren BEIDE Enden einen Bahnhof haben.
## Damit liegt das Schienennetz zwangsläufig auf den bestehenden Straßen — es gibt keine
## zweite, widersprüchliche Geografie.
static func rail_segments() -> Array:
	var out: Array = []
	for r in ROUTES:
		if has_station(String(r[0])) and has_station(String(r[1])):
			out.append([String(r[0]), String(r[1])])
	return out

## Befriedete Zone: dort spawnt nichts Feindliches. Der Hub immer, Fraktionsbasen nur,
## solange die eigene Gilde dort willkommen ist (§1.7.3).
static func is_safe_zone(poi_id: String) -> bool:
	var t: String = String(poi(poi_id).get("type", ""))
	if t == "hub":
		return true
	return t == "base" and is_base_friendly(poi_id)

## Radius der Aktionszone eines POI (Hubs & Basen weiter, Rest enger).
static func zone_radius(poi_id: String) -> float:
	var t: String = String(poi(poi_id).get("type", ""))
	return ZONE_RADIUS_HUB if (t == "hub" or t == "base") else ZONE_RADIUS_DEFAULT

## Kürzester Abstand eines Punktes zur Strecke a→b (Standard-Punkt-Segment-Distanz).
static func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

## In welcher Aktionszone steht der Punkt? ("" = offene Wildnis)
static func zone_at(rel: Vector2) -> String:
	for id in POIS.keys():
		if rel.distance_to(poi_position(String(id))) <= zone_radius(String(id)):
			return String(id)
	return ""

static func in_action_zone(rel: Vector2) -> bool:
	return zone_at(rel) != ""

## Steht der Punkt auf der Iron-Rail-Trasse? (Keine Sperre — man kann ueber die Gleise laufen.
## Die Abfrage sagt nur: hier darf nichts hingestreut werden, sonst waechst ein Kaktus zwischen
## den Schwellen.)
##
## Loeste `on_route` ab, das dasselbe fuer alle ROUTES tat. Solange es Pisten gab, war das
## richtig — mit ihnen ist der Grund weggefallen: Ein unsichtbarer 55-m-Streifen quer durch
## die Wueste, in dem nichts steht, ist keine Wegfuehrung mehr, sondern eine leere Gasse ohne
## erkennbaren Anlass. Die Trasse dagegen liegt sichtbar da und muss frei bleiben.
static func on_rail(rel: Vector2) -> bool:
	for r in rail_segments():
		if _dist_to_segment(rel, poi_position(String(r[0])), poi_position(String(r[1]))) <= RAIL_CORRIDOR_HALF_W:
			return true
	return false

## Liegt die Position im begehbaren Teil der Welt? Die Wüste ist offen — begrenzt wird nur
## durch den Kraterrand (Außengrenze der Welt). Bauten sperren zusätzlich lokal, das
## entscheidet aber die Szene über ihre Kollisionsobjekte, nicht diese Geografie-Schicht.
static func is_walkable(rel: Vector2) -> bool:
	return rel.x >= 1.0 and rel.x <= float(WORLD_SIZE) - 1.0 \
		and rel.y >= 1.0 and rel.y <= float(WORLD_SIZE) - 1.0

## Nächstgelegene gültige Position innerhalb des Kraters (Rückfall nach Schnellreise,
## Rückstoß oder einem Spielstand aus einer älteren Fassung).
static func nearest_walkable(rel: Vector2) -> Vector2:
	return Vector2(
		clampf(rel.x, 1.0, float(WORLD_SIZE) - 1.0),
		clampf(rel.y, 1.0, float(WORLD_SIZE) - 1.0))

# ── Gating-Parameter ──────────────────────────────────────────────────────────
const BLAST_GATE_CHAPTER: int = 5              # ab hier ist der Panzerzug durchgebrochen
const REFINERY_BUILDING: String = "laboratory" # Raffinerie/Labor fürs Smog-Gate (§1.7.2)
const FILTER_REQUIRED_LEVEL: int = 3           # Alchemie-Filter ab Gebäudestufe 3
const SMOG_LETHAL_SECONDS: float = 3.0         # Smog tickt Leben in 3 s auf 0

## Fraktions-HQs → besitzende Gilde (für dynamische Feindseligkeit, §1.7.3).
const BASE_GUILD: Dictionary = {
	"fort_freedom": "rebels",
	"sektor01": "corp",
	"rogues_landing": "smugglers",
}

## Points of Interest (Master-GDD §1.6.1). `sector` 1–3; `multilevel`/`floors` für Dungeons.
const POIS: Dictionary = {
	# ── Sektor 1 (Kapitel 1–4) ──
	"rustwater":            { "name": "Rustwater Hub & Basis", "x": 300, "y": 300, "sector": 1, "type": "hub" },
	"schrott_minen":        { "name": "Die Schrott-Minen", "x": 150, "y": 450, "sector": 1, "type": "dungeon", "multilevel": true, "floors": 3 },
	"rattengestruepp":      { "name": "Das Rattengestrüpp", "x": 500, "y": 200, "sector": 1, "type": "hunting" },
	"zugdepot":             { "name": "Iron Rail Zugdepot", "x": 450, "y": 750, "sector": 1, "type": "boss_arena", "gate": "blast" },
	# ── Sektor 2 (Kapitel 5–8) ──
	"fort_freedom":         { "name": "Fort Freedom", "x": 200, "y": 1200, "sector": 2, "type": "base", "guild": "rebels" },
	"sektor01":             { "name": "Sektor 01", "x": 1700, "y": 1300, "sector": 2, "type": "base", "guild": "corp" },
	"rogues_landing":       { "name": "Rogue's Landing", "x": 950, "y": 950, "sector": 2, "type": "base", "guild": "smugglers" },
	"alchemie_raffinerie":  { "name": "Alchemie-Raffinerie", "x": 1000, "y": 1450, "sector": 2, "type": "refinery", "gate": "smog" },
	# ── Sektor 3 (Kapitel 9–12) ──
	"goliath_testgelaende": { "name": "Goliath-Testgelände", "x": 600, "y": 1750, "sector": 3, "type": "openworld" },
	"schmelzoefen_vulcan":  { "name": "Schmelzöfen von Vulcan", "x": 1400, "y": 1800, "sector": 3, "type": "dungeon", "multilevel": true, "floors": 4 },
	"eisernes_herz":        { "name": "Das Eiserne Herz", "x": 1000, "y": 1950, "sector": 3, "type": "final_dungeon", "multilevel": true, "floors": 5 },
}


# ── Biom-Zonierung: Daten (Master-GDD §1.6.3) ─────────────────────────────────
## Portiert aus dem validierten Web-Prototyp: geografische Zonen mit eigener Palette,
## Deko-Flora und Gegner-Leitmix; an die Sektor-Tore (§1.7) gebunden. `cx/cy/radius` in
## Weltkoordinaten (m) — Vector2 bewusst nicht im const (Konstant-Ausdrucks-Sicherheit).
const UNIQUE_CHAMPION_CHANCE: float = 0.30   # Kritter-Hallen: Chance auf benannten Unique

const BIOMES: Dictionary = {
	"desert":          { "name": "Wüste", "sector": 1, "flora": ["cactus"], "hazard": "" },
	"salt":            { "name": "Salzpfanne", "sector": 1, "cx": 250, "cy": 680, "radius": 220, "flora": ["salt"], "hazard": "" },
	"oasis":           { "name": "Grüne Senke", "sector": 1, "cx": 550, "cy": 250, "radius": 200, "flora": ["tree", "water"], "hazard": "" },
	"rostwald":        { "name": "Rostwald", "sector": 2, "cx": 1120, "cy": 1080, "radius": 320, "flora": ["tree"], "hazard": "" },
	"kupfer_hochland": { "name": "Kupfer-Hochland", "sector": 2, "cx": 1750, "cy": 1350, "radius": 280, "flora": ["rock"], "hazard": "" },
	"smog_oedland":    { "name": "Smog-Ödland", "sector": 3, "flora": ["deadtree"], "hazard": "smog" },
}

## Gegner-Leitmix je Biom [Typ, Gewicht], pre-/post-Reveal (verschiebt sich mechanisch).
const ENEMY_POOLS: Dictionary = {
	"desert":          { "pre": [["outlaw", 4], ["fauna", 3], ["revolver", 2], ["konstrukt", 1]], "post": [["outlaw", 3], ["fauna", 2], ["revolver", 2], ["konstrukt", 4], ["klaeffer", 3]] },
	"oasis":           { "pre": [["fauna", 4], ["outlaw", 3], ["revolver", 1], ["konstrukt", 1]], "post": [["fauna", 4], ["klaeffer", 3], ["outlaw", 2], ["konstrukt", 2], ["revolver", 1]] },
	"salt":            { "pre": [["revolver", 4], ["outlaw", 4], ["fauna", 1]], "post": [["revolver", 3], ["outlaw", 3], ["konstrukt", 3], ["klaeffer", 1]] },
	"rostwald":        { "pre": [["fauna", 5], ["outlaw", 2], ["revolver", 1], ["konstrukt", 1]], "post": [["fauna", 4], ["klaeffer", 4], ["konstrukt", 2], ["outlaw", 1]] },
	"kupfer_hochland": { "pre": [["revolver", 3], ["outlaw", 3], ["konstrukt", 2], ["fauna", 1]], "post": [["konstrukt", 5], ["klaeffer", 3], ["revolver", 2], ["outlaw", 1]] },
	"smog_oedland":    { "pre": [["konstrukt", 5], ["klaeffer", 4], ["goliath", 1]], "post": [["konstrukt", 5], ["klaeffer", 4], ["goliath", 2]] },
}

## Reihenfolge der benannten Kreiszonen (erste Übereinstimmung gewinnt). Smog-Ödland = ganzer Sektor 3.
const BIOME_ZONE_ORDER: Array = ["oasis", "salt", "rostwald", "kupfer_hochland"]


# ── POI-Abfragen ──────────────────────────────────────────────────────────────

static func has_poi(poi_id: String) -> bool:
	return POIS.has(poi_id)

static func poi(poi_id: String) -> Dictionary:
	assert(POIS.has(poi_id), "WorldManager: unbekannter POI '%s'" % poi_id)
	return POIS[poi_id]

static func poi_position(poi_id: String) -> Vector2:
	var p: Dictionary = poi(poi_id)
	return Vector2(float(p["x"]), float(p["y"]))

static func dungeon_floors(poi_id: String) -> int:
	# 0 = kein (multilevel) Dungeon; 1 = einstufige Arena (z. B. Zugdepot).
	var p: Dictionary = poi(poi_id)
	if bool(p.get("multilevel", false)):
		return int(p.get("floors", 1))
	return 1 if String(p.get("type", "")) == "boss_arena" else 0

static func nearest_poi(pos: Vector2) -> String:
	var best_id: String = ""
	var best_d: float = INF
	for id in POIS.keys():
		var d: float = pos.distance_squared_to(poi_position(id))
		if d < best_d:
			best_d = d
			best_id = id
	return best_id


# ── Sektor-Logik ──────────────────────────────────────────────────────────────

static func sector_of_y(y: float) -> int:
	if y < BORDER_S1_S2_Y:
		return 1
	if y < BORDER_S2_S3_Y:
		return 2
	return 3

static func sector_of_pos(pos: Vector2) -> int:
	return sector_of_y(pos.y)


# ── Gate 1: Iron-Rail-Sprengtore (Y = 800), Kapitel-4-Reveal ──────────────────

## Ist der Panzerzug durch die Sprengtore gebrochen? (Kapitel 4 abgeschlossen.)
static func is_blast_gate_open() -> bool:
	return GameState.current_chapter >= BLAST_GATE_CHAPTER

## Darf der Spieler die Nordgrenze von Sektor 1 (Y = 800) überschreiten?
## Prüft nur die tatsächliche Nord-Querung; Bewegung innerhalb eines Sektors ist frei.
static func can_cross_blast_line(from_y: float, to_y: float) -> bool:
	var crossing_north: bool = from_y < BORDER_S1_S2_Y and to_y >= BORDER_S1_S2_Y
	if crossing_north:
		return is_blast_gate_open()
	return true


# ── Gate 2: Alchemistische Smog-Linie (Y = 1500), Raffinerie-Stufe 3 ──────────

## Hat das Chassis den Alchemie-Filter (Raffinerie/Labor auf Stufe 3)?
static func has_alchemie_filter() -> bool:
	return GameState.building_level(REFINERY_BUILDING) >= FILTER_REQUIRED_LEVEL

static func is_in_smog(pos: Vector2) -> bool:
	return pos.y >= SMOG_LINE_Y

## Umwelt-DOT der Smog-Zone für diesen Frame. Ohne Filter tödlich (max_hp in 3 s auf 0);
## mit Filter oder außerhalb der Zone 0. Der Player-Controller wendet das Ergebnis an.
static func smog_dot_damage(pos: Vector2, delta_sec: float) -> int:
	if not is_in_smog(pos) or has_alchemie_filter():
		return 0
	return ceili(float(GameState.max_hp()) / SMOG_LETHAL_SECONDS * delta_sec)


# ── Der Strahlensumpf (Gate 0) ────────────────────────────────────────────────
## Ein Riegel VOR den Sprengtoren, und der erste, den der Spieler überhaupt trifft.
##
## Wozu: Sektor 1 misst 800 × 2000 Welteinheiten, das sind zwei Quadratkilometer, die von
## Minute eins offenstehen. Wer dort loslaeuft, hat vier Orte in beliebiger Reihenfolge und
## keinen Grund, irgendwohin zu gehen. Die Sprengtore greifen erst in Kapitel 4 — bis dahin
## gibt es keine einzige Grenze.
##
## Der Sumpf zieht die Startwelt auf ein Viertel zusammen: ein Band quer ueber die Karte,
## NORDLICH hinter den Schrott-Minen. Alles dahinter — Rattengestruepp-Norden, Zugdepot,
## Salzpfanne — wird erst mit Strahlenschutz begehbar. Damit hat der Anfang eine Form: Stadt,
## Grube, und dazwischen der Weg.
##
## Warum ein Sumpf und keine Mauer: Eine Mauer sagt „hier nicht", ein verstrahltes Moor sagt
## „hier noch nicht, und du siehst schon, was dahinter liegt". Man kann hineinlaufen und
## nimmt Schaden — die Grenze ist eine Entscheidung, keine Wand.
const SWAMP_SOUTH_Y: int = 520      # Sued-Rand des Bandes (Welteinheiten)
const SWAMP_NORTH_Y: int = 640      # Nord-Rand
## Sekunden bis zum Tod ohne Schutz, mitten im Band. Kuerzer als beim Smog (3 s): Der Sumpf
## kommt frueh, und ein frueher Riegel muss unmissverstaendlich sein.
const SWAMP_LETHAL_SECONDS: float = 6.0
## Der Schutzanzug haengt an derselben Werkstatt wie der Smog-Filter, nur eine Stufe frueher.
## Zwei Gates am gleichen Gebaeude geben dem Ausbau eine sichtbare Reihenfolge.
const SWAMP_SUIT_LEVEL: int = 1


static func has_rad_suit() -> bool:
	return GameState.building_level(REFINERY_BUILDING) >= SWAMP_SUIT_LEVEL


## Wie tief im Sumpf (0 = draussen, 1 = mitten drin)?
##
## Ein weicher Verlauf statt einer Kante: An den Raendern nimmt man wenig Schaden und merkt,
## dass es schlimmer wird. Eine harte Grenze wuerde man ueberrennen und ohne Vorwarnung
## sterben — das ist der Unterschied zwischen einer Warnung und einer Falle.
static func swamp_depth(pos: Vector2) -> float:
	if pos.y <= float(SWAMP_SOUTH_Y) or pos.y >= float(SWAMP_NORTH_Y):
		return 0.0
	var t: float = (pos.y - float(SWAMP_SOUTH_Y)) / float(SWAMP_NORTH_Y - SWAMP_SOUTH_Y)
	return sin(PI * t)     # 0 an beiden Raendern, 1 in der Mitte


static func is_in_swamp(pos: Vector2) -> bool:
	return swamp_depth(pos) > 0.0


## Strahlenschaden dieses Frames. Mit Anzug 0 — dann ist der Sumpf nur noch Gelaende.
static func swamp_dot_damage(pos: Vector2, delta_sec: float) -> int:
	var tiefe: float = swamp_depth(pos)
	if tiefe <= 0.0 or has_rad_suit():
		return 0
	return ceili(float(GameState.max_hp()) / SWAMP_LETHAL_SECONDS * delta_sec * tiefe)


## Mitte des Bandes in Welteinheiten — fuer Karte und Gelaendeaufbau.
static func swamp_center_y() -> float:
	return float(SWAMP_SOUTH_Y + SWAMP_NORTH_Y) * 0.5


# ── Sektor-Zutritt (kombiniert) ───────────────────────────────────────────────

## Grundsätzlicher Zutritt zu einem Sektor (Story-/Ausrüstungs-Gate).
## Sektor 3 ist zwar physisch betretbar, aber ohne Filter durch den Smog-DOT tödlich —
## `can_enter_sector(3)` bildet die *sichere* Zugänglichkeit ab.
static func can_enter_sector(sector: int) -> bool:
	match sector:
		1:
			return true
		2:
			return is_blast_gate_open()
		3:
			return is_blast_gate_open() and has_alchemie_filter()
	return false


# ── Gate 3: Dynamische Fraktions-Feindseligkeit (Sektor 2) ────────────────────

## Ist ein Fraktions-HQ feindlich? Vor der Gildenwahl niemand; danach jedes fremde HQ
## (Geschützturm-Aggro & Verstärkung, §1.7.3). Basiert allein auf `GameState.chosen_guild`.
static func is_base_hostile(base_id: String) -> bool:
	if GameState.chosen_guild == null:
		return false
	var owner: Variant = BASE_GUILD.get(base_id, null)
	if owner == null:
		return false
	return owner != GameState.chosen_guild

## Ist ein Fraktions-HQ friedlich betretbar (Händler/Truhe/Dialog)?
static func is_base_friendly(base_id: String) -> bool:
	if not BASE_GUILD.has(base_id):
		return true
	return not is_base_hostile(base_id)


# ── Biom-Zonierung: Logik (Daten: BIOMES/ENEMY_POOLS/BIOME_ZONE_ORDER oben, §1.6.3) ──

## Welches Biom liegt an dieser Weltposition? Geografisch, deterministisch.
static func biome_at(pos: Vector2) -> String:
	if pos.y >= SMOG_LINE_Y:
		return "smog_oedland"
	for id in BIOME_ZONE_ORDER:
		var b: Dictionary = BIOMES[id]
		var c: Vector2 = Vector2(float(b["cx"]), float(b["cy"]))
		var rad: float = float(b["radius"])
		if pos.distance_squared_to(c) <= rad * rad:
			return id
	return "desert"

static func biome(biome_id: String) -> Dictionary:
	assert(BIOMES.has(biome_id), "WorldManager: unbekanntes Biom '%s'" % biome_id)
	return BIOMES[biome_id]

## Ist die Zone sicher betretbar? Erbt das Gating ihres Sektors (§1.7).
static func is_biome_unlocked(biome_id: String) -> bool:
	return can_enter_sector(int(biome(biome_id).get("sector", 1)))

## Gegner-Pool eines Bioms (post nach dem Reveal). Fällt auf Wüste zurück.
static func enemy_pool(biome_id: String, revealed: bool) -> Array:
	var pools: Dictionary = ENEMY_POOLS.get(biome_id, ENEMY_POOLS["desert"])
	return pools["post"] if revealed else pools["pre"]

## Gewichtete Gegner-Auswahl. `roll` (0..1) macht Tests deterministisch; sonst randf().
static func pick_enemy_type(biome_id: String, revealed: bool, roll: float = -1.0) -> String:
	var pool: Array = enemy_pool(biome_id, revealed)
	var total: int = 0
	for p in pool:
		total += int(p[1])
	var x: float = (roll if roll >= 0.0 else randf()) * float(total)
	for p in pool:
		x -= float(p[1])
		if x <= 0.0:
			return String(p[0])
	return "outlaw"
