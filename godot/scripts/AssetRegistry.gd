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
	# ── NPCs (Story-Bibel §4, Rustwater) ──
	"npc_mabel":       ["res://assets/models/npcs/mabel.glb"],
	"npc_silas":       ["res://assets/models/npcs/silas.glb"],
	"npc_doc":         ["res://assets/models/npcs/doc.glb"],
	# ── Gebäude (Rustwater, GDD §1.6/§2.3) ──
	"saloon":          ["res://assets/models/buildings/saloon.glb"],
	"forge":           ["res://assets/models/buildings/forge.glb"],
	"shack_a":         ["res://assets/models/buildings/shack_a.glb"],
	"shack_b":         ["res://assets/models/buildings/shack_b.glb"],
	"shack_c":         ["res://assets/models/buildings/shack_c.glb"],
	"shack_d":         ["res://assets/models/buildings/shack_d.glb"],
	"water_tower":     ["res://assets/models/buildings/water_tower.glb"],
	"gate":            ["res://assets/models/buildings/gate.glb"],
	"palisade_a":      ["res://assets/models/buildings/palisade_a.glb"],
	"palisade_b":      ["res://assets/models/buildings/palisade_b.glb"],
	"palisade_c":      ["res://assets/models/buildings/palisade_c.glb"],
	"palisade_d":      ["res://assets/models/buildings/palisade_d.glb"],
	"palisade_e":      ["res://assets/models/buildings/palisade_e.glb"],
	# ── Waffen (CombatData.WEAPONS) ──
	"weapon_karabiner": ["res://assets/models/weapons/karabiner.glb"],
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

## Zielhöhe je Asset in Metern — die EINE Stelle, an der die Größenverhältnisse der Welt
## stehen. Vorher trug die Szene eine feste 1,6 für jeden Gegner, was spätestens beim ersten
## Fahrzeug falsch wird: ein Panzer ist kein 1,6-m-Mensch. `height_of()` liefert den Wert,
## die Szene fragt nur noch nach dem Namen.
const TARGET_HEIGHT: Dictionary = {
	"player": 1.8,
	"companion_dog": 0.7,        # Bolzen, der Blechhund
	"enemy_outlaw": 1.6,         # Grenzgänger (organisch)
	"enemy_revolver": 1.6,       # Revolverheld
	"enemy_fauna": 0.6,          # Ölfresser-Ratte (Schwarm)
	"enemy_klaeffer": 0.8,       # Kessel-Kläffer (Maschine, Schwarm)
	"enemy_konstrukt": 2.0,      # Konzern-Konstrukt / kleiner Panzer — überragt den Spieler
	"enemy_goliath": 4.0,        # Schwerer Ernter (Boss)
	"chest": 0.7,
	# ── NPCs: Körpergrößen aus der Story-Bibel (§4) ──
	"npc_mabel": 1.70,           # stämmig, Mitte fünfzig
	"npc_silas": 1.75,
	"npc_doc": 1.80,             # hager und hochgewachsen
	# ── Gebäude ──
	# Generatoren normieren jedes Modell auf dieselbe Kantenlänge; die Proportionen stimmen,
	# der Maßstab ist beliebig. Gesetzt wird deshalb die HÖHE — die ist bei einem Haus die
	# Größe, an der das Auge misst (Türhöhe, Stockwerke im Verhältnis zur 1,8-m-Figur).
	# Die Grundfläche folgt aus den Proportionen und wird gemessen, nicht geraten.
	"saloon": 8.5,               # zweistöckig mit Scheinfassade
	"forge": 7.0,                # niedrig und breit, hoher Schornstein
	"shack_a": 4.5, "shack_b": 4.2, "shack_c": 4.0, "shack_d": 5.2,   # vier Bauweisen
	"water_tower": 18.0,         # Silhouette, die man vor der Stadt sieht
	"gate": 6.0,
	"palisade_a": 3.4, "palisade_b": 3.4, "palisade_c": 3.4,
	"palisade_d": 3.4, "palisade_e": 3.4,
}
const TARGET_HEIGHT_DEFAULT: float = 1.6

## Assets, die über ihre **längste** Kante skaliert werden statt über die Höhe. Ein Karabiner
## ist 40 cm hoch und einen Meter lang — auf 1 m Höhe skaliert wäre er fast fünf Meter lang.
## Alles Langgestreckte (Waffen, Balken, Rohre) gehört hierher.
const TARGET_LENGTH: Dictionary = {
	"weapon_karabiner": 1.0,
}

## Zielhöhe eines Assets in Metern (Rückfall: menschengroß).
static func height_of(name: String) -> float:
	return float(TARGET_HEIGHT.get(name, TARGET_HEIGHT_DEFAULT))

## Blickrichtungs-Korrektur je Asset (Grad um Y). Godot-Konvention ist „vorne = −Z"; viele
## Generatoren (Meshy, Sketchfab-Rips, ältere FBX-Ketten) exportieren nach +Z oder +X. Statt
## jede Datei in Blender zu drehen, steht die Korrektur hier — eine Zahl pro Asset.
const YAW_DEG: Dictionary = {
	# Gemessen an der Geometrie: Zehen und Gesicht des Spieler-Modells zeigen nach +Z,
	# Godot läuft nach −Z. Ohne die Drehung würde die Figur rückwärts durch die Wüste laufen.
	"player": 180.0,
	# Dieselbe Herkunft, dasselbe Rig, dieselbe Blickrichtung — die NPCs schauten sonst
	# von ihrem Platz weg statt auf den Stadtplatz.
	"npc_mabel": 180.0, "npc_silas": 180.0, "npc_doc": 180.0,
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

## Instanziiert das Modell (oder `null`, wenn keins vorhanden ist) — **einbaufertig**:
##  • `scale_to_height` skaliert auf eine Zielhöhe in Metern (1 Unit = 1 m, GDD §1.4),
##  • die Unterkante wird auf Y = 0 gelegt (`snap_to_floor`) — egal wohin der Exporter den
##    Pivot gesetzt hat; ohne das schwebt oder versinkt jedes zweite generierte Modell,
##  • `YAW_DEG` dreht die Blickrichtung auf Godots −Z.
## Damit ist ein zugekauftes oder generiertes Asset ohne Nacharbeit in Blender benutzbar.
## Beim Snappen kommt das Modell in einen Halter-Node: der Aufrufer darf `position` und
## `rotation` frei setzen, ohne die Bodenkorrektur zu überschreiben.
static func instantiate(name: String, scale_to_height: float = 0.0, snap_to_floor: bool = true) -> Node3D:
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
	var bounds: AABB = local_bounds(n3)
	var factor: float = 1.0
	var by_length: float = float(TARGET_LENGTH.get(name, 0.0))
	if by_length > 0.0:
		# Langgestrecktes misst sich an der längsten Kante, nicht an der Höhe.
		var longest: float = maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
		if longest > 0.001:
			factor = by_length / longest
			n3.scale = Vector3.ONE * factor
	elif scale_to_height > 0.0 and bounds.size.y > 0.001:
		factor = scale_to_height / bounds.size.y
		n3.scale = Vector3.ONE * factor
	var yaw: float = float(YAW_DEG.get(name, 0.0))
	if not is_zero_approx(yaw):
		n3.rotation.y = deg_to_rad(yaw)
	if not snap_to_floor or bounds.size.y <= 0.001:
		n3.set_meta("asset_name", name)
		return n3
	var holder := Node3D.new()
	holder.name = "asset_" + name
	holder.set_meta("asset_name", name)   # `play_clip` findet darüber die feste Clip-Zuordnung
	holder.add_child(n3)
	n3.position.y = -bounds.position.y * factor   # tiefster Punkt exakt auf Y = 0
	return holder

## Höhe der zusammengefassten Mesh-Bounds im lokalen Raum von `root` (0.0 = keine Meshes).
## Bequemer Sonderfall von `local_size()` für die häufigste Abfrage (Zielhöhen-Skalierung).
static func local_height(root: Node3D) -> float:
	return local_size(root).y

## Größe (X/Y/Z) der zusammengefassten Mesh-Bounds im lokalen Raum von `root`
## (`Vector3.ZERO` = keine Meshes gefunden).
static func local_size(root: Node3D) -> Vector3:
	return local_bounds(root).size

## Zusammengefasste Mesh-Bounds **im lokalen Raum von `root`** (leere AABB = keine Meshes).
## Berücksichtigt die komplette Transform-Kette bis zu jedem Mesh — glTF-Hierarchien haben oft
## verschachtelte Rotationen/Skalierungen, die eine naive Messung verfälschen würden. Die eigene
## Transform von `root` bleibt bewusst außen vor, damit `instantiate()`/Aufrufer daraus ihren
## eigenen Skalierungs- und Boden-Versatz bilden können.
static func local_bounds(root: Node3D) -> AABB:
	var box: AABB = AABB()
	var found: bool = false
	for entry in _meshes_with_transform(root, Transform3D.IDENTITY, true):
		var mi: MeshInstance3D = entry[0]
		var xform: Transform3D = (entry[1] as Transform3D) * _skin_transform(mi)
		var a: AABB = xform * mi.get_aabb()
		box = a if not found else box.merge(a)
		found = true
	return box if found else AABB()


## Abbildung **Mesh-Raum → Skelettraum** des ersten gehäuteten Meshes unter `root`.
##
## Das ist der Raum, in dem das Charakter-Mesh modelliert wurde. Wer etwas an einen Knochen
## hängt (Waffe in die Hand, Hut auf den Kopf), braucht genau diese Abbildung: das Rig steht
## bei generierten Modellen in Zentimetern, das Anbauteil in Metern, und dazu kommt die
## Skalierung der Figur auf ihre Zielhöhe. Die Bindepose trägt alle drei Faktoren.
static func mesh_to_skeleton(root: Node) -> Transform3D:
	for mi in mesh_instances(root):
		if (mi as MeshInstance3D).skin != null:
			return _skin_transform(mi)
	return Transform3D.IDENTITY


## Zusatz-Transform für **gehäutete** Meshes (Identität bei allem anderen).
##
## Bei einem gehäuteten Mesh bestimmt nicht die Knotenkette die Lage — glTF ignoriert die
## Transform eines solchen Knotens ausdrücklich; platziert wird über das Skelett. Rigs aus
## Generatoren stehen dabei oft in **Zentimetern** an einem Armature-Knoten mit Skalierung 0,01;
## die Bindepose rechnet den Faktor 100 wieder heraus. Wer nur die Knotenkette misst, sieht
## deshalb ein 100-fach zu kleines Modell — und skaliert es beim Einbau 100-fach zu groß.
##
## `Knochen-Ruhelage × Bindepose` bildet exakt vom Mesh-Raum in den Skelettraum ab; das ist
## die Definition der Bindepose und gilt für jeden Knochen gleichermaßen.
static func _skin_transform(mi: MeshInstance3D) -> Transform3D:
	if mi.skin == null or mi.skin.get_bind_count() == 0:
		return Transform3D.IDENTITY
	var skel: Skeleton3D = mi.get_node_or_null(mi.skeleton) as Skeleton3D
	if skel == null:
		return Transform3D.IDENTITY
	var idx: int = mi.skin.get_bind_bone(0)
	var bind_name: String = mi.skin.get_bind_name(0)
	if bind_name != "":
		idx = skel.find_bone(bind_name)
	if idx < 0 or idx >= skel.get_bone_count():
		return Transform3D.IDENTITY
	return skel.get_bone_global_rest(idx) * mi.skin.get_bind_pose(0)

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

# ── Skelett & Anbauteile ──────────────────────────────────────────────────────

## Erstes Skelett unter `root` (glTF-Import legt es als `Skeleton3D` an), sonst `null`.
static func skeleton(root: Node) -> Skeleton3D:
	if root == null:
		return null
	if root is Skeleton3D:
		return root as Skeleton3D
	for c in root.get_children():
		var found: Skeleton3D = skeleton(c)
		if found != null:
			return found
	return null


# ── Animationen ───────────────────────────────────────────────────────────────
## Clip-Namen kommen aus jedem Werkzeug anders („Walking", „Armature|walk", „CharacterArmature|Walk",
## „laufen"). Statt jeden Export von Hand umzubenennen, sucht die Registry über **Namensteile**:
## logische Rolle → mögliche Bestandteile des Clip-Namens (klein geschrieben, Teiltreffer).
## Neues Werkzeug mit anderer Benennung = ein Wort hier ergänzen, kein Szenen-Code.
const CLIP_ALIASES: Dictionary = {
	"idle":   ["idle", "stand", "breath", "ruhe", "atmen"],
	"walk":   ["walk", "lauf", "gehen", "move", "locomotion"],
	"run":    ["run", "sprint", "renn", "jog"],
	"attack": ["attack", "shoot", "fire", "punch", "angriff", "schuss", "schlag"],
	"hit":    ["hit", "impact", "damage", "flinch", "treffer"],
	"death":  ["death", "die", "dead", "sterb", "tod"],
}

## Feste Clip-Zuordnung je Asset, wo die Namenssuche raten müsste. Ein Animations-Paket
## enthält oft zwanzig Varianten („Rifle_Aim_Turn_Right", „Run_and_Shoot", „Knock_Down_1");
## welche davon *die* Angriffs- oder Treffer-Animation ist, steht in keinem Namen. Also hier —
## an einer Stelle, nachlesbar, ohne dass jemand Dateien umbenennt.
const CLIP_OVERRIDES: Dictionary = {
	"player": {
		"idle": "Idle_11", "walk": "Walking", "run": "Running",
		"attack": "Run_and_Shoot", "hit": "Shot_and_Blown_Back", "death": "Dead",
	},
	# Die drei Rustwater-NPCs teilen dasselbe Animationspaket. `Stand_and_Chat` ist die
	# Ruhepose für jemanden, der an seinem Platz steht und mit Leuten redet — die Namenssuche
	# fände sie zwar auch, aber bei „Stand_Talking_Angry" daneben soll nichts dem Zufall
	# überlassen bleiben.
	"npc_mabel": { "idle": "Stand_and_Chat", "walk": "Walking", "run": "Running" },
	"npc_silas": { "idle": "Stand_and_Chat", "walk": "Walking", "run": "Running" },
	"npc_doc":   { "idle": "Stand_and_Chat", "walk": "Walking", "run": "Running" },
}

## Erster AnimationPlayer unter `root` (glTF legt ihn beim Import automatisch an), sonst `null`.
static func animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for c in root.get_children():
		var found: AnimationPlayer = animation_player(c)
		if found != null:
			return found
	return null

## Tatsächlicher Clip-Name für eine logische Rolle ("" = dieses Modell hat sie nicht).
## Exakter Treffer schlägt Teiltreffer; unter mehreren Teiltreffern gewinnt der **kürzeste** Name.
## Das ist die entscheidende Regel bei Animations-Paketen: neben „Walking" liegen dort
## „Slow_Walk_Reload" und „Walk_Turn_Left_with_Weapon" — gemeint ist immer der schlichte Clip.
static func find_clip(ap: AnimationPlayer, kind: String) -> String:
	if ap == null:
		return ""
	var parts: Array = CLIP_ALIASES.get(kind, [kind])
	var best: String = ""
	var best_len: int = 0
	for raw in ap.get_animation_list():
		var name: String = String(raw)
		var tail: String = name.get_slice("|", name.get_slice_count("|") - 1).to_lower()
		for p in parts:
			if tail == String(p):
				return name
			if tail.contains(String(p)) and (best == "" or tail.length() < best_len):
				best = name
				best_len = tail.length()
	return best

## Spielt die Rolle (`"walk"`, `"idle"`, …) auf dem Modell ab. Läuft der Clip schon, passiert
## nichts — der Aufruf darf also gefahrlos jeden Frame kommen. `false`, wenn das Modell die
## Rolle nicht kennt (dann bleibt es einfach unanimiert stehen; nichts bricht).
static func play_clip(root: Node, kind: String, loop: bool = true) -> bool:
	var ap: AnimationPlayer = animation_player(root)
	if ap == null:
		return false
	var clip: String = ""
	if root.has_meta("asset_name"):
		clip = String(CLIP_OVERRIDES.get(String(root.get_meta("asset_name")), {}).get(kind, ""))
		if clip != "" and not ap.has_animation(clip):
			clip = ""   # Asset ausgetauscht und der Clip heißt jetzt anders — dann eben suchen
	if clip == "":
		clip = find_clip(ap, kind)
	if clip == "":
		return false
	if ap.current_animation == clip and ap.is_playing():
		return true
	var anim: Animation = ap.get_animation(clip)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	ap.play(clip)
	return true

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
	for mi in mesh_instances(node):
		var m: Material = mi.get_active_material(0)
		if m is BaseMaterial3D:
			mat = (m as BaseMaterial3D).duplicate()   # eigene Kopie -> uv1_scale verändert nicht das Original
			break
	node.queue_free()
	return mat

## Alle MeshInstance3D unter `node` (flach, ohne Transformationen) — für Material-Eingriffe.
static func mesh_instances(node: Node) -> Array:
	var out: Array = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(mesh_instances(c))
	return out
