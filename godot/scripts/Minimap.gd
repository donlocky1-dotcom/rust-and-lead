class_name Minimap extends Control
## Karte des Kraters (Master-GDD §1.4/§1.6) — in zwei Betriebsarten aus einer Zeichenroutine.
##
## `full_world = false` — die kleine Karte oben rechts. Sie zeigt einen Ausschnitt von
## LOCAL_RADIUS_M um den Spieler. Der ganze Krater taugt dafür nicht: 5000 m auf 190 px sind
## 0,038 px pro Meter, die Figur rückt also erst nach 26 gelaufenen Metern um ein einziges
## Pixel weiter, Rustwater ist 4 px groß und sämtliche Gegner sitzen im selben Punkt. Als
## Nahansicht sind es 0,475 px/m — damit werden Straße, Gegner und Laufrichtung wirklich
## lesbar, und die Karte reagiert sichtbar auf jeden Schritt.
##
## `full_world = true` — die Vollbildkarte, die per Tippen auf die kleine Karte aufgeht. Erst
## dort ergibt der ganze Krater Sinn, weil er dann auch die Fläche dafür bekommt: Sektoren,
## Biome, Bahntrasse und alle Orte mit Namen.
##
## Beide benutzen DIESELBE Projektion, nur mit anderem Mittelpunkt und Maßstab. Deshalb ist es
## ein Skript und nicht zwei: eine Orientierungsregel, ein Satz Tests. Rein zeichnend (`_draw`),
## keine 3D-Abhängigkeit — die Daten kommen aus `WorldManager`, die Spielerposition von außen.

const MAP_PX: float = 190.0          # Kantenlänge der kleinen Karte
const LOCAL_RADIUS_M: float = 200.0  # Sichtweite der kleinen Karte: Mitte bis Kante
const DOT_POI: float = 3.0
const DOT_PLAYER: float = 4.5

var full_world: bool = false             # true = Vollbild-Weltkarte statt Nahansicht
var player_pos: Vector3 = Vector3.ZERO   # Szenenposition (Meter)
var player_dir: float = 0.0              # Blickrichtung (rad, wie Node3D.rotation.y)
var enemy_positions: Array = []          # Array[Vector3] — Szenenpositionen

var _sector_color: Dictionary = {
	1: Color(0.83, 0.63, 0.27), 2: Color(0.36, 0.56, 0.83), 3: Color(0.78, 0.30, 0.24) }
var _biome_tint: Dictionary = {
	"oasis": Color(0.31, 0.56, 0.31, 0.5), "salt": Color(0.85, 0.84, 0.78, 0.4),
	"rostwald": Color(0.54, 0.29, 0.18, 0.5), "kupfer_hochland": Color(0.61, 0.42, 0.24, 0.5) }


func _ready() -> void:
	if not full_world:
		custom_minimum_size = Vector2(MAP_PX, MAP_PX)
		size = Vector2(MAP_PX, MAP_PX)
	# Klicks fängt `OverworldView._input` ab, damit Karte und Joystick nicht beide auf denselben
	# Tipp reagieren (sonst öffnet sich die Karte UND die Figur läuft los).
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Die Nahansicht zeigt einen Ausschnitt: Biom-Scheiben und Trassen ragen zwangsläufig über
	# den Rahmen hinaus und müssen abgeschnitten werden.
	clip_contents = true


# ── Projektion ────────────────────────────────────────────────────────────────

## Kürzere Kante der Karte in Pixeln — der Maßstab hängt an ihr, damit ein nicht-quadratischer
## Rahmen die Karte nicht verzerrt.
func map_px() -> float:
	return minf(size.x, size.y)


## Mittelpunkt der Ansicht in Szenenmetern: die Weltmitte bzw. der Spieler.
func view_center() -> Vector3:
	if full_world:
		var h: float = WorldManager.WORLD_METERS * 0.5
		return Vector3(h, 0.0, -h)
	return Vector3(player_pos.x, 0.0, player_pos.z)


## Pixel pro Meter in der aktuellen Betriebsart.
func pixels_per_meter() -> float:
	if full_world:
		return map_px() / WorldManager.WORLD_METERS
	return map_px() / (LOCAL_RADIUS_M * 2.0)


## Szenenposition (Meter) → Pixel auf der Karte. X wächst nach Osten, −Z nach Norden.
##
## Zwei Vorzeichen treffen hier aufeinander und heben sich auf: Norden ist in der Szene −Z, in
## Godots Zeichenfläche wächst Y aber nach UNTEN. Norden oben heißt also NICHT „Z spiegeln"
## (das dreht die Karte auf den Kopf) — die Z-Differenz wandert unverändert in die Y-Achse.
func world_to_map(p: Vector3) -> Vector2:
	var c: Vector3 = view_center()
	return size * 0.5 + Vector2(p.x - c.x, p.z - c.z) * pixels_per_meter()


## Blickrichtung des Spielers als Richtungsvektor auf der Karte (Länge 1).
##
## Bewusst eine eigene Methode und nicht inline in `_draw`: So prüft die Test-Suite exakt die
## Rechnung, die auch gezeichnet wird. Der alte Fehler war nämlich, dass Karte UND Strich
## gemeinsam verdreht waren — untereinander stimmig, gegenüber der Welt beide falsch.
func facing_on_map() -> Vector2:
	# Node3D-Rotation um Y: die Blickrichtung ist (−sin, −cos) in der XZ-Ebene — gemessen, nicht
	# geraten (`rotation.y = atan2(-step.x, -step.z)` in OverworldView macht die Figur exakt zum
	# Laufvektor schauen). Umrechnung wie in `world_to_map`: Z wandert unverändert in Y.
	return Vector2(-sin(player_dir), -cos(player_dir))


# ── Zeichnen ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	var k: float = pixels_per_meter()
	var m: float = WorldManager.METERS_PER_UNIT
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.10, 0.09, 0.08, 0.72))
	# Biom-Kreiszonen (dieselben Daten wie die 3D-Scheiben).
	for id in WorldManager.BIOME_ZONE_ORDER:
		var b: Dictionary = WorldManager.BIOMES[id]
		var at: Vector2 = world_to_map(
			WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))))
		draw_circle(at, float(b["radius"]) * m * k, _biome_tint[id])
	# Smog-Senke: alles nördlich der Smog-Linie, also alles ÜBER ihr. Geklemmt statt abgefragt —
	# liegt die Linie außerhalb des Ausschnitts, wird von selbst nichts oder alles eingefärbt.
	var smog_y: float = world_to_map(Vector3(0.0, 0.0, -float(WorldManager.SMOG_LINE_Y) * m)).y
	var blast_y: float = world_to_map(Vector3(0.0, 0.0, -float(WorldManager.BORDER_S1_S2_Y) * m)).y
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, clampf(smog_y, 0.0, size.y))),
		Color(0.35, 0.72, 0.30, 0.30))
	# Sektorgrenzen als Linien — nur, wenn sie im Ausschnitt liegen.
	if blast_y > 0.0 and blast_y < size.y:
		draw_line(Vector2(0.0, blast_y), Vector2(size.x, blast_y), Color(1.0, 0.55, 0.35, 0.85), 1.5)
	if smog_y > 0.0 and smog_y < size.y:
		draw_line(Vector2(0.0, smog_y), Vector2(size.x, smog_y), Color(0.6, 1.0, 0.5, 0.85), 1.5)
	# Die Karte zeigt nur noch die Trasse. Vorher lag darunter für jede Route eine blasse
	# Pisten-Linie — die gibt es in der Welt nicht mehr, und eine Straße auf der Karte, die
	# draußen nirgends liegt, ist schlimmer als gar keine: Man läuft hin und sucht sie.
	var road_w: float = 1.0 if full_world else 3.0
	# Iron-Rail-Trasse: die Reiseachse der Karte.
	for seg in WorldManager.rail_segments():
		draw_line(world_to_map(WorldManager.poi_scene_position(String(seg[0]))),
			world_to_map(WorldManager.poi_scene_position(String(seg[1]))),
			Color(0.90, 0.82, 0.55, 0.85), road_w * 2.0)
	_draw_pois(rect)
	# Gegner in der Umgebung. Auf der Nahansicht sind sie endlich mehr als ein gemeinsamer
	# Punkt — der Spawnradius von 45 m misst hier 21 px statt 1,7.
	for e in enemy_positions:
		draw_circle(world_to_map(e), 2.6 if full_world else 3.4, Color(0.95, 0.35, 0.30, 0.9))
	_draw_player()
	# Rahmen zuletzt, damit nichts über ihn läuft.
	draw_rect(rect, Color(0.55, 0.44, 0.28, 0.9), false, 2.0)
	_draw_scale_hint()


## Orte. Was aus dem Ausschnitt fällt, wird auf der Nahansicht als blasse Marke an den Rand
## geklemmt: So bleibt die Richtung zum nächsten Ort ablesbar, ohne die Karte zuzukleistern.
func _draw_pois(rect: Rect2) -> void:
	var font: Font = ThemeDB.fallback_font
	for id in WorldManager.POIS.keys():
		var p: Dictionary = WorldManager.POIS[id]
		var sec: int = int(p["sector"])
		var col: Color = _sector_color[sec]
		if not WorldManager.can_enter_sector(sec):
			col = Color(col.r, col.g, col.b, 0.35)
		var at: Vector2 = world_to_map(WorldManager.poi_scene_position(id))
		if not rect.has_point(at):
			if not full_world:
				var edge := Vector2(clampf(at.x, 5.0, size.x - 5.0), clampf(at.y, 5.0, size.y - 5.0))
				draw_circle(edge, 2.2, Color(col.r, col.g, col.b, col.a * 0.6))
			continue
		var r: float = DOT_POI * (1.8 if id == "eisernes_herz" else 1.0)
		if not full_world:
			r *= 1.6   # in der Nahansicht ist Platz, und der Ort ist das Ziel
		draw_circle(at, r, col)
		draw_arc(at, r + 1.0, 0.0, TAU, 12, Color(0.0, 0.0, 0.0, 0.6), 1.0)
		# Bahnhöfe bekommen einen hellen Ring — man sieht auf einen Blick, wo man fahren kann.
		if WorldManager.has_station(String(id)):
			draw_arc(at, r + 3.0, 0.0, TAU, 16, Color(0.95, 0.86, 0.58, 0.9), 1.4)
		# Namen nur auf der Vollbildkarte: dort ist Platz dafür, und genau dafür macht man sie auf.
		if full_world and font != null:
			draw_string(font, at + Vector2(r + 5.0, 4.0), String(p["name"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.93, 0.88, 0.75, 0.92))


func _draw_player() -> void:
	var me: Vector2 = world_to_map(player_pos)
	draw_circle(me, DOT_PLAYER, Color(0.30, 0.62, 1.0))
	draw_arc(me, DOT_PLAYER + 1.0, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, 0.9), 1.2)
	draw_line(me, me + facing_on_map() * (DOT_PLAYER + 7.0), Color(1.0, 1.0, 1.0, 0.95), 1.6)


## Maßstab unten links. Auf der Nahansicht zusätzlich der Reichweitenkreis: Er läuft genau
## durch die Kantenmitten und macht damit sichtbar, was „200 m" auf dieser Karte heißt.
func _draw_scale_hint() -> void:
	if not full_world:
		draw_arc(size * 0.5, LOCAL_RADIUS_M * pixels_per_meter(), 0.0, TAU, 48,
			Color(0.85, 0.78, 0.60, 0.22), 1.0)
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var text: String = "5 km" if full_world else "%d m" % int(LOCAL_RADIUS_M)
	draw_string(font, Vector2(6.0, size.y - 6.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.86, 0.80, 0.62, 0.75))
