class_name AmmoData
## Munition & Energiekristalle (Master-GDD §7.1.1) — begrenzter Vorrat statt Dauerfeuer.
##
## Zwei Pools, damit der Waffenwechsel eine Entscheidung ist und nicht nur eine Farbe: Der
## Blei-Karabiner frisst Munition, die drei Energiewaffen teilen sich die knapperen Kristalle.
## Wer die starke Waffe leerschießt, muss auf den Karabiner zurück.
##
## Zahlen 1:1 aus GDD §7.1.1 und dem durchgespielten Prototyp. Bei 5 Schuss/s reicht ein voller
## Munitionsvorrat für rund 36 Sekunden Dauerfeuer — im Gefecht netto-positiv durch Drops.

const POOLS: Dictionary = {
	"muni":     { "name": "Munition", "icon": "🧨", "cap": 180, "start": 90, "drop": [3, 6], "color": Color(0.98, 0.75, 0.14) },
	"kristall": { "name": "Energiekristalle", "icon": "🔷", "cap": 120, "start": 45, "drop": [3, 5], "color": Color(0.22, 0.74, 0.97) },
}
const ORDER: Array = ["muni", "kristall"]


## Welcher Pool speist diese Waffe?
##
## Entschieden wird an der SCHADENSART, nicht am Namen: Was Blei verschießt (KINETIC), zieht
## Munition, alles andere Kristalle. Vorher stand hier `weapon_id == "karabiner"` — das ging
## gut, solange der Karabiner die einzige kinetische Waffe war, und wurde in dem Moment falsch,
## in dem die Gatling dazukam: Eine Kurbelkanone mit Messingläufen bekam Energiekristalle.
static func pool_for(weapon_id: String) -> String:
	return "muni" if String(CombatData.WEAPONS[weapon_id]["type"]) == CombatData.KINETIC else "kristall"


static func cap(pool: String) -> int:
	return int(POOLS[pool]["cap"])


static func amount(pool: String) -> int:
	return int(GameState.ammo.get(pool, 0))


static func is_empty(weapon_id: String) -> bool:
	return amount(pool_for(weapon_id)) <= 0


## Legt Nachschub an, gedeckelt auf die Kapazität. Liefert, wie viel WIRKLICH ankam — der Rest
## wäre sonst still verschwunden, und der Aufrufer könnte keine ehrliche Meldung anzeigen.
static func add(pool: String, count: int) -> int:
	if not POOLS.has(pool) or count <= 0:
		return 0
	var before: int = amount(pool)
	var after: int = mini(before + count, cap(pool))
	GameState.ammo[pool] = after
	return after - before


## Einen Schuss abbuchen. `false` = leer, es darf nicht gefeuert werden.
static func consume(weapon_id: String) -> bool:
	var pool: String = pool_for(weapon_id)
	var have: int = amount(pool)
	if have <= 0:
		return false
	GameState.ammo[pool] = have - 1
	return true


## Zufällige Drop-Menge für einen Kill (Bandbreite je Pool aus dem GDD).
static func roll_drop(pool: String, rng: RandomNumberGenerator = null) -> int:
	var span: Array = POOLS[pool]["drop"]
	if rng == null:
		return randi_range(int(span[0]), int(span[1]))
	return rng.randi_range(int(span[0]), int(span[1]))


## Startvorrat für ein neues Spiel.
static func fresh() -> Dictionary:
	var out: Dictionary = {}
	for id in ORDER:
		out[id] = int(POOLS[id]["start"])
	return out
