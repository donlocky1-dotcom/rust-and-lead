extends Node
## Erzeugt fertige Bauteil-Szenen unter `scenes/parts/` — zum Hineinziehen in `Rustwater.tscn`.
##
## Warum das noetig ist: Ein GLB aus dem Dateisystem kommt im ROHMASSSTAB in die Szene. Gemessen
## ist ein Palisadenstueck dann 1,91 m lang und 0,75 m hoch — kniehoch — und sitzt mittig auf dem
## Ursprung, steckt also zur Haelfte im Boden. Wer die Mauer von Hand stellt, muesste jedes
## einzelne Stueck um den Faktor 4,5 skalieren und anheben. Dreissigmal.
##
## Die hier erzeugten Szenen enthalten dasselbe, was `AssetRegistry.instantiate()` zur Laufzeit
## baut: richtige Groesse (`TARGET_HEIGHT` / `TARGET_LENGTH`), Blickrichtung (`YAW_DEG`) und
## tiefster Punkt exakt auf Y = 0. Hineinziehen genuegt.
##
## Aufruf (Projektwurzel `godot/`):
##     godot --headless --path . res://tools/MakeParts.tscn
##
## Neu erzeugen, sobald ein Asset dazukommt oder sich eine Zielgroesse aendert.

const OUT_DIR: String = "res://scenes/parts"

## Alles, was in einer Stadt-Szene von Hand platziert wird. NPCs stehen bewusst nicht dabei:
## die setzt `OverworldView` aus `TOWN_NPCS`, weil an ihnen Quests und Gespraeche haengen.
const PARTS: Array = [
	"saloon", "forge", "water_tower",
	"shack_a", "shack_b", "shack_c", "shack_d",
	"palisade_a", "palisade_b", "palisade_c", "palisade_d", "palisade_e", "gate",
]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var made: int = 0
	var skipped: Array = []
	for name in PARTS:
		if not AssetRegistry.has_model(String(name)):
			skipped.append(name)
			continue
		var holder: Node3D = AssetRegistry.instantiate(String(name), AssetRegistry.height_of(String(name)))
		if holder == null:
			skipped.append(name)
			continue
		holder.name = String(name)
		add_child(holder)
		# `pack()` nimmt nur Knoten mit, deren `owner` die Wurzel ist. Das GLB-Kind behaelt
		# dabei seinen `scene_file_path`, wird also als Verweis gespeichert und nicht kopiert —
		# ein neu aufbereitetes Modell schlaegt so ueberall durch.
		for child in holder.get_children():
			_own(child, holder)
		# Damit `_register_town_node` das Teil ohne Umweg einordnen kann (Wand vs. Gebaeude).
		holder.set_meta("asset", String(name))
		var packed := PackedScene.new()
		if packed.pack(holder) != OK:
			skipped.append(name)
			continue
		var path: String = "%s/%s.tscn" % [OUT_DIR, name]
		if ResourceSaver.save(packed, path) != OK:
			skipped.append(name)
			continue
		var b: AABB = AssetRegistry.local_bounds(holder)
		print("  %-14s %5.2f x %5.2f x %5.2f m   Boden y0 = %+.2f   -> %s"
			% [name, b.size.x, b.size.y, b.size.z, b.position.y, path])
		made += 1
	print("%d Bauteile erzeugt%s" % [made, "" if skipped.is_empty() else ", ohne Modell: %s" % ", ".join(skipped)])
	get_tree().quit()


func _own(node: Node, root: Node) -> void:
	node.owner = root
	# Bei instanzierten Szenen nicht weiter absteigen: Deren Innenleben gehoert der Instanz,
	# nicht unserer Wurzel — sonst wird das Modell in die Bauteil-Szene hineinkopiert.
	if node.scene_file_path != "":
		return
	for child in node.get_children():
		_own(child, root)
