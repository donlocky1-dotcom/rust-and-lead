extends Node
## Macht aus einer gestreuten Grube eine **editierbare Szene**.
##
## Aufruf:
##   godot --headless --path godot res://tools/BakePit.tscn -- schrotthalde
##
## Ergebnis: `res://scenes/gruben/<id>.tscn`. Liegt sie vor, streut das Spiel diese Grube nicht
## mehr selbst, sondern lädt sie — dieselbe Regel wie bei `Rustwater.tscn`: **Was in der Szene
## steht, ist die Wahrheit.**
##
## Warum backen, statt mit einer leeren Szene anzufangen: Sonst müsste man die hundertfünfzig
## gestreuten Teile im Editor blind umgehen, weil sie dort gar nicht auftauchen. So sieht man
## beim Öffnen genau das, was auch im Spiel liegt, und kann anfassen, verschieben, wegwerfen.
##
## Der Boden zum Fallenlassen (`PitFloor`) kommt als erster Knoten mit hinein. Er ist ein
## GESCHWISTER der Teile, kein Elternknoten — im Spiel löscht er sich selbst und würde sie sonst
## mitnehmen.

const ZIEL_ORDNER: String = "res://scenes/gruben"
const PitFloor = preload("res://scripts/PitFloor.gd")


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var id: String = String(args[0]) if args.size() > 0 else "schrotthalde"
	if id == "teile":
		get_tree().quit(_teile_backen())
		return
	var code: int = _backen(id)
	get_tree().quit(code)


## Bauteil-Szenen fuer den Editor: `res://scenes/teile/<name>.tscn`.
##
## Ein `.glb` aus dem Dateisystem in die Szene zu ziehen bringt das Modell in MODELLgroesse —
## bei Meshy also grundsaetzlich 1,9 Einheiten, egal ob Fass oder Lokomotive. Wer damit eine
## Halde fuellt, skaliert jedes Stueck von Hand und raet dabei.
##
## Diese Wrapper tragen die Groesse, die `AssetRegistry` dem Modell im Spiel gibt (Zielhoehe
## oder Ziellaenge, Drehung, Unterkante auf null), fest in der Transform. Hineinziehen, fallen
## lassen, fertig.
const TEILE_ORDNER: String = "res://scenes/teile"
const FUER_DIE_HALDE: Array = [
	"locomotive", "shelf", "desk", "office_chair", "oil_barrel", "barbed_wire",
	"medallion", "monolith", "scrap_heap", "scrap_heap_b", "barrels", "barrels_b",
	"barrels_c", "scrap_heap_rust_lod", "scrap_heap_b_rust_lod", "barrels_rust_lod",
	"barrels_b_rust_lod", "barrels_c_rust_lod", "bones", "bones_b", "cactus",
	"rock_small", "rock_boulder", "rad_barrel", "deadtree", "deadtree_b",
]
func _teile_backen() -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEILE_ORDNER))
	var n: int = 0
	for name in FUER_DIE_HALDE:
		var wie: String = String(name)
		if not AssetRegistry.has_model(wie):
			continue
		var halter: Node3D = AssetRegistry.instantiate(wie)
		if halter == null:
			continue
		add_child(halter)
		var teil: Node3D = _als_instanz(halter)
		remove_child(halter)
		halter.free()
		if teil == null:
			continue
		var wurzel := Node3D.new()
		wurzel.name = wie
		add_child(wurzel)
		wurzel.add_child(teil)
		teil.owner = wurzel
		teil.name = "modell"
		wurzel.set_meta("asset", wie)
		var packed := PackedScene.new()
		if packed.pack(wurzel) != OK:
			continue
		if ResourceSaver.save(packed, "%s/%s.tscn" % [TEILE_ORDNER, wie]) == OK:
			n += 1
		wurzel.queue_free()
	print("%d Bauteil-Szenen in %s" % [n, TEILE_ORDNER])
	return 0


func _backen(id: String) -> int:
	var f: Dictionary = {}
	for kandidat in WorldManager.TERRAIN:
		if String(kandidat.get("id", "")) == id:
			f = kandidat
			break
	if f.is_empty():
		printerr("Keine Gelaendeform namens '%s'." % id)
		return 1

	# Die Streuung entsteht in einer Wegwerf-Ansicht und wird danach umgehängt. Damit backt das
	# Werkzeug garantiert dasselbe, was das Spiel baut — es gibt keine zweite Streu-Logik.
	#
	# NICHT in den Baum hängen: Sonst läuft `_ready()` und baut die ganze Welt, und die Ernte
	# danach nimmt Stadt, Gelände und Fußspur gleich mit. (Beim ersten Versuch waren das 1267
	# Knoten und 13 MB statt anderthalbhundert Schrottteilen.)
	var ow := OverworldView.new()
	var pool: Array = ow._scrap_pool()
	if pool.is_empty():
		printerr("Kein Schrott vorhanden (fehlen die Modelle?).")
		return 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	ow._fill_crater(f, pool, rng)
	print("· gestreut: %d Knoten" % ow.get_child_count())

	var wurzel := Node3D.new()
	wurzel.name = id
	add_child(wurzel)
	# Alles relativ zur Kratermitte ablegen. Mit Weltkoordinaten laege die Szene bei x = 370,
	# z = −1130, und der Editor oeffnete sie mit der Kamera im Nichts.
	var mitte: Vector3 = WorldManager.feature_center(f)
	mitte.y = 0.0

	var boden := PitFloor.new()
	boden.name = "BODEN_NUR_EDITOR"
	boden.feature_id = id
	wurzel.add_child(boden)
	boden.owner = wurzel

	var gezaehlt: int = 0
	for kind in ow.get_children().duplicate():
		if not (kind is Node3D):
			continue
		var halter: Node3D = kind as Node3D
		var teil: Node3D = _als_instanz(halter)
		ow.remove_child(halter)
		halter.free()
		if teil == null:
			continue     # Pfütze, Beschriftung — gehört nicht in die Bearbeitungsszene
		wurzel.add_child(teil)
		# Ohne `owner` fällt ein Kind beim Packen unter den Tisch — die Falle bei
		# `PackedScene.pack()`, und sie fällt nicht auf, weil das Speichern trotzdem gelingt.
		teil.owner = wurzel
		teil.position -= mitte
		teil.name = "%03d_%s" % [gezaehlt, teil.scene_file_path.get_file().get_basename()]
		gezaehlt += 1
	ow.free()
	print("· geerntet: %d Teile" % gezaehlt)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL_ORDNER))
	var packed := PackedScene.new()
	var fehler: int = packed.pack(wurzel)
	if fehler != OK:
		printerr("Packen fehlgeschlagen: %d" % fehler)
		return 1
	var pfad: String = "%s/%s.tscn" % [ZIEL_ORDNER, id]
	fehler = ResourceSaver.save(packed, pfad)
	if fehler != OK:
		printerr("Speichern fehlgeschlagen: %d" % fehler)
		return 1
	print("%s geschrieben — %d Teile plus Editor-Boden." % [pfad, gezaehlt])
	return 0


## Ein gestreutes Teil als **Szenen-Instanz** statt als ausgeschriebener Knotenbaum.
##
## `AssetRegistry.instantiate` steckt jedes Modell in einen Halter-Knoten (dort sitzt die
## Bodenkorrektur, damit der Aufrufer `position` frei setzen darf). Dieser Halter hat keinen
## `scene_file_path` — `PackedScene.pack()` schreibt deshalb den ganzen Unterbaum samt Netzen
## und Materialien in die Datei. Beim ersten Versuch waren das 13 MB, und im Editor wäre daraus
## eine Szene geworden, in der ein Fass kein Fass mehr ist, sondern lose Dreiecke.
##
## Also wird der eingesetzte Modellknoten gesucht, seine zusammengesetzte Transform gerechnet
## und das Modell frisch als Instanz gesetzt. Ergebnis: eine Zeile je Teil, anfassbar wie in
## `Rustwater.tscn`.
func _als_instanz(halter: Node3D) -> Node3D:
	var quelle: Node3D = _erste_instanz(halter)
	if quelle == null:
		return null
	var packed: PackedScene = load(quelle.scene_file_path) as PackedScene
	if packed == null:
		return null
	var neu: Node3D = packed.instantiate() as Node3D
	if neu == null:
		return null
	neu.transform = _kette(halter, quelle)
	return neu


## Erster Knoten im Unterbaum, der eine eingesetzte Szene IST.
func _erste_instanz(node: Node3D) -> Node3D:
	if node.scene_file_path != "":
		return node
	for kind in node.get_children():
		if kind is Node3D:
			var treffer: Node3D = _erste_instanz(kind as Node3D)
			if treffer != null:
				return treffer
	return null


## Transform von `bis`, gerechnet im Raum des Elternknotens von `von` — also genau das, was das
## Teil in der Szene tragen muss, damit es liegt wie im Spiel.
func _kette(von: Node3D, bis: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var lauf: Node = bis
	while lauf != null and lauf != von:
		if lauf is Node3D:
			t = (lauf as Node3D).transform * t
		lauf = lauf.get_parent()
	return von.transform * t
