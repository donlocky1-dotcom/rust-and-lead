@tool
extends StaticBody3D
## Ein Boden zum Fallenlassen — **nur im Editor**.
##
## Godots „Objekt auf Boden fallen lassen" (Taste `Bild ab` im 3D-Fenster) wirft einen Strahl
## nach unten und braucht dafür einen KÖRPER, gegen den er trifft. Unser Gelände ist aber eine
## Formel (`WorldManager.height_at`) und entsteht erst beim Spielstart; im Editor liegt dort
## nichts. Genau deshalb meldet Godot „kein Boden definiert".
##
## Dieser Knoten baut den Geländeabschnitt im Editor als Netz mit Kollision nach — dieselbe
## Formel, dieselben Höhen. Was man darauf fallen lässt, liegt auch im Spiel richtig.
##
## **Im Spiel löscht er sich selbst.** Dort baut `OverworldView` das Gelände ohnehin, und zwei
## Böden übereinander streiten um jedes Pixel. Deshalb ist er ein GESCHWISTER der abgelegten
## Teile und nicht ihr Elternknoten — sonst nähme er sie beim Verschwinden mit.
##
## Die Teile liegen in WELTkoordinaten, nicht relativ zum Krater: Der Boden wird aus derselben
## Formel gebaut, die das Spiel benutzt, und jede Verschiebung dazwischen wäre eine zweite
## Wahrheit über die Lage der Grube.

## Welche Geländeform nachgebaut wird (`WorldManager.TERRAIN`).
@export var feature_id: String = "schrotthalde":
	set(v):
		feature_id = v
		_neu_bauen()

## Wie weit über den Kraterrand hinaus. Ohne Zuschlag endet der Boden genau an der Kante, und
## was man dort ablegt, fällt ins Nichts.
@export var rand_m: float = 10.0:
	set(v):
		rand_m = maxf(v, 0.0)
		_neu_bauen()

## Maschenweite. Feiner als das Spielgelände wäre sinnlos (das rechnet mit 0,35 m), gröber als
## ein Meter lässt Teile in der Kraterwand schweben.
@export var schrittweite_m: float = 0.5:
	set(v):
		schrittweite_m = clampf(v, 0.2, 2.0)
		_neu_bauen()

## Sichtbar oder nur als Kollision. Sichtbar hilft beim Zielen, verdeckt aber das echte Gelände
## in der Vorschau — deshalb umschaltbar.
@export var sichtbar: bool = true:
	set(v):
		sichtbar = v
		var mi: MeshInstance3D = get_node_or_null("Netz") as MeshInstance3D
		if mi != null:
			mi.visible = v

## Neu bauen, ohne etwas zu ändern (Knopf im Inspektor).
@export var neu_bauen: bool = false:
	set(_v):
		neu_bauen = false
		_neu_bauen()


func _ready() -> void:
	if not Engine.is_editor_hint():
		# Im Spiel gibt es das echte Gelände. Dieser Knoten hat dort nichts verloren.
		queue_free()
		return
	_neu_bauen()


func _neu_bauen() -> void:
	if not is_node_ready():
		return    # Setter feuern beim Laden, bevor es einen Baum gibt
	for alt in get_children():
		alt.queue_free()
	var f: Dictionary = _feature()
	if f.is_empty():
		push_warning("PitFloor: keine Gelaendeform namens '%s'" % feature_id)
		return
	var c: Vector3 = WorldManager.feature_center(f)
	var r: float = float(f.get("radius", 20.0)) * (1.0 + float(f.get("rim_width", 0.0))) + rand_m
	var n: int = maxi(int(ceil(r * 2.0 / schrittweite_m)), 2)
	var schritt: float = r * 2.0 / float(n)

	var ecken := PackedVector3Array()
	ecken.resize((n + 1) * (n + 1))
	for iz in n + 1:
		for ix in n + 1:
			var lx: float = -r + float(ix) * schritt
			var lz: float = -r + float(iz) * schritt
			# Gemessen wird in der WELT, abgelegt wird LOKAL — so bleibt die Hoehe exakt und
			# die Szene trotzdem am Ursprung.
			ecken[iz * (n + 1) + ix] = Vector3(lx,
				WorldManager.height_at(c.x + lx, c.z + lz), lz)

	var flaechen := PackedVector3Array()
	flaechen.resize(n * n * 6)
	var k: int = 0
	for iz in n:
		for ix in n:
			var a: Vector3 = ecken[iz * (n + 1) + ix]
			var b: Vector3 = ecken[iz * (n + 1) + ix + 1]
			var cc: Vector3 = ecken[(iz + 1) * (n + 1) + ix]
			var d: Vector3 = ecken[(iz + 1) * (n + 1) + ix + 1]
			# Wicklung so, dass die Vorderseite nach OBEN zeigt: Bei einem vorderseitigen
			# Dreieck zeigt `cross(v1−v0, v2−v0)` in Godot ENTGEGEN der Schattierungsnormale.
			flaechen[k] = a; flaechen[k + 1] = cc; flaechen[k + 2] = b
			flaechen[k + 3] = b; flaechen[k + 4] = cc; flaechen[k + 5] = d
			k += 6

	var netz := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = flaechen
	netz.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.name = "Netz"
	mi.mesh = netz
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.45, 0.32, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	mi.visible = sichtbar
	add_child(mi)

	var form := ConcavePolygonShape3D.new()
	form.set_faces(flaechen)
	var cs := CollisionShape3D.new()
	cs.name = "Kollision"
	cs.shape = form
	add_child(cs)


func _feature() -> Dictionary:
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == feature_id:
			return f
	return {}
