class_name DialogBox extends Control
## Die Sprechtafel — was ein NPC sagt, steht unten im Bild und nicht in einer Blase.
##
## Vorher lief jedes Gespräch über `_say()`, also über dieselbe Einblendung, die auch „Beutel
## voll" und „Munition leer" meldet. Zwei völlig verschiedene Dinge in derselben Zeile: Eine
## Systemmeldung verschwindet nach zwei Sekunden von selbst, ein Gespräch wartet auf einen.
##
## Vorlage ist Diablo Immortal (Bilder vom Auftraggeber): **Bildnis links, Name in Versalien,
## Text daneben, unten am Bildrand über die ganze Breite.** Das funktioniert dort aus drei
## Gründen, und alle drei gelten hier genauso:
##
##  1. **Unten.** Die Figuren stehen in der Bildmitte — eine Sprechblase an ihnen verdeckt genau
##     das, was die Nahaufnahme zeigen soll. Der untere Rand ist die einzige Fläche, die man
##     zudecken darf.
##  2. **Bildnis.** Es sagt in einem Blick, WER spricht, ohne dass man den Namen lesen muss. In
##     einer Stadt mit drei Auftraggebern ist das der Unterschied zwischen „jemand redet" und
##     „Mabel redet".
##  3. **Sie wartet.** Der Text steht, bis man tippt. Deshalb der Winkel unten rechts — er ist
##     das einzige Bedienelement und sagt „es geht weiter, wenn du willst".
##
## GEZEICHNET wie die Puppe und das Beutel-Raster. Sobald es Grafiken gibt (`docs/PROMPTS_UI.md`),
## ersetzt `set_frame()` den gemalten Rahmen und `set_portrait()` das Platzhalter-Bildnis, ohne
## dass sich am Rest etwas ändert.

signal dismissed

## Maße bei 1280×720 Bezugsauflösung.
const MARGIN: float = 22.0        # Abstand zum Bildrand
## Mindesthöhe. Die Tafel WÄCHST mit dem Text — der erste Entwurf stand fest auf 138 px, und
## sobald eine Quest ihre Zeile „🧭 Das Rattengestrüpp — 559 m" mitbrachte, wurde die unterste
## Zeile abgeschnitten. Ein Kasten, der Text verschluckt, ist schlimmer als ein hoher Kasten.
const BOX_H: float = 138.0
const BOX_H_MAX: float = 268.0
const PORTRAIT: float = 108.0     # Kantenlänge des Bildnisses
const PAD: float = 15.0

## Farben. Pergament, aber ein verrußtes — reines Diablo-Creme wäre in dieser Welt ein
## Fremdkörper; hier ist alles Papier seit dreißig Jahren im Kesselrauch gehangen.
const PAPER: Color = Color(0.84, 0.79, 0.66)
const PAPER_DARK: Color = Color(0.74, 0.68, 0.55)
const IRON: Color = Color(0.13, 0.11, 0.10)
const BRASS: Color = Color(0.68, 0.54, 0.28)
const INK: Color = Color(0.16, 0.13, 0.10)

var speaker: String = ""
var line: String = ""

var _portrait: Texture2D = null
var _frame: Texture2D = null
var _label: Label
var _blink: float = 0.0


## Aufbau in `_init` und nicht in `_ready`.
##
## `_ready` laeuft erst, wenn das Steuerelement im Szenenbaum haengt. Eine frisch erzeugte
## Sprechtafel waere bis dahin halb fertig: `visible` stuende auf `true` (Godots Vorgabe) und
## `_label` waere `null` — der erste Satz haette sie zum Absturz gebracht. `_init` laeuft bei
## `new()`, also immer. Das ist nicht nur fuer Tests richtig, sondern fuer jeden Aufrufer.
func _init() -> void:
	# Ganze Bildbreite unten. `set_anchors_AND_OFFSETS_preset` — die kurze Variante lässt die
	# Ränder auf 0 und das Ergebnis wäre wieder ein 0×0-Steuerelement (dieselbe Falle wie bei
	# allen anderen Vollbild-Oberflächen).
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = MARGIN
	offset_right = -MARGIN
	offset_top = -(BOX_H + MARGIN)
	offset_bottom = -MARGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# Der Fließtext als echtes Label, nicht gezeichnet: Umbruch über mehrere Zeilen ist die eine
	# Sache, die `draw_string` nicht kann und die hier jedes Mal gebraucht wird.
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", INK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	if _label == null:
		return
	var x: float = PAD * 2.0 + PORTRAIT
	_label.position = Vector2(x, PAD + 26.0)
	_label.size = Vector2(maxf(_text_width(), 40.0), maxf(size.y - PAD * 2.0 - 26.0, 20.0))
	_label.custom_minimum_size = _label.size


## Eine Zeile zeigen. `giver` ist die Auftraggeber-Id — daraus wird das Bildnis gesucht.
func show_line(name_text: String, body: String, giver: String = "") -> void:
	speaker = name_text
	line = body
	_label.text = body
	_portrait = _load_ui("portrait_" + giver) if giver != "" else null
	offset_top = -(_needed_height(body) + MARGIN)
	visible = true
	_blink = 0.0
	_layout()
	queue_redraw()


## Wie hoch muss die Tafel für diesen Text sein?
##
## GEMESSEN am Umbruch, nicht an der Zeichenzahl. `get_multiline_string_size` rechnet mit
## derselben Schrift und derselben Breite, mit der das Label gleich umbricht — jede andere
## Schätzung liegt bei einem Text mit Sonderzeichen und langen Ortsnamen daneben.
func _needed_height(body: String) -> float:
	var schrift: Font = ThemeDB.fallback_font
	if schrift == null:
		return BOX_H
	var breite: float = maxf(_text_width(), 80.0)
	var h: float = schrift.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_LEFT,
		breite, 16).y
	return clampf(PAD * 2.0 + 30.0 + h, BOX_H, BOX_H_MAX)


## Breite der Textspalte. Steht in einer eigenen Funktion, weil sie an ZWEI Stellen gebraucht
## wird — beim Messen und beim Setzen. Zwei Rechnungen liefen hier garantiert auseinander.
func _text_width() -> float:
	# Bei einem Control, das noch nie umbrochen wurde, ist `size.x` 0. Dann gilt die
	# Bezugsauflösung minus der beiden Ränder.
	var voll: float = size.x if size.x > 1.0 else 1280.0 - MARGIN * 2.0
	return voll - (PAD * 2.0 + PORTRAIT) - PAD


func hide_box() -> void:
	if not visible:
		return
	visible = false
	dismissed.emit()


## Wird der Tipp hier verbraucht? Die Tafel schluckt alles, was auf ihr landet — sonst startet
## derselbe Tipp, der weiterblättert, gleich noch den Joystick.
func hits(at: Vector2) -> bool:
	return visible and Rect2(global_position, size).has_point(at)


## Optionale Grafiken. Solange keine da sind, zeichnet die Tafel sich selbst; liegt eine Datei,
## wird sie genommen. Kein Fehler, kein Platzhalter-Rot — die Oberfläche funktioniert in beiden
## Zuständen, und der Auftraggeber kann liefern, wann er will.
static func _load_ui(basename: String) -> Texture2D:
	var pfad: String = "res://assets/ui/%s.png" % basename
	if not ResourceLoader.exists(pfad):
		return null
	return load(pfad) as Texture2D


func set_frame(tex: Texture2D) -> void:
	_frame = tex
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if _frame != null:
		draw_texture_rect(_frame, r, false)
	else:
		_draw_frame(r)
	_draw_portrait(Rect2(Vector2(PAD, PAD), Vector2(PORTRAIT, PORTRAIT)))
	var schrift: Font = ThemeDB.fallback_font
	if schrift == null:
		return
	# Name in VERSALIEN und gesperrt. Beides aus der Vorlage, und beides hat einen Grund: Der
	# Name ist eine Überschrift, kein Satz — gesperrte Versalien lesen sich als Rubrik und
	# geraten nicht mit dem Gesprochenen durcheinander.
	var x: float = PAD * 2.0 + PORTRAIT
	draw_string(schrift, Vector2(x, PAD + 17.0), _sperren(speaker.to_upper()),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.33, 0.26, 0.16))
	# Der Winkel unten rechts blinkt langsam: das einzige Bedienelement der Tafel.
	var a: float = 0.45 + 0.4 * sin(_blink * 3.2)
	var mx: float = size.x - PAD - 12.0
	var my: float = size.y - PAD - 6.0
	draw_line(Vector2(mx - 9.0, my - 5.0), Vector2(mx, my), Color(0.33, 0.26, 0.16, a), 2.0)
	draw_line(Vector2(mx, my), Vector2(mx + 9.0, my - 5.0), Color(0.33, 0.26, 0.16, a), 2.0)


## Buchstaben sperren (ein Leerzeichen dazwischen). Godots Standardschrift kennt kein
## `letter_spacing`; bei einer Überschrift aus fünf Wörtern ist das der billigste Weg.
static func _sperren(t: String) -> String:
	var out: String = ""
	for i in t.length():
		out += t[i]
		if i < t.length() - 1 and t[i] != " ":
			out += " "
	return out


## Der gemalte Rahmen: Pergamentfläche, dunkle Eisenkante, dünne Messinglinie innen.
##
## Drei Lagen statt einer, weil ein einzelnes Rechteck flach aussieht. Die Messinglinie ist der
## Trick — sie sitzt zwei Pixel innerhalb der Eisenkante und lässt die Tafel wie etwas
## Gefasstes wirken statt wie ein aufgeklebter Kasten.
func _draw_frame(r: Rect2) -> void:
	draw_rect(r, IRON)
	var innen: Rect2 = r.grow(-3.0)
	draw_rect(innen, PAPER)
	# Angeschmutzter Fuß: Ein gleichmäßig helles Feld sieht aus wie Papier aus dem Drucker.
	draw_rect(Rect2(innen.position + Vector2(0.0, innen.size.y - 7.0),
		Vector2(innen.size.x, 7.0)), PAPER_DARK)
	draw_rect(r.grow(-5.0), Color(BRASS.r, BRASS.g, BRASS.b, 0.55), false, 1.0)


## Das Bildnis. Ohne Datei ein dunkles Feld mit dem Anfangsbuchstaben — lesbar, ruhig, und
## unverwechselbar genug, dass man Mabel von Silas unterscheidet.
func _draw_portrait(r: Rect2) -> void:
	draw_rect(r.grow(2.0), IRON)
	if _portrait != null:
		draw_texture_rect(_portrait, r, false)
	else:
		draw_rect(r, Color(0.17, 0.15, 0.14))
		var schrift: Font = ThemeDB.fallback_font
		if schrift != null and not speaker.is_empty():
			var z: String = speaker.substr(0, 1).to_upper()
			var m: Vector2 = schrift.get_string_size(z, HORIZONTAL_ALIGNMENT_LEFT, -1, 54)
			draw_string(schrift, r.position + (r.size - m) * 0.5 + Vector2(0.0, m.y * 0.78),
				z, HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(0.62, 0.54, 0.38))
	draw_rect(r, Color(BRASS.r, BRASS.g, BRASS.b, 0.7), false, 1.5)
