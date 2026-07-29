class_name FogOfWar
## Erkundete Karte — was man gesehen hat, bleibt sichtbar; der Rest ist Nebel.
##
## Warum überhaupt: Die Karte zeigt bisher alle vierzehn Orte ab dem ersten Schritt. Damit ist
## das Erkunden erzählt, bevor es angefangen hat — man liest die Karte und weiß, wo alles ist.
## Mit Nebel wird aus der Karte ein Protokoll dessen, was man wirklich getan hat, und ein
## neuer Ortsname darauf ist ein kleiner Fund.
##
## **Die Speicherform ist die eigentliche Entscheidung.** Naheliegend wäre ein Raster über die
## Karte, aber bei 2000×2000 Welteinheiten und 20 m Zellen sind das 10 000 Zellen, die in jeden
## Spielstand wandern und jedes Kartenbild einzeln abgefragt werden. Stattdessen merken wir uns
## nur die BESUCHTEN ZELLEN in einem Wörterbuch: Wer nichts erkundet hat, speichert nichts, und
## wer die halbe Karte kennt, speichert die halbe Karte. Ein Spielstand nach zwei Stunden hat
## ein paar hundert Einträge.
##
## Aufgedeckt wird großzügig — `SIGHT_UNITS` ist der Radius, den ein Schritt freilegt. 30
## Welteinheiten sind 75 m: Was man von einem Punkt aus tatsächlich überblicken würde.

## Kantenlänge einer Nebelzelle in Welteinheiten (2000 = ganze Karte). 16 Einheiten sind 40 m.
const CELL: int = 16
## Sichtweite in Welteinheiten. Großzügiger als die Zelle, damit Laufen eine Spur freilegt und
## keine Kette einzelner Punkte.
const SIGHT_UNITS: float = 30.0


static func cell_of(rel: Vector2) -> Vector2i:
	return Vector2i(int(floor(rel.x / float(CELL))), int(floor(rel.y / float(CELL))))


static func _key(c: Vector2i) -> int:
	# Ein int als Schlüssel statt eines Strings oder Vector2i: Wörterbücher mit int-Schlüsseln
	# sind schneller, und JSON kann sie im Spielstand direkt ablegen.
	return c.y * 10000 + c.x


static func is_seen(rel: Vector2) -> bool:
	return GameState.fog.has(_key(cell_of(rel)))


## Sicht um eine Position freilegen. Liefert die Anzahl NEU aufgedeckter Zellen — daran hängt,
## ob die Karte neu gezeichnet werden muss (fast immer 0, deshalb lohnt die Rückgabe).
static func reveal(rel: Vector2) -> int:
	var r: int = int(ceil(SIGHT_UNITS / float(CELL)))
	var mitte: Vector2i = cell_of(rel)
	var neu: int = 0
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var c := Vector2i(mitte.x + dx, mitte.y + dy)
			# Kreisförmig, nicht quadratisch: Ein quadratischer Sichtbereich zeichnet beim
			# Laufen eine Treppe an den Rand, und die sieht man auf der Karte.
			var m := Vector2((float(c.x) + 0.5) * float(CELL), (float(c.y) + 0.5) * float(CELL))
			if m.distance_to(rel) > SIGHT_UNITS:
				continue
			var k: int = _key(c)
			if not GameState.fog.has(k):
				GameState.fog[k] = 1
				neu += 1
	return neu


## Ist dieser Ort schon entdeckt? Orte werden aufgedeckt, wenn man in ihre Nähe kommt — nicht,
## wenn man exakt darauf steht.
static func poi_known(poi_id: String) -> bool:
	return is_seen(WorldManager.poi_position(poi_id))


## Wie viel der Karte ist bekannt (0..1)? Für die Kopfzeile der Weltkarte.
static func explored_share() -> float:
	var gesamt: int = int(pow(ceil(float(WorldManager.WORLD_SIZE) / float(CELL)), 2))
	return clampf(float(GameState.fog.size()) / maxf(float(gesamt), 1.0), 0.0, 1.0)


## Startzustand: Rustwater und seine Umgebung sind bekannt. Wer bei null anfängt, sieht eine
## völlig schwarze Karte und hält sie für kaputt.
static func fresh() -> Dictionary:
	GameState.fog = {}
	reveal(WorldManager.poi_position("rustwater"))
	return GameState.fog
