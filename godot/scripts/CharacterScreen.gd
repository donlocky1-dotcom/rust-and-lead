class_name CharacterScreen extends Control
## Charakter-Bildschirm — Ausrüstung, Beutel und Fähigkeiten (GDD §7.4/§7.5.1).
##
## Zwei Reiter, weil beides dieselbe Frage beantwortet („was habe ich aus dem Gespielten
## gemacht?") und beides vorher **unsichtbar** war:
##
## * **Ausrüstung:** Truhen legten bisher automatisch an, was besser war. Man sah nie, was man
##   trug, konnte nie tauschen und nie vergleichen — Beute war etwas, das einem passierte.
## * **Fähigkeiten:** `perk_points` stiegen bei jedem Aufstieg und ließen sich nirgends
##   ausgeben. Der ganze Perk-Baum aus `ProgressionManager` war tote Rechenleistung.
##
## Der Bildschirm rechnet nichts selbst. Ausrüstung läuft über `EquipManager`/`BagManager`,
## Fähigkeiten über `ProgressionManager` — hier steht nur, wie es aussieht und was ein Tipp
## auslöst.

enum Tab { AUSRUESTUNG, FAEHIGKEITEN }

const PANEL_W: float = 560.0

var tab: int = Tab.AUSRUESTUNG

var _head: Label
var _tabs: HBoxContainer
var _list: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.04, 0.90)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position = Vector2(-PANEL_W * 0.5, 30.0)
	box.custom_minimum_size = Vector2(PANEL_W, 0.0)
	box.add_theme_constant_override("separation", 7)
	add_child(box)
	_head = Label.new()
	_head.add_theme_font_size_override("font_size", 17)
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_head)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	box.add_child(_tabs)
	# Die Liste kann lang werden (zwölf Perks, fünf Slots, voller Beutel) — ohne Rollbereich
	# waere sie auf dem Handy unten abgeschnitten.
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(PANEL_W, 430.0)
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(PANEL_W, 0.0)
	_list.add_theme_constant_override("separation", 4)
	_scroll.add_child(_list)
	var hint := Label.new()
	hint.add_theme_font_size_override("font_size", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "[C] oder [Esc] schließt"
	box.add_child(hint)


func open(which: int = Tab.AUSRUESTUNG) -> void:
	tab = which
	visible = true
	refresh()


func close() -> void:
	visible = false


## Liegt der Punkt auf der Tafel? Ein Tipp DARAUF muss an die Knöpfe durchgereicht werden,
## ein Tipp DANEBEN schließt (dieselbe Trennung wie beim Laden).
func hits_panel(at: Vector2) -> bool:
	return Rect2(Vector2(size.x * 0.5 - PANEL_W * 0.5 - 12.0, 20.0),
		Vector2(PANEL_W + 24.0, 560.0)).has_point(at)


func refresh() -> void:
	if _list == null:
		return
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_head.text = "⭐ Stufe %d   💰 %d   %s %d/%d   %s %d/%d" % [
		GameState.level, GameState.gold,
		String(AmmoData.POOLS["muni"]["icon"]), AmmoData.amount("muni"), AmmoData.cap("muni"),
		String(AmmoData.POOLS["kristall"]["icon"]), AmmoData.amount("kristall"), AmmoData.cap("kristall")]
	_add_tab("🎽 Ausrüstung", Tab.AUSRUESTUNG)
	_add_tab("✴ Fähigkeiten (%d)" % GameState.perk_points, Tab.FAEHIGKEITEN)
	if tab == Tab.AUSRUESTUNG:
		_build_gear()
	else:
		_build_perks()


func _add_tab(text: String, which: int) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(PANEL_W * 0.5 - 6.0, 40.0)
	b.add_theme_font_size_override("font_size", 15)
	b.disabled = (tab == which)
	b.pressed.connect(func() -> void:
		tab = which
		refresh())
	_tabs.add_child(b)


# ── Reiter „Ausrüstung" ───────────────────────────────────────────────────────

func _build_gear() -> void:
	_caption("Getragen")
	for slot in EquipManager.GEAR_SLOTS:
		var worn: Dictionary = EquipManager.equipped(String(slot))
		var cat: String = String(ProgressionManager.GEAR_SLOTS[String(slot)]["name"])
		if worn.is_empty():
			_row("%s\n   — leer —" % cat, Color(0.55, 0.55, 0.55), "", Callable())
			continue
		_row("%s\n   %s" % [cat, _describe(worn)], _rarity_color(worn), "Ablegen",
			func() -> void:
				if BagManager.unequip_to_bag(String(slot)):
					refresh())
	# Werte-Blatt: erst hier wird sichtbar, dass ein Fund überhaupt etwas bewirkt hat.
	_caption("Wirksame Werte")
	var sheet: Array = [
		["❤ Leben", "%d" % PlayerStats.max_hp()],
		["🔫 Schaden/Schuss", "%d" % PlayerStats.damage_per_bullet("karabiner")],
		["⚡ Feuerrate", "%d ms" % PlayerStats.fire_ms("karabiner")],
		["💥 Krit", "%.0f %% x%.1f" % [PlayerStats.crit_chance() * 100.0, PlayerStats.crit_mult()]],
		["🛡 Rüstung", "%d" % PlayerStats.player_armor()],
		["🦿 Tempo", "%.0f" % PlayerStats.move_speed()],
		["🧲 Magnet", "%d" % PlayerStats.magnet_dist()],
	]
	for r in sheet:
		_row("%s: %s" % [String(r[0]), String(r[1])], Color(0.86, 0.84, 0.78), "", Callable())
	_caption("Beutel — %d/%d Plätze" % [BagManager.used_cells(), BagManager.total_cells()])
	if GameState.bag.is_empty():
		_row("   — leer —", Color(0.55, 0.55, 0.55), "", Callable())
		return
	for i in GameState.bag.size():
		var g: Dictionary = GameState.bag[i]
		var idx: int = i
		var f: Vector2i = BagManager.footprint(g)
		_row("%s\n   %s · %d Plätze" % [_describe(g),
			String(ProgressionManager.GEAR_SLOTS[String(g["slot"])]["name"]), f.x * f.y],
			_rarity_color(g), "Anlegen",
			func() -> void:
				if BagManager.equip_from_bag(idx):
					refresh(),
			"🔩", func() -> void:
				BagManager.scrap_at(idx)
				refresh())


func _describe(g: Dictionary) -> String:
	var out: String = "%s  (+%d %s)" % [String(g["name"]), int(g["stat"]["val"]), String(g["stat"]["key"])]
	var extra: Array = g.get("affixes", [])
	if not extra.is_empty():
		var parts: Array = []
		for a in extra:
			parts.append("+%d %s" % [int(a["val"]), String(a["key"])])
		out += "  " + ", ".join(parts)
	return out


func _rarity_color(g: Dictionary) -> Color:
	return OverworldView.RARITY_COLOR.get(String(g.get("rarity", "common")), Color.WHITE)


# ── Reiter „Fähigkeiten" ──────────────────────────────────────────────────────

func _build_perks() -> void:
	_caption("%d Punkt(e) frei — steigen mit jedem Aufstieg" % GameState.perk_points)
	for branch in ProgressionManager.PERK_BRANCHES:
		var bid: String = String(branch["id"])
		_caption("%s — %s  (%d investiert)" % [String(branch["name"]), String(branch["blurb"]),
			ProgressionManager.branch_points(bid)])
		for pid in ProgressionManager.PERKS:
			var p: Dictionary = ProgressionManager.PERKS[pid]
			if String(p["branch"]) != bid:
				continue
			var id: String = String(pid)
			var rank: int = ProgressionManager.perk_rank(id)
			var maxr: int = int(p["max"])
			var t: Dictionary = ProgressionManager.PERK_TIER[int(p["tier"])]
			var text: String = "%s   Rang %d/%d" % [String(p["name"]), rank, maxr]
			if int(p["per"]) > 0:
				text += "   (je +%d)" % int(p["per"])
			var col := Color(0.90, 0.88, 0.80)
			var action: Callable = Callable()
			var btn: String = ""
			if rank >= maxr:
				btn = "voll"
			elif not ProgressionManager.perk_tier_ok(id):
				# Warum es zu ist, gehoert daneben: „gesperrt" allein ist eine Sackgasse.
				btn = "Stufe %d · %d Pkt" % [int(t["lvl"]), int(t["inv"])]
				col = Color(0.52, 0.52, 0.52)
				text = "🔒 " + text
			elif ProgressionManager.xor_blocked(id):
				btn = "anderer Kapstein"
				col = Color(0.52, 0.52, 0.52)
			elif GameState.perk_points <= 0:
				btn = "kein Punkt"
			else:
				action = func() -> void:
					if ProgressionManager.buy_perk(id):
						refresh()
			_row(text, col, "Wählen" if action.is_valid() else btn, action)


# ── Bausteine ─────────────────────────────────────────────────────────────────

func _caption(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.72, 0.66, 0.50))
	_list.add_child(l)


## Eine Zeile: Text links, bis zu zwei Knöpfe rechts. Ein leerer Knopftext ohne Aktion ergibt
## eine reine Anzeigezeile.
func _row(text: String, col: Color, btn_text: String, action: Callable,
		btn2_text: String = "", action2: Callable = Callable()) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", col)
	row.add_child(l)
	if btn_text != "":
		var b := Button.new()
		b.text = btn_text
		b.custom_minimum_size = Vector2(132.0, 38.0)
		b.add_theme_font_size_override("font_size", 14)
		if action.is_valid():
			b.pressed.connect(action)
		else:
			b.disabled = true
		row.add_child(b)
	if btn2_text != "":
		var b2 := Button.new()
		b2.text = btn2_text
		b2.tooltip_text = "Verschrotten"
		b2.custom_minimum_size = Vector2(46.0, 38.0)
		b2.pressed.connect(action2)
		row.add_child(b2)
	_list.add_child(row)
