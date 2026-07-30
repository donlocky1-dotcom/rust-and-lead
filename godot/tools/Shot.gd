extends Node
## Bildschirmfotos der laufenden Welt — das Werkzeug fuer "sieht falsch aus".
##
## Zweimal hat das Rechnen an Formeln hier in die Irre gefuehrt (die Piste ueber dem Krater,
## der Ring dunkler Flecken am Kraterrand). Beide Male hat erst ein echtes Bild gezeigt, was
## los war. Deshalb steht das hier im Projekt statt in einem Wegwerf-Ordner.
##
## Aufruf (braucht eine X-Attrappe, headless rendert nichts):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --path godot res://tools/Shot.tscn
## Die Bilder landen unter `user://shot_*.png`.
##
## Zwei Fallen, beide teuer gelernt:
##  • **Fenstergroesse setzen.** `--resolution` wirkt hier nicht; ohne `get_window().size`
##    rendert Godot in 64x64, und jede gemessene Bildschirmposition ist Unsinn.
##  • **Eigene Kamera.** Die Spielkamera folgt der Blickrichtung der Figur, und die ist nach
##    einem Sprung an einen Ort beliebig. Die ersten Bilder zeigten leeren Sand, waehrend
##    Stadt und Bahnhof hinter der Kamera lagen.
const OUT: String = "user://shot"
var _views: Array = []
var _i: int = -1
var _wait: int = 0
var _cam: Camera3D


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	add_child(load("res://scenes/Overworld.tscn").instantiate())
	_cam = Camera3D.new()
	_cam.fov = 55.0
	add_child(_cam)
	var rw: Vector3 = WorldManager.poi_scene_position("rustwater")
	var dir: Vector3 = Vector3.ZERO
	for seg in WorldManager.rail_segments():
		if String(seg[0]) == "rustwater":
			dir = WorldManager.poi_scene_position(String(seg[1])) - rw
			break
		if String(seg[1]) == "rustwater":
			dir = WorldManager.poi_scene_position(String(seg[0])) - rw
			break
	dir = Vector3(dir.x, 0.0, dir.z).normalized()
	var side := Vector3(-dir.z, 0.0, dir.x)
	var platform: Vector3 = rw + dir * 68.0
	var halle: Vector3 = platform + side * 11.9
	var krater: Vector3 = WorldManager.poi_scene_position("schrott_minen")
	_views = [
		["bahnhof_front", halle - side * 26.0 + Vector3(0.0, 14.0, 0.0), halle],
		["bahnhof_schraeg", halle - side * 20.0 - dir * 24.0 + Vector3(0.0, 16.0, 0.0), halle],
		["krater_ueber", krater + Vector3(0.0, 26.0, 30.0), krater],
		["krater_rand", krater + Vector3(0.0, 3.0, 17.0), krater + Vector3(0.0, -3.0, 0.0)],
		["wueste", rw + Vector3(160.0, 22.0, 160.0), rw + Vector3(210.0, 0.0, 210.0)],
	]
	# Der Strahlensumpf: einmal von oben über ein Sumpfloch (liegt das Wasser wirklich IM Loch?),
	# einmal aus Spielerhöhe davor (sieht man den Wall, bevor man drinsteht?) und einmal weit
	# oben über der ganzen Zone.
	for f in WorldManager.TERRAIN:
		if not WorldManager.is_swamp_feature(f):
			continue
		var id: String = String(f["id"])
		# _1 liegt in der Salzpfanne, _7 ausserhalb. Zwei Bilder desselben Bauwerks unter
		# unterschiedlicher Biom-Toenung — nur so laesst sich trennen, ob ein Farbunterschied
		# vom Gelaende kommt oder von der Toenung darueber.
		if id != "sumpfloch_1" and id != "sumpfloch_7":
			continue
		var loch: Vector3 = WorldManager.feature_center(f)
		_views.append([id + "_ueber", loch + Vector3(0.0, 24.0, 28.0), loch])
		_views.append([id + "_flach", loch + Vector3(0.0, 3.4, 34.0),
			loch + Vector3(0.0, -1.0, 0.0)])
	var sumpf: Vector3 = WorldManager.world_to_scene(
		Vector2(float(WorldManager.SWAMP_CENTER_X), float(WorldManager.SWAMP_CENTER_Y)))
	_views.append(["sumpf_weit", sumpf + Vector3(0.0, 140.0, 210.0), sumpf])
	_wait = 60


func _process(_dt: float) -> void:
	if _wait > 0:
		_wait -= 1
		return
	if _i >= 0:
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OUT, String(_views[_i][0])])
	_i += 1
	if _i >= _views.size():
		get_tree().quit()
		return
	_cam.position = _views[_i][1]
	_cam.look_at(_views[_i][2], Vector3.UP)
	_cam.current = true
	_wait = 12
