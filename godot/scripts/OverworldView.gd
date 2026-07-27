class_name OverworldView extends Node3D
## OverworldView — begehbarer Kraterboden im Produktions-Maßstab (Master-GDD §1.4/§1.6).
##
## Erste sichtbare Szene des Godot-Ports (Xogot-/Editor-tauglich, nur Primitives — keine
## Assets, lädt sofort). Alles wird zur Laufzeit aus den kanonischen `WorldManager`-Daten
## generiert: 5000×5000-m-Boden, Biom-Zonen, Sektor-Linien (Sprengtore/Smog), Kraterrand
## mit Rand-Tunnel, alle POIs als Landmarken. Dazu ein steuerbarer Spieler (4,7 m/s,
## virtueller Joystick + Tastatur), ein Gegner-Rudel bei Rustwater und Auto-Feuer über
## die ECHTEN Systeme (PlayerStats → CombatEngine → CombatTarget → GameState-XP/Gold).
## Truhen rollen echte Ausrüstung über `ProgressionManager`/`EquipManager` aus — Kämpfen wirkt
## sich dadurch sofort auf den nächsten Schuss aus (PlayerStats liest live aus GameState.equip).

const AGGRO_M: float = 45.0          # Gegner erwachen in dieser Distanz
const SHOOT_RANGE_M: float = 32.0    # Auto-Ziel-Reichweite des Spielers
const CONTACT_RANGE_M: float = 2.2   # Nahkampf-Kontakt
const ENEMY_SPEED_MS: float = 3.4    # Rudel etwas langsamer als der Spieler (4,7)
## Spawn liegt neben, nicht auf der Rustwater-Landmarken-Säule (die am exakten POI-Punkt steht).
const RUSTWATER_SPAWN_OFFSET: Vector3 = Vector3(0.0, 0.0, 25.0)   # 25 m südlich der Säule

# ── Kontinuierliches Spawning (echter Biom-Gegnermix aus WorldManager) ────────
const ENEMY_MAX: int = 10
const SPAWN_INTERVAL_SEC: float = 6.0
const SPAWN_MIN_DIST: float = 140.0
const SPAWN_MAX_DIST: float = 300.0

# ── Waffen (alle vier Schadensarten testbar — Kapitel-Gating folgt später über
# das Quest-/Reveal-System; dieser Sandbox-Screen ist bewusst ungesperrt). ────
const WEAPON_ORDER: Array = ["karabiner", "voltgun", "saeure", "brenner"]
const WEAPON_ICON: Dictionary = { "karabiner": "🔫", "voltgun": "⚡", "saeure": "🧪", "brenner": "🔥" }
const TRACER_COLOR: Dictionary = {
	"karabiner": Color(0.98, 0.75, 0.14), "voltgun": Color(0.35, 0.75, 0.98),
	"saeure": Color(0.55, 0.85, 0.25), "brenner": Color(0.95, 0.42, 0.15),
}

# ── Truhen: echte Ausrüstung über ProgressionManager/EquipManager (Diablo-Loot-Achse) ──
const CHEST_INTERACT_M: float = 2.5
const CHEST_MAX: int = 3
const CHEST_SPAWN_INTERVAL_SEC: float = 15.0
const CHEST_MIN_DIST: float = 40.0
const CHEST_MAX_DIST: float = 220.0
const CHEST_RARITY_BIAS: float = 0.3   # etwas höher als Basis-Gegner-Loot -> Truhen lohnen sich

# ── Persistenz (SaveManager, seit Phase 2 fertig — hier zum ersten Mal an eine Szene
# angeschlossen): Slot 0 als laufender Spielstand dieser Sandbox. ──────────────
const SAVE_SLOT: int = 0
const AUTOSAVE_INTERVAL_SEC: float = 10.0

## Rustwater ist Schutzzone: innerhalb dieses Radius spawnt nichts Feindliches und es
## wird kein Dekor gestreut — die Stadt bleibt Stadt (GDD §1.6: befriedete Hubs).
const TOWN_SAFE_M: float = 95.0

## Schnellreise-Ziele (Tasten 1–5) — nur echte Hubs, passend zu GDD §1.4.
const FAST_TRAVEL: Array = ["rustwater", "zugdepot", "fort_freedom", "rogues_landing", "sektor01"]

func _in_town(pos: Vector3) -> bool:
	return pos.distance_to(WorldManager.poi_scene_position("rustwater")) < TOWN_SAFE_M

var _player: Node3D
var _cam: Camera3D
var _hp: float = 100.0
var _fire_cd: float = 0.0
var _spawn_cd: float = SPAWN_INTERVAL_SEC * 0.5   # erster Nachschub etwas früher
var _weapon_id: String = "karabiner"
var _enemies: Array = []             # { node, target: CombatTarget, bar: MeshInstance3D }
var _chests: Array = []              # { node, label, pos: Vector3 }
var _chest_spawn_cd: float = 3.0      # erste Truhe erscheint schnell
var _hud: Label
var _minimap: Minimap
var _toast: Label
var _toast_until: float = 0.0
var _touch_id: int = -1
var _touch_start: Vector2 = Vector2.ZERO
var _touch_vec: Vector2 = Vector2.ZERO
var _save_loaded: bool = false
var _save_cd: float = AUTOSAVE_INTERVAL_SEC


func _ready() -> void:
	_load_or_init_save()   # vor allem Weiteren: GameState (Level/Gold/Ausrüstung) korrekt setzen
	_build_environment()
	_build_ground_and_biomes()
	_build_sector_lines_and_rim()
	_build_roads()
	_build_pois()
	_build_township()
	_scatter_decor()
	_build_player()
	_build_hud()
	_spawn_pack()
	_spawn_chest_near(_rustwater_spawn() + Vector3(-18.0, 0.0, 14.0))
	_hp = float(PlayerStats.max_hp())
	if _save_loaded:
		_say("💾 Spielstand geladen — Lv %d · %d 💰 · 🎽 %d/%d   [Tab] Waffe" % [
			GameState.level, GameState.gold, EquipManager.worn().size(), EquipManager.GEAR_SLOTS.size()], 4.0)
	else:
		_say("🤠 Willkommen im Krater — 5000 m Kante zu Kante. [Tab] wechselt die Waffe.", 5.0)


## Lädt den laufenden Spielstand (falls vorhanden), BEVOR irgendetwas anderes GameState liest
## (Leben/Schaden hängen an Level & Ausrüstung). Reine GameState-Mutation, keine Szenen-Abhängigkeit.
func _load_or_init_save() -> void:
	_save_loaded = SaveManager.has_slot(SAVE_SLOT)
	if _save_loaded:
		SaveManager.load_from_slot(SAVE_SLOT)


## Schreibt den Spielstand in festem Takt weg (Gold/Level/Ausrüstung/Kills — alles, was
## SaveManager.serialize() abdeckt). Reine Datei-I/O, kein Einfluss auf die laufende Szene.
func _process_autosave(delta: float) -> void:
	_save_cd -= delta
	if _save_cd <= 0.0:
		_save_cd = AUTOSAVE_INTERVAL_SEC
		SaveManager.save_to_slot(SAVE_SLOT)


# ── Weltaufbau ────────────────────────────────────────────────────────────────

func _mat(color: Color, unshaded: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(size: Vector3, pos: Vector3, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color, false, alpha)
	mi.position = pos
	add_child(mi)
	return mi


## Echte Sand-PBR-Textur (Diffuse/Normal/ARM aus "ground_sand"), über die gesamte Fläche
## gekachelt — Kachelgröße wird aus den tatsächlichen Modell-Bounds abgeleitet (kein geratener
## Wert). Fällt auf die alte Einheitsfarbe zurück, solange kein Asset vorhanden ist.
func _ground_material() -> BaseMaterial3D:
	var mat: BaseMaterial3D = AssetRegistry.material_from_model("ground_sand")
	if mat == null:
		return _mat(Color(0.76, 0.64, 0.42))
	var tile_m: float = 2.5
	var probe: Node3D = AssetRegistry.instantiate("ground_sand")
	if probe != null:
		var sz: Vector3 = AssetRegistry.local_size(probe)
		tile_m = maxf(sz.x, sz.z)
		probe.queue_free()
	var repeats: float = WorldManager.WORLD_METERS / maxf(tile_m, 0.1)
	mat.uv1_scale = Vector3(repeats, repeats, 1.0)
	return mat


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_energy = 1.15
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.55, 0.42)   # grüner Bronzehimmel (Story-Bibel)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.62)
	env.ambient_light_energy = 0.8
	we.environment = env
	add_child(we)


func _build_ground_and_biomes() -> void:
	var half: float = WorldManager.WORLD_METERS / 2.0
	# Kraterboden: Wüsten-Sand über die volle Produktionsfläche.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(WorldManager.WORLD_METERS, WorldManager.WORLD_METERS)
	ground.mesh = plane
	ground.material_override = _ground_material()
	ground.position = Vector3(half, 0.0, -half)
	add_child(ground)
	# Benannte Biom-Kreiszonen (WorldManager.BIOMES) als getönte Scheiben.
	var tint: Dictionary = {
		"oasis": Color(0.31, 0.56, 0.31), "salt": Color(0.85, 0.84, 0.78),
		"rostwald": Color(0.54, 0.29, 0.18), "kupfer_hochland": Color(0.61, 0.42, 0.24),
	}
	for id in WorldManager.BIOME_ZONE_ORDER:
		var b: Dictionary = WorldManager.BIOMES[id]
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		var r_m: float = float(b["radius"]) * WorldManager.METERS_PER_UNIT
		cyl.top_radius = r_m
		cyl.bottom_radius = r_m
		cyl.height = 0.3
		disc.mesh = cyl
		disc.material_override = _mat(tint[id])
		disc.position = WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))) + Vector3(0.0, 0.15, 0.0)
		add_child(disc)
	# Smog-Senke: alles nördlich der Smog-Linie liegt unter giftgrünem Schleier.
	var smog_depth_m: float = (float(WorldManager.WORLD_SIZE) - float(WorldManager.SMOG_LINE_Y)) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT + smog_depth_m / 2.0)
	_box(Vector3(WorldManager.WORLD_METERS, 0.4, smog_depth_m), Vector3(half, 0.35, smog_z), Color(0.35, 0.65, 0.30), 0.35)


func _build_sector_lines_and_rim() -> void:
	var w: float = WorldManager.WORLD_METERS
	var half: float = w / 2.0
	var blast_z: float = -float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT
	# Gate 1 — Iron-Rail-Sprengtore (dunkle Stahlwand quer über den Krater).
	_box(Vector3(w, 22.0, 5.0), Vector3(half, 11.0, blast_z), Color(0.24, 0.16, 0.13))
	_label(Vector3(half, 30.0, blast_z), "⛔ IRON-RAIL-SPRENGTORE", Color(1.0, 0.55, 0.35), 150, 600.0)
	# Gate 2 — Smog-Linie (durchscheinend, giftgrün).
	_box(Vector3(w, 28.0, 4.0), Vector3(half, 14.0, smog_z), Color(0.35, 0.75, 0.30), 0.45)
	_label(Vector3(half, 38.0, smog_z), "☣ SMOG-LINIE", Color(0.6, 1.0, 0.5), 150, 600.0)
	# Kraterrand: 350 m Fels an allen vier Horizonten — die diegetische Außengrenze.
	var rock := Color(0.28, 0.22, 0.18)
	_box(Vector3(w + 300.0, 350.0, 150.0), Vector3(half, 175.0, 75.0), rock)            # Süd
	_box(Vector3(w + 300.0, 350.0, 150.0), Vector3(half, 175.0, -w - 75.0), rock)       # Nord
	_box(Vector3(150.0, 350.0, w + 300.0), Vector3(-75.0, 175.0, -half), rock)          # West
	_box(Vector3(150.0, 350.0, w + 300.0), Vector3(w + 75.0, 175.0, -half), rock)       # Ost
	# Rand-Tunnel (§1.7.4): das eine, verriegelte Tor durch die Nordwand.
	_box(Vector3(60.0, 80.0, 40.0), Vector3(half, 40.0, -w - 20.0), Color(0.08, 0.07, 0.06))
	_label(Vector3(half, 95.0, -w + 5.0), "🚪 RAND-TUNNEL (verriegelt)", Color(0.95, 0.85, 0.6), 130, 500.0)


## Schwebende Beschriftung. Höhe in Weltmetern = font_size × pixel_size; mit LABEL_PIXEL
## ergibt `size` also grob die Zeichenhöhe in Zentimetern (150 ≈ 1,8 m) — vorher waren es
## 7,5 m, was die Szene zugepflastert hat. `fade_m` blendet die Schrift auf Distanz aus,
## damit ferne POI-Namen nicht über der halben Karte kleben.
const LABEL_PIXEL: float = 0.012

func _label(pos: Vector3, text: String, color: Color, size: int = 120, fade_m: float = 260.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = LABEL_PIXEL
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = maxi(1, int(size / 10.0))
	l.position = pos
	if fade_m > 0.0:
		l.visibility_range_end = fade_m
		l.visibility_range_end_margin = fade_m * 0.2
	add_child(l)
	return l


func _build_pois() -> void:
	var sector_color: Dictionary = {
		1: Color(0.83, 0.63, 0.27), 2: Color(0.36, 0.56, 0.83), 3: Color(0.78, 0.30, 0.24) }
	for id in WorldManager.POIS.keys():
		var p: Dictionary = WorldManager.POIS[id]
		var pos: Vector3 = WorldManager.poi_scene_position(id)
		var col: Color = sector_color[int(p["sector"])]
		if id == "eisernes_herz":
			# Zentrale Landmarke: hoher, dunkler Turm — von überall am Horizont sichtbar.
			# Der Turm trägt die Fernsicht; die Schrift bleibt dezent und blendet früher aus.
			_box(Vector3(120.0, 420.0, 120.0), pos + Vector3(0.0, 210.0, 0.0), Color(0.15, 0.13, 0.14))
			_label(pos + Vector3(0.0, 445.0, 0.0), "🖤 " + String(p["name"]), Color(1.0, 0.45, 0.35), 220, 900.0)
			continue
		var pillar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 4.0
		cyl.bottom_radius = 6.0
		cyl.height = 36.0
		pillar.mesh = cyl
		pillar.material_override = _mat(col)
		pillar.position = pos + Vector3(0.0, 18.0, 0.0)
		add_child(pillar)
		_label(pos + Vector3(0.0, 41.0, 0.0), String(p["name"]), col.lightened(0.35), 130, 420.0)


## Handelsrouten zwischen den großen Knoten — gestampfte Pisten als flache Bänder auf dem
## Sand. Gibt der leeren Weite Struktur und macht Landmark-Navigation lesbar (GDD §1.4):
## man folgt einer Straße, statt blind über 5000 m zu peilen.
const ROUTES: Array = [
	["rustwater", "rattengestruepp"], ["rustwater", "schrott_minen"], ["rustwater", "zugdepot"],
	["zugdepot", "rogues_landing"], ["rogues_landing", "fort_freedom"],
	["rogues_landing", "sektor01"], ["rogues_landing", "alchemie_raffinerie"],
	["fort_freedom", "goliath_testgelaende"], ["sektor01", "schmelzoefen_vulcan"],
	["alchemie_raffinerie", "eisernes_herz"],
]

func _build_roads() -> void:
	var road_col := Color(0.56, 0.46, 0.32)   # festgefahrener, hellerer Staub
	for r in ROUTES:
		var a: Vector3 = WorldManager.poi_scene_position(String(r[0]))
		var b: Vector3 = WorldManager.poi_scene_position(String(r[1]))
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(9.0, 0.12, a.distance_to(b))
		seg.mesh = bm
		seg.material_override = _mat(road_col)
		seg.position = (a + b) / 2.0 + Vector3(0.0, 0.06, 0.0)   # knapp über dem Boden
		seg.look_at_from_position(seg.position, b, Vector3.UP)
		add_child(seg)


## Rustwater als begehbare Township (GDD §1.6/§2.3: Saloon, Schmiede, Destille, Labor +
## Wohnhäuser + Palisade). Bewusst aus Primitives gebaut — so steht die Stadt schon jetzt,
## und die Blender-Module können sie später Stück für Stück ersetzen (AssetRegistry-Prinzip).
func _build_township() -> void:
	var c: Vector3 = WorldManager.poi_scene_position("rustwater")
	# Kernbauten: Name, Winkel um das Zentrum, Distanz, Grundfläche, Höhe, Farbe.
	var core: Array = [
		["🍺 Gatling-Saloon", 25.0, 34.0, Vector2(16.0, 11.0), 7.5, Color(0.45, 0.28, 0.16)],
		["🔨 Schmiede", 110.0, 32.0, Vector2(12.0, 10.0), 6.0, Color(0.36, 0.30, 0.27)],
		["🥃 Destille", 195.0, 33.0, Vector2(11.0, 9.0), 6.5, Color(0.40, 0.34, 0.20)],
		["⚗ Alchemie-Labor", 285.0, 34.0, Vector2(12.0, 10.0), 6.0, Color(0.30, 0.36, 0.31)],
	]
	for b in core:
		var ang: float = deg_to_rad(float(b[1]))
		var d: float = float(b[2])
		var fp: Vector2 = b[3]
		var h: float = float(b[4])
		var pos: Vector3 = c + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		_box(Vector3(fp.x, h, fp.y), pos + Vector3(0.0, h / 2.0, 0.0), b[5])
		_box(Vector3(fp.x + 1.6, 0.6, fp.y + 1.6), pos + Vector3(0.0, h + 0.3, 0.0), Color(0.24, 0.19, 0.15))   # Dachkante
		_label(pos + Vector3(0.0, h + 2.4, 0.0), String(b[0]), Color(0.98, 0.90, 0.72), 95, 150.0)
	# Wohnhäuser: schlichter Ring aus kleinen Hütten, deterministisch gesetzt.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	for i in 10:
		var ang: float = deg_to_rad(float(i) * 36.0 + 18.0)
		var d: float = rng.randf_range(52.0, 68.0)
		var w: float = rng.randf_range(5.0, 8.0)
		var h: float = rng.randf_range(3.4, 4.8)
		var pos: Vector3 = c + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		_box(Vector3(w, h, w * 0.85), pos + Vector3(0.0, h / 2.0, 0.0), Color(0.42, 0.33, 0.24))
	# Wasserturm — die Silhouette, an der man Rustwater von weitem erkennt.
	var tw: Vector3 = c + Vector3(-26.0, 0.0, -22.0)
	for leg in [Vector3(-3.0, 0.0, -3.0), Vector3(3.0, 0.0, -3.0), Vector3(-3.0, 0.0, 3.0), Vector3(3.0, 0.0, 3.0)]:
		_box(Vector3(0.8, 14.0, 0.8), tw + leg + Vector3(0.0, 7.0, 0.0), Color(0.33, 0.27, 0.22))
	_box(Vector3(9.0, 6.0, 9.0), tw + Vector3(0.0, 17.0, 0.0), Color(0.48, 0.38, 0.26))
	_label(tw + Vector3(0.0, 22.0, 0.0), "RUSTWATER", Color(0.95, 0.82, 0.55), 120, 350.0)
	# Palisade: unterbrochener Ring aus Pfosten (Durchlässe bleiben begehbar).
	for i in 48:
		if i % 6 == 0:
			continue   # Torlücken
		var ang: float = deg_to_rad(float(i) * 7.5)
		var pos: Vector3 = c + Vector3(cos(ang) * 84.0, 0.0, sin(ang) * 84.0)
		_box(Vector3(1.0, 3.2, 1.0), pos + Vector3(0.0, 1.6, 0.0), Color(0.34, 0.26, 0.19))


func _scatter_decor() -> void:
	## Streut vorhandene CC0-Umgebungsmodelle um Rustwater — beweist die Asset-Pipeline und
	## gibt der Wüste Maßstab. Nur nahe dem Startbereich (der Rest der 5000 m folgt via
	## Streaming/LOD, GDD §1.4). Deterministisch, damit die Welt bei jedem Start gleich aussieht.
	var kinds: Array = ["rock_small", "rock_boulder", "cliff"]
	var available: Array = []
	for k in kinds:
		if AssetRegistry.has_model(k):
			available.append(k)
	if available.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var origin: Vector3 = WorldManager.poi_scene_position("rustwater")
	for i in 90:
		var kind: String = available[rng.randi_range(0, available.size() - 1)]
		var height: float = 1.2 if kind == "rock_small" else (3.5 if kind == "rock_boulder" else 9.0)
		var rock: Node3D = AssetRegistry.instantiate(kind, height * rng.randf_range(0.7, 1.5))
		if rock == null:
			continue
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(TOWN_SAFE_M + 15.0, 700.0)   # außerhalb der Stadt
		var pos: Vector3 = origin + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		# Nicht in die Smog-Zone streuen und im Kraterbecken bleiben.
		pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
		pos.z = clampf(pos.z, -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT), -20.0)
		if _in_town(pos):
			rock.queue_free()
			continue
		rock.position = pos
		rock.rotation.y = rng.randf() * TAU
		add_child(rock)


func _rustwater_spawn() -> Vector3:
	return WorldManager.poi_scene_position("rustwater") + RUSTWATER_SPAWN_OFFSET


func _build_player() -> void:
	_player = Node3D.new()
	# Modell, sobald eines unter assets/models/characters/player.glb liegt — sonst Kapsel.
	var model: Node3D = AssetRegistry.instantiate("player", 1.8)
	if model != null:
		_player.add_child(model)
	else:
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.5
		cap.height = 1.8
		body.mesh = cap
		body.material_override = _mat(Color(0.23, 0.51, 0.96))
		body.position = Vector3(0.0, 0.9, 0.0)
		_player.add_child(body)
	_player.position = _rustwater_spawn()
	add_child(_player)
	_cam = Camera3D.new()
	# Nahe Diablo-Immortal-Kamera statt Strategie-Übersicht: Figur füllt sichtbar den Rahmen.
	_cam.position = Vector3(0.0, 13.0, 10.0)
	_cam.rotation_degrees = Vector3(-50.0, 0.0, 0.0)
	_cam.far = 8000.0   # Kraterrand & Herz bleiben trotzdem am Horizont sichtbar (Landmark-Navigation)
	_player.add_child(_cam)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(14.0, 10.0)
	_hud.add_theme_font_size_override("font_size", 15)
	layer.add_child(_hud)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position = Vector2(0.0, 64.0)
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_toast)
	# Minikarte oben rechts — Orientierung im 5000-m-Becken.
	_minimap = Minimap.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.position = Vector2(-Minimap.MAP_PX - 14.0, 12.0)
	layer.add_child(_minimap)


## Baut einen Gegner-Node (Modell oder Primitive + Lebensleiste), fügt ihn NICHT in die Szene
## ein (Aufrufer setzt zuerst die Position) und trägt ihn NICHT in `_enemies` ein.
func _make_enemy(type_id: String) -> Dictionary:
	var target: CombatTarget = CombatTarget.from_type(type_id)
	var node := Node3D.new()
	# Modell, sobald eines unter assets/models/enemies/<typ>.glb liegt — sonst Primitive.
	var model: Node3D = AssetRegistry.instantiate(AssetRegistry.enemy_asset(type_id), 1.6)
	if model != null:
		node.add_child(model)
	else:
		var body := MeshInstance3D.new()
		if target.classification == CombatData.MECHANICAL:
			var bm := BoxMesh.new()                  # Kampf-Lesbarkeit: eckig = Maschine
			bm.size = Vector3(1.1, 1.4, 1.1)
			body.mesh = bm
			body.material_override = _mat(Color(0.49, 0.83, 0.99))
			body.position = Vector3(0.0, 0.7, 0.0)
		else:
			var cm := CapsuleMesh.new()              # rund = organisch
			cm.radius = 0.45
			cm.height = 1.6
			body.mesh = cm
			body.material_override = _mat(Color(0.97, 0.44, 0.44))
			body.position = Vector3(0.0, 0.8, 0.0)
		node.add_child(body)
	var bar := MeshInstance3D.new()                  # simple Lebensleiste
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(1.4, 0.12, 0.12)
	bar.mesh = bar_mesh
	bar.material_override = _mat(Color(0.52, 0.80, 0.09), true)
	bar.position = Vector3(0.0, 2.1, 0.0)
	node.add_child(bar)
	return { "node": node, "target": target, "bar": bar }


func _spawn_pack() -> void:
	# Grenzgänger-Rudel + ein Kessel-Kläffer südöstlich von Rustwater (echter Biom-Leitmix) —
	# der erste Kontakt beim Einstieg; danach übernimmt der kontinuierliche Spawner unten.
	var base: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(40.0, 0.0, 55.0)
	for i in 4:
		var type_id: String = "klaeffer" if i == 3 else "outlaw"
		var e: Dictionary = _make_enemy(type_id)
		(e["node"] as Node3D).position = base + Vector3(float(i) * 5.0 - 7.5, 0.0, float(i % 2) * 6.0)
		add_child(e["node"])
		_enemies.append(e)


## Nachschub aus dem echten Biom-Gegnermix (WorldManager), solange die Kappe nicht erreicht ist.
## Spawnt in Lauf-Distanz um den Spieler herum, aber nie in einem noch gesperrten Sektor
## (Gates sind aus GameState/WorldManager abgeleitet — sobald die Kampagne hier andockt,
## respektiert der Nachschub automatisch Kapitel-/Tor-Fortschritt).
func _process_spawns(delta: float) -> void:
	_spawn_cd -= delta
	if _spawn_cd > 0.0 or _enemies.size() >= ENEMY_MAX:
		return
	_spawn_cd = SPAWN_INTERVAL_SEC
	var ang: float = randf() * TAU
	var dist: float = randf_range(SPAWN_MIN_DIST, SPAWN_MAX_DIST)
	var pos: Vector3 = _player.position + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
	pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
	pos.z = clampf(pos.z, -(WorldManager.WORLD_METERS - 20.0), -20.0)
	if _in_town(pos):
		return   # Rustwater ist befriedet
	var rel: Vector2 = WorldManager.scene_to_world(pos)
	if not WorldManager.can_enter_sector(WorldManager.sector_of_pos(rel)):
		return   # jenseits eines noch geschlossenen Tors — hier siedelt sich (noch) nichts an
	var biome_id: String = WorldManager.biome_at(rel)
	var type_id: String = WorldManager.pick_enemy_type(biome_id, GameState.is_revealed)
	var e: Dictionary = _make_enemy(type_id)
	(e["node"] as Node3D).position = pos
	add_child(e["node"])
	_enemies.append(e)


# ── Truhen: echte Ausrüstung, sofort wirksam über EquipManager/PlayerStats ───

## Baut eine Truhe an `pos` (Modell + schwebende Beschriftung zur Fernsicht) und trägt sie ein.
func _spawn_chest_near(pos: Vector3) -> void:
	var node := Node3D.new()
	var model: Node3D = AssetRegistry.instantiate("chest", 0.7)
	if model != null:
		node.add_child(model)
	else:
		var body := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 0.5, 0.4)
		body.mesh = bm
		body.material_override = _mat(Color(0.55, 0.38, 0.16))
		body.position = Vector3(0.0, 0.25, 0.0)
		node.add_child(body)
	node.position = pos
	add_child(node)
	var label: Label3D = _label(pos + Vector3(0.0, 1.3, 0.0), "📦 Truhe", Color(1.0, 0.85, 0.4), 90, 120.0)
	_chests.append({ "node": node, "label": label, "pos": pos })


## Nachschub an Truhen — ähnlich dem Gegner-Spawner, aber seltener und mit eigener Kappe.
func _process_chest_spawns(delta: float) -> void:
	_chest_spawn_cd -= delta
	if _chest_spawn_cd > 0.0 or _chests.size() >= CHEST_MAX:
		return
	_chest_spawn_cd = CHEST_SPAWN_INTERVAL_SEC
	var ang: float = randf() * TAU
	var dist: float = randf_range(CHEST_MIN_DIST, CHEST_MAX_DIST)
	var pos: Vector3 = _player.position + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
	pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
	pos.z = clampf(pos.z, -(WorldManager.WORLD_METERS - 20.0), -20.0)
	var rel: Vector2 = WorldManager.scene_to_world(pos)
	if not WorldManager.can_enter_sector(WorldManager.sector_of_pos(rel)):
		return
	_spawn_chest_near(pos)


## Läuft der Spieler nah genug an eine Truhe, wird sie sofort geplündert (kein Knopf nötig,
## passend zum reinen Auto-Kampf-Sandbox-Charakter dieser Szene).
func _process_chests(delta: float) -> void:
	_process_chest_spawns(delta)
	for c in _chests.duplicate():
		if _player.position.distance_to(c["pos"]) <= CHEST_INTERACT_M:
			_loot_chest()
			(c["node"] as Node3D).queue_free()
			(c["label"] as Label3D).queue_free()
			_chests.erase(c)


## Rollt ein echtes Ausrüstungsstück (ProgressionManager) und legt es an, wenn es das aktuell
## getragene Teil übertrifft (EquipManager) — sonst wird es zu Gold eingeschmolzen. Wirkt sich
## dank PlayerStats' Live-Zugriff auf GameState.equip ab dem NÄCHSTEN Schuss aus.
func _loot_chest() -> void:
	var rarity: String = ProgressionManager.roll_rarity(CHEST_RARITY_BIAS)
	var slot: String = EquipManager.GEAR_SLOTS[randi_range(0, EquipManager.GEAR_SLOTS.size() - 1)]
	var gear: Dictionary = ProgressionManager.make_gear(slot, rarity)
	var current: Dictionary = EquipManager.equipped(slot)
	var new_value: int = ProgressionManager.gear_value(gear)
	var rarity_name: String = String(ProgressionManager.RARITY[rarity]["name"])
	if current.is_empty() or new_value > ProgressionManager.gear_value(current):
		EquipManager.equip_item(gear, slot)
		_say("✦ %s %s angelegt (+%d %s)" % [rarity_name, String(gear["name"]), int(gear["stat"]["val"]), String(gear["stat"]["key"])], 3.5)
		sfx_equip()
	else:
		var gold: int = maxi(1, roundi(new_value * 0.5))
		GameState.add_gold(gold)
		_say("📦 %s %s eingeschmolzen (+%d Gold)" % [rarity_name, String(gear["name"]), gold], 3.0)


## Kleiner Aufblitz-Effekt beim Anlegen, damit ein Ausrüstungswechsel spürbar ist.
func sfx_equip() -> void:
	if _player == null:
		return
	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.9, 0.5)
	flash.omni_range = 4.0
	flash.light_energy = 2.0
	_player.add_child(flash)
	get_tree().create_timer(0.25).timeout.connect(flash.queue_free)


# ── Eingabe: virtueller Joystick (Touch) + Tastatur ───────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_start = event.position
			_touch_vec = Vector2.ZERO
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_touch_vec = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var v: Vector2 = event.position - _touch_start
		_touch_vec = Vector2.ZERO if v.length() < 12.0 else (v / 100.0).limit_length(1.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_cycle_weapon()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			_fast_travel(event.keycode - KEY_1)


## Schnellreise zu den großen Knoten (GDD §1.4: Bahnhöfe nur an echten Hubs). Gesperrte
## Sektoren bleiben gesperrt — dasselbe Gating wie Bewegung und Spawns, aus WorldManager.
func _fast_travel(idx: int) -> void:
	if idx < 0 or idx >= FAST_TRAVEL.size():
		return
	var poi_id: String = String(FAST_TRAVEL[idx])
	var p: Dictionary = WorldManager.POIS[poi_id]
	var sec: int = int(p["sector"])
	if not WorldManager.can_enter_sector(sec):
		_say("🚫 %s liegt hinter einem verschlossenen Tor (Sektor %d)." % [String(p["name"]), sec], 2.5)
		return
	_player.position = WorldManager.poi_scene_position(poi_id) + Vector3(0.0, 0.0, 25.0)
	_say("🚂 Schnellreise: %s" % String(p["name"]), 2.5)


func _cycle_weapon() -> void:
	var i: int = WEAPON_ORDER.find(_weapon_id)
	_weapon_id = WEAPON_ORDER[(i + 1) % WEAPON_ORDER.size()]
	var dt: String = String(CombatData.WEAPONS[_weapon_id]["type"])
	_say("%s %s (%s)" % [WEAPON_ICON[_weapon_id], String(CombatData.WEAPONS[_weapon_id]["name"]), dt], 2.0)


func _move_vector() -> Vector2:
	var kb: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return kb if kb.length() > 0.05 else _touch_vec


# ── Spielschleife ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_process_movement(delta)
	_process_combat(delta)
	_process_enemies(delta)
	_process_hazards(delta)
	_process_spawns(delta)
	_process_chests(delta)
	_process_autosave(delta)
	_update_hud()


func _process_movement(delta: float) -> void:
	var mv: Vector2 = _move_vector()
	if mv.length() < 0.05:
		return
	var step: Vector3 = Vector3(mv.x, 0.0, mv.y) * WorldManager.PLAYER_SPEED_MS * delta
	var next: Vector3 = _player.position + step
	# Weltgrenzen (Kraterrand).
	next.x = clampf(next.x, 2.0, WorldManager.WORLD_METERS - 2.0)
	next.z = clampf(next.z, -(WorldManager.WORLD_METERS - 2.0), -2.0)
	# Gate 1: Sprengtore blocken die Nord-Querung, bis Kapitel 5 (WorldManager entscheidet).
	var from_rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var to_rel: Vector2 = WorldManager.scene_to_world(next)
	if not WorldManager.can_cross_blast_line(from_rel.y, to_rel.y):
		next.z = maxf(next.z, -(float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT - 1.5))
		_say("⛔ Die Sprengtore sind zu. Erst der Panzerzug (Kapitel 4) bricht sie auf.", 2.5)
	_player.position = next
	if Vector2(step.x, step.z).length() > 0.001:
		_player.rotation.y = atan2(-step.x, -step.z)


func _nearest_enemy(max_dist: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = max_dist
	for e in _enemies:
		var d: float = _player.position.distance_to(e["node"].position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _process_combat(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0:
		return
	var e: Dictionary = _nearest_enemy(SHOOT_RANGE_M)
	if e.is_empty():
		return
	_fire_cd = float(PlayerStats.fire_ms(_weapon_id)) / 1000.0
	var target: CombatTarget = e["target"]
	var damage_type: String = String(CombatData.WEAPONS[_weapon_id]["type"])
	var acid: int = CombatData.weapon_acid(_weapon_id, 0)
	var res: Dictionary = CombatEngine.resolve_hit(
		damage_type, target, PlayerStats.damage_per_bullet(_weapon_id), acid, Time.get_ticks_msec())
	_spawn_tracer(e["node"].position)
	var frac: float = clampf(float(target.health) / float(target.max_health), 0.0, 1.0)
	(e["bar"] as MeshInstance3D).scale.x = maxf(frac, 0.02)
	if bool(res["killed"]):
		GameState.add_gold(target.gold)
		GameState.add_kill()
		GameState.add_xp(CombatData.xp_for_kill(target))
		_say("☠ %s erlegt — +%d Gold" % [CombatData.ENEMY_TYPES[target.type_id]["name"], target.gold], 2.0)
		(e["node"] as Node3D).queue_free()
		_enemies.erase(e)


func _spawn_tracer(to_pos: Vector3) -> void:
	var from_pos: Vector3 = _player.position + Vector3(0.0, 1.2, 0.0)
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, from_pos.distance_to(to_pos))
	tracer.mesh = mesh
	tracer.material_override = _mat(TRACER_COLOR[_weapon_id], true)
	add_child(tracer)
	tracer.position = (from_pos + Vector3(to_pos.x, 1.0, to_pos.z)) / 2.0
	tracer.look_at(Vector3(to_pos.x, 1.0, to_pos.z))
	get_tree().create_timer(0.07).timeout.connect(tracer.queue_free)


func _process_enemies(delta: float) -> void:
	for e in _enemies:
		var node: Node3D = e["node"]
		var d: float = _player.position.distance_to(node.position)
		if d > AGGRO_M:
			continue
		if d > CONTACT_RANGE_M:
			var dir: Vector3 = (_player.position - node.position).normalized()
			node.position += dir * ENEMY_SPEED_MS * delta
		else:
			var target: CombatTarget = e["target"]
			_hp -= float(target.contact_dps) * delta * CombatEngine.player_damage_taken_mul(0)
			if _hp <= 0.0:
				_respawn()
				return


func _process_hazards(delta: float) -> void:
	# Smog-DOT (Gate 2): WorldManager rechnet, die Szene wendet nur an.
	var dot: int = WorldManager.smog_dot_damage(WorldManager.scene_to_world(_player.position), delta)
	if dot > 0:
		_hp -= float(dot)
		if _hp <= 0.0:
			_respawn()


func _respawn() -> void:
	_hp = float(PlayerStats.max_hp())
	_player.position = _rustwater_spawn()
	_say("💀 Ausgeknockt — zurück in Rustwater.", 3.0)


func _say(text: String, secs: float) -> void:
	if _toast == null:
		return
	_toast.text = text
	_toast_until = Time.get_ticks_msec() / 1000.0 + secs


func _update_hud() -> void:
	var rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var biome: Dictionary = WorldManager.biome(WorldManager.biome_at(rel))
	var poi_id: String = WorldManager.nearest_poi(rel)
	var poi_d: int = roundi(_player.position.distance_to(WorldManager.poi_scene_position(poi_id)))
	var worn_n: int = EquipManager.worn().size()
	_hud.text = "❤ %d/%d   💰 %d   ⭐ Lv %d   🎽 %d/%d   %s %s\n➡ %s (%d m)   Sektor %d · %s   [Tab] Waffe" % [
		maxi(0, roundi(_hp)), PlayerStats.max_hp(), GameState.gold, GameState.level,
		worn_n, EquipManager.GEAR_SLOTS.size(),
		WEAPON_ICON[_weapon_id], String(CombatData.WEAPONS[_weapon_id]["name"]),
		String(WorldManager.POIS[poi_id]["name"]), poi_d,
		WorldManager.sector_of_pos(rel), String(biome["name"])]
	_hud.text += "   [1-5] Schnellreise"
	if _minimap != null:
		_minimap.player_pos = _player.position
		_minimap.player_dir = _player.rotation.y
		var ep: Array = []
		for e in _enemies:
			ep.append((e["node"] as Node3D).position)
		_minimap.enemy_positions = ep
		_minimap.queue_redraw()
	if Time.get_ticks_msec() / 1000.0 > _toast_until:
		_toast.text = ""
