class_name FireButton extends Control
## Schuss-Knopf unten rechts (Master-GDD §1.5) — die Gegenhand zum Joystick unten links.
##
## Zeichnet nur; die Eingabe wertet `OverworldView` aus (Finger ODER Maus ODER Leertaste,
## dieselbe Logik wie beim Joystick). Bewusst ein eigenes Skript wie `VirtualStick` und
## `Minimap`: hält `OverworldView` schlank.
##
## Der Knopf meldet zusätzlich, OB ein Ziel in Reichweite ist. Das ist kein Zierrat: Gezielt
## wird weiterhin automatisch auf den nächsten Gegner (es gibt keinen zweiten Stick zum
## Zielen), und ohne Ziel passiert beim Drücken nichts. Ohne diese Rückmeldung wäre nicht
## unterscheidbar, ob der Knopf nicht reagiert oder schlicht niemand in Reichweite ist.

const RADIUS: float = 54.0        # sichtbarer Radius
const TOUCH_SLACK: float = 1.18   # Trefferfläche etwas größer — ein Daumen zielt grob
const MARGIN: float = 38.0        # Abstand zur unteren rechten Ecke

var pressed: bool = false       # Finger/Taste liegt auf
var has_target: bool = false    # Gegner in Schussreichweite


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # Treffer prüft `hits()`, nicht die GUI
	# Ränder DIREKT setzen statt über `position` — der Knopf lag sonst außerhalb des Bildes.
	#
	# Godots `position` ist die Lage relativ zur Elternecke, nicht der Abstand zum Anker. Wird
	# sie gesetzt, solange das Elternteil noch keine Größe hat (also VOR `add_child`), rechnet
	# Godot daraus einen Rand und der Anker verschiebt ihn später richtig. Wird sie danach
	# gesetzt — und `_ready` läuft nach `add_child` —, zählt der Wert absolut: aus −146 wurde
	# die Bildschirmposition −146 statt „146 px vor dem rechten Rand". Der Knopf saß dadurch
	# links oberhalb des Bildes, gemessen bei (−146, −146) in einem 1152×648-Fenster.
	#
	# Ränder sind gegen diese Reihenfolge unempfindlich: Sie sind IMMER relativ zum Anker.
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_right = -MARGIN
	offset_bottom = -MARGIN
	offset_left = -MARGIN - RADIUS * 2.0
	offset_top = -MARGIN - RADIUS * 2.0


func center() -> Vector2:
	return global_position + size * 0.5


## Kreisförmige Treffprüfung statt Rechteck: Der Knopf SIEHT rund aus, also muss er sich auch
## rund anfühlen — sonst löst die Ecke aus, in der sichtbar nichts ist.
func hits(at: Vector2) -> bool:
	return at.distance_to(center()) <= RADIUS * TOUCH_SLACK


func set_state(is_pressed: bool, target_in_range: bool) -> void:
	if is_pressed == pressed and target_in_range == has_target:
		return   # nur bei Wechsel neu zeichnen, nicht sechzigmal pro Sekunde
	pressed = is_pressed
	has_target = target_in_range
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	# Drei Zustände, klar unterscheidbar: schlafend (kein Ziel), scharf (Ziel da), gedrückt.
	var fill: Color = Color(0.55, 0.16, 0.11, 0.55)
	var rim: Color = Color(1.0, 0.72, 0.48, 0.55)
	if pressed:
		fill = Color(0.95, 0.55, 0.22, 0.80)
		rim = Color(1.0, 0.92, 0.72, 0.95)
	elif has_target:
		fill = Color(0.72, 0.24, 0.14, 0.68)
		rim = Color(1.0, 0.82, 0.55, 0.85)
	draw_circle(c, RADIUS, fill)
	draw_arc(c, RADIUS, 0.0, TAU, 48, rim, 3.0, true)
	# Fadenkreuz: liest sich auch bei 54 px noch als „schießen" und braucht keine Textur.
	var inner: float = RADIUS * 0.34
	draw_arc(c, inner, 0.0, TAU, 24, rim, 2.0, true)
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(c + d * (inner + 6.0), c + d * (RADIUS - 8.0), rim, 2.0, true)
