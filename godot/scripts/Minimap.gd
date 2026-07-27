class_name Minimap extends Control
## Minimap — Orientierung im 5000-m-Krater (Master-GDD §1.4/§1.6).
##
## Zeichnet die Welt als Draufsicht: Sektorgrenzen (Sprengtore/Smog), Biom-Zonen, alle POIs
## und den Spieler mit Blickrichtung. Rein zeichnend (`_draw`), keine 3D-Abhängigkeit — die
## Daten kommen aus `WorldManager`, die Spielerposition wird von außen gesetzt.
##
## Bewusst als eigenes Skript: hält `OverworldView` schlank und macht die Karte
## wiederverwendbar (später auch für eine Vollbild-Karte).

const MAP_PX: float = 190.0        # Kantenlänge der Karte in Pixeln
const DOT_POI: float = 3.0
const DOT_PLAYER: float = 4.5

var player_pos: Vector3 = Vector3.ZERO   # Szenenposition (Meter)
var player_dir: float = 0.0              # Blickrichtung (rad, wie Node3D.rotation.y)
var enemy_positions: Array = []          # Array[Vector3] — Szenenpositionen

var _sector_color: Dictionary = {
	1: Color(0.83, 0.63, 0.27), 2: Color(0.36, 0.56, 0.83), 3: Color(0.78, 0.30, 0.24) }


func _ready() -> void:
	custom_minimum_size = Vector2(MAP_PX, MAP_PX)
	size = Vector2(MAP_PX, MAP_PX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # blockiert den Touch-Joystick nicht


## Szenenposition (Meter) → Pixel auf der Karte. X wächst nach Osten, −Z nach Norden;
## auf der Karte zeigt Norden nach oben, deshalb wird Z gespiegelt.
func world_to_map(p: Vector3) -> Vector2:
	var w: float = WorldManager.WORLD_METERS
	return Vector2(clampf(p.x / w, 0.0, 1.0) * MAP_PX, clampf(-p.z / w, 0.0, 1.0) * MAP_PX)


func _draw() -> void:
	var w: float = WorldManager.WORLD_METERS
	var m: float = WorldManager.METERS_PER_UNIT
	# Untergrund + Rahmen (der Rahmen ist der Kraterrand).
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_PX, MAP_PX)), Color(0.10, 0.09, 0.08, 0.72))
	draw_rect(Rect2(Vector2.ZERO, Vector2(MAP_PX, MAP_PX)), Color(0.55, 0.44, 0.28, 0.9), false, 2.0)
	# Biom-Kreiszonen (dieselben Daten wie die 3D-Scheiben).
	var tint: Dictionary = {
		"oasis": Color(0.31, 0.56, 0.31, 0.5), "salt": Color(0.85, 0.84, 0.78, 0.4),
		"rostwald": Color(0.54, 0.29, 0.18, 0.5), "kupfer_hochland": Color(0.61, 0.42, 0.24, 0.5) }
	for id in WorldManager.BIOME_ZONE_ORDER:
		var b: Dictionary = WorldManager.BIOMES[id]
		var c: Vector2 = world_to_map(WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))))
		draw_circle(c, float(b["radius"]) * m / w * MAP_PX, tint[id])
	# Smog-Senke: alles nördlich der Smog-Linie.
	var smog_y: float = world_to_map(Vector3(0.0, 0.0, -float(WorldManager.SMOG_LINE_Y) * m)).y
	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(MAP_PX, smog_y)), Color(0.35, 0.72, 0.30, 0.30))
	# Sektorgrenzen als Linien.
	var blast_y: float = world_to_map(Vector3(0.0, 0.0, -float(WorldManager.BORDER_S1_S2_Y) * m)).y
	draw_line(Vector2(0.0, blast_y), Vector2(MAP_PX, blast_y), Color(1.0, 0.55, 0.35, 0.85), 1.5)
	draw_line(Vector2(0.0, smog_y), Vector2(MAP_PX, smog_y), Color(0.6, 1.0, 0.5, 0.85), 1.5)
	# Pisten zwischen den Orten — Wegführung, keine Sperre (GDD §1.4a).
	for r0 in WorldManager.ROUTES:
		draw_line(world_to_map(WorldManager.poi_scene_position(String(r0[0]))),
			world_to_map(WorldManager.poi_scene_position(String(r0[1]))),
			Color(0.72, 0.62, 0.44, 0.45), 1.0)
	# Iron-Rail-Trasse darüber: dicker und heller — sie ist die Reiseachse der Karte.
	for seg in WorldManager.rail_segments():
		draw_line(world_to_map(WorldManager.poi_scene_position(String(seg[0]))),
			world_to_map(WorldManager.poi_scene_position(String(seg[1]))),
			Color(0.90, 0.82, 0.55, 0.85), 2.0)
	# POIs, eingefärbt nach Sektor; gesperrte Sektoren blass.
	for id in WorldManager.POIS.keys():
		var p: Dictionary = WorldManager.POIS[id]
		var sec: int = int(p["sector"])
		var col: Color = _sector_color[sec]
		if not WorldManager.can_enter_sector(sec):
			col = Color(col.r, col.g, col.b, 0.35)
		var at: Vector2 = world_to_map(WorldManager.poi_scene_position(id))
		var r: float = DOT_POI * (1.8 if id == "eisernes_herz" else 1.0)
		draw_circle(at, r, col)
		draw_arc(at, r + 1.0, 0.0, TAU, 12, Color(0.0, 0.0, 0.0, 0.6), 1.0)
		# Bahnhöfe bekommen einen hellen Ring — man sieht auf einen Blick, wo man fahren kann.
		if WorldManager.has_station(String(id)):
			draw_arc(at, r + 3.0, 0.0, TAU, 16, Color(0.95, 0.86, 0.58, 0.9), 1.4)
	# Gegner in der Umgebung.
	for e in enemy_positions:
		draw_circle(world_to_map(e), 1.8, Color(0.95, 0.35, 0.30, 0.9))
	# Spieler + Blickrichtung.
	var me: Vector2 = world_to_map(player_pos)
	draw_circle(me, DOT_PLAYER, Color(0.30, 0.62, 1.0))
	draw_arc(me, DOT_PLAYER + 1.0, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, 0.9), 1.2)
	# Node3D-Rotation um Y: Blickrichtung ist (−sin, −cos) in der XZ-Ebene; auf der Karte
	# entspricht −Z „oben", daher wird die Y-Komponente gespiegelt.
	var dir := Vector2(-sin(player_dir), cos(player_dir))
	draw_line(me, me + dir * (DOT_PLAYER + 7.0), Color(1.0, 1.0, 1.0, 0.95), 1.6)
