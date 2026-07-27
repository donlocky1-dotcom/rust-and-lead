class_name VirtualStick extends Control
## VirtualStick — sichtbare Rückmeldung für den dynamischen Joystick (Master-GDD §1.5).
##
## Zeichnet nur; die Eingabe selbst wertet `OverworldView` aus (Finger ODER Maus, dieselbe
## Logik). Ohne diese Anzeige steuert man blind: man sieht weder, wo der Stick aufgesetzt hat,
## noch wie weit man ausgelenkt ist — auf dem Handy ist der Daumen zwar drauf, am Rechner
## fehlt jeder Anhaltspunkt.
##
## Bewusst ein eigenes Skript (wie `Minimap`): hält `OverworldView` schlank und lässt sich
## später in jeder anderen Szene wiederverwenden.

const RING_COLOR: Color = Color(1.0, 0.96, 0.88, 0.30)
const KNOB_COLOR: Color = Color(1.0, 0.94, 0.78, 0.72)

var active: bool = false
var origin: Vector2 = Vector2.ZERO   # Aufsetzpunkt (Mitte des Rings)
var knob: Vector2 = Vector2.ZERO     # aktuelle Position des Griffs
var radius: float = 96.0             # Vollausschlag in Pixeln


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # schluckt keine Eingaben
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	if not active:
		return
	draw_arc(origin, radius, 0.0, TAU, 48, RING_COLOR, 3.0, true)
	draw_arc(origin, radius * 0.24, 0.0, TAU, 24, RING_COLOR, 2.0, true)
	# Linie vom Aufsetzpunkt zum Griff: macht Richtung und Stärke auf einen Blick lesbar.
	draw_line(origin, knob, KNOB_COLOR, 2.0, true)
	draw_circle(knob, 22.0, KNOB_COLOR)
	draw_arc(knob, 22.0, 0.0, TAU, 24, Color(0.15, 0.12, 0.10, 0.85), 2.0, true)
