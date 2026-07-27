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

## Reiseziele (Tasten 1–5) sind exakt die Bahnhöfe — eine Liste, keine zweite Wahrheit.
const FAST_TRAVEL: Array = WorldManager.RAIL_STATIONS

# ── NPCs & Quests: der QuestManager ist seit Phase 2 fertig, hier zum ersten Mal
# an die sichtbare Welt angeschlossen. Auftraggeber stehen bei ihren Gebäuden. ──
const NPC_INTERACT_M: float = 4.5
## giver-Id (QuestManager.QUESTS[..].giver) → Anzeigename, Winkel/Distanz um das Stadtzentrum, Farbe.
const TOWN_NPCS: Array = [
	["mabel", "Mamma „Rusty“ Mabel", 25.0, 22.0, Color(0.85, 0.45, 0.35)],
	["silas", "Silas „Kupferauge“ Finch", 110.0, 21.0, Color(0.55, 0.50, 0.40)],
	["doc", "Doktor „Doc“ Aris", 285.0, 22.0, Color(0.88, 0.88, 0.90)],
]
## Material-Drops beim Kill — ohne sie ist die Sammel-Quest „Baumaterial: Schrott" unlösbar.
const DROP_TABLE: Array = [["schrott", 0.65], ["zahnrad", 0.22], ["dampfkern", 0.05]]

# ── Kamera (an Diablo-Immortal-Referenz eingemessen, GDD §1.5a) ───────────────
const CAM_FOV: float = 50.0     # eng statt Godots 75° — sonst wirkt die Figur winzig
## Abstand zur Figur. Sichtbare Höhe = 2·Abstand·tan(FOV/2) = 0,93·Abstand; bei 9,5 m sieht man
## also ~8,9 m, die 1,8-m-Figur füllt damit rund 20 % der Bildhöhe. Der frühere Wert (14 m)
## traf zwar die gemessenen 14 % der Vorlage, war am Bildschirm aber zu weit weg, um etwas
## zu erkennen — Spielbarkeit schlägt Messwert.
const CAM_DIST: float = 9.5
const CAM_PITCH: float = 52.0   # Neigung nach unten (etwas flacher -> mehr von der Figur)
const CAM_YAW: float = 20.0     # leichte Gierung -> isometrischer Eindruck statt Frontalsicht

# ── Virtueller Joystick (Finger und Maus, GDD §1.5) ───────────────────────────
const STICK_RADIUS: float = 96.0     # Pixel bis Vollausschlag
const STICK_DEADZONE: float = 10.0   # darunter passiert nichts (Zittern/Klick)
const MOUSE_STICK_ID: int = 9001     # eigene „Finger"-Id für die Maus (kollidiert mit keiner echten)
const TURN_RATE: float = 12.0        # wie schnell die Figur in die neue Richtung eindreht

# ── Bauliche Begrenzung (GDD §1.4a) ───────────────────────────────────────────
## Die Wüste ist offen, die Aktionszonen sind eng — und zwar durch ECHTE Bauten, nicht
## durch unsichtbare Wände: jedes Haus, jeder Palisadenpfosten, jedes Turmbein trägt sich
## beim Bauen selbst als Sperre ein (`_solid_box` / `_solid_pillar`). Was man sieht, blockt.
const PLAYER_RADIUS_M: float = 0.6
## Rustwaters Palisade: Radius, Tore (Grad) und halbe Torbreite. Wand und Sperre werden
## beide daraus gebaut — die vier Tore sind die einzigen Wege hinein.
const PALISADE_R: float = 84.0
const PALISADE_GATES: Array = [0.0, 90.0, 180.0, 270.0]
const PALISADE_GATE_HALF_DEG: float = 7.0

# ── Eisenbahn (GDD §1.4a): Schnellreise nur noch von Bahnhof zu Bahnhof ───────
const RAIL_GAUGE_M: float = 3.2        # Spurweite der Iron Rail (Breitspur, Panzerzug-tauglich)
const STATION_RANGE_M: float = 45.0    # so nah muss man am Bahnsteig stehen, um zu fahren

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
var _npcs: Array = []                # { giver, name, node, label, pos: Vector3 }
var _npc_cd: float = 0.0             # Entprellung: nicht bei jedem Frame erneut ansprechen
var _chest_spawn_cd: float = 3.0      # erste Truhe erscheint schnell
var _hud: Label
var _minimap: Minimap
var _stick: VirtualStick
var _toast: Label
var _toast_until: float = 0.0
var _touch_id: int = -1
var _touch_start: Vector2 = Vector2.ZERO
var _touch_vec: Vector2 = Vector2.ZERO
var _save_loaded: bool = false
var _save_cd: float = AUTOSAVE_INTERVAL_SEC
var _blockers: Array = []            # rechteckige Sperren: { c: Vector2(x,z), h: Vector2 }
var _pillars: Array = []             # runde Sperren:       { c: Vector2(x,z), r: float }
var _rings: Array = []               # Ringmauern mit Toren: { c, r, t, gates, gate_half }
var _stations: Array = []            # { id, pos: Vector3 } — Bahnsteige der Iron Rail
var _player_model: Node3D = null     # nur gesetzt, wenn ein echtes Modell geladen wurde
var _coat: Node3D = null             # angehängter Mantel (optional)
var _coat_mats: Array = []           # dessen ShaderMaterials (Schwung-Parameter)
var _coat_sway: float = 0.0          # geglättete Laufstärke 0…1 (kein Ruckeln beim Anlaufen)


func _ready() -> void:
	_load_or_init_save()   # vor allem Weiteren: GameState (Level/Gold/Ausrüstung) korrekt setzen
	_build_environment()
	_build_ground_and_biomes()
	_build_sector_lines_and_rim()
	_build_roads()
	_build_railway()
	_build_pois()
	_build_township()
	_scatter_decor()
	_build_player()
	_build_hud()
	_build_npcs()
	_spawn_pack()
	_spawn_chest_near(_rustwater_spawn() + Vector3(-18.0, 0.0, 14.0))
	_hp = float(PlayerStats.max_hp())
	if _save_loaded:
		_say("💾 Spielstand geladen — Lv %d · %d 💰 · 🎽 %d/%d   [Tab] Waffe" % [
			GameState.level, GameState.gold, EquipManager.worn().size(), EquipManager.GEAR_SLOTS.size()], 4.0)
	else:
		_say("🤠 Willkommen im Krater — 5000 m Kante zu Kante. Ziehen (Maus/Finger) = laufen, [Tab] wechselt die Waffe.", 5.0)


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


## Wie `_box`, aber die Grundfläche sperrt den Weg. Der Spielerradius wird schon beim
## Eintragen aufgeschlagen — der Lauftest ist damit ein reiner Punkt-in-Rechteck-Test.
func _solid_box(size: Vector3, pos: Vector3, color: Color, alpha: float = 1.0) -> MeshInstance3D:
	var mi: MeshInstance3D = _box(size, pos, color, alpha)
	_blockers.append({
		"c": Vector2(pos.x, pos.z),
		"h": Vector2(size.x * 0.5 + PLAYER_RADIUS_M, size.z * 0.5 + PLAYER_RADIUS_M) })
	return mi


## Runde Sperre (Säulen, Türme, Silos) — Radius inklusive Spielerradius.
func _solid_pillar(center: Vector3, radius: float) -> void:
	_pillars.append({ "c": Vector2(center.x, center.z), "r": radius + PLAYER_RADIUS_M })


## Ringmauer mit Toren (Palisaden, Stadtmauern, Arena-Wälle). Exakter und billiger als
## hunderte Einzelboxen — und die Tore bleiben garantiert genau dort, wo die Optik sie zeigt.
func _solid_ring(center: Vector3, radius: float, thickness: float, gates_deg: Array, gate_half_deg: float) -> void:
	_rings.append({
		"c": Vector2(center.x, center.z), "r": radius,
		"t": thickness * 0.5 + PLAYER_RADIUS_M,
		"gates": gates_deg, "gate_half": gate_half_deg })


## Liegt der Winkel in einer der Torlücken? (Grad, Szenen-Konvention atan2(z, x).)
func _in_gate_gap(ang_deg: float, gates_deg: Array, gate_half_deg: float) -> bool:
	for g in gates_deg:
		if absf(wrapf(ang_deg - float(g), -180.0, 180.0)) <= gate_half_deg:
			return true
	return false


## Steht dieser Punkt in einem Bauwerk? Grundlage der baulichen Begrenzung: in der Wildnis
## ist die Liste leer, in einer Aktionszone dicht — daher fühlt sich dieselbe Steuerung
## draußen weit und drinnen geführt an.
func _blocked(p: Vector3) -> bool:
	var q := Vector2(p.x, p.z)
	for b in _blockers:
		var d: Vector2 = (q - Vector2(b["c"])).abs()
		if d.x <= float(b["h"].x) and d.y <= float(b["h"].y):
			return true
	for s in _pillars:
		if q.distance_to(Vector2(s["c"])) <= float(s["r"]):
			return true
	for r in _rings:
		var off: Vector2 = q - Vector2(r["c"])
		if absf(off.length() - float(r["r"])) > float(r["t"]):
			continue   # weder in noch an der Mauer
		if not _in_gate_gap(rad_to_deg(atan2(off.y, off.x)), r["gates"], float(r["gate_half"])):
			return true
	return false


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
			_solid_box(Vector3(120.0, 420.0, 120.0), pos + Vector3(0.0, 210.0, 0.0), Color(0.15, 0.13, 0.14))
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
		_solid_pillar(pos, 6.0)   # die Landmarke steht im Weg — man läuft um sie herum
		_label(pos + Vector3(0.0, 41.0, 0.0), String(p["name"]), col.lightened(0.35), 130, 420.0)


## Zeichnet die Routen aus `WorldManager.ROUTES` als gestampfte Pisten. Sie SPERREN nichts —
## die Wüste daneben ist genauso begehbar (GDD §1.4a). Sie sind Wegführung: die schnellste,
## sicherste Linie zwischen zwei Orten, an der man sich orientiert, statt Wände zu haben.
func _build_roads() -> void:
	var road_col := Color(0.56, 0.46, 0.32)   # festgefahrener, hellerer Staub
	for r in WorldManager.ROUTES:
		var a: Vector3 = WorldManager.poi_scene_position(String(r[0]))
		var b: Vector3 = WorldManager.poi_scene_position(String(r[1]))
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(WorldManager.CORRIDOR_HALF_W * 2.0 * WorldManager.METERS_PER_UNIT, 0.12, a.distance_to(b))
		seg.mesh = bm
		seg.material_override = _mat(road_col)
		seg.position = (a + b) / 2.0 + Vector3(0.0, 0.06, 0.0)   # knapp über dem Boden
		seg.look_at_from_position(seg.position, b, Vector3.UP)
		add_child(seg)


## Die Iron Rail (GDD §1.4a): Schotterbett + zwei Schienen auf den Routen zwischen den
## Bahnhöfen, dazu an jedem Knoten ein Bahnsteig mit Depot. Der lange Fußmarsch durch die
## Wüste bleibt möglich — später fährt man ihn. Fahren darf man nur AM Bahnsteig
## (`_fast_travel`), damit Schnellreise ein Ort in der Welt ist und kein Menüpunkt.
func _build_railway() -> void:
	var ballast := Color(0.30, 0.27, 0.24)
	var steel := Color(0.62, 0.60, 0.58)
	for seg_ids in WorldManager.rail_segments():
		var a: Vector3 = WorldManager.poi_scene_position(String(seg_ids[0]))
		var b: Vector3 = WorldManager.poi_scene_position(String(seg_ids[1]))
		var mid: Vector3 = (a + b) / 2.0
		var length: float = a.distance_to(b)
		# Schotterbett und beide Schienen liegen im selben gedrehten Knoten — dann muss die
		# Ausrichtung nur einmal berechnet werden und die Spurweite stimmt garantiert.
		var track := Node3D.new()
		add_child(track)
		track.position = mid + Vector3(0.0, 0.2, 0.0)
		track.look_at(Vector3(b.x, track.position.y, b.z), Vector3.UP)
		var bed := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(RAIL_GAUGE_M + 2.4, 0.3, length)
		bed.mesh = bm
		bed.material_override = _mat(ballast)
		track.add_child(bed)
		for side in [-1.0, 1.0]:
			var rail := MeshInstance3D.new()
			var rm := BoxMesh.new()
			rm.size = Vector3(0.22, 0.24, length)
			rail.mesh = rm
			rail.material_override = _mat(steel)
			rail.position = Vector3(side * RAIL_GAUGE_M * 0.5, 0.27, 0.0)
			track.add_child(rail)
	for id in WorldManager.RAIL_STATIONS:
		_build_station(String(id))


## Bahnsteig + Depot an einem Knoten. Der Bahnsteig selbst sperrt nicht (man steht darauf),
## das Depot schon — es ist Teil der baulichen Begrenzung des Ortes.
func _build_station(poi_id: String) -> void:
	var c: Vector3 = WorldManager.poi_scene_position(poi_id)
	var platform: Vector3 = c + Vector3(0.0, 0.0, 14.0)
	_box(Vector3(26.0, 0.9, 8.0), platform + Vector3(0.0, 0.45, 0.0), Color(0.44, 0.38, 0.30))
	for x in [-11.0, 0.0, 11.0]:
		_box(Vector3(0.5, 3.4, 0.5), platform + Vector3(x, 2.6, 3.2), Color(0.30, 0.26, 0.22))
	_box(Vector3(26.0, 0.4, 7.0), platform + Vector3(0.0, 4.5, 1.2), Color(0.34, 0.28, 0.22))   # Vordach
	_solid_box(Vector3(9.0, 5.0, 6.0), c + Vector3(-18.0, 2.5, 16.0), Color(0.38, 0.31, 0.24))  # Depot
	_label(platform + Vector3(0.0, 6.4, 0.0), "🚂 Bahnhof " + String(WorldManager.poi(poi_id)["name"]),
		Color(0.92, 0.86, 0.70), 100, 200.0)
	_stations.append({ "id": poi_id, "pos": platform })


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
		_solid_box(Vector3(fp.x, h, fp.y), pos + Vector3(0.0, h / 2.0, 0.0), b[5])
		_box(Vector3(fp.x + 1.6, 0.6, fp.y + 1.6), pos + Vector3(0.0, h + 0.3, 0.0), Color(0.24, 0.19, 0.15))   # Dachkante (überhängend, sperrt nicht)
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
		_solid_box(Vector3(w, h, w * 0.85), pos + Vector3(0.0, h / 2.0, 0.0), Color(0.42, 0.33, 0.24))
	# Wasserturm — die Silhouette, an der man Rustwater von weitem erkennt.
	var tw: Vector3 = c + Vector3(-26.0, 0.0, -22.0)
	for leg in [Vector3(-3.0, 0.0, -3.0), Vector3(3.0, 0.0, -3.0), Vector3(-3.0, 0.0, 3.0), Vector3(3.0, 0.0, 3.0)]:
		_solid_box(Vector3(0.8, 14.0, 0.8), tw + leg + Vector3(0.0, 7.0, 0.0), Color(0.33, 0.27, 0.22))
	_box(Vector3(9.0, 6.0, 9.0), tw + Vector3(0.0, 17.0, 0.0), Color(0.48, 0.38, 0.26))
	_label(tw + Vector3(0.0, 22.0, 0.0), "RUSTWATER", Color(0.95, 0.82, 0.55), 120, 350.0)
	# Palisade: geschlossene Bretterwand mit vier Toren. Das ist die bauliche Grenze der
	# Aktionszone (GDD §1.4a) — man kommt nur durch die Tore hinein, aber man SIEHT warum:
	# es ist eine Wand, keine unsichtbare Barriere. Optik (Panele) und Sperre (Ring-Blocker)
	# stammen aus denselben Zahlen, können also nicht auseinanderlaufen.
	_solid_ring(c, PALISADE_R, 1.2, PALISADE_GATES, PALISADE_GATE_HALF_DEG)
	var panels: int = 120
	for i in panels:
		var ang_deg: float = float(i) * (360.0 / float(panels))
		if _in_gate_gap(ang_deg, PALISADE_GATES, PALISADE_GATE_HALF_DEG):
			continue
		var a: float = deg_to_rad(ang_deg)
		var pos: Vector3 = c + Vector3(cos(a) * PALISADE_R, 1.6, sin(a) * PALISADE_R)
		var panel := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(1.2, 3.2, TAU * PALISADE_R / float(panels) + 0.4)   # tangential, leicht überlappend
		panel.mesh = pm
		panel.material_override = _mat(Color(0.34, 0.26, 0.19))
		panel.position = pos
		panel.rotation.y = -a
		add_child(panel)
	# Torpfeiler markieren die Durchlässe (und tragen die Ring-Lücke optisch).
	for g in PALISADE_GATES:
		for side in [-PALISADE_GATE_HALF_DEG, PALISADE_GATE_HALF_DEG]:
			var a2: float = deg_to_rad(float(g) + float(side))
			var pos2: Vector3 = c + Vector3(cos(a2) * PALISADE_R, 0.0, sin(a2) * PALISADE_R)
			_solid_box(Vector3(2.2, 5.4, 2.2), pos2 + Vector3(0.0, 2.7, 0.0), Color(0.28, 0.21, 0.15))


# ── NPCs & Quests ─────────────────────────────────────────────────────────────

func _build_npcs() -> void:
	var c: Vector3 = WorldManager.poi_scene_position("rustwater")
	for n in TOWN_NPCS:
		var ang: float = deg_to_rad(float(n[2]))
		var d: float = float(n[3])
		var pos: Vector3 = c + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		var node := Node3D.new()
		var body := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.42
		cap.height = 1.7
		body.mesh = cap
		body.material_override = _mat(n[4])
		body.position = Vector3(0.0, 0.85, 0.0)
		node.add_child(body)
		node.position = pos
		add_child(node)
		var label: Label3D = _label(pos + Vector3(0.0, 2.5, 0.0), String(n[1]), Color(0.98, 0.94, 0.82), 85, 140.0)
		_npcs.append({ "giver": String(n[0]), "name": String(n[1]), "node": node, "label": label, "pos": pos })


## Die (erste) Quest dieses Auftraggebers, die gerade relevant ist — offen oder aktiv.
## Fertige Quests werden übersprungen, damit ein NPC nach Abschluss die nächste anbietet.
func _quest_for_giver(giver: String) -> String:
	for qid in QuestManager.QUESTS.keys():
		var def: Dictionary = QuestManager.QUESTS[qid]
		if String(def.get("giver", "")) != giver:
			continue
		var st: String = QuestManager.get_quest_state(String(qid))
		if st != QuestManager.STATE_DONE:
			return String(qid)
	return ""


## Nähe zu einem NPC = Gespräch. Annehmen, Fortschritt melden oder abgeben — die
## Entscheidung trifft komplett der QuestManager (Kapitel-/Gilden-Gates inklusive).
func _process_npcs(delta: float) -> void:
	_npc_cd = maxf(0.0, _npc_cd - delta)
	if _npc_cd > 0.0:
		return
	for n in _npcs:
		if _player.position.distance_to(n["pos"]) > NPC_INTERACT_M:
			continue
		_npc_cd = 3.0   # nicht sofort erneut ansprechen
		var giver: String = String(n["giver"])
		var qid: String = _quest_for_giver(giver)
		if qid == "":
			_say('%s: „Nichts mehr zu tun, Fremder.“' % String(n['name']), 2.5)
			return
		var def: Dictionary = QuestManager.QUESTS[qid]
		var title: String = String(def["title"])
		var st: String = QuestManager.get_quest_state(qid)
		if st == QuestManager.STATE_AVAILABLE:
			if QuestManager.accept_quest(qid):
				var goal: String = ("%d Gegner erlegen" % int(def["count"])) if String(def["kind"]) == "kill" \
					else ("%dx %s sammeln" % [int(def["count"]), String(def["item"])])
				_say('📜 Auftrag angenommen: „%s“ — %s' % [title, goal], 4.0)
			else:
				_say('🔒 „%s“ ist noch nicht verfügbar.' % title, 2.5)
		elif QuestManager.is_quest_complete(qid):
			var gold_before: int = GameState.gold
			if QuestManager.complete_quest(qid):
				_say('✅ „%s“ abgeschlossen — +%d Gold' % [title, GameState.gold - gold_before], 4.0)
				sfx_equip()
			else:
				_say("Hm — die Abgabe wurde abgelehnt.", 2.5)
		else:
			var p: Dictionary = QuestManager.check_quest_progress(qid)
			_say('📜 „%s“: %d/%d' % [title, int(p['current']), int(p['target'])], 3.0)
		return


## Zeile für den HUD-Quest-Tracker: die erste aktive Quest mit Fortschritt.
func _active_quest_line() -> String:
	for qid in QuestManager.QUESTS.keys():
		if QuestManager.get_quest_state(String(qid)) != QuestManager.STATE_ACTIVE:
			continue
		var def: Dictionary = QuestManager.QUESTS[qid]
		var p: Dictionary = QuestManager.check_quest_progress(String(qid))
		var mark: String = "✔" if bool(p["complete"]) else "▸"
		return "%s %s  %d/%d" % [mark, String(def["title"]), int(p["current"]), int(p["target"])]
	return ""


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
		# Weder in der Stadt noch auf Piste/Trasse — die Wege sollen frei und lesbar bleiben.
		if _in_town(pos) or WorldManager.on_route(WorldManager.scene_to_world(pos)):
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
		_player_model = model   # trägt den AnimationPlayer, sobald das Modell animiert ist
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
	_attach_coat()
	_cam = Camera3D.new()
	# Kamera nach Diablo-Immortal-Referenz eingemessen: die Figur soll rund 14 % der Bildhöhe
	# füllen. Entscheidend ist das ENGE Sichtfeld — Godots Standard-75° zieht die Welt
	# auseinander und lässt die Figur winzig wirken (nur ~7 %). Mit 50° FOV und 14 m Abstand
	# stimmt die Füllung; die leichte Gierung bricht die achsenparallele Sicht auf und erzeugt
	# den isometrischen Eindruck der Vorlage.
	_cam.fov = CAM_FOV
	_cam.position = Vector3(
		sin(deg_to_rad(CAM_YAW)) * CAM_DIST * cos(deg_to_rad(CAM_PITCH)),
		CAM_DIST * sin(deg_to_rad(CAM_PITCH)),
		cos(deg_to_rad(CAM_YAW)) * CAM_DIST * cos(deg_to_rad(CAM_PITCH)))
	_cam.rotation_degrees = Vector3(-CAM_PITCH, CAM_YAW, 0.0)
	_cam.far = 8000.0   # Kraterrand & Herz bleiben trotzdem am Horizont sichtbar (Landmark-Navigation)
	_player.add_child(_cam)


## Hängt den Mantel (falls vorhanden) an den Brustknochen der Figur und ersetzt sein Material
## durch den Schwung-Shader. Fehlt die Datei, passiert nichts — wie bei jedem anderen Asset.
##
## Der Mantel ist ein EIGENES Mesh, kein Teil der Figur: so kann er sich frei bewegen, ohne
## dass das Rig der Figur ihn mitverformt (Auto-Rigging kennt keine Stoff-Knochen). Angehängt
## wird an `Spine` & Co. — dort, wo ein Mantel auf den Schultern aufliegt.
func _attach_coat() -> void:
	if _player_model == null:
		return
	var skel: Skeleton3D = AssetRegistry.skeleton(_player_model)
	if skel == null:
		return
	var bone: String = AssetRegistry.best_bone(skel, AssetRegistry.COAT_BONES)
	if bone == "":
		return
	# Ohne Boden-Snap und ohne Zielhöhe: der Mantel muss GENAU so im Raum liegen, wie er
	# modelliert wurde, sonst passt er nicht zur Figur.
	var coat: Node3D = AssetRegistry.instantiate("player_coat", 0.0, false)
	if coat == null:
		return
	var bounds: AABB = AssetRegistry.local_bounds(coat)
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	skel.add_child(att)
	att.add_child(coat)
	# Die Knochen-Aufhängung sitzt auf Brusthöhe; der Mantel ist aber in Figur-Koordinaten
	# modelliert (Ursprung an den Füßen). Die inverse Ruhelage des Knochens rechnet genau
	# diesen Versatz heraus — danach steht der Mantel in Ruhepose exakt am modellierten Platz
	# und folgt trotzdem jeder Bewegung des Oberkörpers.
	var idx: int = skel.find_bone(bone)
	if idx >= 0:
		coat.transform = skel.get_bone_global_rest(idx).affine_inverse()
	_coat = coat
	_apply_coat_shader(coat, bounds)


## Ersetzt die Materialien des Mantels durch `coat_sway.gdshader` und übernimmt dabei Farbe,
## Textur und Rauheit aus dem importierten Material — der Mantel sieht also aus wie modelliert,
## bewegt sich aber. Aufhängung und Länge kommen aus den gemessenen Bounds (nichts abgeschrieben).
func _apply_coat_shader(coat: Node3D, bounds: AABB) -> void:
	var shader: Shader = load("res://shaders/coat_sway.gdshader") as Shader
	if shader == null:
		return
	for mi in AssetRegistry.mesh_instances(coat):
		var src: BaseMaterial3D = mi.get_active_material(0) as BaseMaterial3D
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("coat_top", bounds.position.y + bounds.size.y)
		mat.set_shader_parameter("coat_length", maxf(bounds.size.y, 0.05))
		if src != null:
			mat.set_shader_parameter("albedo_color", src.albedo_color)
			mat.set_shader_parameter("albedo_tex", src.albedo_texture)
			mat.set_shader_parameter("roughness", src.roughness)
			mat.set_shader_parameter("metallic", src.metallic)
		mi.material_override = mat
		_coat_mats.append(mat)


## Füttert den Shader mit der aktuellen Bewegung. `world_dir` ist die Laufrichtung in der
## XZ-Ebene (Länge 0 = Stillstand); sie wird in den lokalen Raum des Mantels gedreht, weil der
## Stoff relativ zur Figur nachzieht, nicht relativ zur Welt.
func _process_coat(delta: float, world_dir: Vector3) -> void:
	if _coat_mats.is_empty():
		return
	var target: float = clampf(world_dir.length(), 0.0, 1.0)
	# Anwehen schnell, Ausschwingen langsam — sonst fällt der Stoff beim Stehenbleiben zu abrupt.
	var rate: float = 6.0 if target > _coat_sway else 2.5
	_coat_sway = lerpf(_coat_sway, target, clampf(delta * rate, 0.0, 1.0))
	var local: Vector3 = Vector3.FORWARD
	if world_dir.length_squared() > 0.0001:
		local = (_coat.global_transform.basis.inverse() * world_dir).normalized()
	for mat in _coat_mats:
		(mat as ShaderMaterial).set_shader_parameter("sway_dir", local)
		(mat as ShaderMaterial).set_shader_parameter("sway_amount", _coat_sway)


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
	# Joystick-Anzeige ganz oben drüber (zeichnet nur, wenn gezogen wird).
	_stick = VirtualStick.new()
	_stick.radius = STICK_RADIUS
	layer.add_child(_stick)


## Baut einen Gegner-Node (Modell oder Primitive + Lebensleiste), fügt ihn NICHT in die Szene
## ein (Aufrufer setzt zuerst die Position) und trägt ihn NICHT in `_enemies` ein.
func _make_enemy(type_id: String) -> Dictionary:
	var target: CombatTarget = CombatTarget.from_type(type_id)
	var node := Node3D.new()
	# Modell, sobald eines unter assets/models/enemies/<typ>.glb liegt — sonst Primitive.
	var model: Node3D = AssetRegistry.instantiate(AssetRegistry.enemy_asset(type_id), 1.6)
	if model != null:
		node.add_child(model)
		AssetRegistry.play_clip(model, "idle")
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
	return { "node": node, "target": target, "bar": bar, "model": model }


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
	if not WorldManager.is_walkable(rel) or _blocked(pos):
		return   # nur dort, wo der Spieler auch hinkommt — und nicht mitten in einem Bau
	if not WorldManager.can_enter_sector(WorldManager.sector_of_pos(rel)):
		return   # jenseits eines noch geschlossenen Tors — hier siedelt sich (noch) nichts an
	var zone: String = WorldManager.zone_at(rel)
	if zone != "" and WorldManager.is_safe_zone(zone):
		return   # befriedete Aktionszone (Hub / eigene Fraktionsbasis)
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
	if not WorldManager.can_enter_sector(WorldManager.sector_of_pos(rel)) or not WorldManager.is_walkable(rel):
		return
	if _blocked(pos):
		return   # keine Truhe in einer Hauswand
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
			_begin_stick(event.position, event.index)
		elif not event.pressed and event.index == _touch_id:
			_end_stick()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_drag_stick(event.position)
	# Maus verhält sich exakt wie ein Finger — derselbe Joystick, damit man am Rechner das
	# testet, was auf dem Handy auch passiert (statt einer zweiten, abweichenden Steuerung).
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _touch_id == -1:
			_begin_stick(event.position, MOUSE_STICK_ID)
		elif not event.pressed and _touch_id == MOUSE_STICK_ID:
			_end_stick()
	elif event is InputEventMouseMotion and _touch_id == MOUSE_STICK_ID:
		_drag_stick(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_cycle_weapon()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			_fast_travel(event.keycode - KEY_1)


## Der Joystick erscheint dort, wo man aufsetzt (dynamischer Stick, GDD §1.5) — er hat keine
## feste Ecke, weil man auf dem Handy nicht hinschaut, bevor man den Daumen aufsetzt.
func _begin_stick(at: Vector2, id: int) -> void:
	_touch_id = id
	_touch_start = at
	_touch_vec = Vector2.ZERO
	if _stick != null:
		_stick.origin = at
		_stick.knob = at
		_stick.active = true
		_stick.queue_redraw()


func _drag_stick(at: Vector2) -> void:
	var v: Vector2 = at - _touch_start
	# Unter der Totzone passiert nichts (Zittern), darüber wächst es linear bis STICK_RADIUS.
	_touch_vec = Vector2.ZERO if v.length() < STICK_DEADZONE else (v / STICK_RADIUS).limit_length(1.0)
	if _stick != null:
		_stick.knob = _touch_start + v.limit_length(STICK_RADIUS)
		_stick.queue_redraw()


func _end_stick() -> void:
	_touch_id = -1
	_touch_vec = Vector2.ZERO
	if _stick != null:
		_stick.active = false
		_stick.queue_redraw()


## Bahnhof, an dem der Spieler gerade steht ("" = keiner in Reichweite).
func _station_at_player() -> String:
	for s in _stations:
		if _player.position.distance_to(s["pos"]) <= STATION_RANGE_M:
			return String(s["id"])
	return ""


## Iron-Rail-Reise (GDD §1.4a): von Bahnsteig zu Bahnsteig. Die Wüste dazwischen kann man
## immer zu Fuß durchqueren — die Bahn ersetzt nur den langen Marsch, und zwar erst, wenn
## man tatsächlich an einem Bahnhof steht. Gesperrte Sektoren bleiben gesperrt (WorldManager).
func _fast_travel(idx: int) -> void:
	if idx < 0 or idx >= FAST_TRAVEL.size():
		return
	var here: String = _station_at_player()
	if here == "":
		_say("🚉 Nur am Bahnhof. Die Iron Rail hält nicht mitten in der Wüste.", 2.5)
		return
	var poi_id: String = String(FAST_TRAVEL[idx])
	var p: Dictionary = WorldManager.POIS[poi_id]
	if poi_id == here:
		_say("🚉 Du stehst schon in %s." % String(p["name"]), 2.0)
		return
	var sec: int = int(p["sector"])
	if not WorldManager.can_enter_sector(sec):
		_say("🚫 %s liegt hinter einem verschlossenen Tor (Sektor %d)." % [String(p["name"]), sec], 2.5)
		return
	_player.position = WorldManager.poi_scene_position(poi_id) + Vector3(0.0, 0.0, 25.0)
	_say("🚂 Iron Rail: %s → %s" % [String(WorldManager.poi(here)["name"]), String(p["name"])], 2.5)


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
	_process_npcs(delta)
	_process_autosave(delta)
	_update_hud()


func _process_movement(delta: float) -> void:
	var mv: Vector2 = _move_vector()
	var moving: bool = mv.length() >= 0.05
	# Animation folgt der Bewegung, sobald ein animiertes Modell da ist. Kennt das Modell den
	# Clip nicht (oder ist es der Kapsel-Platzhalter), passiert schlicht nichts.
	AssetRegistry.play_clip(_player_model, "walk" if moving else "idle")
	# Eingabe ist bildschirmbezogen: um die Kamera-Gierung zurückdrehen, damit „nach oben
	# ziehen" auch bei gedrehter Kamera nach oben läuft (sonst zieht es schräg).
	var dir: Vector2 = mv.rotated(-deg_to_rad(CAM_YAW))
	# Der Mantel schwingt auch im Stand aus — deshalb VOR dem frühen Ausstieg.
	_process_coat(delta, Vector3(dir.x, 0.0, dir.y) if moving else Vector3.ZERO)
	if not moving:
		return
	var step: Vector3 = Vector3(dir.x, 0.0, dir.y) * WorldManager.PLAYER_SPEED_MS * delta
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
		to_rel = WorldManager.scene_to_world(next)
	# Weltstruktur (GDD §1.4a): draußen ist offene Wüste, drinnen begrenzen BAUTEN. Beides
	# geht durch denselben Test — nur ist die Blocker-Liste in der Wildnis leer, weshalb sich
	# dort nichts anfühlt wie eine Wand. Achsenweise nachgeben, damit man an einer Hausecke
	# entlanggleitet statt hängenzubleiben.
	if not WorldManager.is_walkable(to_rel) or _blocked(next):
		var slide_x: Vector3 = Vector3(next.x, 0.0, _player.position.z)
		var slide_z: Vector3 = Vector3(_player.position.x, 0.0, next.z)
		if WorldManager.is_walkable(WorldManager.scene_to_world(slide_x)) and not _blocked(slide_x):
			next = slide_x
		elif WorldManager.is_walkable(WorldManager.scene_to_world(slide_z)) and not _blocked(slide_z):
			next = slide_z
		else:
			return   # in eine Ecke gelaufen — Position halten
		step = next - _player.position
	_player.position = next
	# Drehung weich nachziehen statt hart umzuschnappen: bei einem Joystick wechselt die
	# Richtung stufenlos, und eine Figur, die pro Frame springt, wirkt wie ein Blechspielzeug.
	if Vector2(step.x, step.z).length() > 0.001:
		var want: float = atan2(-step.x, -step.z)
		_player.rotation.y = lerp_angle(_player.rotation.y, want, clampf(delta * TURN_RATE, 0.0, 1.0))


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
		var extra: String = _roll_material_drop()
		_say("☠ %s erlegt — +%d Gold%s" % [CombatData.ENEMY_TYPES[target.type_id]["name"], target.gold, extra], 2.0)
		(e["node"] as Node3D).queue_free()
		_enemies.erase(e)


## Material-Drop beim Kill (Schrott/Zahnrad/Dampfkern). Ohne diese Drops waeren die
## Sammel-Quests des QuestManagers in der Overworld gar nicht erfuellbar.
func _roll_material_drop() -> String:
	for entry in DROP_TABLE:
		if randf() < float(entry[1]):
			var id: String = String(entry[0])
			GameState.add_item(id, 1)
			return "  +1 %s" % id
	return ""


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
			AssetRegistry.play_clip(e["model"], "idle")
			continue
		if d > CONTACT_RANGE_M:
			var dir: Vector3 = (_player.position - node.position).normalized()
			node.position += dir * ENEMY_SPEED_MS * delta
			node.rotation.y = atan2(-dir.x, -dir.z)   # Gegner schaut, wohin er läuft
			AssetRegistry.play_clip(e["model"], "walk")
		else:
			AssetRegistry.play_clip(e["model"], "attack")
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
	# Weltstruktur ablesbar machen (GDD §1.4a): am Bahnsteig fährt man, in der Aktionszone
	# ist es baulich eng, dazwischen liegt offene Wüste. Die Bahn ist ein Ort, kein Menüpunkt.
	var zone: String = WorldManager.zone_at(rel)
	if _station_at_player() != "":
		_hud.text += "   🚉 [1-5] Iron Rail"
	elif zone != "":
		_hud.text += "   🏛 " + String(WorldManager.poi(zone)["name"])
	else:
		_hud.text += "   🏜 offene Wüste"
	var q: String = _active_quest_line()
	if q != "":
		_hud.text += "\n📜 " + q
	_hud.text += "\n🔩 %d  ⚙ %d  🔆 %d" % [
		GameState.item_count("schrott"), GameState.item_count("zahnrad"), GameState.item_count("dampfkern")]
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
