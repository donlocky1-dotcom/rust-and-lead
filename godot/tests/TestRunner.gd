extends Node
## TestRunner — abhängigkeitsfreie headless Test-Suite für das gesamte Backend.
##
## Ausführen (kein GUT-Addon nötig):  godot --headless --path godot
## (oder im Editor: Projekt starten). Exit-Code 0 = alle Tests bestanden, 1 = Fehler.
##
## Deterministisch: geprüft werden die exakten Zahlenwerte aus dem Master-GDD. Zufalls-
## behaftete Status-Auslösungen werden umgangen, indem Status direkt über apply_status()
## gesetzt wird (Schaden selbst ist deterministisch).

var _passed: int = 0
var _failed: int = 0
var _scratch: Array = []   # Wegwerf-Objekte der Tests; am Ende gesammelt freigegeben


func _ready() -> void:
	print("──────────────────────────────────────────────")
	print("  Rust & Lead — Backend Test-Suite")
	print("──────────────────────────────────────────────")
	_test_combat_engine()
	_test_quest_manager()
	_test_tycoon_manager()
	_test_grid_inventory()
	_test_world_manager()
	_test_world_scale()
	_test_walkable_zones()
	_test_minimap()
	_test_fire_control()
	_test_wall_classification()
	_test_workshop()
	_test_ammo()
	_test_reload()
	_test_weapons()
	_test_terrain()
	_test_winding()
	_test_props()
	_test_station()
	_test_camera_zoom()
	_test_hud_layout()
	_test_bag()
	_test_asset_registry()
	_test_overworld_loot_flow()
	_test_overworld_quest_flow()
	_test_memory_manager()
	_test_encounter_manager()
	_test_progression_manager()
	_test_rift_manager()
	_test_save_manager()
	_test_equip_manager()
	_test_player_stats()
	for obj in _scratch:
		if is_instance_valid(obj):
			obj.free()
	_scratch.clear()
	print("──────────────────────────────────────────────")
	print("  Ergebnis: %d bestanden, %d fehlgeschlagen" % [_passed, _failed])
	print("──────────────────────────────────────────────")
	get_tree().call_deferred("quit", 1 if _failed > 0 else 0)


func _check(label: String, condition: bool, info: String = "") -> void:
	if condition:
		_passed += 1
		print("  [OK]   ", label)
	else:
		_failed += 1
		printerr("  [FAIL] ", label, ("  -> " + info) if info != "" else "")


func _reset_state() -> void:
	GameState.current_chapter = 1
	GameState.is_revealed = false
	GameState.chosen_guild = null
	GameState.level = 1
	GameState.xp = 0
	GameState.perk_points = 0
	GameState.perks = {}
	GameState.upgrades = { "damage": 0, "firerate": 0, "reload": 0, "hp": 0, "speed": 0, "regen": 0, "magnet": 0 }
	GameState.ng_plus = 0
	GameState.gold = 0
	GameState.potions = 3
	GameState.kills = 0
	GameState.inventory = { "schrott": 0, "zahnrad": 0, "dampfkern": 0 }
	GameState.equip = {}
	GameState.bag = []
	GameState.ammo = AmmoData.fresh()
	GameState.mag = AmmoData.fresh_mags()
	GameState.economy = { "saloon": 0, "forge": 0, "distillery": 0, "laboratory": 0 }
	GameState.quests = {}
	GameState.quest_base = {}
	GameState.flags_ui = { "reveal_playing": false }
	GameState.memories_found = 0
	GameState.memorials_seen = []
	GameState.family_buried = false
	GameState.codex = []


# ── Modul 1: CombatEngine ─────────────────────────────────────────────────────
func _test_combat_engine() -> void:
	print("· CombatEngine (Modul 1)")
	var now: int = Time.get_ticks_msec()

	var mech := CombatTarget.from_type("konstrukt")   # MECHANICAL, armor 15
	_check("Galvanik vs Mech = 2.5x", CombatEngine.calculate(CombatData.GALVANIC, mech, 40).damage == 100)
	_check("Kinetik vs Mech = max(1, dmg-armor)", CombatEngine.calculate(CombatData.KINETIC, mech, 40).damage == 25)
	_check("Thermik vs Leichtbau-Automat = 1.2x", CombatEngine.calculate(CombatData.THERMAL, mech, 40).damage == 48)

	var bio := CombatTarget.from_type("outlaw")        # BIOLOGICAL, armor 0
	_check("Kinetik vs Bio = 1.5x", CombatEngine.calculate(CombatData.KINETIC, bio, 40).damage == 60)
	_check("Galvanik vs Bio = 0.4x (Isolierung)", CombatEngine.calculate(CombatData.GALVANIC, bio, 40).damage == 16)
	_check("Thermik vs Bio = 1.3x", CombatEngine.calculate(CombatData.THERMAL, bio, 40).damage == 52)

	# Front-Immunität (Goliath, armor 30): frontal 0 Kinetik, Flanke normal, nach Korrosion voll.
	var goliath := CombatTarget.from_type("goliath")
	var frontal := CombatEngine.calculate(CombatData.KINETIC, goliath, 40)
	_check("Goliath frontal immun (Kinetik = 0)", frontal.damage == 0 and frontal.immune == true)
	_check("Goliath Flanke umgeht Immunität", CombatEngine.calculate(CombatData.KINETIC, goliath, 40, 10, false).damage == 10)
	_check("Thermik vs Goliath = 0.6x (widersteht)", CombatEngine.calculate(CombatData.THERMAL, goliath, 40).damage == 24)
	_check("Alchemie flaggt Korrosion", CombatEngine.calculate(CombatData.ALCHEMICAL, goliath, 12).effect == CombatData.FX_CORRODE)
	CombatEngine.apply_status(goliath, CombatData.FX_CORRODE, now, 30)   # Panzerung 30 -> 0
	_check("Korrosion senkt Panzerung auf 0", goliath.armor == 0)
	_check("Nach Korrosion trifft Kinetik frontal voll", CombatEngine.calculate(CombatData.KINETIC, goliath, 40).damage == 40)

	# Mitigations-Formel 100/(100+armor*9).
	_check("Mitigation armor 0 = voll", CombatEngine.mitigate_damage(100, 0) == 100)
	_check("Mitigation armor 10 = 53", CombatEngine.mitigate_damage(100, 10) == 53)

	# Status: Stun & DOT.
	var t := CombatTarget.from_type("konstrukt")
	CombatEngine.apply_status(t, CombatData.FX_STUN, now)
	_check("Kurzschluss-Stun aktiv", t.is_stunned(now + 3999) and not t.is_stunned(now + 4001))
	CombatEngine.apply_status(t, CombatData.FX_BLEED, now)
	var dot_dmg: int = CombatEngine.tick_dot(t, now + 100, 0.5)   # >= 0.4s -> tickt
	_check("Verbluten-DOT fügt Schaden zu", dot_dmg > 0 and t.health < t.max_health)
	_check("DOT läuft nach 3s ab", CombatEngine.tick_dot(t, now + 4000, 0.5) == 0 and not t.has_dot())

	# XP pro Kill.
	_check("XP Superboss = 300", CombatData.xp_for_kill(CombatTarget.from_type("goliath", {"superboss": true})) == 300)
	_check("XP Elite = 50", CombatData.xp_for_kill(CombatTarget.from_type("outlaw", {"elite": true})) == 50)


# ── Modul (Quest): QuestManager ───────────────────────────────────────────────
func _test_quest_manager() -> void:
	print("· QuestManager")
	_reset_state()

	# Reveal (Kapitel 4 -> 5).
	GameState.current_chapter = 4
	QuestManager.trigger_chapter_4_reveal()
	_check("Reveal setzt is_revealed & reveal_playing", GameState.is_revealed and GameState.flags_ui["reveal_playing"] == true)
	QuestManager.trigger_chapter_4_reveal()   # zweiter Aufruf: idempotent, kein Effekt
	_check("Reveal ist idempotent (Kapitel noch 4)", GameState.current_chapter == 4 and GameState.is_revealed == true)
	QuestManager.finish_reveal()
	_check("finish_reveal hebt auf Kapitel 5", GameState.current_chapter == 5 and GameState.flags_ui["reveal_playing"] == false)

	# Gildenwahl (Kapitel-5-Gate, exklusiv).
	_check("choose_guild rebels ok", QuestManager.choose_guild("rebels") == true and GameState.chosen_guild == "rebels")
	_check("zweite Gildenwahl blockiert", QuestManager.choose_guild("corp") == false)
	_check("fremde Gilde gesperrt", QuestManager.can_access_guild("corp") == false)

	# Kill-Quest via questBase.
	_check("accept q_rebels5", QuestManager.accept_quest("q_rebels5") == true)
	_check("questBase eingefroren", int(GameState.quest_base["q_rebels5"]) == GameState.kills)
	_check("fremde Gilden-Quest geblockt", QuestManager.accept_quest("q_corp5") == false)
	for i in 12:
		GameState.add_kill()
	var prog: Dictionary = QuestManager.check_quest_progress("q_rebels5")
	_check("Fortschritt 12/12", prog["current"] == 12 and prog["complete"] == true)
	var gold_before: int = GameState.gold
	_check("complete q_rebels5", QuestManager.complete_quest("q_rebels5") == true)
	_check("Belohnung Gold +250", GameState.gold == gold_before + 250)
	_check("Belohnung Dampfkern +1", GameState.item_count("dampfkern") == 1)
	_check("Kapitel-Sprung -> 8", GameState.current_chapter == 8)
	_check("Doppel-Abgabe blockiert", QuestManager.complete_quest("q_rebels5") == false)

	# Collect-Quest (Schmuggler) mit Item-Abzug — eigener Reset.
	_reset_state()
	GameState.is_revealed = true
	GameState.current_chapter = 5
	QuestManager.choose_guild("smugglers")
	QuestManager.accept_quest("q_smug5")   # 3 Dampfkerne sammeln
	_check("Collect nicht komplett ohne Items", QuestManager.complete_quest("q_smug5") == false)
	GameState.add_item("dampfkern", 3)
	_check("Collect komplett mit 3 Dampfkernen", QuestManager.is_quest_complete("q_smug5"))
	_check("complete q_smug5", QuestManager.complete_quest("q_smug5") == true)
	_check("Collect zieht Items ab", GameState.item_count("dampfkern") == 0)
	_check("Collect Gold +300", GameState.gold == 300)


# ── Modul 2: TycoonManager ────────────────────────────────────────────────────
func _test_tycoon_manager() -> void:
	print("· TycoonManager (Modul 2)")
	_reset_state()
	TycoonManager.sim_seconds = 0.0
	TycoonManager._boost_until = { "saloon": 0.0, "forge": 0.0, "distillery": 0.0 }

	GameState.set_building_level("saloon", 3)      # 3*1
	GameState.set_building_level("forge", 2)       # 2*2
	GameState.set_building_level("distillery", 1)  # 1*4
	_check("income_per_sec = 3+4+4 = 11", TycoonManager.income_per_sec() == 11)

	# Kostenkurve base*(level+1).
	_check("upgrade_cost saloon (lvl3) = 400", TycoonManager.upgrade_cost("saloon") == 400)
	_check("upgrade_cost forge (lvl2) = 660", TycoonManager.upgrade_cost("forge") == 660)

	# Ausbau bucht ganzzahlig ab.
	GameState.gold = 500
	_check("try_upgrade saloon", TycoonManager.try_upgrade("saloon") == true)
	_check("Gold abgezogen (500-400)", GameState.gold == 100)
	_check("Stufe erhöht auf 4", GameState.building_level("saloon") == 4)
	GameState.gold = 0
	_check("try_upgrade ohne Gold scheitert", TycoonManager.try_upgrade("saloon") == false)

	# Ripple-Matrix.
	TycoonManager.activate_boost("forge", 60.0)
	_check("Forge-Boost aktiv", TycoonManager.is_boost_active("forge"))
	_check("Kosten-Rabatt -10%", is_equal_approx(TycoonManager.cost_multiplier(), 0.9))
	TycoonManager.activate_boost("distillery", 60.0)
	_check("Verkaufswert +20%", TycoonManager.sell_value(200) == 240)
	# Saloon-Boost: +15% auf Schmiede-Komponente. saloon3 + forge2(4*1.15=4.6) + distillery1(4) = 11.6 -> 12
	TycoonManager.activate_boost("saloon", 60.0)
	GameState.set_building_level("saloon", 3)
	_check("Saloon-Ripple hebt Schmiede (-> 12)", TycoonManager.income_per_sec() == 12)
	# Booster laufen über die Sim-Uhr ab.
	TycoonManager.sim_seconds = 100.0
	_check("Booster nach Ablauf inaktiv", not TycoonManager.is_boost_active("forge"))

	# Aktiver Tick schreibt ganzzahlig Gold.
	_reset_state()
	GameState.set_building_level("saloon", 5)   # 5 Gold/Sek
	GameState.gold = 0
	TycoonManager._tick_second()
	_check("Sekunden-Tick schreibt +5 Gold", GameState.gold == 5)


# ── Modul 3: GridInventoryBackend ─────────────────────────────────────────────
func _test_grid_inventory() -> void:
	print("· GridInventoryBackend (Modul 3)")
	var grid := GridInventoryBackend.new(10, 8)

	_check("Footprint Rüstung 2x2", GridInventoryBackend.footprint("armor") == Vector2i(2, 2))
	_check("Footprint Waffe 2x1", GridInventoryBackend.footprint("weapon") == Vector2i(2, 1))
	_check("Footprint schwere Waffe 3x1", GridInventoryBackend.footprint("heavy_weapon") == Vector2i(3, 1))
	_check("Footprint Kleinteil 1x1", GridInventoryBackend.footprint("helmet") == Vector2i(1, 1))

	_check("leeres Grid: 80 frei", grid.free_cells() == 80)
	_check("can_fit 2x2 @ (0,0)", grid.can_fit_item(0, 0, 2, 2) == true)
	_check("insert 2x2 @ (0,0)", grid.insert_item(101, 0, 0, 2, 2) == true)
	_check("belegte Zelle nicht frei", grid.can_fit_item(0, 0, 1, 1) == false)
	_check("used_cells = 4", grid.used_cells() == 4)
	_check("Überlappung abgelehnt", grid.insert_item(102, 1, 1, 2, 2) == false)
	_check("dieselbe uid nicht doppelt", grid.insert_item(101, 5, 5, 1, 1) == false)

	# Grenzen.
	_check("Out-of-Bounds (Breite) abgelehnt", grid.can_fit_item(9, 0, 2, 1) == false)
	_check("Out-of-Bounds (Höhe) abgelehnt", grid.can_fit_item(0, 7, 1, 2) == false)

	# Auto-Platzierung row-major.
	var pos: Vector2i = grid.find_first_empty_space(3, 1)
	_check("find_first_empty_space (3x1) = (2,0)", pos == Vector2i(2, 0))
	_check("place_first schwere Waffe", grid.place_first(103, 3, 1) == true)

	# Entfernen gibt alle Zellen frei.
	grid.remove_item(101)
	_check("remove_item gibt 4 Zellen frei", grid.can_fit_item(0, 0, 2, 2) == true and grid.has_item(101) == false)

	# Voll-Szenario: kein Platz.
	var small := GridInventoryBackend.new(2, 2)
	small.insert_item(1, 0, 0, 2, 2)
	_check("volles Grid: kein Platz", small.find_first_empty_space(1, 1) == Vector2i(-1, -1))


# ── WorldManager ──────────────────────────────────────────────────────────────
func _test_world_manager() -> void:
	print("· WorldManager")
	_reset_state()

	_check("Sektor Y=300 -> 1", WorldManager.sector_of_y(300) == 1)
	_check("Sektor Y=1000 -> 2", WorldManager.sector_of_y(1000) == 2)
	_check("Sektor Y=1600 -> 3", WorldManager.sector_of_y(1600) == 3)
	_check("POI Koordinaten (Eisernes Herz)", WorldManager.poi_position("eisernes_herz") == Vector2(1000, 1950))
	_check("Dungeon-Ebenen Schmelzöfen = 4", WorldManager.dungeon_floors("schmelzoefen_vulcan") == 4)

	# Gate 1: Sprengtore.
	GameState.current_chapter = 1
	_check("Sprengtore vor Kap.4 zu", WorldManager.is_blast_gate_open() == false)
	_check("Nord-Querung blockiert", WorldManager.can_cross_blast_line(700, 850) == false)
	GameState.current_chapter = 5
	_check("Sprengtore nach Kap.4 offen", WorldManager.is_blast_gate_open() == true)
	_check("Nord-Querung frei", WorldManager.can_cross_blast_line(700, 850) == true)

	# Gate 2: Smog-Linie.
	GameState.set_building_level("laboratory", 0)
	_check("kein Filter ohne Labor-Stufe 3", WorldManager.has_alchemie_filter() == false)
	_check("Smog tödlich (>0 DOT)", WorldManager.smog_dot_damage(Vector2(0, 1600), 1.0) > 0)
	GameState.set_building_level("laboratory", 3)
	_check("Labor Stufe 3 -> Filter", WorldManager.has_alchemie_filter() == true)
	_check("mit Filter kein Smog-Schaden", WorldManager.smog_dot_damage(Vector2(0, 1600), 1.0) == 0)

	# Gate 3: Fraktions-Feindseligkeit.
	GameState.chosen_guild = null
	_check("vor Wahl kein HQ feindlich", WorldManager.is_base_hostile("sektor01") == false)
	GameState.chosen_guild = "rebels"
	_check("Rebellen -> Sektor 01 feindlich", WorldManager.is_base_hostile("sektor01") == true)
	_check("eigenes HQ freundlich", WorldManager.is_base_friendly("fort_freedom") == true)

	# ── Biom-Zonierung (§1.6.3) ──
	_check("Biom Hub-Umland = Wüste", WorldManager.biome_at(Vector2(300, 300)) == "desert")
	_check("Biom Salzpfanne", WorldManager.biome_at(Vector2(250, 680)) == "salt")
	_check("Biom Grüne Senke", WorldManager.biome_at(Vector2(550, 250)) == "oasis")
	_check("Biom Rostwald", WorldManager.biome_at(Vector2(1120, 1080)) == "rostwald")
	_check("Biom Kupfer-Hochland", WorldManager.biome_at(Vector2(1750, 1350)) == "kupfer_hochland")
	_check("Biom Smog-Ödland (Sektor 3)", WorldManager.biome_at(Vector2(0, 1600)) == "smog_oedland")
	# Zonen überlappen nicht (jedes Zentrum liefert sein eigenes Biom)
	var centers_ok: bool = true
	for id in ["salt", "oasis", "rostwald", "kupfer_hochland"]:
		var b: Dictionary = WorldManager.BIOMES[id]
		if WorldManager.biome_at(Vector2(float(b["cx"]), float(b["cy"]))) != id:
			centers_ok = false
	_check("Zonen-Zentren eindeutig (kein Overlap)", centers_ok)

	# Gegner-Leitmix je Biom (deterministisch via roll = 0.0 -> erster Pool-Eintrag)
	_check("Rostwald pre = Wildnis (fauna zuerst)", WorldManager.pick_enemy_type("rostwald", false, 0.0) == "fauna")
	_check("Hochland post = mechanisch (konstrukt zuerst)", WorldManager.pick_enemy_type("kupfer_hochland", true, 0.0) == "konstrukt")
	_check("Salzpfanne pre = menschlich (revolver zuerst)", WorldManager.pick_enemy_type("salt", false, 0.0) == "revolver")
	_check("Salzpfanne pre-Reveal ohne Maschinen", not _pool_has(WorldManager.enemy_pool("salt", false), "konstrukt"))
	_check("Desert post enthält Kläffer (nach Reveal)", _pool_has(WorldManager.enemy_pool("desert", true), "klaeffer"))
	_check("Unbekanntes Biom fällt auf Wüste zurück", WorldManager.enemy_pool("nonexistent", false) == WorldManager.enemy_pool("desert", false))

	# Zonen erben Sektor-Gating (§1.7)
	GameState.current_chapter = 1
	GameState.set_building_level("laboratory", 0)
	_check("Rostwald vor Kap.4 gesperrt (Sektor 2)", WorldManager.is_biome_unlocked("rostwald") == false)
	_check("Wüste immer offen (Sektor 1)", WorldManager.is_biome_unlocked("desert") == true)
	GameState.current_chapter = 5
	_check("Rostwald nach Reveal offen", WorldManager.is_biome_unlocked("rostwald") == true)
	_check("Smog-Ödland ohne Filter gesperrt (Sektor 3)", WorldManager.is_biome_unlocked("smog_oedland") == false)
	GameState.set_building_level("laboratory", 3)
	_check("Smog-Ödland mit Filter offen", WorldManager.is_biome_unlocked("smog_oedland") == true)
	_check("Unique-Champion-Chance = 30%", is_equal_approx(WorldManager.UNIQUE_CHAMPION_CHANCE, 0.30))


func _pool_has(pool: Array, type_id: String) -> bool:
	for p in pool:
		if String(p[0]) == type_id:
			return true
	return false


# ── MemoryManager: Erinnerungs-Walzen & Familien-Bogen (§8.3) ─────────────────
func _test_memory_manager() -> void:
	print("· MemoryManager (roter Faden §8.3)")
	_reset_state()

	# Kette: 16 geordnete Fragmente, jedes mit Titel+Text.
	_check("Erinnerungskette = 16", MemoryManager.chain_length() == 16)
	var all_data: bool = true
	for m in MemoryManager.MEMORIES:
		if String(m.get("title", "")) == "" or String(m.get("text", "")) == "":
			all_data = false
	_check("jedes Fragment hat Titel+Text", all_data)
	_check("next_memory = erstes Fragment", MemoryManager.next_memory()["title"] == "Der Nagel")

	# Bergen rückt die Kette vor und schaltet beim ersten Fund den Drop-Logik-Codex frei.
	var m0: Dictionary = MemoryManager.recover_memory()
	_check("recover gibt Fragment 1", m0["title"] == "Der Nagel" and GameState.memories_found == 1)
	_check("erster Fund schaltet 'steuerwalzen' frei", GameState.codex_has("steuerwalzen"))
	_check("next_memory rückt vor", MemoryManager.next_memory()["title"] == "Kaffee, zu früh")

	# Drop-Wahrscheinlichkeit: deterministisch via roll (3 % normal, 50 % Boss).
	_check("recovery_chance normal = 0.03", is_equal_approx(MemoryManager.recovery_chance(false), 0.03))
	_check("recovery_chance Boss = 0.50", is_equal_approx(MemoryManager.recovery_chance(true), 0.50))
	var before: int = GameState.memories_found
	_check("roll 0.02 < 0.03 -> Fund", not MemoryManager.try_recover_memory(false, 0.02).is_empty() and GameState.memories_found == before + 1)
	_check("roll 0.04 >= 0.03 -> kein Fund", MemoryManager.try_recover_memory(false, 0.04).is_empty())
	_check("Boss roll 0.40 < 0.50 -> Fund", not MemoryManager.try_recover_memory(true, 0.40).is_empty())

	# Vollsammlung: Kette füllen, dann sperrt weiteres Bergen.
	while not MemoryManager.is_complete():
		MemoryManager.recover_memory()
	_check("Kette voll bei 16", GameState.memories_found == 16 and MemoryManager.is_complete())
	_check("recover bei voller Kette = {}", MemoryManager.recover_memory().is_empty())
	_check("Erfolg 'Jeremiah Hale' (rememberer)", MemoryManager.is_rememberer())

	# Erinnerungspunkte: Türrahmen/Foto schalten 'familie' frei, liefern Flashback-Zeilen.
	_reset_state()
	var door: Dictionary = MemoryManager.play_memorial("doorframe")
	_check("doorframe erstmalig gesehen", door["first_seen"] == true and GameState.memorials_seen.has("doorframe"))
	_check("doorframe schaltet 'familie' frei", GameState.codex_has("familie"))
	_check("doorframe liefert Flashback-Zeilen", door["lines"].size() >= 3 and door["graves_state"] == "")
	_check("doorframe zweiter Besuch nicht mehr 'first'", MemoryManager.play_memorial("doorframe")["first_seen"] == false)
	_check("photo schaltet ebenfalls 'familie'", not MemoryManager.play_memorial("photo").is_empty())

	# Providence-Gating: erst nach dem Erwachen offen.
	GameState.is_revealed = false
	_check("Providence vor Reveal verschlossen", MemoryManager.is_providence_open() == false)
	GameState.is_revealed = true
	_check("Providence nach Reveal offen", MemoryManager.is_providence_open() == true)

	# Gräber gestuft: unvollständig -> kein Begräbnis.
	_reset_state()
	GameState.memories_found = 5
	var g_inc: Dictionary = MemoryManager.play_memorial("graves")
	_check("Gräber unvollständig", g_inc["graves_state"] == "incomplete")
	_check("bury_family scheitert unvollständig", MemoryManager.bury_family() == false and GameState.family_buried == false)

	# Gräber vollständig: Begräbnis setzt Zustand, Codex, Erfolg — und ist einmalig.
	GameState.memories_found = 16
	_check("Gräber bereit bei 16/16", MemoryManager.play_memorial("graves")["graves_state"] == "ready")
	_check("bury_family erfolgreich", MemoryManager.bury_family() == true and GameState.family_buried)
	_check("Begräbnis schaltet 'heimkehr' frei", GameState.codex_has("heimkehr") and GameState.codex_has("familie"))
	_check("Erfolg 'Heimkehr' (homecoming)", MemoryManager.is_homecoming())
	_check("Gräber danach 'buried'", MemoryManager.graves_state() == "buried")
	_check("bury_family zweimal = false", MemoryManager.bury_family() == false)


# ── EncounterManager: Mini-Dungeons & Unique-Champions (§8.2) ─────────────────
func _test_encounter_manager() -> void:
	print("· EncounterManager (Mini-Dungeons & Champions §8.2)")
	_reset_state()

	# Roster-Parität: Kläffer ist im Backend vorhanden (Hallen-Thema nutzt ihn).
	_check("Kläffer im Roster (Parität)", CombatData.ENEMY_TYPES.has("klaeffer"))
	_check("Kläffer ist mechanischer Schwarm", String(CombatData.ENEMY_TYPES["klaeffer"]["class"]) == "MECHANICAL" and bool(CombatData.ENEMY_TYPES["klaeffer"].get("swarm", false)))

	# Hallen-Themen: 3, deterministisch via roll (0.0 -> erstes).
	_check("3 Hallen-Themen", EncounterManager.HALL_THEMES.size() == 3)
	_check("roll 0.0 -> Rattennest", EncounterManager.roll_hall_theme(0.0)["id"] == "rats")
	_check("roll 0.99 -> Banditenloch", EncounterManager.roll_hall_theme(0.99)["id"] == "outlaws")
	var theme_types_ok: bool = true
	for th in EncounterManager.HALL_THEMES:
		if not CombatData.ENEMY_TYPES.has(String(th["type"])):
			theme_types_ok = false
	_check("alle Themen-Typen im Roster", theme_types_ok)

	# Champion-Wurf: ~30 % (WorldManager.UNIQUE_CHAMPION_CHANCE); deterministisch via roll.
	_check("roll 0.10 < 0.30 -> Champion", EncounterManager.is_unique_pack(0.10) == true)
	_check("roll 0.50 >= 0.30 -> kein Champion", EncounterManager.is_unique_pack(0.50) == false)
	var rats: Dictionary = EncounterManager.roll_hall_theme(0.0)
	_check("Rudel normal = Themen-Anzahl", EncounterManager.pack_size(rats, false) == 11)
	_check("Rudel mit Champion = +3", EncounterManager.pack_size(rats, true) == 14)

	# Champion-Namen: aus der Liste, deterministisch.
	_check("champion_name(0.0) = erster", EncounterManager.champion_name(0.0) == EncounterManager.UNIQUE_NAMES[0])
	_check("champion_name in Liste", EncounterManager.UNIQUE_NAMES.has(EncounterManager.champion_name(0.99)))

	# Champion-Aufbau: ×6 Leben (× Faktor), +Panzerung, benannt, als Boss & Unique.
	var champ: CombatTarget = EncounterManager.make_champion("klaeffer", 0.0, 1.0)
	var base_hp: int = int(CombatData.ENEMY_TYPES["klaeffer"]["hp"])   # 40
	_check("Champion HP = 6x Basis", champ.max_health == base_hp * 6 and champ.health == champ.max_health)
	_check("Champion +Panzerung", champ.armor == int(CombatData.ENEMY_TYPES["klaeffer"]["armor"]) + 6)
	_check("Champion ist Unique+Boss", champ.is_unique and champ.is_boss)
	_check("Champion benannt", champ.display_name == EncounterManager.UNIQUE_NAMES[0])
	var champ2: CombatTarget = EncounterManager.make_champion("outlaw", 0.0, 1.5)
	_check("hp_mul skaliert Leben", champ2.max_health == roundi(int(CombatData.ENEMY_TYPES["outlaw"]["hp"]) * 6.0 * 1.5))

	# Beute-Kontrakt: garantiertes Legendary aus benennbaren Slots, zählt als Boss-Kill.
	var loot: Dictionary = EncounterManager.champion_loot()
	_check("Champion-Beute garantiert Legendary", loot["legendary_guaranteed"] == true)
	_check("Legendary-Slots benennbar", loot["legendary_slots"] == ["weapon", "armor", "gadget", "boots", "helmet"])
	_check("Champion-Beute: 2 Boss-Kisten, x2 Gold", int(loot["boss_chests"]) == 2 and int(loot["gold_mult"]) == 2)
	_check("Champion zählt als Boss-Kill", loot["counts_as_boss"] == true)

	# Konkrete Champion-Beute via ProgressionManager: garantiertes benanntes Legendary.
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var reward: Dictionary = EncounterManager.champion_reward(rng)
	_check("Champion-Reward: Legendary", String(reward["gear"]["rarity"]) == "legendary" and reward["gear"].has("legendary_power"))
	_check("Champion-Reward: Slot benennbar", EncounterManager.CHAMPION_LEGENDARY_SLOTS.has(String(reward["gear"]["slot"])))
	_check("Champion-Reward: zählt als Boss", reward["counts_as_boss"] == true)


# ── ProgressionManager: Itemization (Seltenheiten, Affixe, Legendaries, Tech) §8.1 ──
func _test_progression_manager() -> void:
	print("· ProgressionManager (Itemization §8.1)")
	_reset_state()

	# Seltenheiten.
	_check("4 Seltenheiten", ProgressionManager.RARITY_ORDER.size() == 4)
	_check("Legendär mult 4.2", is_equal_approx(float(ProgressionManager.RARITY["legendary"]["mult"]), 4.2))

	# Affix-Roll: deterministisch via quality_roll. q=0.5 -> Faktor 1.0, val = round(base*mult*factor).
	var aff: Dictionary = ProgressionManager.roll_affix("hp", 1.0, 14.0 / 12.0, 0.5)
	_check("roll_affix hp @q0.5 = 14", int(aff["val"]) == 14 and is_equal_approx(float(aff["q"]), 0.5))
	_check("roll_affix Wert >= 1", int(ProgressionManager.roll_affix("armor", 1.0, 0.1, 0.0)["val"]) >= 1)

	# Seltenheits-Wurf deterministisch.
	_check("roll_rarity 0.0 = common", ProgressionManager.roll_rarity(0.0, 0.0) == "common")
	_check("roll_rarity 0.999 = legendary", ProgressionManager.roll_rarity(0.0, 0.999) == "legendary")

	# make_gear (seedbar): Struktur, Affix-Anzahl je Seltenheit, Legendär-Kraft.
	var grng := RandomNumberGenerator.new()
	grng.seed = 7
	var epic: Dictionary = ProgressionManager.make_gear("armor", "epic", "", grng)
	_check("make_gear Slot/Seltenheit", String(epic["slot"]) == "armor" and String(epic["rarity"]) == "epic")
	_check("make_gear Haupt-Stat (armor)", String(epic["stat"]["key"]) == "armor" and int(epic["stat"]["val"]) >= 1)
	_check("make_gear epic = 2 Affixe", (epic["affixes"] as Array).size() == 2)
	var common: Dictionary = ProgressionManager.make_gear("boots", "common", "", grng)
	_check("make_gear common = 0 Affixe", (common["affixes"] as Array).size() == 0)

	# Legendär: benannte Kraft; erzwungene Boss-Kraft.
	var leg: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "", grng)
	_check("Legendär hat benannte Kraft", leg.has("legendary_power") and String(leg["name"]) != "")
	var forced: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", grng)
	_check("force_power -> Golem-Faust", String(forced["legendary_power"]) == "overcharge" and String(forced["name"]) == "Golem-Faust")
	var vane: Dictionary = ProgressionManager.make_gear("armor", "legendary", "vaneward", grng)
	_check("force_power -> Wachsherz-Kürass", String(vane["name"]) == "Wachsherz-Kürass")

	# Ableitungen: Wert, Stat-Summe, Fußabdruck.
	_check("gear_value legendär > common", ProgressionManager.gear_value(leg) > ProgressionManager.gear_value(common))
	_check("gear_stat_of armor summiert", ProgressionManager.gear_stat_of(epic, "armor") >= int(epic["stat"]["val"]))
	_check("gear_foot Rüstung 2x2", ProgressionManager.gear_foot(epic) == Vector2i(2, 2))
	_check("gear_cells Rüstung = 4", ProgressionManager.gear_cells(epic) == 4)

	# Tech-Modul: Haupt-Stat skaliert mit Seltenheit.
	var tech: Dictionary = ProgressionManager.make_tech("schaden", "rare")
	_check("make_tech Stat = round(base*mult)", int(tech["stat"]["val"]) == roundi(5.0 * 1.8) and String(tech["slot"]) == "tech")

	# ── Perk-Baum (Fallout-Achse §7.5.1) ──
	_reset_state()
	_check("3 Perk-Zweige", ProgressionManager.PERK_BRANCHES.size() == 3)
	# Kauf: Punkt vorhanden, Tier 1 sofort; Rang & Punkte aktualisieren, Wirkwert = Rang×per.
	GameState.level = 1
	GameState.perk_points = 3
	_check("scharf kaufbar (Tier 1)", ProgressionManager.perk_can_buy("scharf"))
	_check("buy_perk scharf", ProgressionManager.buy_perk("scharf") == true and ProgressionManager.perk_rank("scharf") == 1)
	_check("Punkt abgezogen", GameState.perk_points == 2)
	_check("perk_val = Rang×per (4)", ProgressionManager.perk_val("scharf") == 4)
	ProgressionManager.buy_perk("scharf")
	_check("perk_val Rang 2 = 8", ProgressionManager.perk_val("scharf") == 8)
	ProgressionManager.buy_perk("scharf")
	_check("Max-Rang: nicht weiter kaufbar", ProgressionManager.perk_can_buy("scharf") == false and GameState.perk_points == 0)

	# Tier-Gating: Kapstein braucht Level 14 + 6 Punkte im Zweig.
	_reset_state()
	GameState.level = 5
	GameState.perk_points = 20
	_check("Kapstein Level 5 gesperrt", ProgressionManager.perk_can_buy("cap_gun") == false)
	GameState.level = 14
	# 6 Punkte im gun-Zweig investieren.
	ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf")
	ProgressionManager.buy_perk("schnell"); ProgressionManager.buy_perk("schnell"); ProgressionManager.buy_perk("schnell")
	_check("Zweig-Punkte gun = 6", ProgressionManager.branch_points("gun") == 6)
	_check("Kapstein jetzt kaufbar", ProgressionManager.perk_can_buy("cap_gun"))
	ProgressionManager.buy_perk("cap_gun")
	_check("has_cap gun", ProgressionManager.has_cap("gun"))
	# XOR: nur ein Kapstein — die anderen sind gesperrt.
	GameState.level = 14
	# genug tech-Punkte für Tier 4 investieren, damit nur die xor-Sperre greift.
	ProgressionManager.buy_perk("gurt"); ProgressionManager.buy_perk("gurt"); ProgressionManager.buy_perk("gurt")
	ProgressionManager.buy_perk("aasgeier"); ProgressionManager.buy_perk("aasgeier"); ProgressionManager.buy_perk("aasgeier")
	_check("zweiter Kapstein xor-gesperrt", ProgressionManager.perk_can_buy("cap_tech") == false and ProgressionManager.xor_blocked("cap_tech"))

	# Respec: erst nach Reveal, erstattet Ränge als Punkte, kostet Gold + Dampfkern.
	_reset_state()
	GameState.level = 5
	GameState.perk_points = 3
	ProgressionManager.buy_perk("zaeh"); ProgressionManager.buy_perk("panzer")   # 2 Ränge im grit-Zweig
	GameState.is_revealed = false
	_check("Respec vor Reveal gesperrt", ProgressionManager.do_respec() == false)
	GameState.is_revealed = true
	GameState.gold = 1000
	GameState.add_item("dampfkern", 2)
	var pts_before: int = GameState.perk_points
	_check("do_respec erfolgreich", ProgressionManager.do_respec() == true)
	_check("Ränge erstattet (+2 Punkte)", GameState.perk_points == pts_before + 2 and GameState.perks.is_empty())
	_check("Respec zieht Dampfkern ab", GameState.item_count("dampfkern") == 1)


# ── RiftManager: Abstieg-Endlosmodus (Biome, Mods, Tiefen-Skalierung) §7.5.6/§8.1 ──
func _test_rift_manager() -> void:
	print("· RiftManager (Abstieg §7.5.6)")

	# Biome rotieren alle 5 Ebenen, dann von vorn.
	_check("5 Abstieg-Biome", RiftManager.BIOMES.size() == 5)
	var ids: Array = []
	for d in [1, 6, 11, 16, 21, 26]:
		ids.append(String(RiftManager.biome_for(d)["id"]))
	_check("Biom-Rotation stollen..herz..stollen", str(ids) == str(["stollen", "frost", "magma", "sporen", "herz", "stollen"]))
	_check("Biom-Wechsel bei Bandgrenze (5->6)", RiftManager.biome_changed(5, 6) == true)
	_check("kein Wechsel im Band (11->12)", RiftManager.biome_changed(11, 12) == false)

	# Modifikatoren.
	_check("4 Modifikatoren", RiftManager.MODS.size() == 4)
	_check("roll_mod 0.0 = Andrang", String(RiftManager.roll_mod(0.0)["id"]) == "horde")
	_check("roll_mod 0.99 = Elite-Nest", String(RiftManager.roll_mod(0.99)["id"]) == "elite")

	# Tiefen-Skalierung (deterministische Formeln).
	_check("HP-Faktor Ebene 3 = 2.0", is_equal_approx(RiftManager.enemy_hp_mul(3, "", 0), 2.0))
	_check("HP-Faktor Ebene 3 + Überdruck = 2.6", is_equal_approx(RiftManager.enemy_hp_mul(3, "brute", 0), 2.6))
	_check("HP-Faktor Ebene 1 + NG+1 = 1.6", is_equal_approx(RiftManager.enemy_hp_mul(1, "", 1), 1.6))
	_check("Rasende Meute = Tempo x1.25", is_equal_approx(RiftManager.enemy_speed_mul("swift"), 1.25))
	_check("Dichte Ebene 6 + Andrang = 3.0", is_equal_approx(RiftManager.density(6, "horde"), 3.0))
	_check("Elite-Zahl Ebene 9 (Basis 1) = 4", RiftManager.elite_count(9, 1, "") == 4)
	_check("Elite-Nest +2", RiftManager.elite_count(9, 1, "elite") == 6)

	# Superboss alle 3 Ebenen.
	_check("Superboss auf Ebene 3", RiftManager.has_superboss(3))
	_check("Superboss auf Ebene 6", RiftManager.has_superboss(6))
	_check("kein Superboss auf Ebene 4", not RiftManager.has_superboss(4))


# ── SaveManager: Persistenz (serialize/deserialize, JSON, Datei-Slots) §2.3 ───
func _test_save_manager() -> void:
	print("· SaveManager (Persistenz §2.3)")
	_reset_state()

	# Einen bunten Zustand aufbauen.
	GameState.current_chapter = 8
	GameState.is_revealed = true
	GameState.chosen_guild = "rebels"
	GameState.level = 12
	GameState.xp = 55
	GameState.perk_points = 2
	GameState.perks = { "scharf": 3, "krit": 1 }
	GameState.gold = 777
	GameState.inventory = { "schrott": 4, "zahnrad": 1, "dampfkern": 2 }
	GameState.set_building_level("saloon", 3)
	GameState.kills = 140
	GameState.quests = { "q_rebels5": "done", "q_rebels8": "active" }
	GameState.quest_base = { "q_rebels8": 120 }
	GameState.memories_found = 9
	GameState.memorials_seen = ["doorframe", "photo"]
	GameState.family_buried = false
	GameState.codex = ["reveal", "steuerwalzen", "familie"]
	var srng := RandomNumberGenerator.new(); srng.seed = 1
	GameState.equip = { "weapon": ProgressionManager.make_gear("weapon", "legendary", "overcharge", srng) }

	# Dictionary-Roundtrip: serialisieren, Zustand zurücksetzen, wiederherstellen.
	var snap: Dictionary = SaveManager.serialize()
	_check("Save trägt Version", int(snap["version"]) == SaveManager.SAVE_VERSION)
	_reset_state()
	_check("Reset leert Zustand", GameState.level == 1 and GameState.gold == 0)
	SaveManager.deserialize(snap)
	_check("Roundtrip: Kapitel/Gilde", GameState.current_chapter == 8 and GameState.chosen_guild == "rebels")
	_check("Roundtrip: Level/Gold", GameState.level == 12 and GameState.gold == 777)
	_check("Roundtrip: Perks", ProgressionManager.perk_rank("scharf") == 3 and GameState.perk_points == 2)
	_check("Roundtrip: Quests", String(GameState.quests["q_rebels5"]) == "done" and int(GameState.quest_base["q_rebels8"]) == 120)
	_check("Roundtrip: roter Faden", GameState.memories_found == 9 and GameState.memorials_seen == ["doorframe", "photo"] and GameState.codex.has("familie"))
	_check("Roundtrip: Gebäude", GameState.building_level("saloon") == 3)
	_check("Roundtrip: Loadout", EquipManager.is_equipped("weapon") and String(EquipManager.equipped("weapon")["legendary_power"]) == "overcharge")

	# JSON-Roundtrip (Zahlen kommen als Float zurück -> defensiver Cast).
	var json: String = SaveManager.to_json()
	_reset_state()
	_check("from_json ok", SaveManager.from_json(json) == true)
	_check("JSON-Roundtrip: Level/Kills als int", GameState.level == 12 and GameState.kills == 140 and typeof(GameState.level) == TYPE_INT)
	_check("JSON-Roundtrip: Inventar", GameState.item_count("dampfkern") == 2)
	_check("from_json Müll = false", SaveManager.from_json("nicht json {{{") == false)

	# Defensiv: leere Daten -> sichere Defaults, kein Crash.
	_reset_state()
	SaveManager.deserialize({})
	_check("Defaults aus leerer Save", GameState.level == 1 and GameState.current_chapter == 1 and GameState.chosen_guild == null and GameState.item_count("schrott") == 0)

	# Datei-Slot-Roundtrip (user://, headless verfügbar).
	_reset_state()
	GameState.level = 20
	GameState.gold = 999
	GameState.chosen_guild = "smugglers"
	_check("save_to_slot", SaveManager.save_to_slot(3) == true and SaveManager.has_slot(3))
	_reset_state()
	_check("load_from_slot", SaveManager.load_from_slot(3) == true and GameState.level == 20 and GameState.gold == 999 and GameState.chosen_guild == "smugglers")
	_check("load leerer Slot = false", SaveManager.load_from_slot(9) == false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.slot_path(3)))


# ── EquipManager: Loadout, Stat-Aggregation & legendäre Sets §7.4/§7.4.4 ──────
func _test_equip_manager() -> void:
	print("· EquipManager (Loadout & Sets §7.4.4)")
	_reset_state()
	GameState.equip = {}
	GameState.bag = []
	GameState.ammo = AmmoData.fresh()
	GameState.mag = AmmoData.fresh_mags()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	# Slot-Akzeptanz.
	var wpn: Dictionary = ProgressionManager.make_gear("weapon", "rare", "", rng)
	var arm: Dictionary = ProgressionManager.make_gear("armor", "rare", "", rng)
	var tech: Dictionary = ProgressionManager.make_tech("schaden", "epic")
	_check("Waffe passt in weapon-Slot", EquipManager.slot_accepts("weapon", wpn))
	_check("Waffe passt NICHT in helmet-Slot", EquipManager.slot_accepts("helmet", wpn) == false)
	_check("Tech-Modul passt in plate-Slot", EquipManager.slot_accepts("plate1", tech))
	_check("Rüstung passt NICHT in plate-Slot", EquipManager.slot_accepts("plate1", arm) == false)

	# Anlegen/Ablegen.
	_check("equip Waffe", EquipManager.equip_item(wpn, "weapon") and EquipManager.is_equipped("weapon"))
	_check("equip in falschen Slot scheitert", EquipManager.equip_item(wpn, "helmet") == false)
	EquipManager.equip_item(arm, "armor")
	EquipManager.equip_item(tech, "plate1")
	_check("3 Teile getragen", EquipManager.worn().size() == 3)
	var removed: Dictionary = EquipManager.unequip("plate1")
	_check("unequip gibt Teil zurück & leert Slot", not removed.is_empty() and not EquipManager.is_equipped("plate1"))

	# Stat-Aggregation über angelegte Teile.
	_reset_state(); GameState.equip = {}
	var a1: Dictionary = ProgressionManager.make_gear("armor", "epic", "", rng)
	var h1: Dictionary = ProgressionManager.make_gear("helmet", "epic", "", rng)
	EquipManager.equip_item(a1, "armor")
	EquipManager.equip_item(h1, "helmet")
	var expected_armor: int = ProgressionManager.gear_stat_of(a1, "armor") + ProgressionManager.gear_stat_of(h1, "armor")
	_check("stat_total armor summiert Loadout", EquipManager.stat_total("armor") == expected_armor)

	# ── Legendäre Sets ──
	_reset_state(); GameState.equip = {}
	# Direktorat (2-teilig): Wachsherz-Kürass (vaneward) + Golem-Faust (overcharge).
	var vane: Dictionary = ProgressionManager.make_gear("armor", "legendary", "vaneward", rng)
	var golem: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	EquipManager.equip_item(vane, "armor")
	_check("Set 1/2: noch kein Bonus", EquipManager.set_piece_count("direktorat") == 1 and EquipManager.granted_powers().is_empty())
	_check("nur getragene Kraft vaneward aktiv", EquipManager.has_power("vaneward") and not EquipManager.has_power("cap_grit"))
	EquipManager.equip_item(golem, "weapon")
	_check("Set 2/2 vollständig", EquipManager.set_piece_count("direktorat") == 2)
	_check("Set verleiht Perk cap_grit", EquipManager.has_power("cap_grit") and EquipManager.granted_powers().has("cap_grit"))

	# Grenzland (3-teilig): gestufte Boni (2 -> Krit-Stat, 3 -> critchain).
	_reset_state(); GameState.equip = {}
	var trommel: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "spread11", rng)
	var sohlen: Dictionary = ProgressionManager.make_gear("boots", "legendary", "plunder", rng)
	var visier: Dictionary = ProgressionManager.make_gear("helmet", "legendary", "critbase", rng)
	EquipManager.equip_item(trommel, "weapon")
	EquipManager.equip_item(sohlen, "boots")
	_check("Grenzland 2/3: +8 Krit-Bonus", EquipManager.set_piece_count("grenzland") == 2 and EquipManager.set_stat_bonus("crit") == 8)
	_check("Grenzland 2/3: noch kein critchain", EquipManager.has_power("critchain") == false)
	EquipManager.equip_item(visier, "helmet")
	_check("Grenzland 3/3: verleiht critchain", EquipManager.set_piece_count("grenzland") == 3 and EquipManager.has_power("critchain"))


# ── PlayerStats: effektive Kampfwerte (Kapstein: alle Systeme zusammen) §6/§7.5 ──
func _test_player_stats() -> void:
	print("· PlayerStats (effektive Werte — Kapstein)")
	_reset_state()
	GameState.equip = {}
	GameState.bag = []
	GameState.ammo = AmmoData.fresh()
	GameState.mag = AmmoData.fresh_mags()

	# Basiswerte ohne Boni.
	# Gegen die TABELLE geprueft, nicht gegen abgeschriebene Zahlen: Balance-Werte aendern sich,
	# die Formel „ohne Boni kommt die Basis heraus" nicht.
	var kb: Dictionary = CombatData.WEAPONS["karabiner"]
	_check("Basis-Schaden Karabiner = Tabellenwert (%d)" % int(kb["base"]),
		PlayerStats.damage_per_bullet("karabiner") == int(kb["base"]))
	_check("Basis-Feuerrate Karabiner = Tabellenwert (%d ms)" % int(kb["fire_ms"]),
		PlayerStats.fire_ms("karabiner") == int(kb["fire_ms"]))
	_check("Basis max_hp (L1) = 100", PlayerStats.max_hp() == 100)
	_check("Basis Krit = 0", is_equal_approx(PlayerStats.crit_chance(), 0.0))
	_check("Krit-Mult = 2.0", is_equal_approx(PlayerStats.crit_mult(), 2.0))
	_check("Schaden-genommen-Faktor (0 Rüstung) = 1.0", is_equal_approx(PlayerStats.damage_taken_mul(), 1.0))
	_check("Basis Tempo/Regen/Magnet/Loot", PlayerStats.move_speed() == 240.0 and PlayerStats.regen_rate() == 8 and PlayerStats.magnet_dist() == 130 and is_equal_approx(PlayerStats.loot_mul(), 1.0))
	_check("Basis Spread=7, Pierce=0", PlayerStats.spread_count() == 7 and PlayerStats.pierce() == 0)

	# Perk-Beitrag: Scharfschütze Rang 3 (+4/Rang) -> +12 Schaden.
	GameState.level = 1
	GameState.perk_points = 3
	ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf"); ProgressionManager.buy_perk("scharf")
	var basis: int = int(CombatData.WEAPONS["karabiner"]["base"])
	_check("Perk Scharfschütze: Schaden %d+12" % basis,
		PlayerStats.damage_per_bullet("karabiner") == basis + 12)

	# Werkstatt-Upgrade + Ausrüstung + Legendär-Kraft (overcharge x1.18).
	_reset_state(); GameState.equip = {}
	GameState.upgrades["damage"] = 2   # +12
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var wpn: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	var dmg_stat: int = ProgressionManager.gear_stat_of(wpn, "damage")
	EquipManager.equip_item(wpn, "weapon")
	var expected: int = roundi((int(CombatData.WEAPONS["karabiner"]["base"]) + 12 + dmg_stat) * 1.18)
	_check("Upgrade+Ausrüstung+Golem-Faust (x1.18)", PlayerStats.damage_per_bullet("karabiner") == expected)

	# Set-Integration: Direktorat verleiht cap_grit -> max_hp x1.2 & Schaden-genommen x0.8.
	_reset_state(); GameState.equip = {}
	var hp_base: int = PlayerStats.max_hp()   # 100
	var vane: Dictionary = ProgressionManager.make_gear("armor", "legendary", "vaneward", rng)
	var golem: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "overcharge", rng)
	EquipManager.equip_item(vane, "armor")
	EquipManager.equip_item(golem, "weapon")
	var hp_stat: int = ProgressionManager.gear_stat_of(vane, "hp")   # Rüstung hat i. d. R. keinen hp-Stat -> 0
	_check("Set cap_grit hebt max_hp um x1.2", PlayerStats.max_hp() == roundi((hp_base + hp_stat) * 1.2))
	# Schaden genommen: (100/(100+armor*9)) * 0.8 (Wachsherz-Kürass zusätzlich x0.85).
	var armor: int = PlayerStats.player_armor()
	var expected_dtm: float = (100.0 / (100.0 + armor * 9.0)) * 0.8 * 0.85
	_check("Set+Kürass senken Schaden-genommen", is_equal_approx(PlayerStats.damage_taken_mul(), expected_dtm))

	# Beute & Spread über Legendaries + NG+.
	_reset_state(); GameState.equip = {}
	GameState.ng_plus = 2   # +0.70
	var sohlen: Dictionary = ProgressionManager.make_gear("boots", "legendary", "plunder", rng)
	var trommel: Dictionary = ProgressionManager.make_gear("weapon", "legendary", "spread11", rng)
	EquipManager.equip_item(sohlen, "boots")
	EquipManager.equip_item(trommel, "weapon")
	_check("Loot-Faktor: Plünderer(+0.25)+NG+2(+0.70) = 1.95", is_equal_approx(PlayerStats.loot_mul(), 1.95))
	_check("Spread mit Dolores' Trommel = 11", PlayerStats.spread_count() == 11)
	_check("Magnet +Plünderer-Sohlen (+60)", PlayerStats.magnet_dist() == 130 + 60)


func _test_world_scale() -> void:
	print("· Produktions-Maßstab (Krater 5000 m — GDD §1.4)")
	_check("Weltgröße = 5000 m", WorldManager.WORLD_METERS == 5000.0)
	_check("Skalierung 2000 Einheiten → ×2,5 m", WorldManager.METERS_PER_UNIT == 2.5)
	_check("Lauftempo = 4,7 m/s", WorldManager.PLAYER_SPEED_MS == 4.7)
	_check("Rustwater (300,300) → Szene (750, 0, −750)",
		WorldManager.world_to_scene(Vector2(300, 300)).is_equal_approx(Vector3(750, 0, -750)))
	_check("Eisernes Herz → Szene (2500, 0, −4875)",
		WorldManager.poi_scene_position("eisernes_herz").is_equal_approx(Vector3(2500, 0, -4875)))
	_check("Sprengtor-Linie liegt bei z = −2000 m",
		is_equal_approx(WorldManager.world_to_scene(Vector2(0, WorldManager.BORDER_S1_S2_Y)).z, -2000.0))
	var rt: Vector3 = WorldManager.world_to_scene(Vector2(1234, 567))
	_check("scene_to_world ist die exakte Umkehrung",
		WorldManager.scene_to_world(rt).is_equal_approx(Vector2(1234, 567)))
	var hub_dist: float = WorldManager.poi_scene_position("rustwater").distance_to(
		WorldManager.poi_scene_position("zugdepot"))
	_check("Pacing: Rustwater→Zugdepot ≥ 1000 m (Hub-Abstand, §1.4)", hub_dist >= 1000.0)
	_check("Pacing: Querung Rustwater→Zugdepot dauert Minuten (> 180 s)",
		hub_dist / WorldManager.PLAYER_SPEED_MS > 180.0)


## HUD-Verankerung und Eingabewege — zwei Fehler, die nur im laufenden Fenster sichtbar sind.
func _test_hud_layout() -> void:
	print("· HUD-Verankerung & Eingabe")
	# ── Die Weltkarte liess sich nicht oeffnen ────────────────────────────────
	# Godots Maus-Emulation erzeugt aus EINEM Klick zwei Ereignisse: erst einen Finger-Tipp,
	# dann den Mausknopf. Beide liefen durch `_handle_overlay_tap`, und weil das ein Umschalter
	# ist, ging die Karte im ersten auf und im zweiten sofort wieder zu.
	_check("Maus-Emulation ist aus (sonst zaehlt jeder Klick doppelt)",
		not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)))

	# ── Der Schuss-Knopf lag ausserhalb des Bildes ────────────────────────────
	# `position` ist die Lage relativ zur Elternecke, nicht der Abstand zum Anker. Nach
	# `add_child` gesetzt — und `_ready` laeuft danach — zaehlt sie absolut: aus −146 wurde die
	# Bildschirmposition −146. Raender sind dagegen immer ankerrelativ.
	var b := FireButton.new()
	add_child(b)   # erst im Baum laeuft `_ready` und setzt Anker und Raender
	_check("Schuss-Knopf haengt unten rechts", is_equal_approx(b.anchor_left, 1.0)
		and is_equal_approx(b.anchor_top, 1.0))
	# Godots eigene Rechnung nachvollziehen: Kante = Anker x Fenstermass + Rand.
	for schirm in [Vector2(1152, 648), Vector2(720, 1280), Vector2(2400, 1080)]:
		var links: float = b.anchor_left * schirm.x + b.offset_left
		var oben: float = b.anchor_top * schirm.y + b.offset_top
		var rechts: float = b.anchor_right * schirm.x + b.offset_right
		var unten: float = b.anchor_bottom * schirm.y + b.offset_bottom
		var drin: bool = links >= 0.0 and oben >= 0.0 and rechts <= schirm.x and unten <= schirm.y
		_check("Schuss-Knopf liegt bei %dx%d im Bild" % [int(schirm.x), int(schirm.y)], drin,
			"[%.0f, %.0f] bis [%.0f, %.0f]" % [links, oben, rechts, unten])
		if schirm == Vector2(1152, 648):
			_check("Und zwar mit %d px Abstand zur unteren rechten Ecke" % int(FireButton.MARGIN),
				is_equal_approx(schirm.x - rechts, FireButton.MARGIN)
				and is_equal_approx(schirm.y - unten, FireButton.MARGIN))
			_check("Er ist quadratisch mit dem doppelten Radius",
				is_equal_approx(rechts - links, FireButton.RADIUS * 2.0))
	_check("Die Trefferpruefung liegt auf dem gezeichneten Kreis",
		b.hits(b.center()) and not b.hits(b.center() + Vector2(FireButton.RADIUS * 2.0, 0.0)))
	b.queue_free()


## Zoom: von Hand, nicht automatisch (siehe CAM_ZOOM_STEPS).
##
## Der Kamera-Abstand war eine Konstante, aus der ein konstanter Versatz abgeleitet wurde. Jetzt
## ist er verstellbar — und damit haengen zwei Dinge daran, die stillschweigend brechen koennen:
## die Groesse der Figur im Bild und die Reichweite der Schattenkaskaden.
func _test_camera_zoom() -> void:
	print("· Kamera-Zoom")
	var steps: Array = OverworldView.CAM_ZOOM_STEPS
	_check("Mehrere Zoomstufen vorhanden", steps.size() >= 3)
	_check("Zu jeder Stufe gehoert ein Name",
		OverworldView.CAM_ZOOM_NAMES.size() == steps.size())
	var steigend: bool = true
	for i in range(1, steps.size()):
		if float(steps[i]) <= float(steps[i - 1]):
			steigend = false
	_check("Stufen sind aufsteigend sortiert", steigend)
	_check("Vorgabestufe liegt im gueltigen Bereich",
		OverworldView.CAM_ZOOM_DEFAULT >= 0 and OverworldView.CAM_ZOOM_DEFAULT < steps.size())
	_check("Spanne mindestens Faktor 2", float(steps[-1]) / float(steps[0]) >= 2.0,
		"%.1f bis %.1f m" % [float(steps[0]), float(steps[-1])])

	# Bildanteil der Figur: Sichthoehe = 2 * Abstand * tan(FOV/2).
	var ow := OverworldView.new()
	var anteil: Callable = func(d: float) -> float:
		return 1.8 / (2.0 * d * tan(deg_to_rad(OverworldView.CAM_FOV * 0.5))) * 100.0
	var weit: float = anteil.call(float(steps[-1]))
	var nah: float = anteil.call(float(steps[0]))
	_check("Weiteste Stufe trifft die Diablo-Spanne (12–15 %% der Bildhoehe)",
		weit >= 11.5 and weit <= 15.5, "%.1f %%" % weit)
	_check("Naechste Stufe zeigt die Figur deutlich groesser (> 22 %%)", nah > 22.0,
		"%.1f %%" % nah)
	_check("Auch die weiteste Stufe bleibt lesbar (> 10 %%)", weit > 10.0)

	# Schatten: Die hintere Bildkante darf nicht aus den Kaskaden fallen. Der obere
	# Frustumrand liegt (Neigung − halbes Sichtfeld) unter der Waagerechten.
	var rand_deg: float = OverworldView.CAM_PITCH - OverworldView.CAM_FOV * 0.5
	var schlimmster: float = 0.0
	for d in steps:
		var hoehe: float = float(d) * sin(deg_to_rad(OverworldView.CAM_PITCH))
		schlimmster = maxf(schlimmster, hoehe / sin(deg_to_rad(rand_deg)))
	_check("Schattenkaskaden reichen bis zur hintersten Bildkante (%.1f m von %.0f m)"
		% [schlimmster, OverworldView.CAM_SHADOW_M],
		schlimmster < OverworldView.CAM_SHADOW_M)

	# Der Versatz muss den Abstand exakt einhalten — er wird jetzt gerechnet statt konstant.
	for d in steps:
		var off: Vector3 = ow._cam_offset(float(d))
		if not is_equal_approx(off.length(), float(d)):
			_check("Versatz haelt den Abstand bei %.1f m" % float(d), false, "%.3f m" % off.length())
	_check("Versatz haelt bei jeder Stufe exakt den Abstand", true)
	var off0: Vector3 = ow._cam_offset(float(steps[0]))
	_check("Neigung bleibt bei jeder Stufe gleich (%.0f°)" % OverworldView.CAM_PITCH,
		is_equal_approx(rad_to_deg(asin(off0.y / off0.length())), OverworldView.CAM_PITCH))

	# Klemmung an beiden Enden.
	GameState.cam_zoom = -5
	_check("Zu kleiner Index wird auf die naechste Stufe geklemmt", ow._zoom_step() == 0)
	GameState.cam_zoom = 99
	_check("Zu grosser Index wird auf die weiteste Stufe geklemmt",
		ow._zoom_step() == steps.size() - 1)
	GameState.cam_zoom = OverworldView.CAM_ZOOM_DEFAULT
	ow.free()


## Topografie: Die Senke ist eine FORMEL, kein Modell.
##
## Der Boden war eine flache Platte bei y = 0, und die Figur bekam ihr y nie von irgendwoher.
## Ein modelliertes Gelaende waere Kulisse geblieben, durch die man hindurchspaziert. Diese
## Tests halten die Eigenschaften fest, auf die sich alles andere verlaesst: exakt flach
## ausserhalb, stetig ueberall, begehbar steil.
func _test_terrain() -> void:
	print("· Topografie (Senken als Formel)")
	_check("Genau eine Gelaendeform definiert", WorldManager.TERRAIN.size() >= 1)
	var f: Dictionary = WorldManager.TERRAIN[0]
	var c: Vector3 = WorldManager.feature_center(f)
	var R: float = float(f["radius"])
	var reach: float = WorldManager.feature_reach(f)
	_check("Krater ist %.0f m im Durchmesser" % (R * 2.0), is_equal_approx(R * 2.0, 30.0),
		"%.1f m" % (R * 2.0))
	_check("In der Mitte volle Tiefe (-%.1f m)" % float(f["depth"]),
		is_equal_approx(WorldManager.height_at(c.x, c.z), -float(f["depth"])))
	_check("Am Kraterrand wieder auf null",
		is_zero_approx(WorldManager.height_at(c.x + R, c.z)))
	_check("Hinter dem Wall exakt flach",
		is_zero_approx(WorldManager.height_at(c.x + reach + 1.0, c.z)))
	_check("Der Rest der Welt bleibt unberuehrt",
		is_zero_approx(WorldManager.height_at(100.0, -100.0))
		and is_zero_approx(WorldManager.height_at(2500.0, -2500.0)))
	_check("Der Auswurfwall ragt heraus",
		WorldManager.height_at(c.x + R * (1.0 + float(f["rim_width"]) * 0.5), c.z) > 0.3)
	# Der flache Grund: die Buehne, auf der der Held erwacht und auf der der Schrott liegt.
	# Eine Schuessel hat keinen — dort faellt der Boden von der Mitte weg sofort weiter ab.
	var boden_r: float = R * float(f["floor"])
	_check("Der Grund ist ueber %.1f m flach" % (boden_r * 2.0),
		is_equal_approx(WorldManager.height_at(c.x - boden_r * 0.9, c.z), -float(f["depth"]))
		and is_equal_approx(WorldManager.height_at(c.x, c.z - boden_r * 0.9), -float(f["depth"])),
		"%.2f m" % WorldManager.height_at(c.x - boden_r * 0.9, c.z))

	# Wand und Rampe. Das ist der Kern der Form: rundum eine Wand, an EINER Stelle ein Weg.
	# Beides wird an derselben Formel gemessen, nur in verschiedene Richtungen.
	var steil := func(deg: float) -> float:
		var a: float = deg_to_rad(deg)
		var dir := Vector2(cos(a), -sin(a))
		var groesste: float = 0.0
		var vor: float = WorldManager.height_at(c.x, c.z)
		var dd: float = 0.0
		while dd <= reach + 1.0:
			dd += 0.05
			var hh: float = WorldManager.height_at(c.x + dir.x * dd, c.z + dir.y * dd)
			groesste = maxf(groesste, rad_to_deg(atan2(absf(hh - vor), 0.05)))
			vor = hh
		return groesste
	var rampe: float = float(f["ramp_deg"])
	_check("Die Rampe ist begehbar (< 35°)", steil.call(rampe) < 35.0,
		"%.1f° bei %.0f°" % [steil.call(rampe), rampe])
	var wand_min: float = 999.0
	for versatz in [120.0, 180.0, 240.0, 300.0]:
		wand_min = minf(wand_min, steil.call(rampe + versatz))
	_check("Ueberall sonst steht eine Wand (> 50°)", wand_min > 50.0, "flachste %.1f°" % wand_min)
	_check("Die Rampe ist die EINZIGE flache Stelle",
		steil.call(rampe) < 35.0 and wand_min > 50.0)

	# Stetigkeit: dicht abtasten, groessten Sprung messen. Eine steile Wand darf steil sein,
	# aber keine Stufe haben — an einer Stufe bleibt man haengen oder faellt hindurch.
	var max_step: float = 0.0
	var d: float = 0.0
	var prev: float = WorldManager.height_at(c.x, c.z)
	for richtung in [0.0, rampe, rampe + 180.0]:
		var ra: float = deg_to_rad(richtung)
		var rd := Vector2(cos(ra), -sin(ra))
		d = 0.0
		prev = WorldManager.height_at(c.x, c.z)
		while d <= reach + 3.0:
			d += 0.05
			var h: float = WorldManager.height_at(c.x + rd.x * d, c.z + rd.y * d)
			max_step = maxf(max_step, absf(h - prev))
			prev = h
	_check("Keine Stufe im Profil (groesster Sprung auf 5 cm < 12 cm)", max_step < 0.12,
		"%.3f m" % max_step)

	# Normalen kommen aus derselben Formel — in der Mitte senkrecht, an der Flanke geneigt.
	_check("Normale in der Mitte zeigt nach oben",
		WorldManager.normal_at(c.x, c.z).is_equal_approx(Vector3.UP))
	_check("Normale auf dem flachen Grund zeigt ebenfalls nach oben",
		WorldManager.normal_at(c.x + R * 0.5, c.z).is_equal_approx(Vector3.UP))
	var n: Vector3 = WorldManager.normal_at(c.x + R * 0.92, c.z)
	_check("Normale an der Wand ist stark geneigt und zeigt bergab",
		n.y < 0.75 and n.x < 0.0, "%s" % n)

	# Die Restflaeche: Ausschneiden darf keine Flaeche verlieren und keine doppelt zaehlen.
	var ow := OverworldView.new()
	var rects: Array = ow._ground_rects()
	var w: float = WorldManager.WORLD_METERS
	var flaeche: float = 0.0
	for r in rects:
		flaeche += r.size.x * r.size.y
	var loch: float = 0.0
	for tf in WorldManager.TERRAIN:
		var rr: float = WorldManager.feature_reach(tf) + OverworldView.TERRAIN_MARGIN_M
		loch += (rr * 2.0) * (rr * 2.0)
	_check("Restflaeche + Loecher = Weltflaeche (nichts verloren, nichts doppelt)",
		absf(flaeche + loch - w * w) < 1.0,
		"%.0f + %.0f = %.0f statt %.0f" % [flaeche, loch, flaeche + loch, w * w])
	# Ueber die SCHMALSTE Kante geprueft, nicht ueber die Flaeche: Aneinanderstossende
	# Rechtecke ueberlappen sich in float32 um rund 2 Hundertstel Millimeter — mal 4600 m
	# Kantenlaenge ergibt das 0,1 m² Scheinflaeche. Eine echte Ueberlappung ist dagegen in
	# BEIDEN Richtungen breit.
	var ueberlappt: String = ""
	var groesster_sliver: float = 0.0
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			var ov: Rect2 = (rects[i] as Rect2).intersection(rects[j])
			var schmal: float = minf(ov.size.x, ov.size.y)
			groesster_sliver = maxf(groesster_sliver, schmal)
			if schmal > 0.01:
				ueberlappt = "%s und %s (%.3f m breit)" % [rects[i], rects[j], schmal]
	_check("Keine zwei Restflaechen ueberlappen sich (groesste Naht %.5f m)" % groesster_sliver,
		ueberlappt == "", ueberlappt)
	# Und das Loch ist wirklich frei.
	var im_loch: bool = false
	for r in rects:
		if r.has_point(Vector2(c.x, c.z)):
			im_loch = true
	_check("Ueber dem Krater liegt keine flache Platte mehr", not im_loch)

	# Regression: Am Kratergrund stand der Platzhalter-Klotz des Ortes und sperrte ihn mit
	# 6,6 m Radius — man lief die Flanke hinunter und blieb unten stehen. Orte mit geformtem
	# Gelaende bekommen deshalb keine Landmarken-Saeule mehr; der Krater IST die Landmarke.
	# Regression: Pisten und Gleise duerfen eine Senke nicht ueberbruecken.
	#
	# Der erste Anlauf tastete die Hoehe nur an den beiden RAENDERN des Streifens ab. Bei 55 m
	# Pistenbreite und 40 m Kraterdurchmesser liegen beide Raender auf flachem Boden — die
	# Strasse spannte sich als Brett ueber das Loch, und Figur wie Truhe verschwanden darunter.
	# Deshalb wird auch QUER unterteilt, und dieser Test faehrt eine Piste mitten durch.
	ow._add_ribbon(c + Vector3(-200.0, 0.0, 0.0), c + Vector3(200.0, 0.0, 0.0),
		27.5, 0.0, 0.06, null)
	var band: MeshInstance3D = null
	for kind in ow.get_children():
		if kind is MeshInstance3D:
			band = kind
	var tiefster: float = 99.0
	var naechster: float = 9999.0
	if band != null and band.mesh != null:
		for v in band.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			tiefster = minf(tiefster, v.y)
			naechster = minf(naechster, Vector2(v.x - c.x, v.z - c.z).length())
	_check("Eine Piste quer durch die Senke wird auch quer unterteilt",
		naechster < 2.0, "naechster Punkt %.1f m von der Mitte" % naechster)
	_check("Und sie folgt dabei bis auf den Grund (%.1f m tief)" % float(f["depth"]),
		tiefster < -float(f["depth"]) + 0.2,
		"tiefster Punkt %.2f m statt %.2f m" % [tiefster, -float(f["depth"]) + 0.06])

	_check("Der Krater-Ort ist als geformt erkannt",
		not ow._terrain_at_poi(String(f["poi"])).is_empty())
	_check("Ein Ort ohne Gelaende bleibt unveraendert",
		ow._terrain_at_poi("rustwater").is_empty())

	# Regression: Die Piste hat den Krater ZUGEDECKT.
	#
	# Gezeichnet wurde sie mit `CORRIDOR_HALF_W` — das sind 27,5 m JE SEITE, also ein 55 m
	# breites Band ueber einer 30-m-Senke. Dazu lief sie bis in den Mittelpunkt des Ortes, also
	# bis auf den Kratergrund. Im Bild sah man deshalb mitten in der Mulde eine harte Kante,
	# an der der Boden wechselte: links Sand mit Textur, rechts die einfarbige Piste.
	_check("Eine Strecke endet am Kraterrand, nicht in der Mitte",
		ow._route_stop_m(String(f["poi"])) >= WorldManager.feature_reach(f),
		"Stopp bei %.1f m, Wallende bei %.1f m"
			% [ow._route_stop_m(String(f["poi"])), WorldManager.feature_reach(f)])
	_check("In offenem Gelaende wird dagegen nicht gekuerzt",
		is_zero_approx(ow._route_stop_m("rattengestruepp")))
	# Gegenprobe an der echten Route: Kein Punkt der Piste darf noch in der Senke liegen.
	var route: Array = ow._trim_route(WorldManager.poi_scene_position("rustwater"),
		c, "rustwater", String(f["poi"]))
	var dist_zur_mitte: float = (route[1] as Vector3).distance_to(c)
	_check("Eine Strecke von Rustwater hoert vor der Senke auf",
		dist_zur_mitte >= float(f["radius"]),
		"endet %.1f m von der Mitte, Kraterrand bei %.1f m" % [dist_zur_mitte, float(f["radius"])])
	ow.free()


## Umlaufrichtung aller selbst gebauten Bodenflaechen.
##
## Der teuerste Fehler des Projekts bisher, und der am schwersten zu sehende: Bodenviereck und
## Gelaendeflicken waren RUECKSEITIG gewickelt. Sichtbar blieben sie trotzdem, weil das
## Sandmaterial aus dem CC0-Modell doppelseitig ist (`cull_mode = CULL_DISABLED`) — aber Godot
## dreht bei einem rueckseitigen Fragment die Normale um, und eine nach unten zeigende Normale
## bekommt kein Sonnenlicht. Der gesamte Boden der Welt lag im blossen Umgebungslicht.
##
## Gemessen im Bild: Helligkeit 0,239 falsch herum gegen 0,963 richtig herum. Die Piste
## daneben war korrekt gewickelt und deshalb hell — DAS war der „Bodenwechsel", ueber den sich
## der Auftraggeber beschwert hat, und der Grund, warum die Wueste aussah wie nasser Lehm.
##
## Die Regel, gegen die hier geprueft wird, stammt aus dem einzigen Bauteil, das nachweislich
## richtig war (`_add_ribbon`): Bei einem VORDERSEITIGEN Dreieck zeigt das Kreuzprodukt
## (v1−v0)×(v2−v0) ENTGEGEN der Schattierungsnormale.
func _test_winding() -> void:
	print("· Umlaufrichtung der Bodenflaechen")
	var ow := OverworldView.new()
	ow._ground_material()
	ow._add_ground_quad(Rect2(Vector2(0.0, -100.0), Vector2(100.0, 100.0)), null)
	ow._add_terrain_patch(WorldManager.TERRAIN[0], null)
	ow._add_ribbon(Vector3.ZERO, Vector3(100.0, 0.0, -100.0), 5.0, 0.0, 0.06, null)
	var namen: Array = ["Bodenviereck", "Gelaendeflicken", "Gleisband"]
	var i: int = 0
	for c in ow.get_children():
		if not (c is MeshInstance3D):
			continue
		var quote: Array = _vorderseitig_anteil(c as MeshInstance3D)
		_check("%s ist vorderseitig gewickelt (%d Dreiecke)" % [String(namen[i]), int(quote[1])],
			int(quote[0]) == int(quote[1]),
			"%d von %d rueckseitig" % [int(quote[1]) - int(quote[0]), int(quote[1])])
		i += 1
		if i >= namen.size():
			break
	_check("Alle drei Bauteile geprueft", i == namen.size())
	ow.free()


## [vorderseitige Dreiecke, Dreiecke gesamt] eines Meshes.
func _vorderseitig_anteil(mi: MeshInstance3D) -> Array:
	var arr: Array = mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var gut: int = 0
	var alle: int = 0
	for t in range(0, v.size() / 3):
		var flaeche: Vector3 = (v[t * 3 + 1] - v[t * 3]).cross(v[t * 3 + 2] - v[t * 3])
		if flaeche.length() < 0.0000001:
			continue
		alle += 1
		if flaeche.normalized().dot(n[t * 3]) < 0.0:
			gut += 1
	return [gut, alle]


## Requisiten aus docs/PROMPTS_PROPS.md — Maszstab und Streuregeln.
##
## Der Kern dieser Suite ist die GEMESSENE Groesse. Generatoren normieren jedes Modell auf
## dieselbe Kantenlaenge; die Zahl in `AssetRegistry` ist die einzige Stelle, an der ein
## Kaktus ein Kaktus und kein Baum wird. Ein Zahlendreher dort faellt im Spiel erst auf,
## wenn man davorsteht — hier faellt er sofort auf.
func _test_props() -> void:
	print("· Requisiten (Maszstab & Streuung)")
	# Was aufrecht steht, misst sich an der Hoehe; was flach liegt, an der laengsten Kante.
	var aufrecht: Dictionary = {
		"barrels": 1.6, "barrels_b": 1.6, "barrels_c": 1.6,
		"street_lamp": 3.6, "bounty_board": 2.2, "cactus": 2.6,
	}
	var laengs: Dictionary = { "hitching_post": 2.6, "scrap_heap": 3.2, "bones": 1.8 }
	for name in aufrecht:
		_check("%s wird ueber die HOEHE skaliert (%.1f m)" % [name, float(aufrecht[name])],
			AssetRegistry.length_of(String(name)) <= 0.0
			and is_equal_approx(AssetRegistry.height_of(String(name)), float(aufrecht[name])))
	for name in laengs:
		_check("%s wird ueber die LAENGE skaliert (%.1f m)" % [name, float(laengs[name])],
			is_equal_approx(AssetRegistry.length_of(String(name)), float(laengs[name])))
	# Gegenprobe am echten Modell: erst hier faellt auf, wenn die Achse falsch gewaehlt ist.
	for name in ["cactus", "street_lamp", "barrels"]:
		if not AssetRegistry.has_model(String(name)):
			continue
		var node: Node3D = AssetRegistry.instantiate(String(name), AssetRegistry.height_of(String(name)))
		var s: Vector3 = AssetRegistry.local_bounds(node).size
		_check("%s misst gebaut %.2f m hoch (Ziel %.1f)" % [name, s.y, AssetRegistry.height_of(String(name))],
			absf(s.y - AssetRegistry.height_of(String(name))) < 0.05, "%s" % s)
		# Ein aufrecht skaliertes Modell darf nicht in die Breite explodieren — genau daran ist
		# das CC0-Geroellfeld gescheitert (1,2 m hoch skaliert = 10,4 m breit).
		_check("%s bleibt dabei schmaler als hoch" % name, maxf(s.x, s.z) <= s.y * 1.6,
			"%.2f x %.2f bei %.2f hoch" % [s.x, s.z, s.y])
		node.free()
	for name in ["hitching_post", "scrap_heap", "bones"]:
		if not AssetRegistry.has_model(String(name)):
			continue
		var node2: Node3D = AssetRegistry.instantiate(String(name), AssetRegistry.length_of(String(name)))
		var s2: Vector3 = AssetRegistry.local_bounds(node2).size
		var laengste: float = maxf(s2.x, maxf(s2.y, s2.z))
		_check("%s misst gebaut %.2f m in der laengsten Kante (Ziel %.1f)"
			% [name, laengste, AssetRegistry.length_of(String(name))],
			absf(laengste - AssetRegistry.length_of(String(name))) < 0.05, "%s" % s2)
		node2.free()
	# Requisiten sind KEINE Waende — sonst bekaeme ein Fass die Mauer-Kollision ohne Schrumpf.
	for name in ["barrels", "cactus", "scrap_heap", "bones", "bounty_board", "hitching_post",
			"street_lamp", "bahnhof"]:
		_check("%s gilt nicht als Mauerteil" % name, not AssetRegistry.is_wall(String(name)))
	_check("Gestreut wird ausserhalb des befriedeten Stadtrings",
		OverworldView.PROP_SCATTER_R_M > OverworldView.TOWN_SAFE_M + 18.0)


## Bahnsteighalle: das Modell ersetzt sechs Platzhalter-Kisten.
##
## Die eine Zahl, die hier wirklich zaehlt, ist `STATION_SOLID_SHARE`. Sperrt die ganze Halle,
## kommt man nicht auf den Bahnsteig und die Schnellreise ist unerreichbar; sperrt gar nichts,
## laeuft man durch die Rueckwand.
func _test_station() -> void:
	print("· Bahnsteighalle")
	_check("Der Bahnhof steht ausserhalb der Stadt",
		OverworldView.STATION_OFFSET_M > OverworldView.TOWN_R)
	_check("Die Halle ist kuerzer als der Abstand zum Ort (sie ragt nicht hinein)",
		OverworldView.STATION_LEN_M * 0.5 < OverworldView.STATION_OFFSET_M - OverworldView.TOWN_R)
	_check("Ein Teil der Tiefe bleibt begehbar (Bahnsteig)",
		OverworldView.STATION_SOLID_SHARE > 0.0 and OverworldView.STATION_SOLID_SHARE < 1.0,
		"%.2f" % OverworldView.STATION_SOLID_SHARE)
	if not AssetRegistry.has_model("bahnhof"):
		_check("bahnhof.glb vorhanden", false)
		return
	var hall: Node3D = AssetRegistry.instantiate("bahnhof", OverworldView.STATION_LEN_M)
	var b: AABB = AssetRegistry.local_bounds(hall)
	_check("Die Halle misst %.1f m in der Laenge" % b.size.x,
		absf(maxf(b.size.x, b.size.z) - OverworldView.STATION_LEN_M) < 0.05, "%s" % b.size)
	_check("Sie ist laenger als tief (Laengsachse liegt am Gleis)", b.size.x > b.size.z, "%s" % b.size)
	# Der begehbare Streifen muss breiter sein als der Spieler — sonst steht man im Nichts.
	var frei: float = b.size.z * (1.0 - OverworldView.STATION_SOLID_SHARE)
	_check("Der freie Bahnsteig ist %.1f m tief (> 2 Spielerbreiten)" % frei,
		frei > OverworldView.PLAYER_RADIUS_M * 4.0,
		"%.2f m bei Spielerradius %.2f" % [frei, OverworldView.PLAYER_RADIUS_M])
	# Und man muss vom Bahnsteig aus wirklich fahren koennen: Der Bahnsteig liegt hoechstens
	# eine halbe Hallentiefe vom eingetragenen Haltepunkt entfernt.
	_check("Der Bahnsteig liegt in Reichweite des Haltepunkts",
		b.size.z < OverworldView.STATION_RANGE_M,
		"%.1f m Tiefe bei %.0f m Reichweite" % [b.size.z, OverworldView.STATION_RANGE_M])
	_check("Die Front ist auf Godots -Z gedreht", is_equal_approx(
		float(AssetRegistry.YAW_DEG.get("bahnhof", 0.0)), 180.0))
	hall.free()


## Waffenprofile & Streuung (GDD §7.1): Jede Waffe muss sich anders ANFUEHLEN, nicht nur
## anders faerben.
##
## Vorher lagen alle vier Takte zwischen 170 und 240 ms — die Waffenwahl war eine reine
## Schadensart-Frage. Diese Tests halten fest, dass Takt, Schaden und Streuung jetzt
## auseinanderliegen und sich gegenseitig aufwiegen.
func _test_weapons() -> void:
	print("· Waffenprofile & Streuung")
	_reset_state()
	var kb: Dictionary = CombatData.WEAPONS["karabiner"]
	var gat: Dictionary = CombatData.WEAPONS["gatling"]
	_check("Der Karabiner schiesst langsam (>= 700 ms)", int(kb["fire_ms"]) >= 700,
		"%d ms" % int(kb["fire_ms"]))
	_check("Die Gatling schiesst sehr schnell (<= 90 ms)", int(gat["fire_ms"]) <= 90,
		"%d ms" % int(gat["fire_ms"]))
	_check("Takt-Spanne ueber Faktor 10", float(kb["fire_ms"]) / float(gat["fire_ms"]) >= 10.0,
		"Faktor %.1f" % (float(kb["fire_ms"]) / float(gat["fire_ms"])))
	_check("Dafuer trifft der Karabiner haerter (>= 4x Schaden je Schuss)",
		int(kb["base"]) >= 4 * int(gat["base"]), "%d gegen %d" % [int(kb["base"]), int(gat["base"])])
	# Kein Ausreisser: Der Dauerschaden darf sich unterscheiden, aber nicht um Groessenordnungen.
	var dps: Dictionary = {}
	for id in CombatData.WEAPONS:
		var w: Dictionary = CombatData.WEAPONS[id]
		dps[id] = float(w["base"]) * 1000.0 / float(w["fire_ms"])
	var lo: float = 1e9
	var hi: float = 0.0
	for id in dps:
		lo = minf(lo, float(dps[id]))
		hi = maxf(hi, float(dps[id]))
	_check("Kein Dauerschaden-Ausreisser (Spanne < 3x)", hi / lo < 3.0,
		"%.0f bis %.0f Schaden/s" % [lo, hi])
	# Jede Waffe hat eine eigene Munitionsquelle und eine eigene Streuung.
	_check("Gatling zieht aus demselben Pool wie der Karabiner (kinetisch)",
		AmmoData.pool_for("gatling") == AmmoData.pool_for("karabiner"))
	_check("Der Karabiner streut fast nicht (< 1°)", PlayerStats.spread_deg("karabiner") < 1.0)
	_check("Die Gatling sprueht (>= 5°)", PlayerStats.spread_deg("gatling") >= 5.0)

	# Der Kern: Streuung ist eine REICHWEITEN-Frage. Trefferwahrscheinlichkeit = Winkelbreite
	# des Ziels geteilt durch den Streukegel (gedeckelt bei 100 %).
	var radius: float = 0.55   # normal grosser Gegner
	for w in ["karabiner", "gatling"]:
		var cone: float = PlayerStats.spread_deg(String(w))
		var nah: float = _hit_chance(cone, radius, 3.0)
		var weit: float = _hit_chance(cone, radius, 11.0)
		print("    %-10s Kegel %.1f°  ->  auf 3 m %.0f %%, auf 11 m %.0f %%"
			% [w, cone, nah * 100.0, weit * 100.0])
	_check("Der Karabiner trifft auf volle Reichweite noch sicher",
		_hit_chance(PlayerStats.spread_deg("karabiner"), radius, 11.0) > 0.99)
	_check("Die Gatling trifft nah sicher, weit aber nicht",
		_hit_chance(PlayerStats.spread_deg("gatling"), radius, 3.0) > 0.99
		and _hit_chance(PlayerStats.spread_deg("gatling"), radius, 11.0) < 0.6)

	# Mods verengen den Kegel — genau darum ging es.
	_reset_state()
	var vorher: float = PlayerStats.spread_deg("gatling")
	GameState.equip = { "weapon": { "uid": 1, "slot": "weapon", "rarity": "epic", "req": 1,
		"name": "Testlauf", "stat": { "key": "accuracy", "val": 40, "q": 1.0 }, "affixes": [] } }
	var nachher: float = PlayerStats.spread_deg("gatling")
	_check("Praezisions-Mod verengt den Kegel", nachher < vorher,
		"%.2f° -> %.2f°" % [vorher, nachher])
	_check("Der Mod verbessert die Trefferchance auf Distanz spuerbar",
		_hit_chance(nachher, radius, 11.0) > _hit_chance(vorher, radius, 11.0) + 0.15,
		"%.0f %% -> %.0f %%" % [_hit_chance(vorher, radius, 11.0) * 100.0,
			_hit_chance(nachher, radius, 11.0) * 100.0])
	GameState.equip = { "weapon": { "uid": 1, "slot": "weapon", "rarity": "legendary", "req": 1,
		"name": "Testlauf", "stat": { "key": "accuracy", "val": 500, "q": 1.0 }, "affixes": [] } }
	_check("Auch vollgemoddet bleibt die Gatling eine Gatling (Deckel 85 %)",
		PlayerStats.spread_deg("gatling") > float(CombatData.WEAPONS["gatling"]["spread_deg"]) * 0.14,
		"%.2f°" % PlayerStats.spread_deg("gatling"))
	_reset_state()


## Trefferchance aus Streukegel, Zielradius und Entfernung — dieselbe Rechnung wie in
## `OverworldView._process_combat`, hier zum Pruefen nachgezogen.
func _hit_chance(cone_deg: float, radius_m: float, dist_m: float) -> float:
	if cone_deg <= 0.0:
		return 1.0
	var half_deg: float = rad_to_deg(atan2(radius_m, dist_m))
	return minf(1.0, half_deg / cone_deg)


## Munition (GDD §7.1.1): begrenzter Vorrat statt Dauerfeuer.
func _test_ammo() -> void:
	print("· Munition & Energiekristalle")
	_reset_state()
	_check("Karabiner zieht aus dem Munitionsvorrat", AmmoData.pool_for("karabiner") == "muni")
	for w in ["voltgun", "saeure", "brenner"]:
		_check("%s zieht aus den Kristallen" % w, AmmoData.pool_for(w) == "kristall")
	_check("Startvorrat Munition = 90", AmmoData.amount("muni") == 90)
	_check("Startvorrat Kristalle = 45", AmmoData.amount("kristall") == 45)
	# Zweistufig: Geschossen wird aus dem MAGAZIN, nachgefuellt aus dem Vorrat.
	_check("Ein Schuss kostet genau einen aus dem Magazin",
		AmmoData.consume("karabiner")
		and AmmoData.in_mag("karabiner") == AmmoData.mag_size("karabiner") - 1)
	_check("Der Vorrat bleibt dabei unberuehrt", AmmoData.amount("muni") == 90)
	# Kapazitaet deckelt, und `add` meldet ehrlich, wie viel wirklich ankam.
	GameState.ammo["muni"] = 175
	_check("Nachschub ueber die Kapazitaet wird gekappt und ehrlich gemeldet",
		AmmoData.add("muni", 20) == 5 and AmmoData.amount("muni") == 180,
		"jetzt %d" % AmmoData.amount("muni"))
	AmmoData.set_mag("karabiner", 0)
	_check("Leeres Magazin heisst leer", AmmoData.is_empty("karabiner"))
	_check("Aus leerem Magazin faellt kein Schuss", not AmmoData.consume("karabiner"))
	_check("Die andere Waffe hat ihr eigenes Magazin", not AmmoData.is_empty("voltgun"))
	_reset_state()


## Nachladen: Magazingroesse und Dauer je Waffe, beides verbesserbar.
##
## Ohne diese zweite Stufe waere Munition nur ein langsam sinkender Zaehler. Erst das Magazin
## erzeugt den Rhythmus aus Feuern und Deckungsuche — und erst dadurch ist die Gatling eine
## Entscheidung: 60 Schuss am Stueck, danach viereinhalb Sekunden wehrlos.
func _test_reload() -> void:
	print("· Magazin & Nachladen")
	_reset_state()
	_check("Der Karabiner haelt 10 Schuss", AmmoData.mag_size("karabiner") == 10)
	_check("Die Gatling haelt sechsmal so viel", AmmoData.mag_size("gatling") == 60)
	_check("Dafuer laedt sie mehr als doppelt so lang nach",
		PlayerStats.reload_sec("gatling") > PlayerStats.reload_sec("karabiner") * 2.0,
		"%.1f s gegen %.1f s" % [PlayerStats.reload_sec("gatling"), PlayerStats.reload_sec("karabiner")])
	_check("Jede Waffe hat ein eigenes Magazin und eine eigene Dauer",
		AmmoData.mag_size("saeure") != AmmoData.mag_size("brenner")
		and PlayerStats.reload_sec("saeure") != PlayerStats.reload_sec("brenner"))

	# Der Zyklus: leerschiessen, nachladen, wieder voll.
	_reset_state()
	var schuss: int = 0
	while AmmoData.consume("karabiner"):
		schuss += 1
	_check("Magazin leergeschossen nach genau %d Schuss" % AmmoData.mag_size("karabiner"),
		schuss == AmmoData.mag_size("karabiner"), "%d" % schuss)
	_check("Leeres Magazin laesst sich nachladen", AmmoData.can_reload("karabiner"))
	var geladen: int = AmmoData.refill_mag("karabiner")
	_check("Nachladen fuellt das Magazin voll", geladen == 10 and AmmoData.mag_full("karabiner"))
	_check("Und nimmt die Schuesse aus dem Vorrat", AmmoData.amount("muni") == 80,
		"%d" % AmmoData.amount("muni"))
	_check("Volles Magazin braucht kein Nachladen", not AmmoData.can_reload("karabiner"))

	# Teil-Nachladen, wenn der Vorrat nicht reicht — und ehrliche Rueckmeldung darueber.
	_reset_state()
	AmmoData.set_mag("karabiner", 0)
	GameState.ammo["muni"] = 3
	_check("Knapper Vorrat laedt nur teilweise",
		AmmoData.refill_mag("karabiner") == 3 and AmmoData.in_mag("karabiner") == 3)
	_check("Danach ist der Vorrat leer", AmmoData.amount("muni") == 0)
	_check("Ohne Vorrat hilft auch Nachladen nicht", not AmmoData.can_reload("karabiner"))
	AmmoData.set_mag("karabiner", 0)
	_check("Voellig trocken ist etwas anderes als nur leer",
		AmmoData.is_dry("karabiner") and AmmoData.is_empty("karabiner"))
	AmmoData.add("muni", 50)
	_check("Nach Nachschub ist es nur noch 'leer', nicht 'trocken'",
		AmmoData.is_empty("karabiner") and not AmmoData.is_dry("karabiner"))

	# Verbesserbarkeit: Werkstatt UND Ausruestung, beide gedeckelt.
	_reset_state()
	var voll: float = PlayerStats.reload_sec("gatling")
	GameState.upgrades["reload"] = 3          # -24 %
	var werkstatt: float = PlayerStats.reload_sec("gatling")
	_check("Werkstatt-Ausbau verkuerzt das Nachladen", werkstatt < voll,
		"%.2f s -> %.2f s" % [voll, werkstatt])
	_reset_state()
	GameState.equip = { "weapon": { "uid": 1, "slot": "weapon", "rarity": "epic", "req": 1,
		"name": "Testlauf", "stat": { "key": "reload", "val": 30, "q": 1.0 }, "affixes": [] } }
	var item: float = PlayerStats.reload_sec("gatling")
	_check("Ein besseres Item verkuerzt es ebenfalls", item < voll,
		"%.2f s -> %.2f s" % [voll, item])
	GameState.upgrades["reload"] = 5
	GameState.equip["weapon"]["stat"]["val"] = 500
	_check("Auch alles zusammen bleibt bei 60 %% Ersparnis gedeckelt",
		is_equal_approx(PlayerStats.reload_sec("gatling"), voll * 0.4),
		"%.2f s von %.2f s" % [PlayerStats.reload_sec("gatling"), voll])

	# Der bislang wirkungslose Munitionsgurt-Perk hebt endlich den Vorrat.
	_reset_state()
	var cap0: int = AmmoData.cap("muni")
	GameState.perks["gurt"] = 2
	_check("Perk 'Munitionsgurt' hebt die Vorratsgrenze (+25 je Rang)",
		AmmoData.cap("muni") == cap0 + 50, "%d -> %d" % [cap0, AmmoData.cap("muni")])
	_reset_state()


## Beutel: Platz haengt am Fussabdruck, nicht an der Stueckzahl (GDD §7.4).
func _test_bag() -> void:
	print("· Beutel (Grid-Kapazitaet)")
	_reset_state()
	var ruestung: Dictionary = ProgressionManager.make_gear("armor", "common")
	var helm: Dictionary = ProgressionManager.make_gear("helmet", "common")
	_check("Ruestung belegt 2x2", BagManager.footprint(ruestung) == Vector2i(2, 2))
	_check("Helm belegt 1x1", BagManager.footprint(helm) == Vector2i(1, 1))
	_check("Waffe belegt 2x1",
		BagManager.footprint(ProgressionManager.make_gear("weapon", "common")) == Vector2i(2, 1))
	_check("Einpacken klappt", BagManager.add(ruestung) and GameState.bag.size() == 1)
	_check("Belegte Zellen zaehlen den Fussabdruck, nicht die Stueckzahl",
		BagManager.used_cells() == 4, "%d" % BagManager.used_cells())

	# Anlegen aus dem Beutel: Das getragene Teil muss ZURUECK in den Beutel, nicht verschwinden.
	_reset_state()
	var alt: Dictionary = ProgressionManager.make_gear("armor", "common")
	var neu_teil: Dictionary = ProgressionManager.make_gear("armor", "epic")
	EquipManager.equip_item(alt, "armor")
	BagManager.add(neu_teil)
	_check("Anlegen aus dem Beutel", BagManager.equip_from_bag(0))
	_check("Das neue Teil ist angelegt",
		String(EquipManager.equipped("armor").get("rarity", "")) == "epic")
	_check("Das alte Teil liegt im Beutel statt im Nichts",
		GameState.bag.size() == 1 and String(GameState.bag[0]["rarity"]) == "common")
	_check("Ablegen wandert zurueck in den Beutel",
		BagManager.unequip_to_bag("armor") and GameState.bag.size() == 2
		and not EquipManager.is_equipped("armor"))

	# Voller Beutel darf nichts verschlucken.
	_reset_state()
	var passt: int = 0
	for i in 60:
		if BagManager.add(ProgressionManager.make_gear("armor", "common")):
			passt += 1
	# 12, nicht 15: Das Raster ist FUENF Spalten breit (GDD §7.4), eine 2x2-Ruestung passt
	# also nur zweimal nebeneinander — die fuenfte Spalte bleibt in jedem Zweizeilen-Band
	# liegen. Genau dafuer gibt es Fussabdruecke statt einer Stueckzahl: Sperriges kostet
	# mehr als seine Zellen.
	var baender: int = BagManager.ROWS / 2
	var je_band: int = BagManager.COLS / 2
	_check("Der Beutel laeuft voll, mit Verschnitt statt perfekter Packung",
		passt == baender * je_band and passt < BagManager.total_cells() / 4,
		"%d Ruestungen (erwartet %d), Raster %dx%d"
		% [passt, baender * je_band, BagManager.COLS, BagManager.ROWS])
	_check("Volles Raster meldet keinen Platz mehr",
		not BagManager.has_room_for(ProgressionManager.make_gear("armor", "common")))

	# Verschrotten macht Platz und bringt Schrott.
	_reset_state()
	BagManager.add(ProgressionManager.make_gear("armor", "legendary"))
	var vorher: int = GameState.item_count("schrott")
	var ertrag: int = BagManager.scrap_at(0)
	_check("Verschrotten leert den Platz und bringt Schrott",
		GameState.bag.is_empty() and ertrag > 0 and GameState.item_count("schrott") == vorher + ertrag,
		"+%d Schrott" % ertrag)
	# Deutsche Beugung: Seit die Beute mit Namen auf dem Boden liegt, faellt jeder Fehler auf.
	_check("Weiblich: 'Rostige Rüstung', nicht 'Rostiger Rüstung'",
		ProgressionManager._compose("Rostiger", "armor") == "Rostige Rüstung",
		ProgressionManager._compose("Rostiger", "armor"))
	_check("Saechlich: 'Rostiges Gadget'",
		ProgressionManager._compose("Rostiger", "gadget") == "Rostiges Gadget",
		ProgressionManager._compose("Rostiger", "gadget"))
	_check("Maennlich bleibt 'Rostiger Helm'",
		ProgressionManager._compose("Rostiger", "helmet") == "Rostiger Helm")
	_check("Bindestrich haengt ohne Leerzeichen an: 'Präzisions-Helm'",
		ProgressionManager._compose("Präzisions-", "helmet") == "Präzisions-Helm",
		ProgressionManager._compose("Präzisions-", "helmet"))
	for slot in ["helmet", "armor", "weapon", "gadget", "boots"]:
		var nm: String = String(ProgressionManager.make_gear(String(slot), "common")["name"])
		_check("%s: kein Leerzeichen vor dem Bindestrich-Wort" % slot, not nm.contains("- "), nm)


	_reset_state()


## Werkstatt & Wirtschaft: die Gold-Senke.
##
## Bis hierher hatte Gold KEINE Senke — `add_gold` wurde beim Kill und an der Truhe gerufen,
## ausgegeben wurde es nirgends. Die Kernschleife „töten → Gold → stärker werden" brach nach
## dem zweiten Schritt ab, obwohl Kostenkurve, Höchststufen und Einkommensrechnung im
## Hintergrund längst liefen. Diese Tests halten fest, dass sie jetzt geschlossen ist.
func _test_workshop() -> void:
	print("· Werkstatt & Wirtschaft (Gold-Senke)")
	_reset_state()
	_check("spend_gold gibt es ueberhaupt", GameState.has_method("spend_gold"))
	GameState.gold = 100
	_check("Zu teuer -> kein Kauf, kein Abzug",
		not GameState.spend_gold(150) and GameState.gold == 100)
	_check("Bezahlbar -> Kauf und exakter Abzug",
		GameState.spend_gold(60) and GameState.gold == 40)
	_check("Nicht-positive Betraege prallen ab",
		not GameState.spend_gold(0) and not GameState.spend_gold(-10) and GameState.gold == 40)

	# Kostenkurve 1:1 aus dem Prototyp: Basis x (Stufe + 1).
	_reset_state()
	_check("Erste Stufe Schaden kostet 40", WorkshopData.cost("damage") == 40)
	GameState.gold = 10000
	_check("Kauf erhoeht die Stufe", WorkshopData.buy("damage") and WorkshopData.level("damage") == 1)
	_check("Zweite Stufe kostet das Doppelte (80)", WorkshopData.cost("damage") == 80)
	_check("Gold wurde genau um 40 verringert", GameState.gold == 9960)

	# Der Kern: Ein Werkstatt-Kauf muss im Kampfwert ankommen.
	_reset_state()
	GameState.gold = 10000
	var dmg0: int = PlayerStats.damage_per_bullet("karabiner")
	WorkshopData.buy("damage")
	var dmg1: int = PlayerStats.damage_per_bullet("karabiner")
	_check("Ausbau wirkt SOFORT auf den naechsten Schuss", dmg1 > dmg0,
		"vorher %d, nachher %d" % [dmg0, dmg1])

	# Koerper-Eingriffe bleiben zu, solange der Held sich fuer einen Menschen haelt.
	_reset_state()
	GameState.gold = 10000
	GameState.is_revealed = false
	_check("Vor dem Reveal: Panzerung gesperrt", WorkshopData.is_locked("hp"))
	_check("Vor dem Reveal: Schaden NICHT gesperrt", not WorkshopData.is_locked("damage"))
	_check("Gesperrtes laesst sich nicht kaufen",
		not WorkshopData.buy("hp") and WorkshopData.level("hp") == 0 and GameState.gold == 10000)
	_check("Vor dem Reveal heisst es noch 'Schneller Hahn'",
		WorkshopData.label("firerate") == "Schneller Hahn")
	GameState.is_revealed = true
	_check("Nach dem Reveal: Panzerung frei", not WorkshopData.is_locked("hp"))
	_check("Nach dem Reveal kaufbar", WorkshopData.buy("hp") and WorkshopData.level("hp") == 1)
	_check("Nach dem Reveal heisst dasselbe Teil 'Kolben-Frequenz'",
		WorkshopData.label("firerate") == "Kolben-Frequenz")

	# Hoechststufe deckelt.
	_reset_state()
	GameState.gold = 999999
	GameState.is_revealed = true
	var kaeufe: int = 0
	for i in 20:
		if WorkshopData.buy("magnet"):
			kaeufe += 1
	_check("Magnet-Spule endet bei Stufe 4", kaeufe == 4 and WorkshopData.is_maxed("magnet"),
		"%d Kaeufe, Stufe %d" % [kaeufe, WorkshopData.level("magnet")])

	# Wirtschaft: Ausbau erzeugt Einkommen, das es vorher nicht gab.
	_reset_state()
	_check("Ohne Ausbau kein Einkommen", TycoonManager.income_per_sec() == 0)
	GameState.gold = 10000
	_check("Saloon ausbaubar", TycoonManager.try_upgrade("saloon"))
	_check("Ausbau erzeugt Einkommen", TycoonManager.income_per_sec() > 0,
		"%d/s" % TycoonManager.income_per_sec())
	GameState.gold = 0
	_check("Ohne Gold kein Ausbau", not TycoonManager.try_upgrade("forge"))
	_reset_state()


## Mauerstuecke: Kollision darf NICHT geschrumpft werden.
##
## Die Palisade wird nicht mehr vom Code als Kreis gebaut, sondern von Hand in `Rustwater.tscn`
## gestellt. Damit haengt die Dichtheit der Mauer daran, dass `_register_town_node` ein
## Wandstueck als solches erkennt: Der Schrumpf-Faktor fuer Gebaeude (0,82) liesse zwischen
## zwei aneinandergesetzten Stuecken 18 % Luecke, und die Kollision prueft einen Punkt — man
## liefe mitten durch die Palisade.
func _test_wall_classification() -> void:
	print("· Mauerteile (Kollision ohne Schrumpf)")
	for name in ["palisade_a", "palisade_b", "palisade_c", "palisade_d", "palisade_e", "gate"]:
		_check("%s gilt als Wand" % name, AssetRegistry.is_wall(name))
	for name in ["saloon", "forge", "water_tower", "shack_a", "npc_mabel", "rock_small"]:
		_check("%s gilt NICHT als Wand" % name, not AssetRegistry.is_wall(name))
	_check("Neue Varianten greifen von selbst (palisade_f)", AssetRegistry.is_wall("palisade_f"))

	# Die Namensregel gibt es, WEIL die Formregel hier versagt: gemessen liegt `palisade_e` bei
	# 2,13:1 und damit naeher an einer Huette (bis 1,56:1) als an den uebrigen Mauerstuecken
	# (ab 3,71:1). Dieser Test haelt fest, dass die Einstufung eben nicht an der Form haengt.
	var ratios: Dictionary = {}
	for name in ["shack_a", "palisade_e"]:
		if not AssetRegistry.has_model(name):
			continue
		var m: Node3D = AssetRegistry.instantiate(name, AssetRegistry.height_of(name))
		var s: Vector3 = AssetRegistry.local_bounds(m).size
		ratios[name] = maxf(s.x, s.z) / maxf(minf(s.x, s.z), 0.01)
		m.free()
	if ratios.has("palisade_e") and ratios.has("shack_a"):
		_check("Gegenprobe: palisade_e (%.2f:1) ist formaehnlich zu shack_a (%.2f:1) und wird trotzdem richtig eingestuft"
			% [ratios["palisade_e"], ratios["shack_a"]],
			AssetRegistry.is_wall("palisade_e") and not AssetRegistry.is_wall("shack_a"))
		_check("Notfall-Formregel trennt beide sauber (Grenze liegt dazwischen)",
			ratios["shack_a"] < OverworldView.WALL_ASPECT
			and ratios["palisade_e"] > OverworldView.WALL_ASPECT,
			"shack_a %.2f, palisade_e %.2f, Grenze %.2f"
			% [ratios["shack_a"], ratios["palisade_e"], OverworldView.WALL_ASPECT])


## Abzug: geschossen wird NUR auf Befehl.
##
## Die wichtigste Zeile ist die erste Pruefung. Vorher feuerte die Figur von allein, sobald
## irgendetwas in die 11-m-Reichweite geriet — Gegner starben, bevor man sie gesehen hatte.
## Genau dieser Zustand darf nicht zurueckkommen.
##
## `OverworldView.new()` ohne Szenenbaum reicht dafuer: `_fire_wanted()` liest nur eigene
## Felder, und `_map_is_open()` ist null-sicher. So bleibt die Regel geprueft, ohne die 3D-Welt
## mit ihren 589 Knoten hochzufahren.
func _test_fire_control() -> void:
	print("· Abzug (kein Auto-Feuer)")
	var ow := OverworldView.new()
	_check("Ohne Eingabe wird NICHT geschossen", not ow._fire_wanted())
	ow._fire_key = true
	_check("Leertaste feuert", ow._fire_wanted())
	ow._fire_key = false
	ow._fire_mouse = true
	_check("Rechte Maustaste feuert", ow._fire_wanted())
	ow._fire_mouse = false
	ow._fire_touch_id = 3
	_check("Finger auf dem Schuss-Knopf feuert", ow._fire_wanted())
	# Die drei Quellen duerfen sich nicht gegenseitig loeschen: auf dem Handy liegt ein Finger
	# auf dem Joystick und einer auf dem Knopf, am Rechner haelt man Leertaste UND zieht.
	ow._fire_key = true
	ow._fire_touch_id = -1
	_check("Finger loslassen beendet das Feuern nicht, solange die Taste liegt",
		ow._fire_wanted())
	ow._fire_key = false
	_check("Letzte Quelle losgelassen → Feuer aus", not ow._fire_wanted())
	ow.free()

	# Der Knopf sieht rund aus, also muss er sich auch rund anfassen lassen.
	var btn := FireButton.new()
	btn.size = Vector2(FireButton.RADIUS, FireButton.RADIUS) * 2.0
	var c: Vector2 = btn.center()
	_check("Schuss-Knopf: Mitte trifft", btn.hits(c))
	_check("Schuss-Knopf: knapp innerhalb trifft", btn.hits(c + Vector2(FireButton.RADIUS - 4.0, 0.0)))
	_check("Schuss-Knopf: Ecke des Rahmens trifft NICHT (rund, nicht eckig)",
		not btn.hits(Vector2.ZERO))
	_check("Schuss-Knopf: weit daneben trifft nicht", not btn.hits(c + Vector2(300.0, 0.0)))
	btn.free()


## Minikarte: Ausrichtung gegen die WELT prüfen, nicht gegen sich selbst.
##
## Der behobene Fehler war heimtückisch, weil die Karte in sich stimmig war: Projektion und
## Richtungsstrich waren beide auf der Nord-Süd-Achse gespiegelt, also passten sie zueinander.
## Aufgefallen ist es erst beim Vergleich mit der Figur auf dem Bildschirm. Deshalb hier zuerst
## Ankerpunkte gegen echte POI-Daten (Norden oben, Osten rechts) und danach die Bindung des
## Strichs an die Karte.
func _test_minimap() -> void:
	print("· Karte (Nahansicht + Weltkarte)")
	var px: float = Minimap.MAP_PX
	# `_ready` laeuft nur im Szenenbaum, deshalb die Groesse hier von Hand setzen — der
	# Massstab haengt an ihr.
	var world := Minimap.new()
	world.full_world = true
	world.size = Vector2(px, px)
	var south: Vector2 = world.world_to_map(WorldManager.poi_scene_position("rustwater"))
	var north: Vector2 = world.world_to_map(WorldManager.poi_scene_position("eisernes_herz"))
	# Rustwater liegt bei y=300, das Eiserne Herz bei y=1950 — der Norden muss also oben
	# landen, und „oben" heisst in Godots Zeichenflaeche KLEINERES y.
	_check("Weltkarte: Norden oben (Eisernes Herz über Rustwater)",
		north.y < south.y, "Herz y=%.1f, Rustwater y=%.1f" % [north.y, south.y])
	var west: Vector2 = world.world_to_map(WorldManager.poi_scene_position("fort_freedom"))
	var east: Vector2 = world.world_to_map(WorldManager.poi_scene_position("sektor01"))
	_check("Weltkarte: Osten rechts (Sektor 01 rechts von Fort Freedom)",
		east.x > west.x, "Sektor01 x=%.1f, Fort x=%.1f" % [east.x, west.x])
	_check("Weltkarte: Nordrand auf y = 0",
		is_zero_approx(world.world_to_map(Vector3(0.0, 0.0, -WorldManager.WORLD_METERS)).y))
	_check("Weltkarte: Südrand auf y = MAP_PX",
		is_equal_approx(world.world_to_map(Vector3.ZERO).y, px))
	_check("Weltkarte: alle 11 Orte liegen im Rahmen",
		_pois_inside(world) == WorldManager.POIS.size(),
		"%d von %d" % [_pois_inside(world), WorldManager.POIS.size()])

	# Nahansicht: Ausschnitt um den Spieler statt Gesamtansicht. Der Krater misst 5000 m — auf
	# 190 px waeren das 0,038 px/m, also 26 gelaufene Meter pro Pixel.
	var near := Minimap.new()
	near.size = Vector2(px, px)
	near.player_pos = WorldManager.poi_scene_position("rustwater")
	_check("Nahansicht: Spieler steht in der Mitte",
		near.world_to_map(near.player_pos).is_equal_approx(Vector2(px, px) * 0.5))
	_check("Nahansicht: Massstab ist %d m bis zur Kante" % int(Minimap.LOCAL_RADIUS_M),
		is_equal_approx(near.pixels_per_meter(), px / (Minimap.LOCAL_RADIUS_M * 2.0)))
	var edge: Vector2 = near.world_to_map(near.player_pos + Vector3(0.0, 0.0, -Minimap.LOCAL_RADIUS_M))
	_check("Nahansicht: %d m nördlich liegen genau auf der Oberkante" % int(Minimap.LOCAL_RADIUS_M),
		is_zero_approx(edge.y), "y = %.2f" % edge.y)
	var rect := Rect2(Vector2.ZERO, Vector2(px, px))
	_check("Nahansicht: doppelte Reichweite faellt aus dem Rahmen",
		not rect.has_point(near.world_to_map(
			near.player_pos + Vector3(0.0, 0.0, -Minimap.LOCAL_RADIUS_M * 2.0))))
	# Der eigentliche Zweck: Gegner sind nicht mehr ein einziger Punkt. Im Spawnradius von 45 m
	# lagen sie auf der Gesamtansicht 1,7 px auseinander.
	var far_enemy: Vector2 = near.world_to_map(near.player_pos + Vector3(45.0, 0.0, 0.0))
	_check("Nahansicht: Gegner am Spawnrand (45 m) sind ≥ 15 px vom Spieler entfernt",
		far_enemy.distance_to(Vector2(px, px) * 0.5) >= 15.0,
		"%.1f px" % far_enemy.distance_to(Vector2(px, px) * 0.5))
	_check("Nahansicht ist deutlich feiner als die Weltkarte",
		near.pixels_per_meter() > world.pixels_per_meter() * 10.0)

	# Der Strich muss dahin zeigen, wohin der Punkt WANDERT — in BEIDEN Betriebsarten. Beides
	# wird unabhaengig gerechnet: der Strich aus `facing_on_map()`, die Wanderung aus zwei
	# echten Kartenpositionen.
	var origin := Vector3(2500.0, 0.0, -2500.0)   # Kratermitte, weit weg von jedem Rand
	for mode in [["Weltkarte", world], ["Nahansicht", near]]:
		var map: Minimap = mode[1]
		for c in [["Osten", Vector3(1, 0, 0)], ["Norden", Vector3(0, 0, -1)],
				["Westen", Vector3(-1, 0, 0)], ["Sueden", Vector3(0, 0, 1)]]:
			var step: Vector3 = c[1]
			map.player_dir = atan2(-step.x, -step.z)   # dieselbe Formel wie in OverworldView
			var moved: Vector2 = (map.world_to_map(origin + step * 10.0)
				- map.world_to_map(origin)).normalized()
			_check("%s: Richtungsstrich zeigt nach %s wie der Punkt laeuft" % [mode[0], c[0]],
				map.facing_on_map().distance_to(moved) < 0.001,
				"Strich %s, Bewegung %s" % [map.facing_on_map(), moved])
		# Und einmal absolut: nach Norden laufen heisst auf der Karte nach oben.
		map.player_dir = atan2(0.0, 1.0)
		_check("%s: nach Norden laufen → Strich zeigt nach oben" % mode[0],
			map.facing_on_map().y < -0.99, "Strich %s" % map.facing_on_map())
	world.free()
	near.free()


## Wie viele Orte fallen in den Rahmen der Karte? Die Weltkarte muss alle zeigen — sonst waere
## sie als Uebersicht wertlos.
func _pois_inside(map: Minimap) -> int:
	var rect := Rect2(Vector2.ZERO, map.size)
	var n: int = 0
	for id in WorldManager.POIS.keys():
		if rect.has_point(map.world_to_map(WorldManager.poi_scene_position(String(id)))):
			n += 1
	return n


func _test_asset_registry() -> void:
	print("· AssetRegistry (Asset-Pipeline mit Platzhalter-Fallback)")
	_check("Gegner-Typ → Asset-Name", AssetRegistry.enemy_asset("outlaw") == "enemy_outlaw")
	_check("Unbekannter Name liefert '' (→ Platzhalter)", AssetRegistry.resolve("gibts_nicht") == "")
	_check("Unbekannter Name instanziiert nichts", AssetRegistry.instantiate("gibts_nicht") == null)
	_check("Kein Modell → has_model false", AssetRegistry.has_model("gibts_nicht") == false)
	# Jeder registrierte Eintrag muss mindestens einen Kandidatenpfad haben.
	var all_have_paths: bool = true
	for name in AssetRegistry.PATHS.keys():
		if (AssetRegistry.PATHS[name] as Array).is_empty():
			all_have_paths = false
	_check("Alle Registry-Einträge haben Kandidatenpfade", all_have_paths)
	# Jeder Gegnertyp aus dem Kampf-Roster ist in der Registry vorgesehen.
	var every_enemy_mapped: bool = true
	for type_id in CombatData.ENEMY_TYPES.keys():
		if not AssetRegistry.PATHS.has(AssetRegistry.enemy_asset(String(type_id))):
			every_enemy_mapped = false
	_check("Jeder Gegnertyp hat einen Registry-Eintrag", every_enemy_mapped)
	# Höhenmessung muss die komplette Transform-Kette berücksichtigen (glTF-Hierarchien sind
	# verschachtelt) — sonst skalieren Assets falsch. Synthetischer Baum, assetfrei prüfbar.
	var root := Node3D.new()
	var mid := Node3D.new()
	mid.scale = Vector3(2.0, 2.0, 2.0)      # verschachtelte Skalierung
	mid.position = Vector3(0.0, 1.0, 0.0)   # und Versatz
	root.add_child(mid)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 3.0, 1.0)        # 3 m hoch, ×2 verschachtelt = 6 m
	mi.mesh = bm
	mid.add_child(mi)
	_check("Höhe berücksichtigt verschachtelte Skalierung (6 m)",
		is_equal_approx(AssetRegistry.local_height(root), 6.0),
		"gemessen: %.3f" % AssetRegistry.local_height(root))
	_check("local_size liefert volle Bounds (1×6×1 m, gleicher Baum)",
		AssetRegistry.local_size(root).is_equal_approx(Vector3(2.0, 6.0, 2.0)),
		"gemessen: %s" % AssetRegistry.local_size(root))
	# Boden-Versatz: der Baum liegt zwischen y=-2 und y=+4 (Mesh ±3 ×2 verschoben um +1×2).
	# `instantiate()` muss diesen Versatz herausrechnen, damit generierte Assets (Meshy & Co.)
	# nicht schweben oder im Sand versinken — dort sitzt der Pivot fast nie am Boden.
	var b: AABB = AssetRegistry.local_bounds(root)
	_check("local_bounds liefert auch die Unterkante (y = -2 m)",
		is_equal_approx(b.position.y, -2.0), "gemessen: %.3f" % b.position.y)
	root.free()
	# Gegenprobe an einem echten Modell (nur wenn Assets vorhanden sind — das Projekt muss
	# auch ohne sie testbar bleiben): Zielhöhe getroffen UND Unterkante auf dem Boden.
	if AssetRegistry.has_model("rock_small"):
		# `rock_small` ist ein flaches Geroellfeld und wird deshalb ueber die LAENGSTE Kante
		# skaliert (TARGET_LENGTH) — die 2,00 sind hier also Laenge, nicht Hoehe.
		var inst: Node3D = AssetRegistry.instantiate("rock_small", 2.0)
		var ib: AABB = AssetRegistry.local_bounds(inst)
		var longest: float = maxf(ib.size.x, maxf(ib.size.y, ib.size.z))
		_check("Flaches Modell: laengste Kante auf 2,00 m skaliert", is_equal_approx(longest, 2.0),
			"gemessen: %.3f" % longest)
		_check("Flaches Modell: Unterkante steht auf Y = 0", absf(ib.position.y) < 0.001,
			"gemessen: %.4f" % ib.position.y)
		inst.free()
	if AssetRegistry.has_model("player"):
		# Gegenprobe fuer die Hoehen-Skalierung an einem Modell, das NICHT in TARGET_LENGTH steht.
		var ph: Node3D = AssetRegistry.instantiate("player", 2.0)
		_check("Hohes Modell: auf 2,00 m Hoehe skaliert",
			is_equal_approx(AssetRegistry.local_bounds(ph).size.y, 2.0),
			"gemessen: %.3f" % AssetRegistry.local_bounds(ph).size.y)
		ph.free()
	# Clip-Suche: Werkzeuge benennen Animationen unterschiedlich („Armature|Walk", „Idle",
	# „walk_backwards"). Die Registry muss die Rolle treffen, ohne dass jemand umbenennt —
	# und ein exakter Treffer muss einen Teiltreffer schlagen. Synthetisch, assetfrei.
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for clip_name in ["walk_backwards", "CharacterArmature|Walk", "Idle_A"]:
		lib.add_animation(clip_name, Animation.new())
	ap.add_animation_library("", lib)
	_check("Clip-Suche findet 'walk' trotz Armature-Praefix",
		AssetRegistry.find_clip(ap, "walk") == "CharacterArmature|Walk",
		"gefunden: '%s'" % AssetRegistry.find_clip(ap, "walk"))
	_check("Clip-Suche findet 'idle' ueber Teiltreffer",
		AssetRegistry.find_clip(ap, "idle") == "Idle_A")
	_check("Fehlende Rolle liefert '' (Modell bleibt unanimiert)",
		AssetRegistry.find_clip(ap, "death") == "")
	_check("Ohne AnimationPlayer liefert die Suche ''", AssetRegistry.find_clip(null, "walk") == "")
	_check("play_clip auf einem Modell ohne Animation ist folgenlos",
		AssetRegistry.play_clip(null, "walk") == false)
	_check("Kuerzester Teiltreffer gewinnt (Walking schlaegt Slow_Walk_Reload)",
		AssetRegistry.find_clip(_clip_player(["Slow_Walk_Reload", "Walking", "Walk_Turn_Left"]), "walk") == "Walking")
	ap.free()
	# Das echte Spieler-Modell (nur wenn es im Repo liegt): Maßstab, Bodenkontakt und die
	# Rollen, die die Overworld tatsaechlich abspielt. Faengt einen kaputten Re-Export sofort.
	if AssetRegistry.has_model("player"):
		var p: Node3D = AssetRegistry.instantiate("player", 1.8)
		add_child(p)   # `global_transform` gilt nur im Szenenbaum (Gegenprobe unten)
		var pb: AABB = AssetRegistry.local_bounds(p)
		_check("Spieler-Modell: auf 1,80 m skaliert", is_equal_approx(pb.size.y, 1.8),
			"gemessen: %.3f" % pb.size.y)
		_check("Spieler-Modell: steht auf Y = 0", absf(pb.position.y) < 0.001)
		# UNABHAENGIGE Gegenprobe ueber das Skelett: die Bounds-Messung allein kann sich nicht
		# selbst pruefen — wenn sie falsch misst, skaliert sie passend zum eigenen Fehler und
		# der Test bleibt gruen (genau so ist ein 100-facher Massstabsfehler durchgerutscht:
		# gehaeutete Meshes liegen NICHT dort, wo ihre Knotenkette sagt, sondern wo das Skelett
		# sie hinsetzt). Knochenhoehen kommen aus dem Rig, nicht aus `local_bounds`.
		var sk: Skeleton3D = AssetRegistry.skeleton(p)
		if sk != null:
			var head_y: float = (sk.global_transform * sk.get_bone_global_rest(sk.find_bone("Head"))).origin.y
			var toe_y: float = (sk.global_transform * sk.get_bone_global_rest(sk.find_bone("LeftToeBase"))).origin.y
			_check("Kopfknochen sitzt auf Menschenhoehe (1,3…1,8 m)",
				head_y > 1.3 and head_y < 1.8, "gemessen: %.2f m" % head_y)
			_check("Zehenknochen liegt am Boden (< 0,2 m)", toe_y < 0.2, "gemessen: %.2f m" % toe_y)
		var pap: AnimationPlayer = AssetRegistry.animation_player(p)
		_check("Spieler-Modell bringt einen AnimationPlayer mit", pap != null)
		if pap != null:
			for role in ["idle", "walk", "run", "attack", "hit", "death"]:
				var clip: String = String(AssetRegistry.CLIP_OVERRIDES["player"].get(role, ""))
				_check("Spieler-Clip '%s' existiert im Modell (%s)" % [role, clip],
					clip != "" and pap.has_animation(clip))
		_check("Spieler-Modell bringt ein Skelett mit", sk != null)
		remove_child(p)
		p.free()
	# MASSSTABS-WACHE ueber ALLE vorhandenen Assets. Ein flaches Modell (Geroellfeld, Waffe,
	# Wandstueck) ueber die HOEHE zu skalieren blaest es ins Absurde: "sand_rocks_small" wurde
	# so 10,4 x 8,7 m gross und hat halb Rustwater verdeckt. Kein Asset darf in irgendeiner
	# Richtung mehr als das Vierfache seines Zielmasses messen — das laesst normalen
	# Proportionen Luft und faengt genau diesen Fehler.
	var scale_ok: bool = true
	var worst: String = ""
	var worst_ratio: float = 0.0
	for name in AssetRegistry.PATHS.keys():
		var id: String = String(name)
		if not AssetRegistry.has_model(id):
			continue
		var by_length: float = AssetRegistry.length_of(id)
		var target: float = by_length if by_length > 0.0 else AssetRegistry.height_of(id)
		var m: Node3D = AssetRegistry.instantiate(id, target)
		if m == null:
			continue
		var s: Vector3 = AssetRegistry.local_bounds(m).size
		var ratio: float = maxf(s.x, maxf(s.y, s.z)) / maxf(target, 0.001)
		if ratio > worst_ratio:
			worst_ratio = ratio
			worst = id
		if ratio > 4.0:
			scale_ok = false
		m.free()
	_check("Kein Asset ist unverhaeltnismaessig gross skaliert",
		scale_ok, "schlimmster Fall: %s mit Faktor %.1f" % [worst, worst_ratio])
	_test_town_layout()
	_check("Bodentextur ist in der Registry vorgesehen", AssetRegistry.PATHS.has("ground_sand"))
	_check("Unbekanntes Material liefert null (→ Einheitsfarbe)",
		AssetRegistry.material_from_model("gibts_nicht") == null)


# ── Overworld-Truhen: derselbe Mechanismus wie OverworldView._loot_chest() ────
## Prüft NICHT die Node3D-Szene (Platzierung/Distanz — headless per Smoke-Test abgedeckt),
## sondern den eigentlichen Loot-Mechanismus: ProgressionManager.make_gear() ->
## EquipManager.equip_item() -> PlayerStats liest SOFORT das neue Gear (kein Cache/Refresh
## nötig). Deterministisch über einen geseedeten RNG (dieselbe API, die die Truhe nutzt).
func _test_overworld_loot_flow() -> void:
	print("· Overworld-Truhen (Truhe → ProgressionManager/EquipManager → PlayerStats)")
	_reset_state()
	var base_dmg: int = PlayerStats.damage_per_bullet("karabiner")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Gewöhnlich (0 Affixe) hält den Test einfach: nur der Haupt-Stat zählt, keine Affix-Überlagerung.
	var gear: Dictionary = ProgressionManager.make_gear("weapon", "common", "", rng)
	_check("Gerolltes Waffen-Teil hat Haupt-Stat 'damage'", String(gear["stat"]["key"]) == "damage")
	_check("EquipManager: Slot vorher leer", not EquipManager.is_equipped("weapon"))
	_check("equip_item meldet Erfolg", EquipManager.equip_item(gear, "weapon") == true)
	var new_dmg: int = PlayerStats.damage_per_bullet("karabiner")
	_check("Anlegen wirkt SOFORT auf den nächsten Schuss (kein Cache/Refresh)",
		new_dmg == base_dmg + int(gear["stat"]["val"]),
		"vorher %d, nachher %d, Stat +%d" % [base_dmg, new_dmg, int(gear["stat"]["val"])])
	_check("worn() zeigt genau 1 getragenes Teil", EquipManager.worn().size() == 1)
	# Vergleichslogik der Truhe (_loot_chest): ein spürbar schwächeres Teil würde NICHT
	# angelegt, sondern eingeschmolzen -- Beute muss sich lohnen, nicht nur variieren.
	var worse: Dictionary = { "uid": -1, "slot": "weapon", "rarity": "common", "req": 1,
		"name": "Testattrappe", "stat": { "key": "damage", "val": 1, "q": 0.0 }, "affixes": [] }
	_check("Deutlich schwächeres Teil hat niedrigeren Marktwert (würde eingeschmolzen)",
		ProgressionManager.gear_value(worse) < ProgressionManager.gear_value(gear))


# ── Overworld-Questfluss: derselbe Weg, den OverworldView._process_npcs() geht ──
## Prueft die Kette Auftraggeber -> annehmen -> Fortschritt -> abgeben, samt der
## Material-Drop-Logik, ohne die 3D-Szene zu instanzieren.
func _test_overworld_quest_flow() -> void:
	print("· Overworld-Quests (NPC → QuestManager → Belohnung)")
	_reset_state()
	# Mabels Kopfgeld ist der Einstiegsauftrag (Kapitel 1, kein Gilden-Gate).
	var qid: String = "q_bounty"
	var def: Dictionary = QuestManager.QUESTS[qid]
	_check("Mabel ist die Auftraggeberin von q_bounty", String(def["giver"]) == "mabel")
	_check("Startzustand ist 'available'", QuestManager.get_quest_state(qid) == QuestManager.STATE_AVAILABLE)
	_check("Annehmen gelingt", QuestManager.accept_quest(qid) == true)
	_check("Zustand jetzt 'active'", QuestManager.get_quest_state(qid) == QuestManager.STATE_ACTIVE)
	_check("Fortschritt startet bei 0", int(QuestManager.check_quest_progress(qid)["current"]) == 0)
	_check("Vorzeitige Abgabe wird abgelehnt", QuestManager.complete_quest(qid) == false)
	for i in int(def["count"]):
		GameState.add_kill()
	_check("Nach %d Kills erfuellt" % int(def["count"]), QuestManager.is_quest_complete(qid))
	var gold_before: int = GameState.gold
	_check("Abgabe gelingt", QuestManager.complete_quest(qid) == true)
	_check("Goldbelohnung gutgeschrieben", GameState.gold == gold_before + int(def["reward_gold"]))
	_check("Zustand jetzt 'done'", QuestManager.get_quest_state(qid) == QuestManager.STATE_DONE)
	# Jeder in der Szene platzierte NPC muss auch wirklich Quests im Manager haben,
	# sonst steht eine Figur ohne Funktion in der Stadt.
	var givers: Array = ["mabel", "silas", "doc"]
	var all_have_quests: bool = true
	for g in givers:
		var found: bool = false
		for q in QuestManager.QUESTS.keys():
			if String(QuestManager.QUESTS[q].get("giver", "")) == g:
				found = true
		if not found:
			all_have_quests = false
	_check("Alle drei Stadt-NPCs haben Quests", all_have_quests)
	# Sammel-Quest braucht Material-Drops: die Drop-Tabelle muss die Quest-Items abdecken.
	var scrap_quest: Dictionary = QuestManager.QUESTS["q_scrap"]
	_check("Sammel-Quest fordert 'schrott' (von der Drop-Tabelle gedeckt)",
		String(scrap_quest["item"]) == "schrott")


# ── Weltstruktur (GDD §1.4a: offene Wildnis + bauliche Aktionszonen + Eisenbahn) ──
func _test_walkable_zones() -> void:
	print("· Weltstruktur (Wildnis / Aktionszonen / Eisenbahn)")
	# 1. Wildnis: die Wueste zwischen den Orten ist FREI. Nur der Kraterrand begrenzt.
	_check("Rustwater-Mitte ist begehbar",
		WorldManager.is_walkable(WorldManager.poi_position("rustwater")))
	var a: Vector2 = WorldManager.poi_position("rustwater")
	var b: Vector2 = WorldManager.poi_position("zugdepot")
	_check("Mitte zwischen zwei Orten ist begehbar", WorldManager.is_walkable((a + b) / 2.0))
	var perp: Vector2 = (b - a).normalized().orthogonal()
	var off: Vector2 = (a + b) / 2.0 + perp * (WorldManager.RAIL_CORRIDOR_HALF_W * 10.0)
	_check("Auch weit neben der Trasse ist die Wueste begehbar", WorldManager.is_walkable(off))
	_check("Abgelegene Kartenecke ist begehbar (offene Welt)",
		WorldManager.is_walkable(Vector2(30, 1900)))
	_check("Jenseits des Kraterrands endet die Welt",
		not WorldManager.is_walkable(Vector2(-5, 500)) and not WorldManager.is_walkable(Vector2(500, 2100)))
	# 2. Aktionszonen: dort greift die bauliche Begrenzung, draussen nicht.
	_check("Hub-Zone ist groesser als eine Nebenzone",
		WorldManager.zone_radius("rustwater") > WorldManager.zone_radius("schrott_minen"))
	_check("Am Ort steht man in dessen Aktionszone",
		WorldManager.zone_at(WorldManager.poi_position("rustwater")) == "rustwater")
	_check("Zwischen den Orten ist keine Aktionszone",
		not WorldManager.in_action_zone((a + b) / 2.0))
	_check("Aktionszonen ueberlappen sich nicht (jede Zone ist eindeutig)", _zones_disjoint())
	_check("Rustwater ist befriedet, ein Dungeon nicht",
		WorldManager.is_safe_zone("rustwater") and not WorldManager.is_safe_zone("schrott_minen"))
	# 3. Routen sind nur noch Nachbarschaft — gezeichnet wird davon die Trasse. Sie sperrt
	#    nichts (man laeuft ueber die Gleise), haelt aber die Streuung von den Schwellen fern.
	_check("Zwischen zwei Bahnhoefen liegt man auf der Trasse", WorldManager.on_rail((a + b) / 2.0))
	_check("Weit daneben nicht mehr", not WorldManager.on_rail(off))
	_check("Die Trasse sperrt nicht — man darf ueber die Gleise laufen",
		WorldManager.is_walkable((a + b) / 2.0))
	# Regression: Es gab hier gestampfte Pisten. Sie waren 55 m breit (der Kommentar an
	# CORRIDOR_HALF_W las die halbe Breite als volle) und deckten damit den 30-m-Krater der
	# Schrotthalde restlos zu. Der freizuhaltende Streifen muss deutlich schmaler bleiben als
	# die kleinste Gelaendeform, sonst verschluckt er sie wieder.
	var schmalste: float = 1e9
	for tf in WorldManager.TERRAIN:
		schmalste = minf(schmalste, float(tf["radius"]) * 2.0)
	_check("Der Trassenstreifen ist schmaler als die kleinste Senke",
		WorldManager.RAIL_CORRIDOR_HALF_W * 2.0 * WorldManager.METERS_PER_UNIT < schmalste,
		"%.1f m Streifen, %.1f m Senke"
			% [WorldManager.RAIL_CORRIDOR_HALF_W * 2.0 * WorldManager.METERS_PER_UNIT, schmalste])
	var connected: Dictionary = {}
	for r in WorldManager.ROUTES:
		connected[String(r[0])] = true
		connected[String(r[1])] = true
	var all_connected: bool = true
	for id in WorldManager.POIS.keys():
		if not connected.has(String(id)):
			all_connected = false
	_check("Jeder Ort haengt an mindestens einer Route (kein unerreichbarer POI)", all_connected)
	# 4. Eisenbahn: Bahnhoefe sind echte Orte, die Trasse liegt auf den Pisten.
	var stations_are_pois: bool = true
	for s in WorldManager.RAIL_STATIONS:
		if not WorldManager.has_poi(String(s)):
			stations_are_pois = false
	_check("Jeder Bahnhof ist ein echter POI", stations_are_pois)
	_check("Rustwater hat einen Bahnhof, das Rattengestruepp nicht",
		WorldManager.has_station("rustwater") and not WorldManager.has_station("rattengestruepp"))
	var segs: Array = WorldManager.rail_segments()
	_check("Es gibt Trassenabschnitte", segs.size() > 0)
	var segs_ok: bool = true
	for s in segs:
		if not WorldManager.has_station(String(s[0])) or not WorldManager.has_station(String(s[1])):
			segs_ok = false
	_check("Jeder Trassenabschnitt verbindet zwei Bahnhoefe", segs_ok)
	_check("Das Schienennetz haengt zusammen (jeder Bahnhof erreichbar)", _rail_network_connected())
	# 5. Rueckfall: ein Punkt ausserhalb des Kraters wird hineingezogen.
	var rescued: Vector2 = WorldManager.nearest_walkable(Vector2(-40, 2400))
	_check("nearest_walkable liefert eine begehbare Position", WorldManager.is_walkable(rescued))


## Stadtplan von Rustwater: eng, aber nicht ineinander. Genau die Pruefung, die eine dichte
## Bebauung braucht — je enger man baut, desto leichter steht ein Haus im naechsten oder in
## der Gasse. Gerechnet wird mit den GEMESSENEN Modellmassen, nicht mit den Planzahlen.
func _test_town_layout() -> void:
	print("· Stadtplan Rustwater (enge Strassenstadt)")
	var plots: Array = []   # [Name, Mitte (x,z), halbe Kantenlaengen]
	for b in OverworldView.TOWN_LAYOUT:
		plots.append(_plot(String(b[1]), b[2], float(b[3]), b[4]))
	var shack_count: int = 0
	for spot in OverworldView.SHACK_SPOTS:
		var asset: String = "shack_%s" % ["a", "b", "c", "d"][shack_count % 4]
		var yaw: float = 90.0 if spot.x < 0.0 else -90.0
		plots.append(_plot(asset, spot, yaw, Vector3(6.0, 4.2, 5.0)))
		shack_count += 1

	var overlap: String = ""
	for i in plots.size():
		for j in range(i + 1, plots.size()):
			var d: Vector2 = (Vector2(plots[i][1]) - Vector2(plots[j][1])).abs()
			var need: Vector2 = Vector2(plots[i][2]) + Vector2(plots[j][2])
			if d.x < need.x and d.y < need.y:
				overlap = "%s <-> %s" % [plots[i][0], plots[j][0]]
	_check("Keine zwei Gebaeude ueberlappen sich", overlap == "", overlap)

	# Die Hauptstrasse muss frei bleiben, sonst laeuft man in der eigenen Stadt gegen eine Wand.
	var blocked: String = ""
	var in_wall: String = ""
	for p in plots:
		var centre: Vector2 = p[1]
		var half: Vector2 = p[2]
		if absf(centre.x) - half.x < OverworldView.STREET_HALF_W and absf(centre.x) < 30.0:
			blocked = String(p[0])
		if centre.length() + maxf(half.x, half.y) > OverworldView.TOWN_R - 2.0:
			in_wall = String(p[0])
	_check("Die Hauptstrasse bleibt frei (%.0f m breit)" % (2.0 * OverworldView.STREET_HALF_W),
		blocked == "", blocked)
	_check("Alle Bauten stehen innerhalb des Ortsradius", in_wall == "", in_wall)

	# NPCs: auf der Strasse, vor ihrem Haus, nicht in einer Wand.
	var npc_bad: String = ""
	for n in OverworldView.TOWN_NPCS:
		var pos: Vector2 = n[2]
		for p in plots:
			var d2: Vector2 = (pos - Vector2(p[1])).abs()
			if d2.x < float(p[2].x) and d2.y < float(p[2].y):
				npc_bad = "%s steckt in %s" % [String(n[0]), String(p[0])]
	_check("Kein NPC steht in einer Hauswand", npc_bad == "", npc_bad)
	_check("Der Bahnhof liegt ausserhalb des Ortes",
		OverworldView.STATION_OFFSET_M > OverworldView.TOWN_R)


## Grundflaeche eines geplanten Bauwerks: gemessenes Modell (falls vorhanden), sonst Ersatzmass.
## Bei 90°/270° Drehung tauschen Breite und Tiefe die Achsen.
func _plot(asset: String, spot: Vector2, yaw_deg: float, fallback: Vector3) -> Array:
	var size := Vector2(fallback.x, fallback.z)
	if asset != "" and AssetRegistry.has_model(asset):
		var m: Node3D = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset))
		var b: Vector3 = AssetRegistry.local_bounds(m).size
		size = Vector2(b.x, b.z)
		m.free()
	if absf(sin(deg_to_rad(yaw_deg))) > 0.7:
		size = Vector2(size.y, size.x)
	return [asset if asset != "" else "Platzhalter", spot, size * 0.5]


## Wegwerf-AnimationPlayer mit den angegebenen Clip-Namen (fuer die Namenssuche-Tests).
func _clip_player(names: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for n in names:
		lib.add_animation(String(n), Animation.new())
	ap.add_animation_library("", lib)
	_scratch.append(ap)
	return ap


## Keine zwei Aktionszonen duerfen sich beruehren — sonst waere `zone_at` von der
## Reihenfolge der POI-Tabelle abhaengig statt von der Geografie.
func _zones_disjoint() -> bool:
	var ids: Array = WorldManager.POIS.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var x: String = String(ids[i])
			var y: String = String(ids[j])
			var d: float = WorldManager.poi_position(x).distance_to(WorldManager.poi_position(y))
			if d < WorldManager.zone_radius(x) + WorldManager.zone_radius(y):
				return false
	return true


## Breitensuche ueber die Trasse: von einem Bahnhof aus muessen alle anderen erreichbar sein.
func _rail_network_connected() -> bool:
	var segs: Array = WorldManager.rail_segments()
	if WorldManager.RAIL_STATIONS.is_empty():
		return false
	var seen: Dictionary = { String(WorldManager.RAIL_STATIONS[0]): true }
	var queue: Array = [String(WorldManager.RAIL_STATIONS[0])]
	while not queue.is_empty():
		var cur: String = String(queue.pop_front())
		for s in segs:
			var other: String = ""
			if String(s[0]) == cur:
				other = String(s[1])
			elif String(s[1]) == cur:
				other = String(s[0])
			if other != "" and not seen.has(other):
				seen[other] = true
				queue.append(other)
	return seen.size() == WorldManager.RAIL_STATIONS.size()
