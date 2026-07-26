class_name AssetRegistry extends RefCounted
## AssetRegistry — logischer Name → 3D-Modell, mit Fallback auf Primitives.
##
## Zweck: Assets können **nach und nach** entstehen, ohne dass Szenen-Code sich ändert.
## Jede Stelle im Spiel fragt nur nach einem logischen Namen (z. B. "player", "enemy_outlaw").
## Existiert die Datei, wird das Modell instanziiert; fehlt sie, liefert die Registry `null`
## und der Aufrufer zeichnet seinen Platzhalter. So bleibt das Projekt jederzeit lauffähig.
##
## **Neues Asset einbauen:** Datei unter dem unten eingetragenen Pfad ablegen — fertig.
## Ein Eintrag darf mehrere Kandidaten listen (erster Treffer gewinnt), damit z. B. ein
## eigenes `player.glb` ein Platzhalter-Modell automatisch ablöst.

## Logischer Name → Kandidaten-Pfade (erster existierender gewinnt).
const PATHS: Dictionary = {
	# ── Charaktere (deine kommenden Assets) ──
	"player":          ["res://assets/models/characters/player.glb", "res://assets/models/characters/player.gltf"],
	# ── Gegner (Fallback: Primitive nach Klasse) ──
	"enemy_outlaw":    ["res://assets/models/enemies/outlaw.glb", "res://assets/models/enemies/outlaw.gltf"],
	"enemy_fauna":     ["res://assets/models/enemies/fauna.glb", "res://assets/models/enemies/fauna.gltf"],
	"enemy_revolver":  ["res://assets/models/enemies/revolver.glb", "res://assets/models/enemies/revolver.gltf"],
	"enemy_konstrukt": ["res://assets/models/enemies/konstrukt.glb", "res://assets/models/enemies/konstrukt.gltf"],
	"enemy_klaeffer":  ["res://assets/models/enemies/klaeffer.glb", "res://assets/models/enemies/klaeffer.gltf"],
	"enemy_goliath":   ["res://assets/models/enemies/goliath.glb", "res://assets/models/enemies/goliath.gltf"],
	"companion_dog":   ["res://assets/models/characters/bolzen.glb", "res://assets/models/characters/bolzen.gltf"],
	# ── Umgebung (bereits vorhandene CC0-Modelle) ──
	"rock_small":      ["res://assets/models/environment/sand_rocks_small_01_1k/sand_rocks_small_01_1k.gltf"],
	"rock_boulder":    ["res://assets/models/environment/namaqualand_boulder_03_1k/namaqualand_boulder_03_1k.gltf"],
	"cliff":           ["res://assets/models/environment/namaqualand_cliff_02_1k/namaqualand_cliff_02_1k.gltf"],
	"ground_sand":     ["res://assets/models/environment/gravelly_sand_1k/gravelly_sand_1k.gltf"],
	# ── Props / Items ──
	"chest":           ["res://assets/models/items/treasure_chest_1k/treasure_chest_1k.gltf"],
	"ammo_box":        ["res://assets/models/props/ammo_box_1k/ammo_box_1k.gltf"],
	"tool_cart":       ["res://assets/models/props/tool_cart_1k/tool_cart_1k.gltf"],
	"metal_rack":      ["res://assets/models/props/worn_metal_rack_1k/worn_metal_rack_1k.gltf"],
	"wall_lamp":       ["res://assets/models/props/industrial_wall_lamp_1k/industrial_wall_lamp_1k.gltf"],
	"chemistry_set":   ["res://assets/models/props/chemistry_set_1k/chemistry_set_1k.gltf"],
}

## Gegner-Typ (CombatData.ENEMY_TYPES) → logischer Asset-Name.
static func enemy_asset(type_id: String) -> String:
	return "enemy_" + type_id

## Ist für diesen logischen Namen ein Modell vorhanden?
static func has_model(name: String) -> bool:
	return resolve(name) != ""

## Erster existierender Pfad für den Namen ("" = kein Asset vorhanden → Platzhalter nutzen).
static func resolve(name: String) -> String:
	for path in PATHS.get(name, []):
		if ResourceLoader.exists(path):
			return path
	return ""

## Instanziiert das Modell (oder `null`, wenn keins vorhanden ist).
## `scale_to_height` skaliert das Modell auf eine Zielhöhe in Metern — so passen Assets
## unterschiedlicher Herkunft ohne Nacharbeit in den 1-Unit-=-1-Meter-Maßstab der Welt.
static func instantiate(name: String, scale_to_height: float = 0.0) -> Node3D:
	var path: String = resolve(name)
	if path == "":
		return null
	var packed: Resource = load(path)
	if packed == null or not (packed is PackedScene):
		return null
	var node: Node = (packed as PackedScene).instantiate()
	if not (node is Node3D):
		node.queue_free()
		return null
	var n3: Node3D = node as Node3D
	if scale_to_height > 0.0:
		var h: float = local_height(n3)
		if h > 0.001:
			n3.scale = Vector3.ONE * (scale_to_height / h)
	return n3

## Höhe der zusammengefassten Mesh-Bounds im lokalen Raum von `root` (0.0 = keine Meshes).
## Bequemer Sonderfall von `local_size()` für die häufigste Abfrage (Zielhöhen-Skalierung).
static func local_height(root: Node3D) -> float:
	return local_size(root).y

## Größe (X/Y/Z) der zusammengefassten Mesh-Bounds **im lokalen Raum von `root`**
## (`Vector3.ZERO` = keine Meshes gefunden). Berücksichtigt die komplette Transform-Kette bis
## zu jedem Mesh — glTF-Hierarchien haben oft verschachtelte Rotationen/Skalierungen, die eine
## naive Messung verfälschen würden. Die eigene Transform von `root` bleibt bewusst außen vor,
## damit `instantiate()`/Aufrufer daraus ihren eigenen Skalierungsfaktor bilden können.
static func local_size(root: Node3D) -> Vector3:
	var box: AABB = AABB()
	var found: bool = false
	for entry in _meshes_with_transform(root, Transform3D.IDENTITY, true):
		var a: AABB = (entry[1] as Transform3D) * ((entry[0] as MeshInstance3D).get_aabb())
		box = a if not found else box.merge(a)
		found = true
	return box.size if found else Vector3.ZERO

## Alle MeshInstance3D unter `node` samt ihrer Transform relativ zur Startwurzel.
static func _meshes_with_transform(node: Node, parent_xform: Transform3D, is_root: bool) -> Array:
	var out: Array = []
	var xform: Transform3D = parent_xform
	if node is Node3D and not is_root:
		xform = parent_xform * (node as Node3D).transform
	if node is MeshInstance3D:
		out.append([node, xform])
	for c in node.get_children():
		out.append_array(_meshes_with_transform(c, xform, false))
	return out

## Lädt das erste PBR-Material eines Modells zur Wiederverwendung — z. B. um die Sand-Textur
## eines kleinen CC0-Bodenstücks gekachelt auf eine große Bodenfläche zu legen, statt das
## (oft klobige) Mesh selbst zu benutzen. `BaseMaterial3D` deckt sowohl `StandardMaterial3D`
## als auch `ORMMaterial3D` ab (Godot importiert glTF mit gepackter ARM-Textur als ORM) — beide
## haben `uv1_scale` für Kachelung. `null`, wenn das Modell fehlt oder kein Material trägt.
static func material_from_model(name: String) -> BaseMaterial3D:
	var path: String = resolve(name)
	if path == "":
		return null
	var packed: Resource = load(path)
	if packed == null or not (packed is PackedScene):
		return null
	var node: Node = (packed as PackedScene).instantiate()
	var mat: BaseMaterial3D = null
	for mi in _all_mesh_instances(node):
		var m: Material = mi.get_active_material(0)
		if m is BaseMaterial3D:
			mat = (m as BaseMaterial3D).duplicate()   # eigene Kopie -> uv1_scale verändert nicht das Original
			break
	node.queue_free()
	return mat

static func _all_mesh_instances(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(_all_mesh_instances(c))
	return out
