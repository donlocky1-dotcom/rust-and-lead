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
var _welt: Node          # die geladene Overworld — fuer die Oberflaechen-Bilder
var _buehne: Vector3


func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	_welt = load("res://scenes/Overworld.tscn").instantiate()
	add_child(_welt)
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
	# Aus Spielerhoehe an der Bahnquerung: Dort stehen die Baeume am dichtesten.
	var quer: Vector3 = WorldManager.world_to_scene(Vector2(407.0, float(WorldManager.SWAMP_CENTER_Y)))
	_views.append(["sumpf_nah", quer + Vector3(26.0, 7.0, 26.0), quer + Vector3(0.0, 2.0, 0.0)])
	# Oberflaechen-Bilder. Ein Eintrag mit `null` als Position ist kein Kamerastandpunkt,
	# sondern ein Bildschirm — `_process` erkennt das am Typ und ruft `_setup_ui` auf.
	_views.append(["ui_charakter", null, "charakter"])
	_views.append(["quest_spur", null, "quest"])
	_views.append(["nahaufnahme", null, "nahaufnahme"])
	_views.append(["quest_umweg", null, "umweg"])
	_views.append(["ui_charakter2", null, "charakter"])   # jetzt mit Sinnbildern und Puppe
	# Die beiden neuen Gegner: nebeneinander, aus Spielerhoehe.
	var buehne: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 60.0)
	_views.append(["gegner_neu", null, "gegner"])
	_buehne = buehne
	# Am Ziel selbst: Hier stand die Platzhalter-Saeule mitten im Weg.
	var ratten: Vector3 = WorldManager.poi_scene_position("rattengestruepp")
	_views.append(["ort_rattengestruepp", ratten + Vector3(0.0, 12.0, 26.0), ratten])
	_wait = 60


## Ausgangslage fuer ein Oberflaechen-Bild. Eine leere Puppe und ein leerer Beutel zeigen
## nichts von dem, worauf es ankommt — also erst Beute erzeugen, dann anlegen, dann knipsen.
func _setup_ui(art: String) -> void:
	var ow: OverworldView = _welt as OverworldView
	if ow == null:
		return
	if art == "charakter":
		GameState.bag = []
		GameState.equip = {}
		for slot in ["helmet", "armor", "weapon", "boots"]:
			EquipManager.equip_item(ProgressionManager.make_gear(String(slot), "rare"), String(slot))
		EquipManager.equip_item(ProgressionManager.make_gear("plate", "legendary"), "plate1")
		EquipManager.equip_item(ProgressionManager.make_gear("plate", "common"), "plate3")
		for s2 in ["weapon", "armor", "gadget", "helmet", "boots", "armor"]:
			BagManager.add(ProgressionManager.make_gear(String(s2), "epic"))
		ow._toggle_character(CharacterScreen.Tab.AUSRUESTUNG)
	elif art == "quest":
		# Auftrag annehmen, damit Marke und Fussspur ueberhaupt etwas zu zeigen haben, und die
		# Kamera hinter die Figur setzen — die Spur laeuft NACH VORN, von hinten sieht man sie.
		ow._toggle_character(CharacterScreen.Tab.AUSRUESTUNG)
		QuestManager.accept_quest("q_rats")
		var wo: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 26.0)
		ow._player.position = Vector3(wo.x, WorldManager.height_at(wo.x, wo.z), wo.z)
		var ziel: Vector3 = WorldManager.poi_scene_position("schrott_minen")
		var dir: Vector3 = (ziel - ow._player.position).normalized()
		_cam.position = ow._player.position - dir * 12.0 + Vector3(0.0, 9.0, 0.0)
		_cam.look_at(ow._player.position + dir * 20.0, Vector3.UP)
		_cam.current = true
	elif art == "gegner":
		ow._end_cine()
		ow._close_character()
		var i2: int = 0
		for kind in ["enemy_outlaw", "enemy_revolver"]:
			var n: Node3D = AssetRegistry.instantiate(kind, AssetRegistry.height_of(kind))
			if n == null:
				continue
			ow.add_child(n)
			n.position = _buehne + Vector3(float(i2) * 1.6 - 0.8, 0.0, 0.0)
			n.rotation.y = PI
			AssetRegistry.play_clip(n, "idle")
			i2 += 1
		_cam.position = _buehne + Vector3(0.0, 1.5, 4.2)
		_cam.look_at(_buehne + Vector3(0.0, 0.9, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "umweg":
		# Der Fall, der ohne Wegweisung toedlich endet: Die gerade Linie zum Zugdepot fuehrt
		# mitten durch den Strahlensumpf. Die Spur MUSS hier oestlich daran vorbeizeigen.
		ow._end_cine()
		GameState.quests = {}
		GameState.economy["laboratory"] = 0
		QuestManager.accept_quest("q_m3")
		var wo2: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 20.0)
		ow._player.position = Vector3(wo2.x, WorldManager.height_at(wo2.x, wo2.z), wo2.z)
		var ziel2: Vector3 = ow._trail_goal()
		var dir2: Vector3 = (ziel2 - ow._player.position).normalized()
		_cam.position = ow._player.position - dir2 * 14.0 + Vector3(0.0, 11.0, 0.0)
		_cam.look_at(ow._player.position + dir2 * 24.0, Vector3.UP)
		_cam.current = true
		print("UMWEG: Ziel der Spur bei %s (Welt %s)"
			% [ziel2, WorldManager.scene_to_world(ziel2)])
	elif art == "nahaufnahme":
		# Zur Auftraggeberin laufen und ansprechen — die Nahaufnahme startet dabei von selbst.
		# Danach uebernimmt die SPIELKAMERA; die Shot-Kamera muss also aus dem Weg.
		var mabel: Dictionary = {}
		for n in ow._npcs:
			if String(n["giver"]) == "mabel":
				mabel = n
		if mabel.is_empty():
			return
		ow._player.position = (mabel["pos"] as Vector3) + Vector3(2.2, 0.0, 1.6)
		ow._cam.current = true
		ow._talk_to("mabel")
		# Fuer das Bild verlaengert: Sonst haengt es vom Bildtakt des Rechners ab, ob die
		# Aufnahme beim Ausloesen noch laeuft. Die Fahrt nach innen ist davon unabhaengig.
		ow._play_closeup(mabel["node"] as Node3D, 999.0)
		# Die Drehung braucht ein paar Frames; das Bild wartet ohnehin.



func _process(_dt: float) -> void:
	if _wait > 0:
		_wait -= 1
		return
	if _i >= 0:
		if String(_views[_i][0]) == "quest_spur":
			var ow2: OverworldView = _welt as OverworldView
			var n: int = 0
			for t in ow2._trail:
				if (t as MeshInstance3D).visible:
					n += 1
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [OUT, String(_views[_i][0])])
	_i += 1
	if _i >= _views.size():
		get_tree().quit()
		return
	if _views[_i][1] == null:
		_setup_ui(String(_views[_i][2]))
		# Laenger warten als bei einem Kamerastandpunkt: Eine Nahaufnahme FAEHRT heran, und ein
		# Bild nach zwoelf Bildern zeigt die Bewegung, nicht die Einstellung.
		_wait = 70
		return
	_cam.position = _views[_i][1]
	_cam.look_at(_views[_i][2], Vector3.UP)
	_cam.current = true
	_wait = 12
