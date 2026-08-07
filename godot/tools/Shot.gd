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
	_views.append(["blickrichtung", null, "blick"])
	_views.append(["gegner_leiste", null, "leiste"])
	_views.append(["gegner_kampf", null, "kampf"])
	_views.append(["neuzugang", null, "neuzugang"])
	_views.append(["figuren", null, "figuren"])
	_views.append(["waffe", null, "waffe"])
	for uz in [["tageszeit_nacht", "uhr_1.5"], ["tageszeit_daemmerung", "uhr_5.9"],
			["tageszeit_tag", "uhr_12.5"], ["tageszeit_abend", "uhr_19.6"]]:
		_views.append([String(uz[0]), null, String(uz[1])])
	# Die Nachtbeleuchtung als GANZES. Einzelbilder vom Saloon sagen nichts darueber, ob die
	# Stadt nachts als Lichtbild funktioniert — ob Esse, Torfackeln und Turmlaterne zusammen
	# eine Silhouette ergeben oder ob einer davon alles ueberstrahlt. Also von oben, und dann
	# aus Augenhoehe auf die Schmiede.
	_views.append(["nacht_stadt", null, "nachtstadt"])
	_views.append(["nacht_schmiede", null, "nachtschmiede"])
	# Der Anflug auf Rustwater, an fuenf Stellen abgegriffen. Eine Kamerafahrt laesst sich
	# rechnerisch pruefen (der Test tut das), aber ob sie ein BILD ergibt, sieht man erst im
	# Bild — vor allem, ob der Turm bei der Umrundung im Rahmen bleibt.
	#
	# Der erste Wert ist 0,17 und nicht 0,0: Zu Beginn blendet die Fahrt noch von der
	# STANDKAMERA herueber, und die steht hier im Werkzeug woanders als im Spiel. 0,17 ist das
	# Ende der ersten Etappe — der reine Blickpunkt des Helden, ohne Beimischung.
	for anteil in ["0.17", "0.35", "0.60", "0.86", "0.96"]:
		_views.append(["flug_" + anteil, null, "flug_" + anteil])
	_buehne = buehne
	# Am Ziel selbst: Hier stand die Platzhalter-Saeule mitten im Weg.
	var ratten: Vector3 = WorldManager.poi_scene_position("rattengestruepp")
	_views.append(["ort_rattengestruepp", ratten + Vector3(0.0, 12.0, 26.0), ratten])
	# Rustwater von oben, und dasselbe Bild noch einmal mit eingezeichneten Sperren. Ein
	# Kollisionsfehler ist als ZAHL kaum zu erkennen und als Ueberlagerung sofort: Wo Rot ueber
	# Sand liegt statt ueber einem Dach, steht eine unsichtbare Wand.
	_views.append(["stadt_oben", rw + Vector3(0.0, 96.0, 58.0), rw])
	_views.append(["stadt_sperren", null, "sperren"])
	_views.append(["stadt_sperren_oben", rw + Vector3(0.0, 96.0, 58.0), rw])
	# Aus Spielerhoehe durch das Tor hinein — der Weg, den jeder Spieler zuerst nimmt.
	_views.append(["stadt_tor", rw + Vector3(2.0, 2.6, -34.0), rw + Vector3(0.0, 2.0, 0.0)])
	# Und von INNEN, aus Spielkamera-Abstand: So sieht man den Kupferboden, wie man ihn spielt.
	_views.append(["stadt_innen", rw + Vector3(6.0, 5.2, 12.0), rw + Vector3(-2.0, 0.6, -6.0)])
	_wait = 60
	# Ein einzelnes Bild statt aller: `godot … res://tools/Shot.tscn -- stadt`
	var filter: PackedStringArray = OS.get_cmdline_user_args()
	if filter.size() > 0:
		var muster: PackedStringArray = filter[0].split(",", false)
		var gewaehlt: Array = []
		for v in _views:
			for m in muster:
				if String(v[0]).begins_with(m):
					gewaehlt.append(v)
					break
		if not gewaehlt.is_empty():
			_views = gewaehlt


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
		# Zumachen statt umschalten: Mit dem Filterargument kann diese Ansicht die ERSTE sein,
		# und dann oeffnete ein Umschalter den Charakterschirm, statt ihn zu schliessen.
		ow._close_character()
		QuestManager.accept_quest("q_rats")
		var wo: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 26.0)
		ow._player.position = Vector3(wo.x, WorldManager.height_at(wo.x, wo.z), wo.z)
		# Auf das WIRKLICHE Ziel ausrichten, nicht auf ein hier notiertes: Welcher Auftrag
		# verfolgt wird, entscheidet der QuestManager — und mit jedem neuen Auftrag im Kapitel
		# zeigte die Kamera sonst woandershin als die Spur.
		var ziel: Vector3 = ow._trail_goal()
		if ziel == Vector3.INF:
			ziel = WorldManager.poi_scene_position("schrott_minen")
		var dir: Vector3 = Vector3(ziel.x - ow._player.position.x, 0.0,
			ziel.z - ow._player.position.z).normalized()
		_cam.position = ow._player.position - dir * 12.0 + Vector3(0.0, 9.0, 0.0)
		_cam.look_at(ow._player.position + dir * 20.0, Vector3.UP)
		_cam.current = true
	elif art == "sperren":
		# Jede eingetragene Sperre als rote Platte AUF dem Bild (ohne Tiefentest, sonst
		# verschwindet sie unter dem Dach, das sie beschreibt). Deckt sich das Rot mit den
		# Gebaeuden, stimmt die Kollision; liegt es daneben, steht dort eine unsichtbare Wand.
		for b in ow._rot_blockers:
			var c: Vector2 = b["c"]
			var h: Vector2 = b["h"]
			var platte := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(h.x * 2.0, 0.3, h.y * 2.0)
			platte.mesh = box
			platte.position = Vector3(c.x, WorldManager.height_at(c.x, c.y) + 0.3, c.y)
			platte.rotation.y = float(b["yaw"])
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.95, 0.15, 0.12, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.no_depth_test = true
			platte.material_override = mat
			ow.add_child(platte)
	elif art == "blick":
		# Blickrichtungspruefung: alle Figuren UNGEDREHT nebeneinander, Kamera auf +Z.
		# Wer sein Gesicht zeigt, schaut nach +Z und braucht die 180°-Korrektur, denn Godot
		# laeuft nach −Z. Wer den Ruecken zeigt, sitzt richtig.
		ow._end_cine()
		ow._close_character()
		var b3: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, 90.0)
		var reihe: Array = ["enemy_outlaw", "enemy_revolver", "enemy_fauna", "enemy_konstrukt",
			"player", "npc_mabel"]
		for j in reihe.size():
			var kind2: String = String(reihe[j])
			var n2: Node3D = AssetRegistry.instantiate(kind2, AssetRegistry.height_of(kind2))
			if n2 == null:
				continue
			ow.add_child(n2)
			n2.position = b3 + Vector3(float(j) * 2.2 - 5.5, 0.0, 0.0)
			# MIT der eingetragenen Korrektur: Wer jetzt den Ruecken zeigt, laeuft richtig
			# herum. (Zum Nachmessen eines NEUEN Modells hier die Drehung der Kinder auf 0
			# setzen — dann sieht man den rohen Zustand.)
			ow._label(n2.position + Vector3(0.0, 2.4, 0.0), kind2, Color(1, 1, 0.5), 60, 90.0)
		_cam.position = b3 + Vector3(0.0, 1.7, 7.0)
		_cam.look_at(b3 + Vector3(0.0, 1.0, 0.0), Vector3.UP)
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
	elif art == "leiste":
		# Echte Gegner aus `_make_enemy`, nicht nur Modelle: Nur so ist die Lebensleiste dabei.
		# Zwei Zustaende nebeneinander — unverletzt und halb tot —, damit man sieht, ob der
		# Restanteil ueberhaupt schrumpft.
		ow._end_cine()
		ow._close_character()
		var i3: int = 0
		for anteil in [1.0, 0.45]:
			var e: Dictionary = ow._make_enemy("outlaw" if i3 == 0 else "revolver")
			var n2: Node3D = e["node"]
			ow.add_child(n2)
			n2.position = _buehne + Vector3(float(i3) * 1.8 - 0.9, 0.0, 0.0)
			n2.rotation.y = PI
			(e["bar"] as MeshInstance3D).scale.x = anteil
			i3 += 1
		_cam.position = _buehne + Vector3(0.0, 1.9, 3.4)
		_cam.look_at(_buehne + Vector3(0.0, 1.5, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "neuzugang" or art == "figuren":
		# Alle frisch gelieferten Modelle nebeneinander, in Einbaugroesse, auf einer Reihe.
		# Ein Modell, das man nur als Datei kennt, kauft man blind ein — das hier ist die
		# Abnahme: Groesse, Lage, Farbe, und ob es ueberhaupt so herum steht wie gedacht.
		ow._end_cine()
		ow._close_character()
		var reihe: Array = ["locomotive", "shelf", "desk", "office_chair", "oil_barrel",
			"barbed_wire", "medallion", "monolith", "copper_plate_a", "copper_plate_b",
			"figur_ohne_namen", "figur_mit_animationen"]
		if art == "figuren":
			reihe = ["figur_ohne_namen", "figur_mit_animationen"]
		var x: float = 0.0
		for kind2 in reihe:
			var name2: String = String(kind2)
			if not AssetRegistry.has_model(name2):
				continue
			var n4: Node3D = AssetRegistry.instantiate(name2)
			if n4 == null:
				continue
			ow.add_child(n4)
			var b4: AABB = AssetRegistry.local_bounds(n4)
			var breite: float = maxf(b4.size.x * n4.scale.x, 0.5)
			x += breite * 0.5 + 1.2
			n4.position = _buehne + Vector3(x, WorldManager.height_at(_buehne.x, _buehne.z), 0.0)
			x += breite * 0.5
			ow._label(n4.position + Vector3(0.0, 4.6, 0.0), name2,
				Color(1.0, 0.92, 0.7), OverworldView.LBL_HAUS, 300.0)
		_cam.position = _buehne + Vector3(x * 0.5, x * 0.28, x * 0.62)
		_cam.look_at(_buehne + Vector3(x * 0.5, 1.4, 0.0), Vector3.UP)
		if art == "figuren":
			# Naeher heran und auf Brusthoehe: Wer die Figuren erkennen soll, braucht Gesicht
			# und Kleidung, nicht die Silhouette am Horizont.
			_cam.position = _buehne + Vector3(x * 0.5, 1.5, 4.2)
			_cam.look_at(_buehne + Vector3(x * 0.5, 1.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art.begins_with("uhr_"):
		# Dieselbe Einstellung zu vier Tageszeiten. Nur so sieht man, ob die Beleuchtung eine
		# Kurve ist oder eine Treppe — und ob die Nacht dunkel genug ist, dass ein
		# Muendungsfeuer ueberhaupt etwas beleuchtet.
		ow._end_cine()
		ow._close_character()
		GameState.hour = float(art.get_slice("_", 1).to_float())
		ow._apply_daytime()
		ow._apply_night_lights()
		var rw2: Vector3 = WorldManager.poi_scene_position("rustwater")
		ow._player.position = Vector3(rw2.x + 4.0, WorldManager.height_at(rw2.x + 4.0, rw2.z + 6.0),
			rw2.z + 6.0)
		ow._muzzle_flash(30.0)
		# Auf den Saloon: Er hat immer offen und soll den Platz davor beleuchten. Vom
		# Stadtplatz aus schraeg darauf, damit Fassade UND Vorplatz im Bild sind.
		_cam.position = rw2 + Vector3(6.0, 5.0, 17.0)
		_cam.look_at(rw2 + Vector3(-11.0, 2.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art.begins_with("flug_"):
		# Der Anflug an einer bestimmten Stelle seiner Laufzeit. Die Fahrt wird echt ausgeloest
		# (nicht nachgebaut), dann die Uhr vorgestellt und das Bild abgegriffen — was hier steht,
		# ist genau das, was der Spieler sieht.
		# Aufraeumen, was das vorige Flug-Bild hinterlassen hat: Die Welt steht seit dem letzten
		# Aufruf still (siehe unten), die Fahrt ist also nie zu Ende gelaufen. Ohne das lehnt
		# `_maybe_intro_flight` den naechsten Anflug mit „laeuft schon" ab — und dann steht die
		# Kamera zwar richtig, aber die Bedienoberflaeche liegt wieder ueber dem Bild.
		ow.set_process(true)
		ow._end_flight()
		ow._end_cine()
		ow._close_character()
		GameState.hour = 1.5
		GameState.prolog_done = false
		GameState.saw_rustwater = false
		ow._apply_daytime()
		ow._apply_night_lights()
		var rwf: Vector3 = WorldManager.poi_scene_position("rustwater")
		# Knapp innerhalb der Sichtweite, damit die Fahrt beim naechsten Aufruf anspringt.
		var steh: Vector3 = rwf + Vector3(0.0, 0.0, OverworldView.INTRO_SIGHT_M - 4.0)
		ow._player.position = Vector3(steh.x, WorldManager.height_at(steh.x, steh.z), steh.z)
		ow._player.rotation.y = PI
		# Die SPIELKAMERA erst in ihre normale Haltung bringen. Sie folgt der Figur sonst noch
		# ueber mehrere Bilder hinweg — und der Anflug merkt sich beim Start genau diese Haltung
		# als das, wohin er zurueckkehrt. Ohne das endete die Fahrt dort, wo die Kamera beim
		# Laden zufaellig stand.
		ow._cam.position = ow._player.position + ow._cam_offset(ow._cam_dist)
		ow._cam.look_at(ow._player.position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		ow._maybe_intro_flight()
		ow._flight_t = ow._flight_total() * float(art.get_slice("_", 1).to_float())
		# Und die Welt anhalten. Sonst laeuft `_process` die verbleibenden Wartebilder weiter,
		# die Fahrt erreicht ihr Ende und raeumt Balken und Bedienoberflaeche wieder ein — das
		# Bild zeigte dann die richtige Kameraposition mit dem falschen Bildschirm darueber.
		ow.set_process(false)
		var ff: Array = ow._flight_frame()
		_cam.position = ff[0]
		if ff[0].distance_to(ff[1]) > 0.05:
			_cam.look_at(ff[1], Vector3.UP)
		_cam.current = true
	elif art == "nachtstadt" or art == "nachtschmiede":
		# Die Nachtbeleuchtung im Zusammenhang. Ein Bild vom Saloon allein beantwortet nicht die
		# Frage, die zaehlt: Ergibt die Stadt nachts eine LESBARE Silhouette — Torfackeln als
		# Eingang, Esse als Arbeitsplatz, Turmlaterne als Landmarke — oder ist es ein Haufen
		# oranger Flecken?
		ow._end_cine()
		ow._close_character()
		GameState.hour = 1.5
		ow._apply_daytime()
		ow._apply_night_lights()
		var rwn: Vector3 = WorldManager.poi_scene_position("rustwater")
		ow._player.position = Vector3(rwn.x, WorldManager.height_at(rwn.x, rwn.z), rwn.z)
		if art == "nachtstadt":
			_cam.position = rwn + Vector3(0.0, 74.0, 46.0)
			_cam.look_at(rwn, Vector3.UP)
		else:
			# Die Schmiede steht in `Rustwater.tscn` bei (16,9 | −7,0) im Ortsraum. Von der
			# Strasse aus darauf, aus Augenhoehe: So sieht man, ob der Schein aus der Oeffnung
			# faellt und den Boden davor traegt — oder ob das Haus nur innen gluetht.
			var schmiede: Vector3 = rwn + Vector3(16.9, 0.0, -7.0)
			var auge: Vector3 = schmiede + Vector3(-9.0, 4.0, 9.0)
			_cam.position = Vector3(auge.x, WorldManager.height_at(auge.x, auge.z) + 4.0, auge.z)
			_cam.look_at(schmiede + Vector3(0.0, 2.0, 0.0), Vector3.UP)
		_cam.current = true
	elif art == "waffe":
		# Die Figur mit Waffe, gross im Bild — und mitten im Schuss. Zwei Fragen in einem Bild:
		# Liegt das Gewehr richtig in der Hand, und sitzt das Muendungsfeuer an der Muendung?
		ow._end_cine()
		ow._close_character()
		ow._enemies.clear()
		var mitte2: Vector3 = _buehne
		ow._player.position = Vector3(mitte2.x, WorldManager.height_at(mitte2.x, mitte2.z), mitte2.z)
		ow._player.rotation.y = 0.0
		EquipManager.equip_item(ProgressionManager.make_gear("weapon", "rare", "", null,
			"karabiner"), "weapon")
		ow._sync_weapon()
		# Von VORN: Die Figur schaut nach −Z, also steht die Kamera dort. Von hinten sah man
		# nur den Schaft in der Faust — das Gewehr zeigt ja vom Betrachter weg.
		_cam.position = ow._player.position + Vector3(1.15, 1.45, -2.4)
		_cam.look_at(ow._player.position + Vector3(0.0, 1.15, -0.6), Vector3.UP)
		_cam.current = true
	elif art == "kampf":
		# Ein Nahkaempfer im Schlag und ein Schuetze auf Schussdistanz — beide in dem Bild, in
		# dem der Treffer faellt. Nur so sieht man, ob die Animation zum Schaden passt.
		ow._end_cine()
		ow._close_character()
		ow._enemies.clear()
		var mitte: Vector3 = _buehne
		ow._player.position = Vector3(mitte.x, WorldManager.height_at(mitte.x, mitte.z), mitte.z)
		ow._hp = 500.0
		var stellen: Array = [["outlaw", Vector3(1.6, 0.0, 0.4)],
			["revolver", Vector3(-6.5, 0.0, 3.0)]]
		for eintrag in stellen:
			var e2: Dictionary = ow._make_enemy(String(eintrag[0]))
			var n3: Node3D = e2["node"]
			ow.add_child(n3)
			n3.position = ow._player.position + (eintrag[1] as Vector3)
			n3.position.y = WorldManager.height_at(n3.position.x, n3.position.z)
			ow._enemies.append(e2)
		# Bis kurz VOR den Treffer vorspulen: Dann steht die Angriffs-Animation im Bild.
		for _f in 12:
			ow._process_enemies(0.02)
		_cam.position = ow._player.position + Vector3(3.4, 2.2, 6.0)
		_cam.look_at(ow._player.position + Vector3(-1.0, 1.1, 0.0), Vector3.UP)
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
		# Ein Muendungsfeuer lebt 55 ms. Ausgeloest werden muss es EIN Bild vor dem Knipsen:
		# `get_image()` liefert das zuletzt GERENDERTE Bild, im selben Aufruf ausgeloest waere
		# es also noch nicht drauf.
		if _wait == 1 and _i >= 0 and String(_views[_i][0]) == "waffe":
			# Im Bild lange genug: Der Blitz lebt im Spiel 55 ms, und headless rendert langsamer
			# als das. Sonst ist er beim Knipsen schon wieder weg — genau so ist das erste
			# Pruefbild entstanden, auf dem gar keiner zu sehen war.
			(_welt as OverworldView)._muzzle_flash(30.0)
		return
	if _i >= 0:
		if String(_views[_i][0]) == "quest_spur":
			var ow2: OverworldView = _welt as OverworldView
			var n: int = 0
			for t in ow2._trail:
				if (t as MeshInstance3D).visible:
					n += 1
			print("    Fussspur: %d von %d sichtbar" % [n, ow2._trail.size()])
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
