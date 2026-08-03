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

# ── Kampf-Reichweiten: am SICHTBAREN Ausschnitt bemessen ─────────────────────
# Die Kamera zeigt bei 9,5 m Abstand und 50° Sichtfeld rund 15 m Breite und 13 m Tiefe um die
# Figur. Die alten Werte (32 m Schussweite, Spawn ab 140 m) stammen von einer viel weiter
# entfernten Kamera: der Spieler hat Gegner erledigt, die nie im Bild waren. Alles hier liegt
# jetzt INNERHALB des Ausschnitts — man sieht, worauf man schießt.
const AGGRO_M: float = 16.0          # Gegner erwachen, sobald sie im Bild sind
const SHOOT_RANGE_M: float = 11.0    # Auto-Ziel-Reichweite: gut sichtbar, nicht am Bildrand
const CONTACT_RANGE_M: float = 2.2   # Nahkampf-Kontakt
const ENEMY_SPEED_MS: float = 3.4    # Referenztempo (CombatData `speed` 100); Typen skalieren daran
## Ersatzbewegung für Modelle ohne Lauf-Animation (siehe `_scurry`).
const SCURRY_HZ: float = 9.0
const SCURRY_HOP: float = 0.09       # Anteil der Modellhöhe
const SCURRY_ROLL_RAD: float = 0.09
## Spawn liegt neben, nicht auf der Rustwater-Landmarken-Säule (die am exakten POI-Punkt steht).
const RUSTWATER_SPAWN_OFFSET: Vector3 = Vector3(0.0, 0.0, 25.0)   # 25 m südlich der Säule

# ── Kontinuierliches Spawning (echter Biom-Gegnermix aus WorldManager) ────────
const ENEMY_MAX: int = 12
const SPAWN_INTERVAL_SEC: float = 4.0
## Knapp außerhalb des Bildes bis kurze Laufdistanz — nah genug, dass Nachschub ankommt,
## solange man noch da ist, und weit genug, dass niemand vor der Nase aus dem Nichts auftaucht.
const SPAWN_MIN_DIST: float = 18.0
const SPAWN_MAX_DIST: float = 45.0
## Schwarm-Gegner (CombatData `"swarm": true` — Ölfresser-Ratten, Kessel-Kläffer) erscheinen
## als Rudel. Einzeln sind sie mit 32 Lebenspunkten weder gefährlich noch ein Bild.
const SWARM_MIN: int = 4
const SWARM_MAX: int = 7
const SWARM_SPREAD_M: float = 4.5

# ── Waffen (alle vier Schadensarten testbar — Kapitel-Gating folgt später über
# das Quest-/Reveal-System; dieser Sandbox-Screen ist bewusst ungesperrt). ────
const WEAPON_ORDER: Array = ["karabiner", "gatling", "voltgun", "saeure", "brenner"]
const WEAPON_ICON: Dictionary = { "karabiner": "🔫", "gatling": "🌀", "voltgun": "⚡",
	"saeure": "🧪", "brenner": "🔥" }
const TRACER_COLOR: Dictionary = {
	"karabiner": Color(0.98, 0.75, 0.14), "gatling": Color(0.95, 0.86, 0.55),
	"voltgun": Color(0.35, 0.75, 0.98),
	"saeure": Color(0.55, 0.85, 0.25), "brenner": Color(0.95, 0.42, 0.15),
}

# ── Truhen & Bodenbeute (Diablo-Achse) ────────────────────────────────────────
## Truhen sind SELTEN und stehen fest — nicht mehr alle 15 Sekunden eine im Umkreis von 220 m.
## Vorher waren sie damit ein Fließband: Man lief nirgendwo hin, sie kamen zu einem. Jetzt
## liegt genau eine am Mittelpunkt jedes Ortes außer dem Heimathafen — das Ziel eines
## Questlaufs ist damit auch das Ziel der Beute.
const CHEST_INTERACT_M: float = 3.0    # Reichweite für das Hand-Symbol
const CHEST_RESPAWN_SEC: float = 300.0 # geplünderte Truhe füllt sich nach 5 Spielminuten
const CHEST_RARITY_BIAS: float = 0.3   # etwas höher als Basis-Gegner-Loot -> Truhen lohnen sich
const CHEST_GEAR_MIN: int = 1
const CHEST_GEAR_MAX: int = 3

## Beim Öffnen fällt der Inhalt auf den Boden, statt still in die Taschen zu wandern. Der
## Streuradius ist bewusst klein: Man soll die Beute als HAUFEN sehen, nicht als Suchspiel.
const LOOT_SCATTER_M: float = 1.7
## Gold, Munition und Tränke sammeln sich beim Darüberlaufen auf — nur Ausrüstung will eine
## Entscheidung. Die Grundreichweite wächst mit der Magnet-Spule (`PlayerStats.magnet_dist`,
## Prototyp-Einheiten: 130 = Grundwert, +45 je Ausbaustufe).
const PICKUP_AUTO_BASE_M: float = 1.9
const PICKUP_HAND_M: float = 2.6       # Ausrüstung: Reichweite für das Hand-Symbol
## Farbe der Bodenbeschriftung = Seltenheit (GDD §7.4). Grau/Blau/Violett/Gold.
const RARITY_COLOR: Dictionary = {
	"common": Color(0.80, 0.80, 0.78), "rare": Color(0.36, 0.62, 1.0),
	"epic": Color(0.74, 0.44, 0.96), "legendary": Color(1.0, 0.78, 0.26),
}

# ── Persistenz (SaveManager, seit Phase 2 fertig — hier zum ersten Mal an eine Szene
# angeschlossen): Slot 0 als laufender Spielstand dieser Sandbox. ──────────────
const SAVE_SLOT: int = 0
const AUTOSAVE_INTERVAL_SEC: float = 10.0

## Rustwater ist Schutzzone: innerhalb dieses Radius spawnt nichts Feindliches und es
## wird kein Dekor gestreut — die Stadt bleibt Stadt (GDD §1.6: befriedete Hubs).
## Befriedeter Umkreis: knapp außerhalb der Palisade (52 m) plus Bahnsteig-Vorfeld.
const TOWN_SAFE_M: float = 78.0
## Panzer-Rotte vor dem Tor beim Spielstart (der kontinuierliche Nachschub würfelt sie danach
## aus dem Biom-Mix — in der Wüste rund jeder zehnte Gegner, WorldManager.ENEMY_POOLS).
const STARTER_TANKS: int = 3

## Reiseziele (Tasten 1–5) sind exakt die Bahnhöfe — eine Liste, keine zweite Wahrheit.
const FAST_TRAVEL: Array = WorldManager.RAIL_STATIONS

const UiAssets = preload("res://scripts/UiAssets.gd")

const DialogBox = preload("res://scripts/DialogBox.gd")

const TownCollision = preload("res://scripts/TownCollision.gd")

# ── NPCs & Quests: der QuestManager ist seit Phase 2 fertig, hier zum ersten Mal
# an die sichtbare Welt angeschlossen. Auftraggeber stehen bei ihren Gebäuden. ──
const NPC_INTERACT_M: float = 4.5
## giver-Id (QuestManager.QUESTS[..].giver) → Anzeigename, Standort (Versatz vom Zentrum), Farbe.
## Jeder steht **vor seinem Haus** an der Straßenkante — Mabel vor dem Saloon, Silas vor der
## Schmiede, Doc vor dem Labor. Vorher standen sie auf einem eigenen Kreis irgendwo im Sand.
const TOWN_NPCS: Array = [
	["mabel", "Mamma „Rusty“ Mabel", Vector2(-5.0, 3.0), Color(0.85, 0.45, 0.35)],
	["silas", "Silas „Kupferauge“ Finch", Vector2(5.0, 3.0), Color(0.55, 0.50, 0.40)],
	["doc", "Doktor „Doc“ Aris", Vector2(5.5, 15.0), Color(0.88, 0.88, 0.90)],
]
## Material-Drops beim Kill — ohne sie ist die Sammel-Quest „Baumaterial: Schrott" unlösbar.
const DROP_TABLE: Array = [["schrott", 0.65], ["zahnrad", 0.22], ["dampfkern", 0.05]]

# ── Kamera (an Diablo-Immortal-Referenz eingemessen, GDD §1.5a) ───────────────
const CAM_FOV: float = 50.0     # eng statt Godots 75° — sonst wirkt die Figur winzig
## Abstand zur Figur. Sichtbare Höhe = 2·Abstand·tan(FOV/2) = 0,93·Abstand; bei 9,5 m sieht man
## also ~8,9 m, die 1,8-m-Figur füllt damit rund 20 % der Bildhöhe. Der frühere Wert (14 m)
## traf zwar die gemessenen 14 % der Vorlage, war am Bildschirm aber zu weit weg, um etwas
## zu erkennen — Spielbarkeit schlägt Messwert.
const CAM_DIST: float = 9.5     # Vorgabe; zur Laufzeit ueber CAM_ZOOM_STEPS verstellbar
const CAM_PITCH: float = 52.0   # Neigung nach unten (etwas flacher -> mehr von der Figur)
const CAM_YAW: float = 20.0     # leichte Gierung -> isometrischer Eindruck statt Frontalsicht

## Zoomstufen (Abstand Kamera→Figur in Metern) — BEWUSST von Hand statt automatisch.
##
## Automatisches Zoomen nimmt dem Spieler die Entscheidung ab und wechselt zuverlaessig im
## falschen Moment: beim Betreten der Stadt mitten im Gefecht, oder im Sekundentakt, wenn man
## am Ortsrand hin und her laeuft. In der Stadt und im Dungeon will man nah heran, fuer lange
## Wuestenwege weit heraus — das weiss nur, wer gerade spielt.
##
## Gemessen an der Bildhoehe (Sichthoehe = 2·Abstand·tan(FOV/2)) ist die Figur:
##   7,5 m -> 25,7 %   9,5 m -> 20,3 %   12,5 m -> 15,4 %   16,0 m -> 12,1 %
## Die Diablo-Vorlagen liegen bei 12–15 %; die weiteste Stufe trifft sie also genau, waehrend
## die Vorgabe naeher bleibt, weil auf dem Handy sonst nichts mehr zu erkennen ist. Weiter als
## 16 m lohnt nicht — bei 20 m waere die Figur 9,7 % hoch und damit nur noch ein Fleck.
const CAM_ZOOM_STEPS: Array = [7.5, 9.5, 12.5, 16.0]
const CAM_ZOOM_NAMES: Array = ["Nah", "Normal", "Weit", "Fern"]
const CAM_ZOOM_DEFAULT: int = 1
## Wie schnell der Zoom nachzieht (1/s). Springt er hart, verliert man die Orientierung.
const CAM_ZOOM_RATE: float = 6.0
## Fingerspreizung je Zoomstufe beim Kneifen.
const PINCH_PX_PER_STEP: float = 90.0
## Reichweite der Schattenkaskaden in Metern. Als Konstante, weil sie mit dem Zoom
## zusammenhaengt: Beim weitesten Zoom liegt die hintere Bildkante 27,8 m vom Objektiv — passt
## der Zoom kuenftig weiter heraus, muss dieser Wert mit. Ein Test rechnet das nach.
const CAM_SHADOW_M: float = 60.0

## Versatz Kamera→Spieler beim gegebenen Abstand. Die Kamera behaelt ihre Ausrichtung IMMER —
## sie folgt nur der Position. Blickrichtung, Neigung und Gierung sind Weltkonstanten, kein
## Zustand der Figur. Frueher war das eine Konstante; seit der Abstand verstellbar ist, muss
## sie gerechnet werden.
func _cam_offset(dist: float) -> Vector3:
	return Vector3(
		sin(deg_to_rad(CAM_YAW)) * dist * cos(deg_to_rad(CAM_PITCH)),
		dist * sin(deg_to_rad(CAM_PITCH)),
		cos(deg_to_rad(CAM_YAW)) * dist * cos(deg_to_rad(CAM_PITCH)))

const CAM_FOLLOW: float = 10.0

# ── Virtueller Joystick (Finger und Maus, GDD §1.5) ───────────────────────────
const STICK_RADIUS: float = 96.0     # Pixel bis Vollausschlag
const STICK_DEADZONE: float = 10.0   # darunter passiert nichts (Zittern/Klick)
const MOUSE_STICK_ID: int = 9001     # eigene „Finger"-Id für die Maus (kollidiert mit keiner echten)
const TURN_RATE: float = 12.0        # wie schnell die Figur in die neue Richtung eindreht

# ── Waffe in der Hand ─────────────────────────────────────────────────────────
## Knochen des Spieler-Rigs, an dem die Waffe hängt.
const WEAPON_BONE: String = "RightHand"
## Sitz im Griff — in Modell-Metern relativ zur Hand. Diese drei Zahlen kann man nicht
## ausrechnen, nur ansehen: sie sind der Stellknopf, wenn die Waffe schief in der Faust liegt.
const WEAPON_GRIP_OFFSET: Vector3 = Vector3(0.0, 0.02, 0.0)
const WEAPON_GRIP_ROT: Vector3 = Vector3(0.0, 0.0, 0.0)   # Radiant (X, Y, Z)

# ── Bauliche Begrenzung (GDD §1.4a) ───────────────────────────────────────────
## Die Wüste ist offen, die Aktionszonen sind eng — und zwar durch ECHTE Bauten, nicht
## durch unsichtbare Wände: jedes Haus, jeder Palisadenpfosten, jedes Turmbein trägt sich
## beim Bauen selbst als Sperre ein (`_solid_box` / `_solid_pillar`). Was man sieht, blockt.
const PLAYER_RADIUS_M: float = 0.6
## Breite der Meldungszeile. Fest, damit sie mittig bleibt und nicht aus dem Bild waechst.
const TOAST_W: float = 720.0
## Aufloesung des Gelaendenetzes. Verfeinert von 0,5 auf 0,35 m, als aus der Schuessel eine
## Grube mit 66°-Waenden wurde: Bei 0,5 m Schrittweite steigt eine solche Wand je Viereck um
## 1,1 m — sichtbar treppig. Mit 0,35 m sind es 0,79 m, und die Kanten lesen sich als
## ausgewaschene Erde statt als Stufen. Kostet fuer die Schrotthalde (20 m Aussenradius)
## rund 33 000 Dreiecke; das ist der Preis fuer die einzige Gelaendeform im Spiel.
const TERRAIN_STEP_M: float = 0.35
## Zuschlag um jede Gelaendeform, damit der Flicken sicher auf y = 0 ausklingt, bevor die
## flache Restflaeche anschliesst.
const TERRAIN_MARGIN_M: float = 2.0
## Ausdehnung von Rustwater. Frueher war das der Palisadenradius, aus dem der Code die Mauer
## als Kreis gebaut hat — die Palisade wird inzwischen von Hand in `Rustwater.tscn` gestellt
## (siehe `_register_town`), und ein Kreis ist ohnehin nicht die einzige denkbare Form.
##
## Der Wert steuert jetzt nur noch, was NICHT von Hand gesetzt wird: die Groesse des Stadtbodens
## und die Frage, wo Pisten und Bahntrasse am Ortsrand enden. 84 m waren viel zu weit —
## Rustwater war ein Ring aus Einzelhaeusern mit zwanzig Metern Sand dazwischen, in dem man
## Schmiede und Wasserturm schlicht nicht fand. 52 m umschliessen den Stadtplan knapp.
const TOWN_R: float = 52.0

# ── Stadtplan Rustwater ───────────────────────────────────────────────────────
## Eine Hauptstraße von Süden (Tor bei 90°) nach Norden zum Platz, Kernbauten links und rechts
## davon, Hütten in Reihen dahinter, der Wasserturm am Kopfende als Blickfang. Alle Werte sind
## Versätze vom Stadtzentrum in Metern: **+x Ost, +z Süd**.
##
## Blickrichtung in Grad: **alle Fassaden zeigen zur Kamera**, nicht zur Straße. Das ist die
## Regel für eine feste Kamera und der Grund, warum isometrische Spiele „gestellt" wirken: Die
## Kamera steht immer 20° südöstlich (CAM_YAW), also sieht man von jedem Haus dieselbe Seite.
## Vorher schauten die Häuser einander an — die Schmiede stand damit 110° von der Kamera weg
## und zeigte zwangsläufig ihre Rückseite. Kleine Abweichungen je Haus, damit es nicht wie
## aufgereiht wirkt.
## Die Straße bleibt zwischen x = −6 und x = +6 frei, das sind zwölf Meter: eng genug, dass
## immer beide Seiten im Bild sind, breit genug für Kampf und Ausweichen.
const STREET_HALF_W: float = 6.0
## [Beschriftung, Registry-Name ("" = nur Platzhalter), Versatz, Blickrichtung, Ersatzmaße, Farbe]
const TOWN_LAYOUT: Array = [
	["🍺 Gatling-Saloon", "saloon", Vector2(-13.5, 1.0), 14.0,
		Vector3(13.0, 8.5, 11.0), Color(0.45, 0.28, 0.16)],
	["🔨 Eiserne Schmiede", "forge", Vector2(13.5, 1.0), 28.0,
		Vector3(10.0, 7.0, 9.0), Color(0.36, 0.30, 0.27)],
	["🥃 Destille", "", Vector2(-14.0, 17.0), 16.0,
		Vector3(11.0, 6.5, 9.0), Color(0.40, 0.34, 0.20)],
	["⚗ Alchemie-Labor", "", Vector2(14.0, 17.0), 25.0,
		Vector3(12.0, 6.0, 10.0), Color(0.30, 0.36, 0.31)],
	["", "water_tower", Vector2(-14.0, -18.0), 180.0,
		Vector3(9.0, 18.0, 9.0), Color(0.48, 0.38, 0.26)],
]
## Der Turm steht NEBEN dem Kopfende der Straße, nicht darauf: mit 9,4 m Breite würde er die
## zwölf Meter Gasse dichtmachen. Bei 18 m Höhe sieht man ihn von überall, auch von der Seite.
const TOWER_SPOT: Vector2 = Vector2(-14.0, -18.0)
## Hüttenplätze: zwei Reihen an der Straße, zwei Zeilen hinter den Kernbauten.
## Die editierbare Stadt-Szene. Liegt sie vor, wird sie geladen statt gebaut.
const TOWN_SCENE: String = "res://scenes/Rustwater.tscn"
## Radius des festen Stadtbodens — sieben Meter groesser als die Stadt selbst, damit eine
## Palisade auf dem Platz steht und nicht auf der Kante zwischen zwei Böden. Der Zuschlag ist
## genau dafür da: Wer die Mauer weiter aussen setzt, sollte diesen Wert mitziehen.
const TOWN_GROUND_R: float = TOWN_R + 7.0
const SHACK_SPOTS: Array = [
	Vector2(-11.0, 28.0), Vector2(11.0, 28.0),
	Vector2(-11.0, 36.0), Vector2(11.0, 36.0),
	Vector2(-11.0, 44.0), Vector2(11.0, 44.0),
	Vector2(-26.0, 8.0), Vector2(26.0, 8.0),
	Vector2(-26.0, -8.0), Vector2(26.0, -8.0),
]
## Gebäude-Kollision etwas kleiner als die Bounding-Box: Vordächer, Schornsteine und Anbauten
## stecken darin, und man soll am Haus entlanglaufen können, nicht an dessen Luftraum.
const BUILDING_COLLISION_SHRINK: float = TownCollision.GEBAEUDE_SCHRUMPF
## Notfall-Regel für Bauteile ohne feststellbaren Asset-Namen (rohe Meshes): Ab diesem
## Seitenverhältnis der Grundfläche gilt eines als WAND und wird nicht geschrumpft. Gemessen
## liegen die Häuser bei 1,01–1,56:1 und die Mauerstücke bei 2,13–16,22:1 — die Grenze sitzt
## genau in dieser Lücke. Der Regelfall läuft über `AssetRegistry.is_wall`.
const WALL_ASPECT: float = TownCollision.WAND_VERHAELTNIS

# ── Eisenbahn (GDD §1.4a): Schnellreise nur noch von Bahnhof zu Bahnhof ───────
const RAIL_GAUGE_M: float = 3.2        # Spurweite der Iron Rail (Breitspur, Panzerzug-tauglich)
const STATION_RANGE_M: float = 45.0    # so nah muss man am Bahnsteig stehen, um zu fahren
## Abstand des Bahnsteigs vom Ortsmittelpunkt — außerhalb von Rustwaters Palisade (52 m).
const STATION_OFFSET_M: float = 68.0
## Länge der Bahnsteighalle. Steht hier statt in `AssetRegistry`, weil daraus auch die
## Sperrfläche und der Abstand zum Gleis folgen — eine Zahl, drei Nutzer.
const STATION_LEN_M: float = 20.0
## Anteil der Gebäudetiefe, der SPERRT. Der Rest ist Bahnsteig unter dem Vordach: Dort steht
## man beim Einsteigen, dort erscheint die Fahrplan-Abfrage. Gemessen am Modell endet die
## Rückwand bei 67 % der Tiefe, davor liegt nur noch das Dach auf Stützen.
const STATION_SOLID_SHARE: float = 0.67

func _in_town(pos: Vector3) -> bool:
	return pos.distance_to(WorldManager.poi_scene_position("rustwater")) < TOWN_SAFE_M

var _player: Node3D
var _cam: Camera3D
var _hp: float = 100.0
var _fire_cd: float = 0.0
var _spawn_cd: float = SPAWN_INTERVAL_SEC * 0.5   # erster Nachschub etwas früher
var _weapon_id: String = "karabiner"
var _enemies: Array = []             # { node, target: CombatTarget, bar: MeshInstance3D }
var _chests: Array = []              # { node, label, pos: Vector3, looted: bool, cd: float }
## Beute am Boden: { node, label, kind, data, pos }. `kind` ist "gold" | "ammo" | "potion"
## | "material" | "gear" — die ersten vier sammeln sich von selbst auf, Ausrüstung nicht.
var _ground: Array = []
var _shimmer: float = 0.0            # Phase des Schimmerns am nächstgelegenen Fundstück
var _dry_cd: float = 0.0             # Drossel für den "kein Nachschub"-Hinweis
var _reload_left: float = 0.0        # Restdauer des laufenden Nachladens (0 = feuerbereit)
var _reload_total: float = 0.0       # Gesamtdauer, für die Fortschrittsanzeige
var _ground_tile_m: float = 2.5      # Kantenlaenge einer Bodentextur-Kachel (gemessen)
var _ammo_lbl: Label                 # Vorrat der getragenen Waffe, unter dem Schuss-Knopf
var _cam_dist: float = CAM_DIST      # aktueller Abstand, weich nachgezogen
var _zoom_btns: HBoxContainer        # ＋/－ unter der Minikarte
var _hud_buttons: Array = []         # echte Knoepfe im HUD — duerfen den Joystick nicht ausloesen
var _touch_pos: Dictionary = {}      # Finger-Index -> Position (fuer das Kneifen)
var _pinch_a: int = -1               # die beiden Finger einer Kneifgeste
var _pinch_b: int = -1
var _pinch_ref: float = 0.0          # Fingerabstand beim Aufsetzen
var _pinch_zoom0: int = 0            # Zoomstufe beim Aufsetzen
var _zone_lbl: Label                 # Ortsschrift beim Betreten
var _zone_shown: String = ""         # welcher Ort zuletzt angesagt wurde
var _zone_t: float = 0.0             # Restzeit der Einblendung
var _npcs: Array = []                # { giver, name, node, label, pos: Vector3 }
var _actions: VBoxContainer          # Aktionsleiste unten (Sprechen, Bahnreise)
var _ctx: String = ""                # was gerade in Reichweite ist ("npc:silas", "station:…")
var _chest_spawn_cd: float = 3.0      # erste Truhe erscheint schnell
var _hud: Label
var _fire_btn: FireButton        # Schuss-Knopf unten rechts
# Der Abzug hat drei Quellen, die sich nicht gegenseitig ausschliessen duerfen: Auf dem Handy
# liegt EIN Finger auf dem Joystick und ein ZWEITER auf dem Knopf, am Rechner haelt man die
# Leertaste und zieht gleichzeitig mit der Maus. Deshalb je ein eigener Zustand statt eines
# gemeinsamen Flags — sonst loescht das Loslassen der einen Quelle die andere mit.
var _fire_key: bool = false      # Leertaste
var _fire_mouse: bool = false    # rechte Maustaste (links ist der Joystick)
var _fire_touch_id: int = -1     # Finger auf dem Knopf (-1 = keiner)
var _minimap: Minimap            # Nahansicht oben rechts (200-m-Umkreis)
var _world_map: Minimap          # dieselbe Klasse im Vollbild-Modus
var _map_overlay: Control        # Abdunklung + Weltkarte; unsichtbar, solange sie zu ist
var _shop: ShopScreen            # Werkstatt/Geschäfte; unsichtbar, solange zu
var _char: CharacterScreen       # Ausrüstung + Fähigkeiten
var _char_btn: Button            # ruft ihn auf (auf dem Handy der einzige Weg dorthin)
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
var _rot_blockers: Array = []        # gedrehte Sperren:    { c: Vector2(x,z), h: Vector2, yaw }
var _stations: Array = []            # { id, pos: Vector3 } — Bahnsteige der Iron Rail
var _player_model: Node3D = null     # nur gesetzt, wenn ein echtes Modell geladen wurde
var _weapon_model: Node3D = null     # Waffe in der Hand (optional)


func _ready() -> void:
	_load_or_init_save()   # vor allem Weiteren: GameState (Level/Gold/Ausrüstung) korrekt setzen
	_build_environment()
	_build_ground_and_biomes()
	_build_sector_lines_and_rim()
	_build_swamp()
	_build_railway()
	_build_pois()
	_build_township()
	_scatter_decor()
	_scatter_props()
	_fill_craters()
	_build_player()
	_build_hud()
	_build_npcs()
	_build_trail()
	_spawn_pack()
	_build_chests()
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
	else:
		# Neues Spiel: Rustwater und Umgebung sind bekannt. Eine vollstaendig schwarze Karte
		# beim ersten Start haelt man fuer kaputt, nicht fuer eine Aufgabe.
		FogOfWar.fresh()


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


## Gedrehte Sperre: dieselbe Rechteck-Sperre, aber um `yaw` gedreht. Gebäude stehen im Kreis
## um das Stadtzentrum und schauen nach innen — eine achsenparallele Box würde dabei entweder
## in die Gasse ragen oder die Ecke des Hauses frei lassen.
func _solid_rect_rot(center: Vector3, half: Vector2, yaw: float) -> void:
	_rot_blockers.append({
		"c": Vector2(center.x, center.z), "yaw": yaw,
		"h": half + Vector2(PLAYER_RADIUS_M, PLAYER_RADIUS_M) })


## Runde Sperre (Säulen, Türme, Silos) — Radius inklusive Spielerradius.
func _solid_pillar(center: Vector3, radius: float) -> void:
	_pillars.append({ "c": Vector2(center.x, center.z), "r": radius + PLAYER_RADIUS_M })


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
	for r in _rot_blockers:
		var local: Vector2 = (q - Vector2(r["c"])).rotated(-float(r["yaw"])).abs()
		if local.x <= float(r["h"].x) and local.y <= float(r["h"].y):
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
	# UVs kommen jetzt in KACHEL-EINHEITEN direkt aus der Weltposition (siehe `_add_ground_quad`),
	# nicht mehr aus dem 0..1-Bereich einer Plane. Nur so passen Flicken und Restflaeche
	# nahtlos aneinander — sonst haette jedes Teilstueck seine eigene Kachelphase.
	_ground_tile_m = maxf(tile_m, 0.1)
	mat.uv1_scale = Vector3.ONE
	return mat


## Restflaechen des Bodens: die Weltflaeche minus der Bereiche, in denen Gelaende liegt.
## Rechteck-Subtraktion — je Form zerfaellt ein Rechteck in bis zu vier neue.
func _ground_rects() -> Array:
	var w: float = WorldManager.WORLD_METERS
	var rects: Array = [Rect2(Vector2(0.0, -w), Vector2(w, w))]
	for f in WorldManager.TERRAIN:
		var c: Vector3 = WorldManager.feature_center(f)
		var reach: float = WorldManager.feature_reach(f) + TERRAIN_MARGIN_M
		var hole := Rect2(Vector2(c.x - reach, c.z - reach), Vector2(reach * 2.0, reach * 2.0))
		var next: Array = []
		for r in rects:
			next.append_array(_subtract_rect(r, hole))
		rects = next
	return rects


## `a` minus `b` als Liste von Rechtecken (0 bis 4 Stueck).
func _subtract_rect(a: Rect2, b: Rect2) -> Array:
	if not a.intersects(b):
		return [a]
	var out: Array = []
	var x0: float = maxf(a.position.x, b.position.x)
	var x1: float = minf(a.end.x, b.end.x)
	if b.position.y > a.position.y:                       # Streifen oberhalb
		out.append(Rect2(a.position, Vector2(a.size.x, b.position.y - a.position.y)))
	if b.end.y < a.end.y:                                 # Streifen unterhalb
		out.append(Rect2(Vector2(a.position.x, b.end.y), Vector2(a.size.x, a.end.y - b.end.y)))
	var top: float = maxf(a.position.y, b.position.y)
	var bot: float = minf(a.end.y, b.end.y)
	if b.position.x > a.position.x:                       # Streifen links
		out.append(Rect2(Vector2(a.position.x, top), Vector2(b.position.x - a.position.x, bot - top)))
	if b.end.x < a.end.x:                                 # Streifen rechts
		out.append(Rect2(Vector2(b.end.x, top), Vector2(a.end.x - b.end.x, bot - top)))
	return out


## Flaches Bodenstueck. UV = Weltposition in Kacheln, damit alle Teilstuecke dieselbe
## Kachelphase haben und die Naht unsichtbar bleibt.
func _add_ground_quad(r: Rect2, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array = [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x, r.end.y), Vector2(r.position.x, r.end.y)]
	# Umlaufrichtung: siehe `_ist_vorderseitig` in den Tests. Sie stand hier jahrelang falsch
	# herum ([0,2,1 / 0,3,2]) — der Boden war damit RUECKSEITIG. Aufgefallen ist es nie, weil
	# das Sandmaterial aus dem CC0-Modell doppelseitig ist (`cull_mode = CULL_DISABLED`): Die
	# Flaeche blieb sichtbar, Godot dreht bei Rueckseiten aber die Normale um, und eine nach
	# UNTEN zeigende Normale bekommt keine Sonne. Gemessen lag die Helligkeit bei 0,24 statt
	# 0,96 — der ganze Boden der Welt lag nur im Umgebungslicht.
	for idx in [0, 1, 2, 0, 2, 3]:
		var p: Vector2 = corners[idx]
		st.set_normal(Vector3.UP)
		st.set_uv(p / _ground_tile_m)
		st.add_vertex(Vector3(p.x, 0.0, p.y))
	# Tangenten erzeugen, BEVOR das Netz festgeschrieben wird: Der Sandboden ist ein PBR-Satz
	# MIT Normalmap, und die wird im Tangentenraum gelesen. Ohne Tangenten rechnet der Shader
	# mit undefinierten Vektoren. (Gesucht war damit der Helligkeitsunterschied zwischen Boden
	# und Piste — der lag NICHT hieran und ist noch offen. Richtig ist es trotzdem.)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	# Eine waagerechte Flaeche kann keinen sinnvollen Schatten werfen — das spart auf dem Handy
	# die groesste Geometrie der Szene in jedem Schattendurchlauf.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Verformter Flicken ueber einer Gelaendeform. Die Hoehe kommt aus `WorldManager.height_at`,
## die Normale aus `normal_at` — also aus DERSELBEN Formel, aus der auch die Spielerhoehe
## kommt. Gemittelte Dreiecksnormalen waeren an der Naht zur flachen Flaeche sichtbar.
func _add_terrain_patch(f: Dictionary, mat: Material) -> void:
	var c: Vector3 = WorldManager.feature_center(f)
	var reach: float = WorldManager.feature_reach(f) + TERRAIN_MARGIN_M
	# Auflösung je Form, nicht global: Die Grube braucht 0,35 m fuer ihre 66°-Wand, ein 220 m
	# breites Duenenfeld waere damit 940.000 Dreiecke — bei 19 m Wellenlaenge sieht man dort
	# 2 m nicht.
	var schritt: float = float(f.get("step", TERRAIN_STEP_M))
	var n: int = maxi(8, int(ceil(reach * 2.0 / schritt)))
	var step: float = reach * 2.0 / float(n)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in n:
		for ix in n:
			var x0: float = c.x - reach + float(ix) * step
			var z0: float = c.z - reach + float(iz) * step
			# Dieselbe umgekehrte Umlaufrichtung wie beim flachen Bodenviereck — und derselbe
			# Grund, warum es nicht auffiel. Bei einer 66°-Wand wiegt es schwerer als beim
			# flachen Boden: Ohne Sonne hat die Wand keine Schattierung, und dann sieht man
			# die Grube ueberhaupt nicht mehr als Grube.
			for q in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1),
					Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x0 + q.x * step
				var pz: float = z0 + q.y * step
				st.set_normal(WorldManager.normal_at(px, pz))
				st.set_uv(Vector2(px, pz) / _ground_tile_m)
				st.add_vertex(Vector3(px, WorldManager.height_at(px, pz), pz))
	# Tangenten erzeugen, BEVOR das Netz festgeschrieben wird: Der Sandboden ist ein PBR-Satz
	# MIT Normalmap, und die wird im Tangentenraum gelesen. Ohne Tangenten rechnet der Shader
	# mit undefinierten Vektoren. (Gesucht war damit der Helligkeitsunterschied zwischen Boden
	# und Piste — der lag NICHT hieran und ist noch offen. Richtig ist es trotzdem.)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.name = "terrain_" + String(f["id"])
	add_child(mi)


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_energy = 1.6
	sun.light_color = Color(1.0, 0.94, 0.80)   # tiefstehende Wuestensonne, warm
	# ── Schatten: der groesste einzelne Unterschied zur Referenz ──────────────
	# Bis hierher warf NICHTS einen Schatten. Ohne ihn steht eine Figur nicht auf dem Boden,
	# sie klebt darauf — man sieht weder, wo sie aufsetzt, noch wie hoch etwas ist. In den
	# Diablo-Vorlagen wirft selbst der vorbeifliegende Rabe einen harten Schatten auf den Sand.
	sun.shadow_enabled = true
	# Zwei Kaskaden statt vier: Wir sehen 15 m weit, und auf dem Handy zaehlt jede eingesparte
	# Schattenkarte. 60 m Reichweite deckt alles ab, was ueberhaupt im Bild landen kann, und
	# gibt der Nahzone dafuer die volle Aufloesung.
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = CAM_SHADOW_M
	sun.directional_shadow_split_1 = 0.12
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.4
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.55, 0.42)   # grüner Bronzehimmel (Story-Bibel)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.78)   # kuehler Himmelsanteil gegen die warme Sonne
	# Von 0,8 auf 0,32: Bei 0,8 Umgebung gegen 1,15 Sonne lag zwischen Licht- und Schattenseite
	# nur der Faktor 2,4 — deshalb wirkte jedes Objekt flach. Jetzt sind es rund 6.
	env.ambient_light_energy = 0.32
	# Godots Vorgabe ist lineares Tonemapping; helle Flaechen laufen damit aus und Sand wirkt
	# ausgewaschen. Filmic haelt die Lichter zusammen und vertieft die Schatten.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.5
	# Luftperspektive: In der Ferne blasst alles zum Himmel aus, das erzeugt Tiefe. Bewusst
	# duenn — Kraterrand und Eisernes Herz sollen als Landmarken am Horizont sichtbar bleiben.
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.62, 0.52)
	env.fog_density = 0.0007
	env.fog_aerial_perspective = 0.5
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)


## Deckkraft der Biom-Tönung. 0,30 statt 1,0 (siehe unten): Die Salzpfanne soll den Sand
## AUFHELLEN, nicht ersetzen — und vor allem soll man durch sie hindurch sehen, was im Boden
## liegt. Etwas kräftiger als der Sumpfschleier (0,16), weil ein Biom über einen Kilometer
## wirkt und nicht über hundert Meter.
const BIOME_TINT_ALPHA: float = 0.30
func _build_ground_and_biomes() -> void:
	# Der Boden ist nicht mehr EINE Platte: Wo Gelände liegt (WorldManager.TERRAIN), wird ein
	# Loch ausgespart und mit einem verformten Flicken gefuellt. Sonst laege die flache Platte
	# ueber der Senke und man saehe von der Vertiefung nichts.
	var mat: BaseMaterial3D = _ground_material()
	for r in _ground_rects():
		_add_ground_quad(r, mat)
	for f in WorldManager.TERRAIN:
		_add_terrain_patch(f, mat)
	# Benannte Biom-Kreiszonen (WorldManager.BIOMES) als getönte Scheiben.
	#
	# Sie waren DECKEND — eine 550-m-Platte aus Vollfarbe, 15 cm über dem Boden. Solange die
	# Welt flach war, fiel das nicht auf: Die Scheibe lag auf dem Sand und sah aus wie
	# eingefärbter Sand. Sobald aber Gelände darunter liegt, verschluckt sie es restlos — die
	# ersten Sumpflöcher lagen in der Salzpfanne und waren im Bild weiße Kreise mit einem
	# Sandring, weil man nur noch den Teil des Walls sah, der über die Platte ragte.
	# (Dieselbe Falle wie die Piste über dem Krater, nur mit einer Scheibe statt einem Balken.)
	#
	# Jetzt durchscheinend, wie Smog- und Sumpfschleier auch: Godot zeichnet Durchsichtiges
	# NACH dem Undurchsichtigen und ohne in den Tiefenpuffer zu schreiben. Die Senke rendert
	# also zuerst mit ihrer echten Tiefe und wird anschließend nur noch eingefärbt — das ist
	# genau das, was eine Biom-Tönung tun soll.
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
		cyl.height = 0.2
		disc.mesh = cyl
		disc.material_override = _mat(tint[id], false, BIOME_TINT_ALPHA)
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		disc.position = WorldManager.world_to_scene(Vector2(float(b["cx"]), float(b["cy"]))) + Vector3(0.0, 0.10, 0.0)
		add_child(disc)
	# Smog-Senke: alles nördlich der Smog-Linie liegt unter giftgrünem Schleier.
	var half: float = WorldManager.WORLD_METERS / 2.0
	var smog_depth_m: float = (float(WorldManager.WORLD_SIZE) - float(WorldManager.SMOG_LINE_Y)) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT + smog_depth_m / 2.0)
	_box(Vector3(WorldManager.WORLD_METERS, 0.4, smog_depth_m), Vector3(half, 0.35, smog_z), Color(0.35, 0.65, 0.30), 0.35)


## Der Strahlensumpf: ein Fleck von 2,5 × 0,5 km, 800 m nördlich von Rustwater.
##
## Optisch lebt er von drei Dingen, und zwei davon kosten nichts:
##
##  1. **Der Boden verfärbt sich.** Kein Modell, kein zweites Material — dieselbe Sandtextur
##     mit giftgrüner Tönung, als flaches Band knapp über dem Boden. Ein eigenes Biom wäre
##     dasselbe Ergebnis mit mehr Arbeit.
##  2. **Pfützen.** Das ist die Frage, die der Auftraggeber gestellt hat: wie macht man die
##     optisch? Antwort: als flache Scheiben mit LEUCHTENDEM Material (`emission`) und
##     niedriger Rauheit. Das Leuchten ist der Trick — eine Pfütze, die nur eine dunkle Fläche
##     ist, liest sich als Loch; eine, die von innen grün glimmt, liest sich als verseucht.
##     Godots `emission` braucht dafür keine Lichtquelle und kostet nichts.
##  3. **Tote Bäume.** Dafür fehlen Modelle (siehe `docs/ASSETS_OFFEN.md`); bis dahin stehen
##     dort kahle Stämme aus zwei Zylindern. Sie liefern die Silhouette, die aus einem grünen
##     Band ein Moor macht, und lassen sich später durch ein Modell ersetzen, ohne dass sich
##     hier etwas ändert.
## Die Zone misst 2,5 × 0,5 km — bei den ersten Zahlen (90 Pfützen, 44 Bäume) lag im Bild
## praktisch nichts, weil sich das damals sogar über die ganze Kartenbreite verteilte. 420 und
## 240 sind noch billig (Pfütze 28 Dreiecke, Baum 26) und ergeben auf 1,25 km² endlich eine
## Dichte, die man beim Durchlaufen sieht.
const SWAMP_PUDDLES: int = 420
const SWAMP_TREES: int = 240
func _build_swamp() -> void:
	var m: float = WorldManager.METERS_PER_UNIT
	var zone: Rect2 = WorldManager.swamp_rect()
	var breite_m: float = zone.size.x * m          # Ost–West
	var tiefe_m: float = zone.size.y * m           # Süd–Nord
	var mitte_x: float = (zone.position.x + zone.size.x * 0.5) * m
	var mitte_z: float = -(zone.position.y + zone.size.y * 0.5) * m
	var sued: float = zone.position.y * m          # Szenen-|z| des Südrands
	# 1. Die Verfärbung. Knapp über dem Boden, durchscheinend — der Sand bleibt sichtbar.
	# Alpha 0.16, nicht 0.55. Der erste Versuch war eine grüne Platte, die den Sand vollständig
	# verdeckte — das Bild sah aus wie eine Wiese, nicht wie verseuchter Boden. Ein Schleier muss
	# durchlassen, was er einfärbt; die Verseuchung liest man an den Pfützen, nicht am Anstrich.
	var band := _box(Vector3(breite_m, 0.24, tiefe_m),
		Vector3(mitte_x, 0.13, mitte_z),
		Color(0.30, 0.50, 0.18), 0.16)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_label(Vector3(mitte_x, 26.0, mitte_z),
		"☢ STRAHLENSUMPF — ohne Schutzanzug tödlich", Color(0.62, 1.0, 0.45), LBL_LANDMARKE, 900.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20250729
	# 2. Pfützen. Leuchtendes Material, flache Scheibe, zufällig gestreckt — ein Kreis liest
	#    sich als Deckel, eine Ellipse als Lache.
	var lache := StandardMaterial3D.new()
	lache.albedo_color = Color(0.16, 0.34, 0.13)
	lache.emission_enabled = true
	lache.emission = Color(0.35, 0.95, 0.28)
	lache.emission_energy_multiplier = 0.85
	lache.roughness = 0.14
	lache.metallic = 0.25
	for i in SWAMP_PUDDLES:
		var r: float = rng.randf_range(1.1, 4.2)
		# Nur dort, wo die Strahlung wirklich zubeisst: dichter in der Mitte der Zone.
		var x: float = 0.0
		var z: float = 0.0
		var flach: bool = false
		for versuch in 4:
			var t: float = 0.5 + (rng.randf() - 0.5) * 1.4
			z = -(sued + tiefe_m * clampf(t, 0.04, 0.96))
			x = _swamp_x(rng)
			if _liegt_flach(x, z, r):
				flach = true
				break
		if not flach:
			continue
		var mi := MeshInstance3D.new()
		var zyl := CylinderMesh.new()
		zyl.top_radius = r
		zyl.bottom_radius = r
		zyl.height = 0.06
		zyl.radial_segments = 14
		mi.mesh = zyl
		mi.material_override = lache
		mi.position = Vector3(x, WorldManager.height_at(x, z) + 0.05, z)
		mi.scale = Vector3(1.0, 1.0, rng.randf_range(0.45, 1.0))
		mi.rotation.y = rng.randf() * TAU
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# 2b. Jedes Sumpfloch bekommt seinen eigenen Tümpel — die Lache am tiefsten Punkt, wie in
	#     der Schrottgrube. Ein Krater ohne Wasser wäre im Sumpf eine Baugrube; mit Wasser ist
	#     er das, was die kleinen Einschläge überhaupt erzählen sollen.
	#
	#     Sie liegt NICHT in der Mitte, sondern der Rampe gegenüber. In der Rampe fällt der
	#     flache Grund weg (`_floor_share` läuft dort gegen 0) und die Wand zieht sich bis zum
	#     Mittelpunkt — eine mittige Scheibe wurde davon angeschnitten und sah aus wie ein
	#     angebissener Keks. Physikalisch ist die Verschiebung ohnehin richtig: Wasser sammelt
	#     sich am tiefsten Punkt, und der liegt bei einer einseitig offenen Senke abseits der
	#     Öffnung. Maße als Anteil des flachen Grundes, damit sie mit jeder Kratergröße mitgehen.
	for f in WorldManager.TERRAIN:
		if not WorldManager.is_swamp_feature(f):
			continue
		var c: Vector3 = WorldManager.feature_center(f)
		var grund: float = float(f["radius"]) * float(f.get("floor", 0.4))
		# Weg von der Rampe. `ramp_deg` ist 0° = Osten, 90° = Norden; Norden ist −z.
		var weg: float = deg_to_rad(float(f.get("ramp_deg", 0.0))) + PI
		var mx: float = c.x + cos(weg) * grund * 0.45
		var mz: float = c.z - sin(weg) * grund * 0.45
		var tuempel := MeshInstance3D.new()
		var scheibe := CylinderMesh.new()
		var tr: float = grund * 0.42
		scheibe.top_radius = tr
		scheibe.bottom_radius = tr
		scheibe.height = 0.08
		scheibe.radial_segments = 20
		tuempel.mesh = scheibe
		tuempel.material_override = lache
		tuempel.position = Vector3(mx, WorldManager.height_at(mx, mz) + 0.06, mz)
		tuempel.scale = Vector3(1.0, 1.0, rng.randf_range(0.72, 1.0))
		tuempel.rotation.y = rng.randf() * TAU
		tuempel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tuempel)
	# 3. Tote Stämme — jetzt Modelle statt zwei Zylindern.
	#
	# Drei Sorten in einem Durchgang, weil sie sich denselben Platz teilen: stehende Bäume
	# (`deadtree`), umgestürzte (`deadtree_b`) und aufgeplatzte Strahlenfässer (`rad_barrel`).
	# Getrennte Schleifen hätten dreimal dieselbe Streuung gebraucht, und die Fässer sollen
	# GENAU DA liegen, wo auch die Bäume stehen — sie erzählen zusammen, warum der Sumpf
	# verseucht ist.
	#
	# Die Mischung ist bewusst schief: acht Bäume auf einen umgestürzten und ein Fass. Ein
	# Wald aus lauter Umgestürzten sähe aus wie nach einem Sturm, und ein Fass hinter jedem
	# Baum nähme dem einzelnen Fund die Bedeutung.
	var holz: Material = _mat(Color(0.19, 0.17, 0.13))
	for i in SWAMP_TREES:
		var z2: float = -(sued + tiefe_m * rng.randf_range(0.08, 0.92))
		var x2: float = _swamp_x(rng)
		# Nicht auf die Gleise. Die Trasse quert den Sumpf genau dort, wo die Streuung am
		# dichtesten ist — im ersten Bild lag prompt ein Strahlenfass zwischen den Schwellen.
		# Ein Zug faehrt da durch; was dort liegt, sieht nach Fehler aus, nicht nach Absicht.
		if _auf_trasse(Vector3(x2, 0.0, z2)):
			continue
		var wuerfel: float = rng.randf()
		var art: String = "deadtree"
		if wuerfel > 0.90:
			art = "rad_barrel"
		elif wuerfel > 0.80:
			art = "deadtree_b"
		var boden: float = WorldManager.height_at(x2, z2)
		var modell: Node3D = null
		if AssetRegistry.has_model(art):
			# Umgestürztes wird über die LÄNGE gemessen, Stehendes über die Höhe — sonst wäre
			# ein liegender Stamm auf 5,5 m Höhe skaliert ein Baumstamm von zwanzig Metern.
			var mass: float = AssetRegistry.length_of(art)
			if mass <= 0.0:
				mass = AssetRegistry.height_of(art)
			modell = AssetRegistry.instantiate(art, mass * rng.randf_range(0.82, 1.18))
		if modell != null:
			add_child(modell)
			modell.position = Vector3(x2, boden, z2)
			modell.rotation.y = rng.randf() * TAU
			# Nur was STEHT, kippt ein wenig und sperrt. Über einen liegenden Stamm steigt man,
			# und ein Fass tritt man beiseite — eine Sperre daran wäre nur im Weg.
			if art == "deadtree":
				modell.rotation.z = deg_to_rad(rng.randf_range(-9.0, 9.0))
				_solid_pillar(modell.position, 0.4)
			continue
		# Ohne Modell bleibt der Platzhalter: schiefer Stamm plus ein Aststummel. Zwei Zylinder
		# sind das Minimum, ab dem ein Baum als Baum liest und nicht als Pfahl.
		var hoehe: float = rng.randf_range(3.4, 6.8)
		var baum := Node3D.new()
		add_child(baum)
		baum.position = Vector3(x2, boden, z2)
		baum.rotation.y = rng.randf() * TAU
		var stamm: MeshInstance3D = _child_cyl(baum, 0.22, hoehe, Vector3(0.0, hoehe * 0.5, 0.0), holz)
		stamm.rotation.z = deg_to_rad(rng.randf_range(-13.0, 13.0))
		var ast: MeshInstance3D = _child_cyl(baum, 0.10, hoehe * 0.42,
			Vector3(0.0, hoehe * 0.72, 0.0), holz)
		ast.rotation.z = deg_to_rad(rng.randf_range(52.0, 84.0) * (1.0 if rng.randf() < 0.5 else -1.0))
		_solid_pillar(baum.position, 0.35)


## Passt eine flache Scheibe vom Radius `r` an dieser Stelle auf den Boden?
##
## Eine Pfütze ist eine waagerechte Scheibe. Solange der Sumpf eine Tischplatte war, durfte sie
## überall liegen; seit Krater darin liegen, landet sonst eine auf einem Wall und ragt zur
## Hälfte heraus — im Bild ein grüner Keil, der aus dem Hang wächst.
##
## Geprüft wird über HÖHENUNTERSCHIEDE am Rand der Scheibe, nicht über die Normale. Der erste
## Versuch fragte `normal_at(x, z, r)` ab und ließ genau die schlimmsten Stellen durch: Auf
## einem Wallkamm liegen beide Abtastpunkte gleich tief, die gemittelte Normale zeigt sauber
## nach oben, und die Scheibe steckt trotzdem quer im Grat. Sechs Punkte auf dem Kreis
## beantworten stattdessen direkt die Frage, die zählt — passt sie hin, ohne einzutauchen?
const PUDDLE_FLAT_TOL_M: float = 0.16
func _liegt_flach(x: float, z: float, r: float) -> bool:
	var h0: float = WorldManager.height_at(x, z)
	for k in 6:
		var a: float = TAU * float(k) / 6.0
		var h: float = WorldManager.height_at(x + cos(a) * r, z + sin(a) * r)
		if absf(h - h0) > PUDDLE_FLAT_TOL_M:
			return false
	return true


## Ost-West-Lage eines Sumpf-Details, gewichtet zur ÜBERQUERUNG hin.
##
## Die Zone ist 2,5 km breit. Gleichmäßig gestreut sind selbst 420 Pfützen eine je 3 000 m² —
## bei 30 m Sichtweite läuft man daran vorbei, ohne eine zu sehen, und der Sumpf bleibt ein
## grüner Anstrich. Zwei Drittel der Details liegen deshalb in einem 700-m-Fenster um die
## Stelle, an der die Bahntrasse die Zone schneidet: Dort kommt praktisch jeder durch. Das
## letzte Drittel bleibt breit gestreut, damit der Sumpf auch abseits nicht plötzlich aufhört.
func _swamp_x(rng: RandomNumberGenerator) -> float:
	var zone: Rect2 = WorldManager.swamp_rect()
	var m: float = WorldManager.METERS_PER_UNIT
	var links: float = zone.position.x * m + 12.0
	var rechts: float = (zone.position.x + zone.size.x) * m - 12.0
	var rand_x: float = rng.randf_range(links, rechts)
	if rng.randf() > 0.66:
		return rand_x
	var mitte: float = _swamp_crossing_x()
	if mitte < links or mitte > rechts:
		return rand_x     # die Trasse quert daneben — dann gibt es keinen bevorzugten Ort
	return clampf(mitte + rng.randf_range(-350.0, 350.0), links, rechts)


## Wo schneidet die Bahntrasse den Sumpf (Szenen-x, −1 = nirgends)?
func _swamp_crossing_x() -> float:
	var y: float = WorldManager.swamp_center_y()
	for seg in WorldManager.rail_segments():
		var a: Vector2 = WorldManager.poi_position(String(seg[0]))
		var b: Vector2 = WorldManager.poi_position(String(seg[1]))
		if (a.y < y) == (b.y < y):
			continue     # beide Enden auf derselben Seite: kein Schnitt
		var t: float = (y - a.y) / (b.y - a.y)
		return (a.x + (b.x - a.x) * t) * WorldManager.METERS_PER_UNIT
	return -1.0


## Zylinder als Kind eines Knotens — fuer alles Stangenfoermige (Staemme, Rohre, Masten).
func _child_cyl(parent: Node3D, radius: float, hoehe: float, local_pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var zyl := CylinderMesh.new()
	zyl.top_radius = radius * 0.75      # oben schlanker: ein Stamm laeuft nach oben zu
	zyl.bottom_radius = radius
	zyl.height = hoehe
	zyl.radial_segments = 7             # aus zehn Metern zaehlt niemand die Kanten
	mi.mesh = zyl
	mi.material_override = mat
	mi.position = local_pos
	parent.add_child(mi)
	return mi


func _build_sector_lines_and_rim() -> void:
	var w: float = WorldManager.WORLD_METERS
	var half: float = w / 2.0
	var blast_z: float = -float(WorldManager.BORDER_S1_S2_Y) * WorldManager.METERS_PER_UNIT
	var smog_z: float = -float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT
	# Gate 1 — Iron-Rail-Sprengtore (dunkle Stahlwand quer über den Krater).
	_box(Vector3(w, 22.0, 5.0), Vector3(half, 11.0, blast_z), Color(0.24, 0.16, 0.13))
	_label(Vector3(half, 30.0, blast_z), "⛔ IRON-RAIL-SPRENGTORE", Color(1.0, 0.55, 0.35), LBL_LANDMARKE, 600.0)
	# Gate 2 — Smog-Linie (durchscheinend, giftgrün).
	_box(Vector3(w, 28.0, 4.0), Vector3(half, 14.0, smog_z), Color(0.35, 0.75, 0.30), 0.45)
	_label(Vector3(half, 38.0, smog_z), "☣ SMOG-LINIE", Color(0.6, 1.0, 0.5), LBL_LANDMARKE, 600.0)
	# Kraterrand: 350 m Fels an allen vier Horizonten — die diegetische Außengrenze.
	var rock := Color(0.28, 0.22, 0.18)
	_box(Vector3(w + 300.0, 350.0, 150.0), Vector3(half, 175.0, 75.0), rock)            # Süd
	_box(Vector3(w + 300.0, 350.0, 150.0), Vector3(half, 175.0, -w - 75.0), rock)       # Nord
	_box(Vector3(150.0, 350.0, w + 300.0), Vector3(-75.0, 175.0, -half), rock)          # West
	_box(Vector3(150.0, 350.0, w + 300.0), Vector3(w + 75.0, 175.0, -half), rock)       # Ost
	# Rand-Tunnel (§1.7.4): das eine, verriegelte Tor durch die Nordwand.
	_box(Vector3(60.0, 80.0, 40.0), Vector3(half, 40.0, -w - 20.0), Color(0.08, 0.07, 0.06))
	_label(Vector3(half, 95.0, -w + 5.0), "🚪 RAND-TUNNEL (verriegelt)", Color(0.95, 0.85, 0.6), LBL_LANDMARKE, 500.0)


## Schwebende Beschriftung. Höhe in Weltmetern = font_size × pixel_size; mit LABEL_PIXEL
## ergibt `size` also grob die Zeichenhöhe in Zentimetern (150 ≈ 1,8 m) — vorher waren es
## 7,5 m, was die Szene zugepflastert hat. `fade_m` blendet die Schrift auf Distanz aus,
## damit ferne POI-Namen nicht über der halben Karte kleben.
const LABEL_PIXEL: float = 0.012
## Schriftgrößen als eigene Namen, weil sie zusammengehören und einzeln gesetzt auseinander
## laufen. `size × LABEL_PIXEL` ist die Zeichenhöhe in METERN — daran misst man sie:
## Ein Name über einer 1,8-m-Figur, der 1,0 m hoch ist, ist keine Beschriftung mehr, sondern
## eine Bauchbinde. Bei Kameraabstand 9,5 m entspricht ein Meter Welthöhe rund 73 Bildpunkten.
const LBL_FIGUR: int = 25       # Namen über Personen    ≈ 0,30 m  ≈ 22 px
const LBL_BEUTE: int = 20       # Beute am Boden         ≈ 0,24 m
const LBL_TRUHE: int = 24
const LBL_HAUS: int = 34        # Gebäudeschilder        ≈ 0,41 m
const LBL_ORT: int = 60         # Ortsnamen              ≈ 0,72 m
const LBL_LANDMARKE: int = 150  # Eisernes Herz, Zonengrenzen — die sieht man aus Kilometern

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
			_label(pos + Vector3(0.0, 445.0, 0.0), "🖤 " + String(p["name"]), Color(1.0, 0.45, 0.35), LBL_LANDMARKE, 900.0)
			continue
		# Ein Ort ist eine SCHRIFT, kein Pfahl.
		#
		# Hier stand eine 36 m hohe, 12 m dicke Saeule in Vollfarbe, mit 6,6 m Sperrradius genau
		# im Mittelpunkt des Ortes. Sie hat dieselbe Falle dreimal gestellt: erst mitten auf dem
		# Marktplatz von Rustwater, dann im Grund der Schrottgrube (man lief die Flanke hinunter
		# und blieb unten stehen) — und zuletzt im Rattengestruepp, also ausgerechnet dort, wohin
		# die erste Quest schickt. Zweimal wurde sie einzeln ausgenommen; beim dritten Mal ist
		# klar, dass nicht die Ausnahme falsch war, sondern die Saeule.
		#
		# Sie war ein Platzhalter fuer Fernorientierung, und der Job ist inzwischen vergeben:
		# Minikarte und Weltkarte zeigen die Orte, der Nebel deckt auf, was man gesehen hat, die
		# Quest-Marke zeigt das Ziel, die Fussspur den Weg, das HUD die Entfernung, und beim
		# Ankommen zieht der Ortsname gross ueber den Bildschirm. Was bleibt, ist die schwebende
		# Schrift auf 420 m — sie sagt „hier ist etwas", ohne im Weg zu stehen.
		#
		# Landmarken macht ab jetzt das Gelaende: Krater, Duenenfeld, Sumpf. Die sieht man von
		# weitem, sie sperren nichts, und sie sehen nicht aus wie ein Baustellenpoller.
		var hoch: float = WorldManager.height_at(pos.x, pos.z) + 22.0
		_label(pos + Vector3(0.0, hoch, 0.0), String(p["name"]), col.lightened(0.35), LBL_ORT, 420.0)


## Gelaendeform an einem Ort ({} = keine).
func _terrain_at_poi(id: String) -> Dictionary:
	for f in WorldManager.TERRAIN:
		if String(f.get("poi", "")) == id:   # freie Formen (Duenen) haben keinen Ort
			return f
	return {}


## Bodennaher Streifen, der dem Gelaende FOLGT.
##
## Vorher war jede Piste EIN Balken von Ort zu Ort. Auf flachem Boden faellt das nicht auf —
## sobald aber eine Senke darunter liegt, deckt der Balken sie zu wie ein Brett ueber einem
## Loch. In der Schrotthalde verschwanden Figur und Truhe darunter, und vom Krater war nichts
## zu sehen: Man blickte auf die Unterseite der Piste.
##
## Die Schrittweite passt sich an: In der Naehe einer Gelaendeform alle 1,5 m, sonst alle 40 m.
## Ein Streifen ueber 1000 m flacher Wueste kostet damit 50 Dreiecke statt 1300, und die
## Stelle, auf die es ankommt, ist trotzdem fein aufgeloest.
##
## UV traegt METER, nicht 0..1 — quer in `u`, laengs in `v`. Der Gleisbett-Shader zeichnet
## daraus seine Schwellen; sonst haenge die Schwellenzahl an der Segmentlaenge.
const RIBBON_STEP_NEAR: float = 1.5
const RIBBON_STEP_FAR: float = 40.0

func _ribbon_step(p: Vector3) -> float:
	for f in WorldManager.TERRAIN:
		var c: Vector3 = WorldManager.feature_center(f)
		if Vector2(p.x - c.x, p.z - c.z).length() < WorldManager.feature_reach(f) + RIBBON_STEP_FAR:
			return RIBBON_STEP_NEAR
	return RIBBON_STEP_FAR


func _add_ribbon(a: Vector3, b: Vector3, half_w: float, lateral: float, lift: float,
		mat: Material) -> void:
	var flat: Vector3 = Vector3(b.x - a.x, 0.0, b.z - a.z)
	var total: float = flat.length()
	if total < 0.5:
		return
	var dir: Vector3 = flat / total
	var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
	var mitte: Vector3 = a + side * lateral
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var d0: float = 0.0
	while d0 < total:
		var step: float = _ribbon_step(mitte + dir * d0)
		var d1: float = minf(d0 + step, total)
		# AUCH QUER unterteilen. Die Piste ist 55 m breit, der Krater misst 40 m — wird die
		# Hoehe nur an den beiden Raendern abgetastet, liegen beide auf flachem Boden und die
		# Strasse spannt sich als Bruecke ueber das Loch. Genau so verschwand die Figur darunter.
		var spalten: int = maxi(1, int(ceil(half_w * 2.0 / step)))
		for k in spalten:
			var q0: float = -half_w + half_w * 2.0 * float(k) / float(spalten)
			var q1: float = -half_w + half_w * 2.0 * float(k + 1) / float(spalten)
			for e in [[d0, q0], [d1, q1], [d0, q1], [d0, q0], [d1, q0], [d1, q1]]:
				var laengs: float = float(e[0])
				var quer: float = float(e[1])
				var v: Vector3 = mitte + dir * laengs + side * quer
				v.y = WorldManager.height_at(v.x, v.z) + lift
				st.set_normal(WorldManager.normal_at(v.x, v.z))
				st.set_uv(Vector2(quer, laengs))
				st.add_vertex(v)
		d0 = d1
	# Tangenten erzeugen, BEVOR das Netz festgeschrieben wird: Der Sandboden ist ein PBR-Satz
	# MIT Normalmap, und die wird im Tangentenraum gelesen. Ohne Tangenten rechnet der Shader
	# mit undefinierten Vektoren. (Gesucht war damit der Helligkeitsunterschied zwischen Boden
	# und Piste — der lag NICHT hieran und ist noch offen. Richtig ist es trotzdem.)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	# Durchnummeriert, nicht bloss "ribbon": Bei gleichem Namen vergibt Godot beim Einhaengen
	# eigene Namen der Bauart "@MeshInstance3D@23", und dann findet eine Suche nach "ribbon"
	# genau ein Band statt aller. Das hat beim Nachzaehlen der Pisten schon einmal ein
	# falsches Ergebnis geliefert.
	mi.name = "ribbon_%d" % get_child_count()
	# Ein bodennaher Streifen wirft keinen sinnvollen Schatten, kostet im Schattendurchlauf
	# aber die volle Laenge.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## KEINE PISTEN MEHR.
##
## Es gab hier `_build_roads()`: ein gestampftes Band auf jeder Route, gedacht als Wegfuehrung
## („die schnellste Linie zwischen zwei Orten, an der man sich orientiert, statt Waende zu
## haben"). In einer offenen Wueste, in der man ohnehin quer laeuft und ueber die Iron Rail
## reist, hat das nie getragen — die Strassen waren ein Band auf dem Boden, dem niemand folgte.
## Praktisch angerichtet haben sie dafuer einiges: 55 m breit deckten sie den 30-m-Krater der
## Schrotthalde restlos zu, und ihre Kante lief als harter Bodenwechsel quer durch die Senke.
##
## Geblieben ist, was wirklich Weg ist: die Iron-Rail-Trasse (`_build_railway`). Die Routen
## selbst bleiben als Nachbarschafts-Daten bestehen — das Schienennetz leitet sich aus ihnen ab.


## Kuerzt eine Strecke an beiden Enden auf das, was der Ort dort zulaesst.
##
## Routen verbinden die MITTELPUNKTE der Orte. Ungekuerzt laufen Piste und Trasse deshalb quer
## ueber den Marktplatz und durch die Haeuser — und, seit es Topografie gibt, bis auf den Grund
## des Kraters. Zwei Faelle, zwei Endpunkte:
##  • **bebaute Stadt** — bis knapp hinter den Stadtboden.
##  • **geformtes Gelaende** — bis an den Auswurfwall. Ein Fuhrwerk faehrt an den Rand der
##    Grube und laedt dort ab; es faehrt nicht hinein. Vorher endete die Piste in der Mitte
##    der Senke, und ihre abgeschnittene Kante lief quer durch den Krater.
func _trim_route(a: Vector3, b: Vector3, id_a: String, id_b: String) -> Array:
	var dir: Vector3 = (b - a).normalized()
	return [a + dir * _route_stop_m(id_a), b - dir * _route_stop_m(id_b)]


## Abstand vom Ortsmittelpunkt, an dem eine Strecke endet (0 = bis in die Mitte).
func _route_stop_m(poi_id: String) -> float:
	if _is_built_town(poi_id):
		return TOWN_GROUND_R
	var f: Dictionary = _terrain_at_poi(poi_id)
	if not f.is_empty():
		return WorldManager.feature_reach(f)
	return 0.0


## Ist an diesem Ort eine gebaute Stadt (mit eigenem Boden und Mauer)?
func _is_built_town(poi_id: String) -> bool:
	return poi_id == "rustwater" and ResourceLoader.exists(TOWN_SCENE)


## Die GLEISE sind vorerst AUS.
##
## Eine Trasse quer durch die Welt ist eine Entscheidung ueber die ganze Karte: Sie legt fest,
## welche Orte Nachbarn sind, wo man langlaeuft und wovon die Landschaft durchschnitten wird.
## Das macht man am Ende, wenn die Orte stehen — nicht am Anfang.
##
## Der BAHNSTEIG bleibt stehen: An ihm haengt die Schnellreise (`_fast_travel`), und ohne sie
## ist die Welt zum Ausprobieren zu gross. Wieder anschalten ist ein Wort.
const ZEIGE_GLEISE: bool = false


## Liegt dieser Punkt auf der Trasse — und ist die ueberhaupt zu sehen?
##
## Streuwerk (Baeume, Faesser, Steine) wird von der Trasse ferngehalten, damit nichts zwischen
## den Schwellen steht. Ohne sichtbare Gleise waere dieselbe Sperre ein 15 m breiter,
## schnurgerader, auffaellig LEERER Streifen quer durch die Wueste — der Abdruck von etwas, das
## man nicht sieht. Also faellt sie mit den Gleisen zusammen weg.
func _auf_trasse(pos: Vector3) -> bool:
	return ZEIGE_GLEISE and WorldManager.on_rail(WorldManager.scene_to_world(pos))


## Die Iron Rail (GDD §1.4a): Schotterbett mit Schwellen + zwei Schienen auf den Routen
## zwischen den Bahnhoefen, dazu an jedem Knoten ein Bahnsteig. Der lange Fussmarsch durch die
## Wueste bleibt moeglich — spaeter faehrt man ihn. Fahren darf man nur AM Bahnsteig, damit
## Schnellreise ein Ort in der Welt ist und kein Menuepunkt.
func _build_railway() -> void:
	for id in WorldManager.RAIL_STATIONS:
		_build_station(String(id))
	if not ZEIGE_GLEISE:
		return
	var steel: Material = _mat(Color(0.62, 0.60, 0.58))
	var bed_shader: Shader = load("res://shaders/rail_bed.gdshader") as Shader
	for seg_ids in WorldManager.rail_segments():
		# Auch die Trasse endet vor der Stadt statt ueber den Marktplatz zu laufen.
		var pair: Array = _trim_route(WorldManager.poi_scene_position(String(seg_ids[0])),
			WorldManager.poi_scene_position(String(seg_ids[1])),
			String(seg_ids[0]), String(seg_ids[1]))
		# Schotterbett und beide Schienen sind jetzt gelaendefolgende Streifen statt gedrehter
		# Balken — aus demselben Grund wie bei den Pisten. Die Schwellen zeichnet weiterhin der
		# Shader, er liest den Takt aber aus der UV-Laengskoordinate statt aus der Balkenlaenge.
		var bed_mat: Material = null
		if bed_shader != null:
			var sm := ShaderMaterial.new()
			sm.shader = bed_shader
			sm.set_shader_parameter("sleeper_reach", RAIL_GAUGE_M * 0.5 + 0.55)
			bed_mat = sm
		else:
			bed_mat = _mat(Color(0.30, 0.27, 0.24))
		_add_ribbon(pair[0], pair[1], (RAIL_GAUGE_M + 3.0) * 0.5, 0.0, 0.10, bed_mat)
		for side in [-1.0, 1.0]:
			_add_ribbon(pair[0], pair[1], 0.08, side * RAIL_GAUGE_M * 0.5, 0.30, steel)


## Richtung, in die die Trasse einen Knoten verlaesst (Einheitsvektor, XZ-Ebene).
## Ohne Nachbarn: nach Sueden, damit der Bahnsteig nicht in der Landschaft verschwindet.
func _rail_exit_dir(poi_id: String) -> Vector3:
	for seg in WorldManager.rail_segments():
		var other: String = ""
		if String(seg[0]) == poi_id:
			other = String(seg[1])
		elif String(seg[1]) == poi_id:
			other = String(seg[0])
		if other != "":
			var d: Vector3 = WorldManager.poi_scene_position(other) - WorldManager.poi_scene_position(poi_id)
			return Vector3(d.x, 0.0, d.z).normalized()
	return Vector3(0.0, 0.0, 1.0)


## Bahnsteig an einem Knoten — **auf der Trasse und vor den Toren**.
##
## Vorher lag er stur 14 m suedlich des Ortsmittelpunkts. Bei Rustwater verlaesst die Strecke
## den Ort aber nach Norden: der Bahnsteig stand 162° neben den eigenen Gleisen, und seit dem
## engen Stadtplan zusaetzlich mitten in der Stadt. Jetzt sitzt er dort, wo die Schienen
## wirklich verlaufen, ausserhalb der Palisade, und ist wie sie ausgerichtet.
func _build_station(poi_id: String) -> void:
	var c: Vector3 = WorldManager.poi_scene_position(poi_id)
	var dir: Vector3 = _rail_exit_dir(poi_id)
	var platform: Vector3 = c + dir * STATION_OFFSET_M
	var station := Node3D.new()
	add_child(station)
	station.position = platform
	station.look_at(platform + dir, Vector3.UP)   # Laengsachse parallel zum Gleis
	# Bahnsteig NEBEN dem Gleis, nicht darauf: Versatz quer zur Fahrtrichtung.
	var side: float = RAIL_GAUGE_M * 0.5 + 4.6
	if not _build_station_hall(station, side):
		_build_station_boxes(station, side)
	_dress_station(station, side, poi_id)
	# Ueber den First, nicht davor: Bei 6,4 m hing die Schrift mitten in der Fassade und war
	# breiter als die Halle. Die Halle misst 9,8 m — 13 m sind knapp darueber, und die kleinere
	# Schrift laesst das Gebaeude die Hauptsache bleiben.
	var label_at: Vector3 = platform + Vector3(0.0, 13.0, 0.0)
	_label(label_at, "🚂 Bahnhof " + String(WorldManager.poi(poi_id)["name"]),
		Color(0.92, 0.86, 0.70), LBL_HAUS, 200.0)
	_stations.append({ "id": poi_id, "pos": platform })


## Bahnsteighalle aus dem Modell — `false`, wenn keins vorhanden ist.
##
## `station` schaut mit seinem lokalen −Z die Trasse entlang, lokales +X zeigt quer vom Gleis
## weg. Das Modell dagegen ist wie jedes Gebaeude gebaut: Laengsachse X, Front −Z (die
## Korrektur dahin steht in `AssetRegistry.YAW_DEG`). Beides passt erst nach einer weiteren
## Vierteldrehung zusammen — dann liegt die Halle laengs zum Gleis und schaut es an.
func _build_station_hall(station: Node3D, side: float) -> bool:
	var hall: Node3D = AssetRegistry.instantiate("bahnhof", STATION_LEN_M)
	if hall == null:
		return false
	var b: AABB = AssetRegistry.local_bounds(hall)
	var depth: float = maxf(b.size.z, 0.01)   # nach der Vierteldrehung die Tiefe zum Gleis hin
	hall.rotation.y = PI * 0.5
	# `side` ist der Abstand der Bahnsteig-VORDERKANTE zur Gleismitte, nicht der Hallenmitte:
	# Sonst haengt bei jeder Modellaenderung die halbe Halle ueber den Schienen.
	hall.position = Vector3(side + depth * 0.5, 0.0, 0.0)
	station.add_child(hall)
	# Gesperrt wird nur die Rueckwand-Haelfte. Der Bahnsteig unter dem Vordach ist der Ort, an
	# dem man auf den Zug wartet — waere er sperrend, koennte man den Bahnhof nicht betreten.
	var solid: float = depth * STATION_SOLID_SHARE
	var mid_local := Vector3(side + depth - solid * 0.5, 0.0, 0.0)
	_solid_rect_rot(station.global_transform * mid_local,
		Vector2(solid * 0.5, STATION_LEN_M * 0.5), station.rotation.y)
	return true


## Fracht und Licht auf dem Bahnsteig. Ein leerer Bahnsteig sieht aus wie ein Modell, das man
## vergessen hat einzurichten; drei Fassstapel und eine Laterne machen daraus einen Ort, an dem
## gearbeitet wird. Alles im Kollisionsschatten der Halle — nichts davon sperrt zusätzlich,
## sonst steht der Spieler beim Einsteigen im Weg seiner eigenen Kisten.
##
## Die Gaslaterne bekommt ein echtes Licht: Meshy hat die Flamme nur in die Farbtextur gemalt,
## die Emissive-Map ist schwarz (die Aufbereitung hat sie als tote Daten verworfen). Ohne
## `OmniLight3D` wäre die Laterne bei Nacht eine dunkle Stange mit einem hellen Fleck.
func _dress_station(station: Node3D, side: float, poi_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(poi_id)
	var stacks: Array = ["barrels", "barrels_b", "barrels_c"]
	for i in 3:
		var kind: String = stacks[i % stacks.size()]
		var node: Node3D = AssetRegistry.instantiate(kind,
			AssetRegistry.height_of(kind) * rng.randf_range(0.85, 1.15))
		if node == null:
			continue
		node.position = Vector3(side + 1.6 + rng.randf_range(0.0, 1.2),
			0.0, float(i - 1) * 6.0 + rng.randf_range(-1.2, 1.2))
		node.rotation.y = rng.randf() * TAU
		station.add_child(node)
	var lamp: Node3D = AssetRegistry.instantiate("street_lamp", AssetRegistry.height_of("street_lamp"))
	if lamp != null:
		lamp.position = Vector3(side + 1.0, 0.0, -STATION_LEN_M * 0.42)
		station.add_child(lamp)
		var glow := OmniLight3D.new()
		glow.light_color = Color(1.0, 0.72, 0.36)
		glow.light_energy = 2.6
		glow.omni_range = 11.0
		glow.position = Vector3(side + 1.0, AssetRegistry.height_of("street_lamp") * 0.92,
			-STATION_LEN_M * 0.42)
		station.add_child(glow)
	var trough: Node3D = AssetRegistry.instantiate("hitching_post", AssetRegistry.length_of("hitching_post"))
	if trough != null:
		# Quer zur Halle und mit der Trogseite zum Bahnsteig — man tritt von vorn heran.
		trough.position = Vector3(side + 1.4, 0.0, STATION_LEN_M * 0.62)
		trough.rotation.y = PI * 0.5
		station.add_child(trough)


## Platzhalter-Bahnsteig aus Kisten — nur noch in Betrieb, solange `bahnhof.glb` fehlt.
func _build_station_boxes(station: Node3D, side: float) -> void:
	_child_box(station, Vector3(7.0, 0.9, 26.0), Vector3(side, 0.45, 0.0), Color(0.44, 0.38, 0.30))
	for z in [-11.0, 0.0, 11.0]:
		_child_box(station, Vector3(0.5, 3.4, 0.5), Vector3(side + 2.6, 2.6, z), Color(0.30, 0.26, 0.22))
	_child_box(station, Vector3(6.4, 0.4, 26.0), Vector3(side + 0.6, 4.5, 0.0), Color(0.34, 0.28, 0.22))
	var depot_local := Vector3(side + 8.0, 2.5, 8.0)
	_child_box(station, Vector3(9.0, 5.0, 6.0), depot_local, Color(0.38, 0.31, 0.24))
	_solid_rect_rot(station.global_transform * depot_local, Vector2(4.5, 3.0), station.rotation.y)


## Box als Kind eines gedrehten Knotens (lokale Koordinaten) — fuer alles, was an einer
## Trasse oder Fassade ausgerichtet gebaut wird.
func _child_box(parent: Node3D, size: Vector3, local_pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = local_pos
	parent.add_child(mi)
	return mi


## Rustwater. **Liegt `scenes/Rustwater.tscn` vor, ist SIE die Wahrheit** — die Stadt wird dann
## nur noch geladen, nicht gebaut. Genau dafuer ist sie da: Im Editor sieht man jedes Haus,
## kann es anfassen, drehen, verschieben; die Kollision wird beim Start aus den tatsaechlichen
## Positionen abgeleitet, nicht aus Zahlen im Code. Wer ein Haus dazustellt, muss nichts
## programmieren.
##
## Fehlt die Datei, baut der Code die Stadt weiter selbst (`TOWN_LAYOUT`) — das Projekt bleibt
## damit auch ohne die Szene lauffaehig, und der Stadtplan im Code ist die Vorlage, aus der die
## Szene einmal erzeugt wurde.
func _build_township() -> void:
	var c: Vector3 = WorldManager.poi_scene_position("rustwater")
	# Erst die Stadt, dann der Boden: Gepflastert wird nur INNERHALB der Palisade, und wo die
	# steht, weiss erst, wer die Szene geladen hat.
	var umriss := PackedFloat32Array()
	if ResourceLoader.exists(TOWN_SCENE):
		var town: Node3D = (load(TOWN_SCENE) as PackedScene).instantiate()
		town.position = c
		add_child(town)
		var sperren: Array = TownCollision.rects(town, town.transform)
		_register_town_rects(sperren)
		umriss = _wall_outline(sperren, c)
	else:
		_build_township_from_code(c)
	_build_town_ground(c, umriss)
	_label(c + Vector3(TOWER_SPOT.x, 21.0, TOWER_SPOT.y), "RUSTWATER",
		Color(0.95, 0.82, 0.55), LBL_ORT, 350.0)


## Der Umriss der Palisade, als **Radius je Winkel**.
##
## Gebraucht, weil der Kupferboden an der Mauer enden soll und die Mauer kein Kreis ist: Beim
## Umbau von Hand ist sie im Osten weit ausgebeult und im Sueden dicht am Ort. Ein fester Radius
## haette den Boden mal weit in die Wueste hinaus, mal mitten durch die Stadt enden lassen.
##
## Warum Winkel-Eimer und nicht die Mauerstuecke der Reihe nach zu einem Polygon verbinden: Die
## Stuecke stehen in der Szene in beliebiger Reihenfolge und teils verschachtelt, und ein
## Polygon aus falsch sortierten Ecken schlaegt Schlaufen. Der groesste Radius je Winkelfach ist
## gegen beides unempfindlich.
##
## Luecken (das Tor, die offene Ostseite) werden zwischen den nachbarlichen Faechern
## ueberbrueckt — rundherum, ueber die 0°-Grenze hinweg. Sonst laege vor jedem Tor ein Keil
## ohne Boden.
const WALL_BUCKETS: int = 96
func _wall_outline(sperren: Array, c: Vector3) -> PackedFloat32Array:
	var eimer := PackedFloat32Array()
	eimer.resize(WALL_BUCKETS)
	eimer.fill(0.0)
	var besetzt: int = 0
	for r in sperren:
		if not AssetRegistry.is_wall(String(r["asset"])):
			continue
		var p: Vector2 = Vector2(r["c"]) - Vector2(c.x, c.z)
		var laenge: float = p.length()
		if laenge < 1.0:
			continue
		var i: int = int(fposmod(atan2(p.y, p.x), TAU) / TAU * float(WALL_BUCKETS)) % WALL_BUCKETS
		if eimer[i] <= 0.0:
			besetzt += 1
		eimer[i] = maxf(eimer[i], laenge)
	if besetzt < 8:
		return PackedFloat32Array()      # keine erkennbare Mauer — dann eben ohne Umriss
	var voll := PackedFloat32Array(eimer)
	for i in WALL_BUCKETS:
		if eimer[i] > 0.0:
			continue
		# Nachbarn in beide Richtungen suchen und dazwischen linear ueberbruecken.
		var vor: int = 1
		while vor < WALL_BUCKETS and eimer[(i - vor + WALL_BUCKETS) % WALL_BUCKETS] <= 0.0:
			vor += 1
		var nach: int = 1
		while nach < WALL_BUCKETS and eimer[(i + nach) % WALL_BUCKETS] <= 0.0:
			nach += 1
		var a: float = eimer[(i - vor + WALL_BUCKETS) % WALL_BUCKETS]
		var b: float = eimer[(i + nach) % WALL_BUCKETS]
		voll[i] = lerpf(a, b, float(vor) / float(vor + nach))
	return voll


## Umriss an einem Winkel ablesen, zwischen den Faechern geglaettet.
func _outline_at(umriss: PackedFloat32Array, winkel: float) -> float:
	var f: float = fposmod(winkel, TAU) / TAU * float(WALL_BUCKETS)
	var i: int = int(f) % WALL_BUCKETS
	var j: int = (i + 1) % WALL_BUCKETS
	return lerpf(umriss[i], umriss[j], f - floorf(f))


## Der Boden von Rustwater: **verlegte Kupferplatten**, kein Lehm.
##
## Vorher lag hier eine 59-m-Scheibe aus hellem Lehm. Sie hat ihren Zweck erfuellt (die Stadt
## stand nicht mehr auf derselben Wuestenduene wie das Umland), aber zwei Dinge falsch gemacht:
## Sie reichte weit ueber die Palisade hinaus — im Bild von oben eine helle Schuerze um den Ort,
## fuer die es keinen Grund gibt — und sie war eine Flaeche ohne Geschichte. Eine Stadt, die vom
## Schrott lebt, pflastert mit dem, was sie hat.
##
## Verlegt wird als MultiMesh: rund 900 Platten in ZWEI Zeichenaufrufen. Einzelne Knoten waeren
## 900 Objekte, die die Kamera jedes Bild einzeln durchsortiert.
##
## Der Rand loest sich auf, statt zu enden. Ein exakter Kreis aus Kupfer in der Wueste sieht aus
## wie ausgestanzt; im Auslaufband faellt mit wachsendem Abstand jede zweite, dritte, zehnte
## Platte weg, und der Sand nimmt sich den Platz zurueck. Aussen bleibt Wueste — sie ist ja eine.
const PLATE_M: float = 2.6            # Kantenlaenge einer Platte
## Kleiner Zuschlag gegen Fugen. Die grünspanige Platte davor war kein volles Quadrat — schräge
## Kanten, runde Ecken —, und ihr sichtbarer Umriss war so viel kleiner als die Hüllbox, auf die
## `instantiate` skaliert, dass sie 20 % Übermaß brauchte, um zu schließen. Die jetzige Platte
## füllt ihren Grundriss zu 100 % aus (gemessen: alle Rasterzellen belegt), also reichen 5 % für
## den Versatz beim Verlegen.
const PLATE_OVERLAP: float = 1.05
const PLATE_JITTER_M: float = 0.05    # von Hand verlegt, nicht gefraest
## Nur ohne Stadt-Szene gebraucht: Steht die Palisade, endet der Boden an IHR (`_wall_outline`).
const TOWN_FLOOR_R: float = 38.0      # geschlossen gepflastert
const TOWN_FLOOR_FADE: float = 11.0   # darin loest sich die Pflasterung auf
## Oberkante des Stadtbodens ueber dem Gelaende. Steht als Konstante da, weil etwas DARAUF
## liegen muss — und wer den Belag dicker macht, ohne das mitzuziehen, versenkt es. Die Platten
## werden so eingesenkt, dass ihre OBERSEITE genau hier liegt; alles, was auf dem Stadtboden
## liegt (Fussspur, Marken), rechnet weiter mit dieser einen Zahl.
const TOWN_GROUND_TOP: float = 0.08
func _build_town_ground(c: Vector3, umriss := PackedFloat32Array()) -> void:
	# Je Sorte einmal das Modell laden, vermessen und wieder wegwerfen — gebraucht werden nur
	# Netz und Masse, nicht der Knoten.
	var netze: Array = []
	var deckel: Array = []      # Hoehe der begehbaren Plattenflaeche in ihrem eigenen Raum
	var innen: Array = []       # Netz → Modellwurzel: die Kette, die `instantiate` aufbaut
	# EINE Sorte, nicht zwei. Der Wechsel zwischen zwei Platten sollte die Flaeche beleben; im
	# Bild wurde daraus ein Schachbrett aus zwei Brauntoenen, und der Boden las sich als Muster
	# statt als Belag. Die Vielfalt tragen jetzt allein die Vierteldrehungen — dieselbe Platte,
	# vier Lagen. `copper_plate_b` bleibt im Repo; umstellen ist ein Wort.
	for name in ["copper_plate_a"]:
		var probe: Node3D = AssetRegistry.instantiate(name, PLATE_M * PLATE_OVERLAP)
		if probe == null:
			continue
		var mi: MeshInstance3D = null
		for kandidat in AssetRegistry.mesh_instances(probe):
			mi = kandidat as MeshInstance3D
			break
		if mi == null or mi.mesh == null:
			probe.queue_free()
			continue
		# Ein MultiMesh kennt nur NETZE, keine Knoten — die Kette vom Netz bis zur Wurzel muss
		# deshalb ausgerechnet und in jede Instanz-Transform hineingerechnet werden. Genau das
		# hat beim ersten Versuch gefehlt: `instantiate` legt Skalierung, Drehung und das
		# Absetzen auf den Boden auf ZWISCHENknoten, nicht auf das Netz. Ohne diese Kette lagen
		# neunhundert Platten in Originalgroesse und falscher Lage im Sand — im Bild nichts.
		var kette := Transform3D.IDENTITY
		var lauf: Node = mi
		while lauf != null and lauf != probe:
			if lauf is Node3D:
				kette = (lauf as Node3D).transform * kette
			lauf = lauf.get_parent()
		netze.append(mi.mesh)
		innen.append(kette)
		deckel.append(_plate_top(mi.mesh, kette))
		probe.queue_free()
	if netze.is_empty():
		_build_town_ground_lehm(c)
		return

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260802
	var lagen: Array = []
	for _v in netze.size():
		lagen.append([])
	var weiteste: float = TOWN_FLOOR_R + TOWN_FLOOR_FADE
	for v in umriss:
		weiteste = maxf(weiteste, v)
	var n: int = int(ceil(weiteste / PLATE_M))
	for iz in range(-n, n + 1):
		for ix in range(-n, n + 1):
			var raster := Vector2(float(ix) * PLATE_M, float(iz) * PLATE_M)
			var r: float = raster.length()
			if not umriss.is_empty():
				# Mit Palisade: Der Boden endet AN IHR und franst nicht aus. Die Grenze liegt
				# auf der Mauerlinie, nicht davor — eine halbe Platte laeuft also unter die
				# Palisade. Genau so herum ist es richtig: Ein Streifen Sand zwischen Belag und
				# Mauer waere zu sehen, das Stueck Kupfer unter der Mauer nicht.
				if r > _outline_at(umriss, atan2(raster.y, raster.x)):
					continue
			elif r > TOWN_FLOOR_R + TOWN_FLOOR_FADE:
				continue
			elif r > TOWN_FLOOR_R \
					and rng.randf() < (r - TOWN_FLOOR_R) / TOWN_FLOOR_FADE:
				continue
			var v: int = rng.randi_range(0, netze.size() - 1)
			# Vierteldrehungen plus ein Hauch Schiefe: Eine Platte kann in jeder Lage liegen,
			# aber nicht in jedem Winkel — sie stossen ja aneinander.
			var yaw: float = float(rng.randi_range(0, 3)) * (PI * 0.5) \
				+ rng.randf_range(-0.025, 0.025)
			var x: float = c.x + raster.x + rng.randf_range(-PLATE_JITTER_M, PLATE_JITTER_M)
			var z: float = c.z + raster.y + rng.randf_range(-PLATE_JITTER_M, PLATE_JITTER_M)
			var y: float = WorldManager.height_at(x, z) + TOWN_GROUND_TOP - float(deckel[v])
			var platz := Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))
			(lagen[v] as Array).append(platz * (innen[v] as Transform3D))

	var gelegt: int = 0
	var reichweite: float = 0.0
	for liste2 in lagen:
		for t in liste2:
			reichweite = maxf(reichweite,
				Vector2((t as Transform3D).origin.x - c.x, (t as Transform3D).origin.z - c.z).length())
	reichweite += PLATE_M * 0.5
	for v in netze.size():
		var liste: Array = lagen[v]
		if liste.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = netze[v]
		mm.instance_count = liste.size()
		for i in liste.size():
			mm.set_instance_transform(i, liste[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "stadtboden_%d" % v
		# Ein Bodenbelag wirft keinen Schatten, der irgendwo hinfaellt — aber er EMPFAENGT
		# welche. Das Ausschalten spart 900 Instanzen im Schattendurchgang.
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		gelegt += liste.size()
	_town_plates = gelegt
	_town_floor_reach = reichweite


## Hoehe der BEGEHBAREN Flaeche einer Platte — nicht die Oberkante ihrer Huellbox.
##
## Die Platte hat einen erhabenen Rand mit Bolzen und eine vertiefte Mitte; zwischen beidem
## liegen 7,8 cm. Der erste Entwurf hat die HUELLBOX auf den Stadtboden gelegt, damit sass die
## Mitte 7,8 cm tiefer — bei 8 cm Stadtboden also 2 mm ueber dem Wuestenboden, praktisch in
## derselben Ebene. Der Sand hat das Pixelduell gewonnen, und jede Platte bekam einen
## sandfarbenen Fleck in der Mitte. Im Bild sah es aus wie ein Loch; es war eine Hoehe.
##
## Gemessen wird deshalb die Flaeche, auf der man STEHT: der hoechste nach oben zeigende Punkt
## im Ring zwischen 10 % und 40 % der halben Kantenlaenge. Der innerste Zehntel bleibt aussen
## vor (dort sitzt bei manchen Platten ein Bolzen), der Rand ebenso.
##
## Gemessen statt eingetragen, weil eine andere Platte andere Masse hat und niemand daran denken
## wird, hier eine Zahl nachzuziehen.
func _plate_top(mesh: Mesh, innen: Transform3D) -> float:
	var arr: Array = mesh.surface_get_arrays(0)
	var ecken: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var kanten: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	if ecken.is_empty() or kanten.size() < 3:
		return (innen * Vector3.ZERO).y
	var mi: Vector3 = ecken[0]
	var ma: Vector3 = ecken[0]
	for p in ecken:
		mi = Vector3(minf(mi.x, p.x), minf(mi.y, p.y), minf(mi.z, p.z))
		ma = Vector3(maxf(ma.x, p.x), maxf(ma.y, p.y), maxf(ma.z, p.z))
	var mitte_x: float = (mi.x + ma.x) * 0.5
	var mitte_z: float = (mi.z + ma.z) * 0.5
	var halb: float = maxf(ma.x - mi.x, ma.z - mi.z) * 0.5
	# Kein Normalen-Test: In diesem Ring liegen nur Ober- und Unterseite, und das Maximum ist
	# damit die Oberseite. Das ist unempfindlich gegen die Frage, wie herum das Netz gewickelt
	# ist — eine Falle, die in diesem Projekt schon einmal einen halben Tag gekostet hat.
	var hoechste: float = -INF
	var i: int = 0
	while i + 2 < kanten.size():
		var s: Vector3 = (ecken[kanten[i]] + ecken[kanten[i + 1]] + ecken[kanten[i + 2]]) / 3.0
		i += 3
		var d: float = maxf(absf(s.x - mitte_x), absf(s.z - mitte_z))
		if d < halb * 0.10 or d > halb * 0.40:
			continue
		hoechste = maxf(hoechste, s.y)
	if hoechste == -INF:
		hoechste = ma.y
	return (innen * Vector3(0.0, hoechste, 0.0)).y


## Wie viele Platten liegen (0 = die Modelle fehlen, es liegt Lehm).
var _town_plates: int = 0
## Wie weit der Belag reicht. Alles, was auf ihm LIEGT (Fussspur, Marken), muss um seine Dicke
## angehoben werden — und zwar genau dort, wo er ist. Mit der Palisade als Grenze ist das keine
## Konstante mehr, also wird beim Pflastern der groesste vorkommende Abstand gemerkt.
var _town_floor_reach: float = TOWN_FLOOR_R + TOWN_FLOOR_FADE


## Rueckfall ohne Plattenmodelle: die alte Lehmscheibe. Bleibt, damit das Projekt auch mit
## fehlenden Assets startet — dieselbe Regel wie ueberall sonst.
func _build_town_ground_lehm(c: Vector3) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = TOWN_FLOOR_R + TOWN_FLOOR_FADE
	mesh.bottom_radius = TOWN_FLOOR_R + TOWN_FLOOR_FADE
	mesh.height = TOWN_GROUND_TOP
	mesh.radial_segments = 64
	mesh.rings = 1
	disc.mesh = mesh
	disc.position = c + Vector3(0.0, TOWN_GROUND_TOP * 0.5, 0.0)
	var shader: Shader = load("res://shaders/town_ground.gdshader") as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		# Feinstruktur aus der vorhandenen Sand-PBR-Textur uebernehmen, Farbe kommt vom Shader.
		var src: BaseMaterial3D = AssetRegistry.material_from_model("ground_sand")
		if src != null and src.albedo_texture != null:
			mat.set_shader_parameter("albedo_tex", src.albedo_texture)
			mat.set_shader_parameter("has_tex", true)
			if src.normal_texture != null:
				mat.set_shader_parameter("normal_tex", src.normal_texture)
				mat.set_shader_parameter("has_normal", true)
		disc.material_override = mat
	else:
		disc.material_override = _mat(Color(0.80, 0.71, 0.54))
	add_child(disc)


## Traegt Kollision und Beschriftung fuer alles ein, was in der Stadt-Szene steht — egal ob es
## dort seit der Erzeugung liegt oder von Hand dazugestellt wurde. Verschiebt man ein Haus im
## Editor, wandert seine Sperre mit, ohne dass hier eine Zahl steht.
##
## Die Ableitung selbst steht in `TownCollision`, weil der Test sie ohne die gebaute Welt
## braucht: Er rastert Rustwater ab und faellt durch, sobald eine Flaeche nicht mehr erreichbar
## ist. Hier bleibt nur das Eintragen.
func _register_town(town: Node3D) -> void:
	_register_town_rects(TownCollision.rects(town, town.transform))


## Wie `_register_town`, aber mit bereits abgeleiteten Sperren — der Aufbau der Stadt braucht
## sie ohnehin ein zweites Mal (fuer den Umriss der Palisade) und soll sie nicht zweimal
## ausrechnen.
func _register_town_rects(sperren: Array) -> void:
	for r in sperren:
		_solid_rect_rot(Vector3(r["c"].x, 0.0, r["c"].y), r["h"], float(r["yaw"]))
		var text: String = String(r["label"])
		if text != "":
			_label(Vector3(r["c"].x, float(r["deckel"]) + 2.2, r["c"].y), text,
				Color(0.98, 0.90, 0.72), LBL_HAUS, 150.0)


## Rueckfall: Stadt aus dem Stadtplan im Code bauen (Stand vor `Rustwater.tscn`).
func _build_township_from_code(c: Vector3) -> void:
	for b in TOWN_LAYOUT:
		var pos: Vector3 = c + Vector3(b[2].x, 0.0, b[2].y)
		var size: Vector3 = _place_building(String(b[1]), pos, deg_to_rad(float(b[3])),
			b[4], Color(b[5]))
		if String(b[0]) != "":
			_label(pos + Vector3(0.0, size.y + 2.2, 0.0), String(b[0]),
				Color(0.98, 0.90, 0.72), LBL_HAUS, 150.0)
	var shacks: Array = []
	for suffix in ["a", "b", "c", "d"]:
		if AssetRegistry.has_model("shack_" + suffix):
			shacks.append("shack_" + suffix)
	for i in SHACK_SPOTS.size():
		var spot: Vector2 = SHACK_SPOTS[i]
		var pos: Vector3 = c + Vector3(spot.x, 0.0, spot.y)
		var yaw: float = deg_to_rad(CAM_YAW + (7.0 if i % 2 == 0 else -9.0))
		var asset: String = "" if shacks.is_empty() else String(shacks[i % shacks.size()])
		_place_building(asset, pos, yaw, Vector3(6.0, 4.2, 5.0), Color(0.42, 0.33, 0.24))


## Setzt ein Gebaeude ab und traegt seine Kollision ein. Liefert die tatsaechliche Groesse
## zurueck (fuer die Hoehe der Beschriftung). `fallback` ist die Ersatzbox, falls kein Modell
## vorliegt; `extra_scale` variiert baugleiche Haeuser.
func _place_building(asset: String, pos: Vector3, yaw: float, fallback: Vector3,
		color: Color, extra_scale: float = 1.0) -> Vector3:
	var model: Node3D = null
	if asset != "":
		model = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset) * extra_scale)
	if model == null:
		_solid_box(fallback, pos + Vector3(0.0, fallback.y / 2.0, 0.0), color)
		return fallback
	model.position = pos
	model.rotation.y = yaw
	add_child(model)
	# Kollision aus dem gemessenen Modell. Etwas kleiner als die Bounding-Box, weil Vordaecher,
	# Schornsteine und Anbauten darin stecken — man soll am Haus entlanglaufen koennen, nicht
	# an dessen Luftraum.
	var size: Vector3 = AssetRegistry.local_bounds(model).size
	_solid_rect_rot(pos, Vector2(size.x, size.z) * 0.5 * BUILDING_COLLISION_SHRINK, yaw)
	return size




# ── NPCs & Quests ─────────────────────────────────────────────────────────────

func _build_npcs() -> void:
	var c: Vector3 = WorldManager.poi_scene_position("rustwater")
	for n in TOWN_NPCS:
		var spot: Vector2 = n[2]
		var pos: Vector3 = c + Vector3(spot.x, 0.0, spot.y)
		var node := Node3D.new()
		var asset: String = "npc_" + String(n[0])
		var model: Node3D = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset))
		if model != null:
			node.add_child(model)
			# `Stand_and_Chat` — die drei stehen an ihrem Platz und reden mit Leuten.
			AssetRegistry.play_clip(model, "idle")
		else:
			var body := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.42
			cap.height = 1.7
			body.mesh = cap
			body.material_override = _mat(n[3])
			body.position = Vector3(0.0, 0.85, 0.0)
			node.add_child(body)
		node.position = pos
		# Die NPCs schauen zur Stadtmitte, wie die Gebäude — nicht in die Wüste hinaus.
		# Zur Straßenmitte schauen (x = 0), wie die Häuser hinter ihnen — nicht zum Stadtplatz.
		node.rotation.y = PI * 0.5 if spot.x < 0.0 else -PI * 0.5
		add_child(node)
		var label: Label3D = _label(pos + Vector3(0.0, 2.5, 0.0), String(n[1]), Color(0.98, 0.94, 0.82), LBL_FIGUR, 140.0)
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
## Bestimmt, was gerade in Reichweite ist, und baut die Aktionsleiste danach auf. Neu gebaut
## wird nur bei WECHSEL des Kontexts — sonst wuerde die Leiste sechzigmal pro Sekunde entstehen
## und waere nicht anklickbar.
func _process_interactions(_delta: float) -> void:
	var ctx: String = ""
	var npc: Dictionary = _npc_in_range()
	var station: String = _station_at_player()
	var chest: Dictionary = _chest_in_range()
	var gear: Dictionary = _gear_in_range()
	# Reihenfolge = Dringlichkeit: Was man aufheben kann, geht vor dem Schwatz. Der Kontext ist
	# ein String, weil die Leiste nur bei WECHSEL neu gebaut wird — bei der Ausruestung gehoert
	# deshalb das Fundstueck selbst hinein, sonst bliebe der Knopf beim Wechsel zum naechsten
	# Stueck auf dem alten Namen stehen.
	if not chest.is_empty():
		ctx = "chest:%d" % _chests.find(chest)
	elif not gear.is_empty():
		ctx = "gear:%d" % _ground.find(gear)
	elif not npc.is_empty():
		ctx = "npc:" + String(npc["giver"])
	elif station != "":
		ctx = "station:" + station
	if ctx == _ctx:
		return
	_ctx = ctx
	# Erst aus dem Baum nehmen, dann freigeben: `queue_free` allein wirkt erst am Frame-Ende,
	# die alten Knöpfe stuenden also noch unter den neuen.
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	if ctx.begins_with("chest:"):
		_add_action("✋  Truhe öffnen   [E]", _open_chest.bind(_chest_in_range()))
	elif ctx.begins_with("gear:"):
		_add_action("✋  %s aufheben   [E]" % String(_gear_in_range()["data"]["name"]), _pick_up_gear)
	elif ctx.begins_with("npc:"):
		_add_action("🗣  %s ansprechen   [E]" % String(npc["name"]),
			_talk_to.bind(String(npc["giver"])))
		# Die Laeden haengen an den LEUTEN, nicht an ihren Haeusern. Zwei Gruende: Die Stadt
		# wird von Hand umgestellt, ein Haus kann also morgen woanders stehen — die NPCs setzt
		# `TOWN_NPCS` im Code. Und Destille und Labor haben noch gar kein Modell, waeren als
		# Anlaufstelle also unerreichbar.
		if String(npc["giver"]) == "silas":
			_add_action("🔨  Werkstatt", _open_shop.bind(ShopScreen.Mode.WERKSTATT))
		elif String(npc["giver"]) == "mabel":
			_add_action("💰  Geschäfte", _open_shop.bind(ShopScreen.Mode.WIRTSCHAFT))
	elif ctx.begins_with("station:"):
		_add_action("🚂  Iron Rail — Ziel wählen", Callable())
		for i in FAST_TRAVEL.size():
			var id: String = String(FAST_TRAVEL[i])
			if id == station:
				continue
			_add_action("   %d  %s" % [i + 1, String(WorldManager.poi(id)["name"])],
				_fast_travel.bind(i))


## Naechster NPC in Gespraechsreichweite ({} = keiner).
func _npc_in_range() -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = NPC_INTERACT_M
	for n in _npcs:
		var d: float = _player.position.distance_to(n["pos"])
		if d < best_d:
			best_d = d
			best = n
	return best


## Eine Schaltflaeche in der Aktionsleiste. Ohne `action` ist es nur eine Ueberschrift.
func _add_action(text: String, action: Callable) -> void:
	if not action.is_valid():
		var head := Label.new()
		head.text = text
		head.add_theme_font_size_override("font_size", 15)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_actions.add_child(head)
		return
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 38.0)   # Daumengroesse, nicht Mausgroesse
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(action)
	_actions.add_child(btn)


## Ein Gespraech. Vorher lief das AUTOMATISCH beim Vorbeilaufen — man wurde angequatscht, statt
## zu entscheiden. Jetzt braucht es den Knopf (oder [E]).
func _talk_to(giver: String) -> void:
	var npc: Dictionary = {}
	for n in _npcs:
		if String(n["giver"]) == giver:
			npc = n
	if npc.is_empty():
		return
	var qid: String = _quest_for_giver(giver)
	if qid == "":
		_talk(npc, giver, _npc_line(giver, "idle"))
		return
	var def: Dictionary = QuestManager.QUESTS[qid]
	var title: String = String(def["title"])
	var st: String = QuestManager.get_quest_state(qid)
	if st == QuestManager.STATE_AVAILABLE:
		if QuestManager.accept_quest(qid):
			var goal: String = ("%d Gegner erlegen" % int(def["count"])) if String(def["kind"]) == "kill" \
				else ("%dx %s sammeln" % [int(def["count"]), String(def["item"])])
			# WOHIN gehoert in denselben Satz wie WAS. Vorher stand hier „8 Gegner erlegen" und
			# man drehte sich danach in einer 5 km breiten Wueste um sich selbst.
			var ziel: String = QuestManager.quest_target(qid)
			var wohin: String = ""
			if ziel != "" and WorldManager.has_poi(ziel):
				var d: int = roundi(_player.position.distance_to(
					WorldManager.poi_scene_position(ziel)))
				wohin = "\n🧭 %s — %d m. Der Spur folgen." % [String(WorldManager.poi(ziel)["name"]), d]
			_talk(npc, giver, "%s\n\n📜 „%s“ — %s%s"
				% [_npc_line(giver, "offer"), title, goal, wohin])
		else:
			_say("🔒 „%s“ ist noch nicht verfügbar." % title, 2.5)
	elif QuestManager.is_quest_complete(qid):
		var gold_before: int = GameState.gold
		if QuestManager.complete_quest(qid):
			_talk(npc, giver, "%s\n\n✅ „%s“ — +%d Gold"
				% [_npc_line(giver, "done"), title, GameState.gold - gold_before])
			sfx_equip()
		else:
			_say("Hm — die Abgabe wurde abgelehnt.", 2.5)
	else:
		var p: Dictionary = QuestManager.check_quest_progress(qid)
		_talk(npc, giver, "%s\n\n📜 „%s“: %d/%d"
			% [_npc_line(giver, "wait"), title, int(p["current"]), int(p["target"])])


## Ein Gespraech zeigen: Sprechtafel unten, Nahaufnahme dazu, beide drehen sich zueinander.
##
## EINE Stelle fuer alle vier Faelle (nichts zu tun, annehmen, warten, abgeben). Vorher stand in
## jedem Zweig ein eigenes `_say(...)` mit eigener Anzeigedauer, und die Nahaufnahme kam nur bei
## zweien davon — Mabel drehte sich also mal zum Spieler und mal nicht, je nachdem, ob gerade
## eine Quest anstand.
##
## Die Tafel laeuft OHNE Zeitlimit und die Aufnahme mit: Solange der Text steht, bleibt auch das
## Bild. Beendet wird beides zusammen — durch Tippen, durch eine Taste, oder von selbst, wenn
## `CLOSEUP_SEC` abgelaufen ist.
const CLOSEUP_SEC: float = 5.5
func _talk(npc: Dictionary, giver: String, text: String) -> void:
	if _dialog != null:
		_dialog.show_line(String(npc["name"]), text, giver)
	_play_closeup(npc["node"] as Node3D, CLOSEUP_SEC)


## Die Stimmen aus der Story-Bibel (GDD §4). Nach dem Reveal reden alle drei anders mit einem —
## sie wissen dann, dass unter dem Mantel ein Automat steckt.
func _npc_line(giver: String, kind: String) -> String:
	var revealed: bool = GameState.is_revealed
	match giver:
		"mabel":
			if kind == "offer":
				return "„Setz dich, Kind. Aber vorher…“" if not revealed else "„Für dich hab ich Schmieröl statt Schnaps.“"
			if kind == "done":
				return "„Du bist zäher, als du aussiehst.“"
			if kind == "wait":
				return "„Die Wüste frisst Leute wie dich zum Frühstück.“"
			return "„Trink was, Fremder. Geht aufs Haus.“"
		"silas":
			if kind == "offer":
				return "„Diese Stadt frisst Material.“"
			if kind == "done":
				return "„Gute Arbeit. Das hält.“"
			if kind == "wait":
				return "„Ohne Schrott keine Mauer.“"
			return "„Mein Auge sieht mehr als deins, Fremder.“" if not revealed else "„Chassis-Platten? Für dich zum Selbstkostenpreis.“"
		"doc":
			if kind == "offer":
				return "„Die Viecher kommen aus den Rohren.“"
			if kind == "done":
				return "„Eine Plage weniger.“"
			if kind == "wait":
				return "„Zähl die Kadaver, nicht die Stunden.“"
			return "„Halt dich von den Ratten fern.“" if not revealed else "„Bei dir spar ich mir das Verarzten.“"
	return "„…“"


# ── Die Fußspur: der Wegweiser am Boden ───────────────────────────────────────
## Diablo löst die Frage „wohin jetzt?" mit zwei Mitteln, und wir übernehmen beide: eine Marke
## auf der Karte und eine leuchtende Spur am Boden. Die Marke beantwortet die Frage, wenn man
## die Karte aufmacht — die Spur beantwortet sie, ohne dass man sie aufmacht. Das ist der
## eigentliche Gewinn: Man läuft und wird geführt, statt zu laufen und nachzusehen.
##
## Bewusst KEINE Wegfindung. Die Welt ist offen, es gibt zwischen zwei Orten keine Hindernisse
## außer dem Strahlensumpf — und den umgeht `WorldManager.swamp_detour()`. Ein A* über 5 km
## Wüste wäre viel Maschinerie für eine gerade Linie.
##
## Die Spur läuft dem Spieler VORAUS und endet nach 30 m. Eine Spur bis zum Ziel wäre bei 1200 m
## Entfernung ein leuchtender Strich durch die halbe Welt — und würde die Reise erzählen, statt
## sie stattfinden zu lassen.
## Und die Spur STEHT. Der erste Versuch hat die vierzehn Abdrücke jeden Frame neu vor die Figur
## gerechnet — damit klebten sie am Spieler und glitten mit ihm über den Sand. Es sind aber
## Abdrücke: Sie gehören dem Boden, nicht dem Läufer. Sie schweben nicht in der Gegend herum.
##
## Deshalb hängt die Spur jetzt an einem **Anker** in der Welt. Zwischen zwei Schritten bewegt
## sich kein einziger Abdruck. Erst wenn der Spieler einen ganzen Schrittabstand zurückgelegt
## hat, rückt der Anker um genau diesen Abstand vor und richtet sich neu aufs Ziel aus: Vorn
## kommt ein Abdruck dazu, hinten verschwindet einer unter den Füßen. Man LÄUFT die Spur ab,
## statt sie vor sich herzuschieben.
const TRAIL_STEPS: int = 16        # Anzahl Abdrücke ≈ 33 m Vorlauf
const TRAIL_SPACING_M: float = 2.1 # Abstand von Abdruck zu Abdruck
const TRAIL_SIDE_M: float = 0.34   # links/rechts versetzt — sonst ist es eine Linie, kein Gang
## Weicht man so weit seitlich vom Anker ab, wird neu angesetzt. Ohne das zeigt die Spur noch in
## die Richtung, in die man vor zwanzig Metern gelaufen ist.
const TRAIL_DRIFT_M: float = 2.5
## Unter den Füßen blendet ein Abdruck aus, statt zu verschwinden. Ein Abdruck, der einen Meter
## vor der Figur wegploppt, ist auffälliger als einer, der nie da war.
const TRAIL_FADE_NEAR_M: float = 2.6
## Näher als das ist man da; dann verschwindet die Spur. Ein Wegweiser, der noch zeigt, wenn man
## schon steht, sieht aus wie ein Fehler.
const TRAIL_ARRIVED_M: float = 14.0
## Ein Abdruck ist eine VERTIEFUNG, also dunkel. Vorher war er ein gelbes Leuchtzeichen — auf
## dem hellen Stadtboden von Rustwater war davon nichts zu sehen, und draussen sah es aus, als
## schwebten Lichter ueber dem Sand. Jetzt liegt eingedrueckte Erde am Boden, und durch sie
## laeuft ein warmer Puls: Der traegt die Richtung, ohne dass der Abdruck aufhoert, einer zu sein.
const TRAIL_DUNKEL: Color = Color(0.22, 0.14, 0.06)
const TRAIL_HELL: Color = Color(0.98, 0.78, 0.34)
var _trail: Array = []             # MeshInstance3D je Abdruck
var _trail_mats: Array = []        # je Abdruck ein eigenes Material (für die Laufwelle)
var _trail_anker: Vector3 = Vector3.INF   # Weltpunkt, an dem der erste Abdruck liegt
var _trail_dir: Vector3 = Vector3.FORWARD # Richtung der Spur, wird beim Vorrücken erneuert
var _trail_paritaet: int = 0              # linker oder rechter Fuß zuerst


func _build_trail() -> void:
	# Ein Abdruck ist ein Viereck, kein Modell: 2 Dreiecke gegen ein Netz mit Textur. Bei
	# vierzehn Stück, die jeden Frame umgesetzt werden, zählt das.
	for i in TRAIL_STEPS:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.46, 0.88)
		mi.mesh = q
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(TRAIL_DUNKEL, 0.75)
		# Liegt eine Sohle (`footprint.png`), wird aus dem Viereck ein echter Abdruck. Die
		# Textur ist weiss und traegt nur die Deckung — die Farbe kommt aus `albedo_color`,
		# damit die Laufwelle weiter ueber `albedo_color.a` gesteuert werden kann.
		var sohle: Texture2D = UiAssets.texture("footprint")
		if sohle != null:
			m.albedo_texture = sohle
			var s_gr: Vector2 = sohle.get_size()
			q.size = Vector2(0.46 * (s_gr.x / maxf(s_gr.y, 1.0)), 0.88)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# Nicht in den Tiefenpuffer schreiben: Der Abdruck liegt 6 cm über dem Sand und würde
		# sonst mit ihm um jedes Pixel streiten (Z-Fighting), sobald das Gelände ansteigt.
		m.no_depth_test = false
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		# Beidseitig. Ein waagerechtes Viereck, dessen Normale versehentlich nach unten zeigt,
		# ist unsichtbar — genau dieser Fehler hat schon einmal den ganzen Weltboden ins
		# Umgebungslicht gelegt. Bei vierzehn Vierecken kostet doppelseitig nichts.
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.rotation.x = -PI * 0.5    # flach auf den Boden legen
		mi.visible = false
		mi.name = "trail_%d" % i
		add_child(mi)
		_trail.append(mi)
		_trail_mats.append(m)


## Wohin zeigt die Spur gerade? (Szenenposition; `Vector3.INF` = nirgendwohin.)
##
## Zwischenziel vor Endziel: Liegt der Sumpf im Weg, führt die Spur erst um ihn herum. Sonst
## zöge das Spiel eine leuchtende Linie mitten durch die Todeszone — und der Spieler folgte ihr,
## weil das Spiel sie gezeichnet hat.
func _trail_goal() -> Vector3:
	var qid: String = QuestManager.tracked_quest()
	if qid == "":
		return Vector3.INF
	var ziel: String = QuestManager.quest_target(qid)
	if ziel == "" or not WorldManager.has_poi(ziel):
		return Vector3.INF
	var hier: Vector2 = WorldManager.scene_to_world(_player.position)
	var dort: Vector2 = WorldManager.poi_position(ziel)
	var umweg: Vector2 = WorldManager.swamp_detour(hier, dort)
	if umweg != Vector2.INF:
		return WorldManager.world_to_scene(umweg)
	return WorldManager.poi_scene_position(ziel)


## Hoehe, auf der ein FLACHER Marker liegen muss, damit man ihn sieht.
##
## `height_at` allein reicht nicht: In Rustwater liegt ueber dem Gelaende noch die Stadtscheibe
## (Oberkante `TOWN_GROUND_TOP`). Genau daran ist die Fussspur beim ersten Versuch gescheitert —
## vierzehn Abdruecke, alle korrekt gesetzt, alle `visible`, und im Bild nichts: Sie lagen bei
## 0,06 und damit zwei Zentimeter UNTER dem Stadtboden. Vom Rechnen an den Zahlen war das nicht
## zu sehen; erst ein Wuerfel an derselben Stelle, der brav erschien, hat es verraten.
const DECAL_LIFT_M: float = 0.06
func _decal_height(x: float, z: float) -> float:
	var boden: float = WorldManager.height_at(x, z)
	var stadt: Vector3 = WorldManager.poi_scene_position("rustwater")
	if Vector2(x - stadt.x, z - stadt.z).length() <= _town_floor_reach:
		boden += TOWN_GROUND_TOP
	return boden + DECAL_LIFT_M


func _process_trail(_delta: float) -> void:
	if _trail.is_empty() or _player == null:
		return
	var ziel: Vector3 = _trail_goal()
	var sichtbar: bool = ziel != Vector3.INF and not _overlay_open()
	if sichtbar:
		var flach := Vector3(ziel.x - _player.position.x, 0.0, ziel.z - _player.position.z)
		if flach.length() < TRAIL_ARRIVED_M:
			sichtbar = false
		else:
			_advance_trail(flach.normalized())
			var quer := Vector3(-_trail_dir.z, 0.0, _trail_dir.x)
			for i in _trail.size():
				var mi: MeshInstance3D = _trail[i]
				var seite: float = TRAIL_SIDE_M * (1.0 if (i + _trail_paritaet) % 2 == 0 else -1.0)
				var p: Vector3 = _trail_anker + _trail_dir * (float(i) * TRAIL_SPACING_M) \
					+ quer * seite
				mi.position = Vector3(p.x, _decal_height(p.x, p.z), p.z)
				# Der Abdruck liegt flach; gedreht wird um die Hochachse in Laufrichtung.
				# Godots Vorne ist −Z, deshalb die negierten Komponenten — mit `atan2(x, z)`
				# zeigten alle Zehen nach hinten, und die Spur wies aus dem Ziel heraus.
				mi.rotation = Vector3(-PI * 0.5, atan2(-_trail_dir.x, -_trail_dir.z), 0.0)
				# Ein- und Ausblenden nach ECHTER Entfernung zum Spieler, nicht nach Platznummer:
				# Die Abdrücke stehen still, also wandert der Spieler durch sie hindurch — und
				# was er erreicht, muss unter ihm verlöschen statt wegzuploppen.
				var d: float = Vector2(p.x - _player.position.x, p.z - _player.position.z).length()
				var nah: float = smoothstep(0.0, TRAIL_FADE_NEAR_M, d)
				var fern: float = 1.0 - smoothstep(0.55, 1.0,
					d / (float(TRAIL_STEPS) * TRAIL_SPACING_M))
				# KEINE Laufwelle. Der erste Entwurf liess die Helligkeit vom Spieler weg
				# wandern — als Richtungsanzeige gedacht, im Bild ein Blinken. Ein Abdruck im
				# Boden blinkt nicht; die Richtung tragen die Zehen, dafuer zeigen sie hin.
				# Die Helligkeit haengt jetzt nur noch an der ENTFERNUNG: nah warm, fern
				# verlaufend. Das ist ueber die Zeit konstant und wandert mit dem Laeufer.
				var hell: float = 1.0 - smoothstep(0.0, 0.7, d / (float(TRAIL_STEPS) * TRAIL_SPACING_M))
				var m: StandardMaterial3D = _trail_mats[i]
				m.albedo_color = Color(TRAIL_DUNKEL.lerp(TRAIL_HELL, hell * 0.55), nah * fern * 0.9)
	for mi2 in _trail:
		(mi2 as MeshInstance3D).visible = sichtbar


## Rückt den Anker nach, wenn der Spieler einen Schritt gegangen ist — und nur dann.
##
## Zwei Fälle setzen neu an statt vorzurücken: der erste Frame (es gibt noch keinen Anker) und
## eine zu große seitliche Abweichung. Ohne den zweiten Fall zeigt die Spur nach einem Bogen
## noch dorthin, wo das Ziel vor zwanzig Metern lag.
func _advance_trail(dir: Vector3) -> void:
	var quer := Vector3(-_trail_dir.z, 0.0, _trail_dir.x)
	if _trail_anker == Vector3.INF \
			or absf((_player.position - _trail_anker).dot(quer)) > TRAIL_DRIFT_M:
		_trail_anker = _player.position
		_trail_dir = dir
		return
	var vor: float = (_player.position - _trail_anker).dot(_trail_dir)
	if vor < 0.0:
		# Rückwärts gelaufen: Der Anker darf nicht hinter dem Spieler bleiben.
		_trail_anker = _player.position
		_trail_dir = dir
		return
	# Mehrere Schritte auf einmal kommen beim Schnellreisen vor; dann wird ohnehin neu angesetzt,
	# sobald die Abweichung zu groß ist. Die Schleife ist deshalb gedeckelt.
	var schritte: int = mini(int(vor / TRAIL_SPACING_M), TRAIL_STEPS)
	if schritte <= 0:
		return
	_trail_anker += _trail_dir * (float(schritte) * TRAIL_SPACING_M)
	_trail_paritaet = (_trail_paritaet + schritte) % 2
	_trail_dir = dir


## Nächsten laufenden Auftrag verfolgen. Absichtlich auch bei offenem Overlay erlaubt: Man
## schaut auf die Karte, sieht zwei Marken und will umschalten, ohne sie zuzumachen.
func _cycle_tracked_quest() -> void:
	var laufend: Array = QuestManager.active_quests()
	if laufend.is_empty():
		_say("📜 Kein laufender Auftrag. Sprich in Rustwater mit Mabel, Silas oder Doc.", 3.0)
		return
	if laufend.size() == 1:
		_say("📜 Nur ein Auftrag läuft: „%s“"
			% String(QuestManager.QUESTS[QuestManager.tracked_quest()]["title"]), 2.5)
		return
	var neu_id: String = QuestManager.track_next()
	if neu_id == "":
		return
	var ziel: String = QuestManager.quest_target(neu_id)
	var wohin: String = String(WorldManager.poi(ziel)["name"]) if ziel != "" else "—"
	_say("🧭 Verfolgt: „%s“ → %s" % [String(QuestManager.QUESTS[neu_id]["title"]), wohin], 3.0)


## Zeile für den HUD-Quest-Tracker: der VERFOLGTE Auftrag mit Fortschritt und Wegangabe.
##
## Vorher stand hier nur „Kopfgeld: Wegelagerer 3/8". Das sagt, WAS zu tun ist, und verschweigt
## das Einzige, was man in einer 5 km breiten Wüste wirklich braucht: wo. Jetzt steht der Ort
## und die Entfernung daneben — dieselbe Information, die auch die Marke auf der Karte und die
## Fußspur am Boden tragen, nur in Worten.
func _active_quest_line() -> String:
	var qid: String = QuestManager.tracked_quest()
	if qid == "":
		return ""
	var def: Dictionary = QuestManager.QUESTS[qid]
	var p: Dictionary = QuestManager.check_quest_progress(qid)
	var fertig: bool = bool(p["complete"])
	var zeile: String = "%s %s  %d/%d" % ["✔" if fertig else "▸", String(def["title"]),
		int(p["current"]), int(p["target"])]
	var ziel: String = QuestManager.quest_target(qid)
	if ziel != "" and WorldManager.has_poi(ziel):
		var d: int = roundi(_player.position.distance_to(WorldManager.poi_scene_position(ziel)))
		# „abgeben bei" statt „nach", sobald das Ziel erfüllt ist: Der Ort ist derselbe Kasten
		# im HUD, aber die Aufgabe ist eine andere.
		zeile += "   %s %s (%d m)" % ["💰 abgeben bei" if fertig else "🧭 nach",
			String(WorldManager.poi(ziel)["name"]), d]
	var laufend: int = QuestManager.active_quests().size()
	if laufend > 1:
		zeile += "   [Q] wechseln (%d)" % laufend
	return zeile


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
		# Zielgröße ist die LÄNGSTE Kante (AssetRegistry.TARGET_LENGTH), nicht die Höhe: die
		# CC0-Steine sind flache Geröllfelder — über die Höhe skaliert wurden aus „kleinen
		# Sandsteinen" zehn Meter breite Platten, die halb Rustwater verdeckt haben.
		var rock: Node3D = AssetRegistry.instantiate(kind,
			AssetRegistry.length_of(kind) * rng.randf_range(0.7, 1.5))
		if rock == null:
			continue
		var ang: float = rng.randf() * TAU
		# Große Felsen gehören in die Ferne, nicht vor das Stadttor: aus zehn Metern Entfernung
		# füllt eine Felsnase den Bildschirm und wirkt wie ein Bauwerk. Je größer das Stück,
		# desto weiter weg beginnt sein Streubereich.
		var near: float = TOWN_SAFE_M + 15.0 + AssetRegistry.length_of(kind) * 12.0
		var dist: float = rng.randf_range(near, 700.0)
		var pos: Vector3 = origin + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		# Nicht in die Smog-Zone streuen und im Kraterbecken bleiben.
		pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
		pos.z = clampf(pos.z, -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT), -20.0)
		# Weder in der Stadt noch auf Piste/Trasse — die Wege sollen frei und lesbar bleiben.
		if _in_town(pos) or _auf_trasse(pos):
			rock.queue_free()
			continue
		rock.position = pos
		rock.rotation.y = rng.randf() * TAU
		add_child(rock)


## Wüsten-Requisiten: Kakteen, Tierskelette, verwehte Schrotthaufen.
##
## Getrennt von `_scatter_decor`, obwohl beide streuen — die Regeln sind andere. Ein Felsen
## darf ueberall liegen; ein Kaktus, der mitten auf der Piste steht, sieht aus wie ein Fehler,
## und ein Skelett gehoert an den Wegrand, wo man es SIEHT. Die Wegnaehe ist hier also ein
## Ziel und kein Ausschlusskriterium.
const PROP_SCATTER_COUNT: int = 64
const PROP_SCATTER_R_M: float = 620.0
func _scatter_props() -> void:
	# Gewichte statt Gleichverteilung: Kakteen praegen die Wueste, Skelette sind der seltene
	# Fund, an dem man kurz stehenbleibt. Gleich verteilt waere die Wueste ein Beinhaus.
	var kinds: Array = [
		["cactus", 5], ["cactus", 5], ["bones", 1], ["bones_b", 1],
		["scrap_heap", 2], ["scrap_heap_b", 2],
	]
	var pool: Array = []
	for k in kinds:
		if AssetRegistry.has_model(String(k[0])):
			for _i in int(k[1]):
				pool.append(String(k[0]))
	if pool.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	var origin: Vector3 = WorldManager.poi_scene_position("rustwater")
	for i in PROP_SCATTER_COUNT:
		var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
		var goal: float = AssetRegistry.length_of(kind)
		if goal <= 0.0:
			goal = AssetRegistry.height_of(kind)
		var node: Node3D = AssetRegistry.instantiate(kind, goal * rng.randf_range(0.75, 1.35))
		if node == null:
			continue
		var ang: float = rng.randf() * TAU
		var dist: float = rng.randf_range(TOWN_SAFE_M + 18.0, PROP_SCATTER_R_M)
		var pos: Vector3 = origin + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		pos.x = clampf(pos.x, 20.0, WorldManager.WORLD_METERS - 20.0)
		pos.z = clampf(pos.z, -(float(WorldManager.SMOG_LINE_Y) * WorldManager.METERS_PER_UNIT), -20.0)
		if _in_town(pos) or _auf_trasse(pos):
			node.queue_free()
			continue
		pos.y = WorldManager.height_at(pos.x, pos.z)   # Senken mitnehmen, sonst schwebt es
		node.position = pos
		node.rotation.y = rng.randf() * TAU
		add_child(node)
		# Nur der Kaktus sperrt. Ein Skelett tritt man beiseite, einen Schrotthaufen ueber-
		# steigt man — aber in einen zwei Meter dicken Saeulenkaktus laeuft niemand hinein.
		if kind == "cactus":
			_solid_pillar(pos, 0.9)


## Füllt jede Geländesenke mit dem, wonach sie benannt ist — bei der Schrotthalde also mit
## Schrott. Vorlage sind die Bilder, die der Auftraggeber geschickt hat: eine Grube, deren
## Grund von Rand zu Rand unter Metall verschwindet, mit einer Lache in der Mitte.
##
## Der Unterschied zur ersten Fassung ist nicht die Menge, sondern die ART der Verteilung.
## Vorher standen 26 Stücke einzeln herum, jedes auf dem Boden, jedes für sich erkennbar —
## das liest sich als „hier wurde etwas abgestellt". Ein Schrotthaufen liest sich erst als
## Haufen, wenn drei Dinge zusammenkommen:
##
##  1. **Kein Boden mehr sichtbar.** Deshalb wird nicht gestreut, sondern in drei Lagen
##     gefüllt: große Brocken, mittleres Zeug dazwischen, Kleinkram als Lückenfüller.
##  2. **Überlappung.** Die Stücke dürfen ineinanderstecken. Ein Mindestabstand — der erste
##     Reflex — erzeugt genau das Raster, das man vermeiden will.
##  3. **Teilweise vergraben.** Jedes Stück sinkt um 15–45 % seiner Höhe in den Grund. Ohne
##     das steht alles mit der Unterkante auf einer gemeinsamen Ebene, und die Ebene sieht
##     man sofort — sie verrät, dass da nichts liegt, sondern etwas platziert wurde.
##
## Gefüllt wird nur der FLACHE Grund plus ein Stück Wandfuß. Die Wand selbst bleibt frei:
## Bei 66° würde jedes Fass wie angeklebt aussehen.
## Die drei Lagen. Die Zahlen sind ein Kompromiss mit dem Dreiecksbudget: 80 Stücke kosten
## rund 190 000 Dreiecke, und das ist für den einen Ort, an dem das Spiel anfängt, vertretbar
## — für die Wüste daneben wäre es das nicht.
const CRATER_LAYERS: Array = [
	# n = Anzahl, min/max = Größe als Anteil der Normalgröße, sink = Einsinken (Anteil Höhe)
	{ "n": 22, "min": 0.95, "max": 1.55, "sink": [0.10, 0.30] },   # große Brocken
	{ "n": 44, "min": 0.50, "max": 0.90, "sink": [0.15, 0.40] },   # mittleres Zeug
	{ "n": 62, "min": 0.22, "max": 0.46, "sink": [0.20, 0.55] },   # Kleinkram in den Lücken
]
## Radius der Lache am tiefsten Punkt. Sie ist der einzige freie Fleck — und der Ort, an dem
## der Held erwacht, weil man dort als Einziges liegen kann.
const PUDDLE_R_M: float = 2.1
func _fill_craters() -> void:
	# Zuerst die von Hand gefuellten Gruben: Liegt eine Szene vor, wird sie GELADEN statt
	# gestreut — dieselbe Regel wie bei Rustwater.
	for f2 in WorldManager.TERRAIN:
		var id2: String = String(f2.get("id", ""))
		if _hand_gefuellt(id2):
			_load_pit(id2)
	var pool: Array = _scrap_pool()
	if pool.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	for f in WorldManager.TERRAIN:
		if String(f.get("kind", "crater")) != "crater":
			continue   # in ein Duenenfeld gehoert kein Schrott
		if not bool(f.get("scrap", true)):
			continue   # und in die Sumpfloecher auch nicht — dort liegt Wasser
		if _hand_gefuellt(String(f.get("id", ""))):
			continue   # von Hand gefuellt — die Szene ist die Wahrheit (wie bei Rustwater)
		_fill_crater(f, pool, rng)


## Eine einzelne Grube fuellen. Steht getrennt, weil zwei Aufrufer sie brauchen: der Weltaufbau
## und das Backwerkzeug, das aus derselben Streuung eine editierbare Szene macht.
func _fill_crater(f: Dictionary, pool: Array, rng: RandomNumberGenerator) -> void:
	var c: Vector3 = WorldManager.feature_center(f)
	var radius: float = float(f["radius"])
	# Bis an den Wandfuß plus ein Meter: Der Schrott soll die Wand berühren, nicht davor
	# aufhören. Eine sichtbare Fuge zwischen Haufen und Wand wäre das Verräterischste.
	var reichweite: float = radius * float(f.get("floor", 0.8)) + 1.0
	_add_puddle(c, f)
	_place_wreck(c, reichweite, rng)
	for lage in CRATER_LAYERS:
		for i in int(lage["n"]):
			_drop_scrap(c, reichweite, pool, lage, rng)
	_dress_rim(c, f, rng)


## Eine von Hand gefuellte Grube laden.
##
## Die Teile stehen in WELTkoordinaten (siehe `PitFloor`), die Wurzel bleibt also bei null.
##
## Kollision bekommt nur, was HOCH ist. Eine Schrotthalde, in der jedes Fass sperrt, ist keine
## Halde, sondern ein Labyrinth — man soll darueber steigen koennen. Ein dreizehn Meter langes
## Lokomotivenwrack dagegen laeuft man nicht durch. Die Grenze steht als Zahl da, damit man sie
## verschieben kann, ohne die Regel zu suchen.
const PIT_BLOCK_H_M: float = 1.5
func _load_pit(id: String) -> void:
	var packed: PackedScene = load(pit_scene_path(id)) as PackedScene
	if packed == null:
		return
	var grube: Node3D = packed.instantiate() as Node3D
	if grube == null:
		return
	add_child(grube)
	# Die Lache bleibt Sache des Codes, nicht der Bearbeitungsszene: Sie haengt an der Form des
	# Kraters (tiefster Punkt, Radius) und nicht am Geschmack dessen, der die Halde fuellt.
	for f in WorldManager.TERRAIN:
		if String(f.get("id", "")) == id:
			_add_puddle(WorldManager.feature_center(f), f)
			break
	for r in TownCollision.rects(grube, grube.transform):
		# `deckel` ist die Oberkante ueber Grund; darunter liegt Kleinkram, ueber den man geht.
		if float(r["deckel"]) - WorldManager.height_at(r["c"].x, r["c"].y) < PIT_BLOCK_H_M:
			continue
		_solid_rect_rot(Vector3(r["c"].x, 0.0, r["c"].y), r["h"], float(r["yaw"]))


## Szenendatei einer von Hand gefuellten Grube ("" = es gibt keine).
static func pit_scene_path(id: String) -> String:
	return "res://scenes/gruben/%s.tscn" % id


func _hand_gefuellt(id: String) -> bool:
	return id != "" and ResourceLoader.exists(pit_scene_path(id))


## Das eine grosse Stueck: eine gestrandete Werkslok, halb im Schutt.
##
## Eine Halde aus lauter gleich grossen Teilen hat keinen Massstab — man sieht einen Teppich
## und weiss nicht, ob er knietief oder haushoch ist. Ein Wrack von dreizehn Metern beantwortet
## das in dem Augenblick, in dem man ueber den Kraterrand schaut, und gibt der Grube ausserdem
## eine Mitte, auf die man zulaeuft.
##
## Am RAND des Grundes, nicht in der Mitte: Die Mitte gehoert der Lache, in der der Held
## erwacht. Ein Wrack quer darueber waere die Kulisse fuer eine andere Geschichte.
const WRECK_SINK: float = 0.22        # Anteil der Hoehe, der im Schutt steckt
func _place_wreck(c: Vector3, reichweite: float, rng: RandomNumberGenerator) -> void:
	if not AssetRegistry.has_model("locomotive"):
		return
	var lok: Node3D = AssetRegistry.instantiate("locomotive")
	if lok == null:
		return
	var ang: float = rng.randf() * TAU
	var dist: float = reichweite * 0.55
	var pos := Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
	pos.y = WorldManager.height_at(pos.x, pos.z)
	pos.y -= maxf(AssetRegistry.local_bounds(lok).size.y * lok.scale.y, 0.1) * WRECK_SINK
	lok.position = pos
	# Quer zur Blickrichtung aus der Grubenmitte: So sieht man ihre ganze Laenge, nicht die
	# Stirnseite. Leicht gekippt, weil sie liegt und nicht parkt.
	lok.rotation.y = ang + PI * 0.5 + rng.randf_range(-0.35, 0.35)
	lok.rotation.z = deg_to_rad(rng.randf_range(6.0, 14.0))
	lok.rotation.x = deg_to_rad(rng.randf_range(-5.0, 5.0))
	add_child(lok)


## Ein Stück Schrott an eine zufällige Stelle des Grundes.
func _drop_scrap(c: Vector3, reichweite: float, pool: Array, lage: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var kind: String = pool[rng.randi_range(0, pool.size() - 1)]
	var basis: float = AssetRegistry.length_of(kind)
	if basis <= 0.0:
		basis = AssetRegistry.height_of(kind)
	var groesse: float = basis * rng.randf_range(float(lage["min"]), float(lage["max"]))
	var node: Node3D = AssetRegistry.instantiate(kind, groesse)
	if node == null:
		return
	# `sqrt` verteilt gleichmäßig über die FLÄCHE. Ohne die Wurzel drängt sich alles in der
	# Mitte und der Rand des Grundes bleibt kahl — bei einem Teppich fällt das sofort auf.
	var ang: float = rng.randf() * TAU
	var dist: float = sqrt(rng.randf()) * reichweite
	var pos := Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
	# Nur die Lache selbst bleibt frei, nicht ein Ring darum: Der Schnitt liegt INNERHALB des
	# Lachenrands, sodass Stuecke von aussen hineinragen duerfen. Sonst zieht sich ein
	# makellos runder Freiraum durch den Haufen, und ein makelloser Kreis ist das Letzte, was
	# in einer Schuttgrube liegt.
	if Vector2(pos.x - c.x, pos.z - c.z).length() < PUDDLE_R_M * 0.72:
		return
	pos.y = WorldManager.height_at(pos.x, pos.z)
	var hoehe: float = maxf(AssetRegistry.local_bounds(node).size.y, 0.05)
	pos.y -= hoehe * rng.randf_range(float(lage["sink"][0]), float(lage["sink"][1]))
	node.position = pos
	node.rotation.y = rng.randf() * TAU
	# Kippen: nicht nach der Hangneigung wie bisher (der Grund ist flach), sondern zufällig.
	# Geworfenes Metall liegt schief; alles waagerecht wirkt wie ein Regal.
	node.rotation.x = deg_to_rad(rng.randf_range(-26.0, 26.0))
	node.rotation.z = deg_to_rad(rng.randf_range(-26.0, 26.0))
	add_child(node)


## Sparsame Fassungen bevorzugen. Ein Stück Schrott liegt hier hundertfach — bei 12.000
## Dreiecken je Haufen wäre allein die Grube teurer als die ganze übrige Welt. Die `_lod`-
## Dateien sind dieselben Modelle mit 1.400 Dreiecken und 512er Textur; aus zehn Metern
## Entfernung, in einem Haufen aus dreißig anderen, sieht man den Unterschied nicht.
func _scrap_pool() -> Array:
	var pool: Array = []
	# Gewichtet nach KOSTEN, nicht nur nach Optik. Die beiden Schrotthaufen bleiben auch
	# reduziert bei 6.600 bzw. 3.600 Dreiecken haengen — die Reduktion kommt dort nicht weiter,
	# weil die Modelle aus vielen losen Einzelteilen bestehen und jede Bruchkante als Rand
	# geschuetzt wird. Die Fass-Stapel gehen dagegen sauber auf 1.400 herunter. Also liegen
	# mehr Faesser als Haufen in der Grube; im Gewirr faellt das nicht auf.
	# `bones` ist raus: kein sparsamer Zwilling, und ein Tierskelett gehoert in die Wueste,
	# nicht in eine Grube voller Maschinenteile.
	# Dazu der Sperrmüll: Regal, Schreibtisch, Bürostuhl, Ölfass, Stacheldraht, Rostmedaillon,
	# Betonplatte. Sie haben keinen sparsamen Zwilling, sind aber von vornherein knapp gebaut
	# (2.500–9.000 Dreiecke) und liegen einzeln statt zu Dutzenden — der Gewichtungswert 1 hält
	# ihre Zahl klein. Ihr Beitrag ist nicht Masse, sondern UNGLEICHHEIT: Bis hierher lagen in
	# der Grube fünf Sorten in hundert Kopien, und aus zehn Metern Höhe war das ein Muster.
	for zusatz in ["shelf", "desk", "office_chair", "oil_barrel", "barbed_wire",
			"medallion", "monolith"]:
		if AssetRegistry.has_model(zusatz):
			pool.append(zusatz)
	for eintrag in [["scrap_heap", 2], ["scrap_heap_b", 3], ["barrels", 4], ["barrels_b", 4],
			["barrels_c", 4]]:
		var name: String = String(eintrag[0])
		# Rostfassung zuerst, dann die sparsame, dann das volle Modell. Zwei Drittel der
		# Stuecke sollen rostig sein — die Vorlage ist ein Haufen Metall, kein Holzlager.
		for kandidat in [[name + "_rust_lod", 2], [name + "_lod", 1]]:
			var wie: String = String(kandidat[0])
			if not AssetRegistry.has_model(wie):
				continue
			for _i in int(eintrag[1]) * int(kandidat[1]):
				pool.append(wie)
		if pool.is_empty() and AssetRegistry.has_model(name):
			for _i in int(eintrag[1]):
				pool.append(name)
	return pool


## Steine auf der Lippe. In der Vorlage ist der Rand der Grube kein sauberer Kreis, sondern
## aufgebrochene Erde mit losem Geroell — daran erkennt man, dass hier etwas eingebrochen ist
## und nicht jemand ein Loch ausgehoben hat.
func _dress_rim(c: Vector3, f: Dictionary, rng: RandomNumberGenerator) -> void:
	var sorten: Array = []
	for k in ["rock_small", "rock_boulder"]:
		if AssetRegistry.has_model(k):
			sorten.append(k)
	if sorten.is_empty():
		return
	var radius: float = float(f["radius"])
	for i in 22:
		var kind: String = sorten[rng.randi_range(0, sorten.size() - 1)]
		# Klein halten: Bei voller Groesse standen dort helle Findlinge, die groesser waren als
		# die Faesser in der Grube — das las sich als Steinbruch, nicht als abgebrochene Kante.
		var node: Node3D = AssetRegistry.instantiate(kind,
			AssetRegistry.length_of(kind) * rng.randf_range(0.18, 0.45))
		if node == null:
			continue
		var ang: float = rng.randf() * TAU
		# Genau auf dem Wall, nicht davor und nicht dahinter: dort, wo die Kante bricht.
		var dist: float = radius * rng.randf_range(1.02, 1.0 + float(f["rim_width"]) * 0.9)
		var pos := Vector3(c.x + cos(ang) * dist, 0.0, c.z + sin(ang) * dist)
		pos.y = WorldManager.height_at(pos.x, pos.z) - 0.15   # etwas eingesunken
		node.position = pos
		node.rotation.y = rng.randf() * TAU
		node.rotation.x = deg_to_rad(rng.randf_range(-15.0, 15.0))
		node.rotation.z = deg_to_rad(rng.randf_range(-15.0, 15.0))
		add_child(node)


## Stehendes Wasser am tiefsten Punkt — Regen, Öl und was aus dem Metall läuft.
##
## Der einzige waagerechte, spiegelnde Fleck in einer Grube voller stumpfem Rost: Genau
## deshalb zieht er den Blick auf die Mitte, und genau dort soll der Held liegen.
func _add_puddle(c: Vector3, f: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = PUDDLE_R_M
	disc.bottom_radius = PUDDLE_R_M
	disc.height = 0.04
	disc.radial_segments = 24
	mi.mesh = disc
	var m := StandardMaterial3D.new()
	# Nicht schwarz: Ein schwarzer Fleck im hellen Sand liest sich als LOCH, nicht als Wasser.
	# Ein bisschen Eigenfarbe, mittlere Rauheit und etwas Metallic ergeben einen breiten
	# Glanz statt eines Spiegels — und Glanz ist es, was eine Pfuetze im Bild ausmacht.
	m.albedo_color = Color(0.14, 0.13, 0.10)
	m.metallic = 0.40
	m.roughness = 0.22
	m.rim_enabled = true
	m.rim = 0.6
	mi.mesh.surface_set_material(0, m)
	mi.position = Vector3(c.x, WorldManager.height_at(c.x, c.z) + 0.02, c.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _rustwater_spawn() -> Vector3:
	return WorldManager.poi_scene_position("rustwater") + RUSTWATER_SPAWN_OFFSET


func _build_player() -> void:
	_player = Node3D.new()
	# Modell, sobald eines unter assets/models/characters/player.glb liegt — sonst Kapsel.
	var model: Node3D = AssetRegistry.instantiate("player", AssetRegistry.height_of("player"))
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
	_equip_weapon_model()
	_cam = Camera3D.new()
	# Kamera nach Diablo-Immortal-Referenz eingemessen: enges Sichtfeld (Godots Standard-75°
	# zieht die Welt auseinander und lässt die Figur winzig wirken), feste Neigung, feste
	# Gierung für den isometrischen Eindruck.
	#
	# WICHTIG — die Kamera hängt NICHT am Spieler-Node: sie würde sonst dessen Drehung erben und
	# sich beim Laufen mitdrehen. Genau das macht Diablo nicht: dort ist die Blickrichtung fix,
	# die Welt behält ihre Orientierung, und nur die Figur dreht sich. Deshalb steht die Kamera
	# in der Szene und folgt dem Spieler in `_process_camera` **nur in der Position**.
	_cam.fov = CAM_FOV
	_cam.rotation_degrees = Vector3(-CAM_PITCH, CAM_YAW, 0.0)
	_cam.far = 8000.0   # Kraterrand & Herz bleiben trotzdem am Horizont sichtbar (Landmark-Navigation)
	add_child(_cam)
	_cam_dist = float(CAM_ZOOM_STEPS[_zoom_step()])
	_cam.position = _player.position + _cam_offset(_cam_dist)


## Hängt das Waffenmodell in die rechte Hand der Figur. Das Spieler-Rig bringt Gewehr-Clips mit
## („Rifle_Charge", „Run_and_Shoot") — die Hand ist also dafür gedacht, etwas zu halten.
##
## Sitz und Griffwinkel lassen sich nicht ausrechnen: wo genau eine generierte Waffe in einer
## generierten Hand liegt, sieht man nur. `WEAPON_GRIP_*` sind deshalb bewusst drei Zahlen an
## einer Stelle, keine verstreute Magie.
func _equip_weapon_model() -> void:
	if _player_model == null:
		return
	var skel: Skeleton3D = AssetRegistry.skeleton(_player_model)
	if skel == null:
		return
	var idx: int = skel.find_bone(WEAPON_BONE)
	if idx < 0:
		return
	var weapon: Node3D = AssetRegistry.instantiate("weapon_karabiner", 0.0, false)
	if weapon == null:
		return
	var att := BoneAttachment3D.new()
	att.bone_name = WEAPON_BONE
	skel.add_child(att)
	att.add_child(weapon)
	# Vom Mesh-Raum der Figur in den Knochenraum — dieselbe Brücke wie bei jedem Anbauteil,
	# sonst stimmt der Maßstab nicht (das Rig steht in Zentimetern, das Modell in Metern).
	# Die Waffe wird an die Hand GESETZT (Ursprung = Griff), nicht wie ein Mantel im Mesh-Raum
	# der Figur platziert. Gebraucht wird deshalb nur der Maßstab: Ein Knochenraum, dessen Rig
	# in Zentimetern steht, misst pro Einheit rund einen Zentimeter — ein Meter Waffe braucht
	# dort also den Faktor 100. Das rechnet die Skelett-Skalierung exakt aus, ohne Raterei.
	var unit: float = 1.0 / maxf(skel.global_transform.basis.get_scale().x, 0.0001)
	# `fitted` trägt die Skalierung auf Zielgröße aus `instantiate()` und muss erhalten bleiben —
	# ein direktes Überschreiben von `transform` verwirft sie.
	var fitted: Transform3D = weapon.transform
	weapon.transform = Transform3D(
		Basis.from_euler(WEAPON_GRIP_ROT).scaled(Vector3.ONE * unit),
		WEAPON_GRIP_OFFSET * unit) * fitted
	_weapon_model = weapon


var _hud_layer: CanvasLayer
func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_layer = layer
	_hud = Label.new()
	_hud.position = Vector2(14.0, 10.0)
	_hud.add_theme_font_size_override("font_size", 15)
	layer.add_child(_hud)
	# Ortsschrift: Beim Betreten eines Ortes zieht sein Name gross und gesperrt ueber die Mitte
	# und blendet wieder weg. Kostet nichts und macht aus einem Punkt auf der Karte einen Ort,
	# an dem man ANGEKOMMEN ist — genau die Einblendung aus den Diablo-Vorlagen.
	_zone_lbl = Label.new()
	_zone_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_zone_lbl.position = Vector2(-300.0, -40.0)
	_zone_lbl.custom_minimum_size = Vector2(600.0, 0.0)
	_zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_lbl.add_theme_font_size_override("font_size", 34)
	_zone_lbl.add_theme_constant_override("outline_size", 6)
	_zone_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	_zone_lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_zone_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_zone_lbl)
	# Die Meldungszeile bekommt eine feste Breite und wird um die halbe davon nach links
	# gerückt. Ohne das beginnt sie in der Bildmitte und wächst mit dem Text nach rechts aus
	# dem Bild heraus — gemessen ragte sie bei 1152 px Fensterbreite 260 px darüber hinaus.
	_dialog = DialogBox.new()
	_dialog.dismissed.connect(_end_cine)
	layer.add_child(_dialog)
	_toast = Label.new()
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -TOAST_W * 0.5
	_toast.offset_right = TOAST_W * 0.5
	_toast.offset_top = 64.0
	_toast.add_theme_font_size_override("font_size", 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(_toast)
	# Minikarte oben rechts — Nahansicht im 200-m-Umkreis (Minimap.LOCAL_RADIUS_M).
	_minimap = Minimap.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.position = Vector2(-Minimap.MAP_PX - 14.0, 12.0)
	layer.add_child(_minimap)
	# Joystick-Anzeige ganz oben drüber (zeichnet nur, wenn gezogen wird).
	_stick = VirtualStick.new()
	_stick.radius = STICK_RADIUS
	layer.add_child(_stick)
	# Schuss-Knopf unten rechts — die Gegenhand zum Joystick unten links.
	_fire_btn = FireButton.new()
	layer.add_child(_fire_btn)
	# Munitionsanzeige direkt darunter (GDD §7.4.0): Der Vorrat gehoert dorthin, wo der Daumen
	# ohnehin hinschaut — gelb bei Knappheit, rot bei leer.
	_ammo_lbl = Label.new()
	_ammo_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_ammo_lbl.position = Vector2(-FireButton.RADIUS * 2.0 - FireButton.MARGIN, -FireButton.MARGIN + 4.0)
	_ammo_lbl.custom_minimum_size = Vector2(FireButton.RADIUS * 2.0, 0.0)
	_ammo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ammo_lbl.add_theme_font_size_override("font_size", 15)
	layer.add_child(_ammo_lbl)
	# Aktionsleiste unten Mitte: erscheint nur, wenn etwas in Reichweite ist. Ohne sie gäbe es
	# auf dem Handy keinen Weg, jemanden anzusprechen oder die Bahn zu nehmen — das ging bisher
	# nur über die Tastatur, also ausgerechnet nicht auf der Zielplattform.
	_actions = VBoxContainer.new()
	_actions.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_actions.position = Vector2(-140.0, -168.0)
	_actions.custom_minimum_size = Vector2(280.0, 0.0)
	_actions.add_theme_constant_override("separation", 6)
	layer.add_child(_actions)
	# Zoom-Knoepfe unter der Minikarte. Auf dem Handy der verlaessliche Weg — die Kneifgeste
	# gibt es zwar, aber beide Daumen liegen dort meist auf Joystick und Abzug.
	_zoom_btns = HBoxContainer.new()
	_zoom_btns.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_zoom_btns.position = Vector2(-Minimap.MAP_PX - 14.0, 12.0 + Minimap.MAP_PX + 8.0)
	_zoom_btns.add_theme_constant_override("separation", 6)
	for entry in [["－", -1], ["＋", 1]]:
		var zb := Button.new()
		zb.text = String(entry[0])
		zb.custom_minimum_size = Vector2(46.0, 42.0)
		zb.add_theme_font_size_override("font_size", 19)
		zb.pressed.connect(_zoom_by.bind(int(entry[1])))
		_zoom_btns.add_child(zb)
		_hud_buttons.append(zb)
	layer.add_child(_zoom_btns)
	# Charakter-Knopf oben links unter der Statuszeile. Ohne ihn waere der Bildschirm auf dem
	# Handy unerreichbar — dort gibt es kein [C].
	_char_btn = Button.new()
	_char_btn.text = "🎽"
	_char_btn.tooltip_text = "Ausrüstung & Fähigkeiten [C]"
	_char_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_char_btn.position = Vector2(14.0, 84.0)
	_char_btn.custom_minimum_size = Vector2(52.0, 46.0)
	_char_btn.add_theme_font_size_override("font_size", 20)
	_char_btn.pressed.connect(_toggle_character)
	layer.add_child(_char_btn)
	_hud_buttons.append(_char_btn)
	# Weltkarte ZULETZT: In einem CanvasLayer ist die Kindreihenfolge die Zeichenreihenfolge,
	# und eine Vollbildkarte, unter der die Aktionsleiste hervorlugt, ist keine.
	_build_world_map(layer)
	_shop = ShopScreen.new()
	layer.add_child(_shop)
	_char = CharacterScreen.new()
	layer.add_child(_char)


## Vollbild-Weltkarte: liegt fertig gebaut, aber unsichtbar über allem und geht per Tippen auf
## die Minikarte auf (oder mit M). Bewusst NICHT bei jedem Öffnen neu gebaut — die Karte zeichnet
## sich ohnehin bei jedem Frame neu, und ein Aufbau pro Öffnen wäre ein Ruckler ohne Gegenwert.
func _build_world_map(layer: CanvasLayer) -> void:
	_map_overlay = Control.new()
	_map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_overlay.visible = false
	layer.add_child(_map_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.04, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_overlay.add_child(dim)
	_world_map = Minimap.new()
	_world_map.full_world = true   # vor add_child: `_ready` wertet das Flag aus
	_map_overlay.add_child(_world_map)
	var hint := Label.new()
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-180.0, -46.0)
	hint.custom_minimum_size = Vector2(360.0, 0.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.text = "Tippen oder M schließt die Karte"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_overlay.add_child(hint)


func _map_is_open() -> bool:
	return _map_overlay != null and _map_overlay.visible


## Aktuelle Zoomstufe, gegen die Tabelle geklemmt — ein Altstand koennte einen Index tragen,
## den es nicht mehr gibt.
func _zoom_step() -> int:
	return clampi(GameState.cam_zoom, 0, CAM_ZOOM_STEPS.size() - 1)


## Zoomstufe setzen. Meldet die Stufe nur, wenn sie sich wirklich aendert — beim Kneifen
## kaeme sonst pro Frame eine Einblendung.
func _set_zoom(step: int) -> void:
	var neu: int = clampi(step, 0, CAM_ZOOM_STEPS.size() - 1)
	if neu == _zoom_step():
		return
	GameState.cam_zoom = neu
	_say("🔍 %s (%.1f m)" % [String(CAM_ZOOM_NAMES[neu]), float(CAM_ZOOM_STEPS[neu])], 1.2)


func _zoom_by(delta_steps: int) -> void:
	_set_zoom(_zoom_step() + delta_steps)


## Liegt IRGENDEIN Vollbild-Overlay ueber der Welt? Karte und Laden sperren beide dasselbe:
## Bewegung und Abzug. Eine gemeinsame Abfrage, damit ein spaeter dazukommender Bildschirm
## nicht wieder an zwei Stellen nachgetragen werden muss.
func _overlay_open() -> bool:
	return _map_is_open() or (_shop != null and _shop.visible) or (_char != null and _char.visible)


## Blendet aus, was sonst UEBER dem Overlay stehenbliebe. Die Aktionsleiste und der Schuss-Knopf
## sind eigene Controls; Zeichenreihenfolge allein genuegt bei ihnen nicht.
func _set_hud_hidden(hidden: bool) -> void:
	if _actions != null:
		_actions.visible = not hidden
	if _fire_btn != null:
		_fire_btn.visible = not hidden
	if _ammo_lbl != null:
		_ammo_lbl.visible = not hidden
	if _char_btn != null:
		_char_btn.visible = not hidden
	if _zoom_btns != null:
		_zoom_btns.visible = not hidden


## Oeffnet Werkstatt oder Geschaefte.
func _open_shop(which: int) -> void:
	if _shop == null:
		return
	_close_world_map()
	_shop.open(which)
	_end_stick()
	_set_hud_hidden(true)


func _close_shop() -> void:
	if _shop != null:
		_shop.close()
	_set_hud_hidden(false)


## Charakter-Bildschirm. Der einzige, der an keinem Ort haengt: Was man traegt und kann, geht
## einen ueberall etwas an.
func _toggle_character(which: int = CharacterScreen.Tab.AUSRUESTUNG) -> void:
	if _char == null:
		return
	if _char.visible:
		_close_character()
		return
	_close_world_map()
	_close_shop()
	_char.open(which)
	_end_stick()
	_set_hud_hidden(true)


func _close_character() -> void:
	if _char != null:
		_char.close()
	_set_hud_hidden(false)


## Beide Karten bekommen denselben Stand — die Nahansicht und die Weltkarte sind dieselbe
## Klasse und unterscheiden sich nur in Mittelpunkt und Maßstab.
func _feed_map(map: Minimap, enemies: Array) -> void:
	if map == null:
		return
	map.player_pos = _player.position
	map.player_dir = _player.rotation.y
	map.enemy_positions = enemies
	map.queue_redraw()


## Öffnet die Weltkarte und misst sie dabei auf den aktuellen Bildschirm ein. Die Messung
## gehört hierher und nicht in den Aufbau: Auf dem Handy dreht sich das Gerät, und eine beim
## Start berechnete Größe wäre nach dem ersten Drehen falsch.
func _open_world_map() -> void:
	if _map_overlay == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var s: float = minf(vp.x, vp.y) * 0.82
	_world_map.size = Vector2(s, s)
	_world_map.position = (vp - Vector2(s, s)) * 0.5
	_map_overlay.visible = true
	# Der Joystick darf nicht mit gedrücktem Daumen hängenbleiben, sonst läuft die Figur unter
	# der offenen Karte weiter.
	_end_stick()
	# Die Aktionsleiste zeichnet trotz Zeichenreihenfolge weiter ihre Knöpfe: Sie ist ein
	# eigenes Control und würde als Streifen über der Karte stehenbleiben. Der Schuss-Knopf
	# genauso — und ein sichtbarer Abzug, der nichts auslöst, sieht nach Fehler aus.
	_set_hud_hidden(true)


func _close_world_map() -> void:
	if _map_overlay != null:
		_map_overlay.visible = false
	_set_hud_hidden(false)


## Der Lebensbalken ist ein STRICH, kein Balken.
##
## Vorher war es ein Quader von 1,40 × 0,12 × 0,12 m über jedem Kopf — bei einer 1,8-m-Figur ein
## fingerdickes Brett, das breiter war als der Gegner und aus jeder Richtung Volumen zeigte.
## Ein Zustandsanzeiger soll man lesen, nicht ansehen. Jetzt: 4,5 cm hoch, immer zur Kamera
## gedreht (also nie schräg oder von der Kante), auf einem dunklen Untergrund, damit der Rest-
## anteil auch vor hellem Sand ablesbar bleibt.
const HP_BAR_W: float = 1.0
const HP_BAR_H: float = 0.045
const HP_BAR_RAND: float = 0.018


## Ein Streifen der Lebensleiste. `versatz` schiebt ihn minimal nach vorn, damit die Füllung
## nicht mit ihrem eigenen Untergrund um Bildpunkte streitet.
##
## Mittig verankert, nicht linksbündig: Die Leiste ist auf die Kamera gedreht, ihr Ursprung
## bleibt aber im Raum des Gegners. Ein Anker am linken Ende säße damit auf einem Punkt, der
## mitschwenkt, sobald sich der Gegner dreht — die Leiste würde beim Umdrehen seitlich
## weglaufen. Der Restanteil schrumpft deshalb symmetrisch.
func _hp_streifen(breite: float, hoehe: float, farbe: Color, versatz: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(breite, hoehe)
	q.center_offset = Vector3(0.0, 0.0, versatz)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if farbe.a < 1.0 \
		else BaseMaterial3D.TRANSPARENCY_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Baut einen Gegner-Node (Modell oder Primitive + Lebensleiste), fügt ihn NICHT in die Szene
## ein (Aufrufer setzt zuerst die Position) und trägt ihn NICHT in `_enemies` ein.
func _make_enemy(type_id: String) -> Dictionary:
	var target: CombatTarget = CombatTarget.from_type(type_id)
	var node := Node3D.new()
	# Modell, sobald eines unter assets/models/enemies/<typ>.glb liegt — sonst Primitive.
	var asset: String = AssetRegistry.enemy_asset(type_id)
	var model: Node3D = AssetRegistry.instantiate(asset, AssetRegistry.height_of(asset))
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
	# Leiste über den Kopf des jeweiligen Gegners — bei einem 4-m-Goliath steckte eine feste
	# Höhe sonst mitten im Modell.
	var traeger := Node3D.new()
	traeger.position = Vector3(0.0, AssetRegistry.height_of(asset) + 0.32, 0.0)
	node.add_child(traeger)
	# Der Untergrund ist der VERLORENE Teil, nicht bloss ein Rand: Ein Strich, der nur kuerzer
	# wird, sagt „wenig"; einer, hinter dem dunkles Rot steht, sagt „so viel ist schon weg".
	traeger.add_child(_hp_streifen(HP_BAR_W + HP_BAR_RAND * 2.0, HP_BAR_H + HP_BAR_RAND * 2.0,
		Color(0.24, 0.05, 0.04, 0.88), 0.0))
	var bar: MeshInstance3D = _hp_streifen(HP_BAR_W, HP_BAR_H, Color(0.52, 0.80, 0.09), 0.004)
	traeger.add_child(bar)
	# Bringt das Modell eine Lauf-Animation mit? Wenn nicht, übernimmt `_scurry` die Bewegung —
	# sonst gleitet die Figur reglos über den Sand, was bei einem Rudel besonders auffällt.
	var animated: bool = model != null \
		and AssetRegistry.find_clip(AssetRegistry.animation_player(model), "walk") != ""
	# Trefferradius aus der Zielhoehe des Modells: Ein Kessel-Klaeffer (0,8 m) ist ein deutlich
	# kleineres Ziel als der Schwere Ernter (4 m), und genau das soll die Streuung spueren.
	# Gedeckelt, damit weder eine Ratte unmoeglich noch ein Boss trivial wird.
	var radius: float = clampf(AssetRegistry.height_of(asset) * 0.30, 0.32, 1.40)
	# `windup` = −1 heisst „holt gerade nicht aus", `cooldown` zaehlt bis zum naechsten Angriff.
	# Beide gehoeren in den Gegner, nicht in eine Nebenliste: Ein Gegner, der stirbt, nimmt
	# seinen halb ausgefuehrten Schlag mit.
	return { "node": node, "target": target, "bar": bar, "model": model,
		"animated": animated, "phase": randf() * TAU, "radius": radius,
		"windup": -1.0, "cooldown": 0.0 }


func _spawn_pack() -> void:
	# Der erste Kontakt steht direkt VOR dem Südtor — Rustwater ist befriedet (TOWN_SAFE_M),
	# drinnen spawnt nichts, also gehört das Empfangskomitee dorthin, wo man beim Verlassen
	# der Stadt hinschaut. Danach übernimmt der kontinuierliche Spawner.
	var gate: Vector3 = WorldManager.poi_scene_position("rustwater") + Vector3(0.0, 0.0, TOWN_SAFE_M + 12.0)
	for i in 4:
		var type_id: String = "klaeffer" if i == 3 else "outlaw"
		var e: Dictionary = _make_enemy(type_id)
		(e["node"] as Node3D).position = gate + Vector3(float(i) * 5.0 - 7.5, 0.0, float(i % 2) * 6.0)
		add_child(e["node"])
		_enemies.append(e)
	# Dahinter eine Panzer-Rotte: schwerer, langsamer, aus der Ferne als Silhouette erkennbar —
	# und die zweite Welle, wenn das Rudel liegt.
	for i in STARTER_TANKS:
		var e: Dictionary = _make_enemy("konstrukt")
		(e["node"] as Node3D).position = gate + Vector3(float(i) * 9.0 - 9.0, 0.0, 22.0 + float(i % 2) * 7.0)
		add_child(e["node"])
		_enemies.append(e)


## Setzt ein Rudel um `center` ab (locker gestreut, nicht auf einem Punkt gestapelt).
## Kappe und Bauten-Sperre gelten pro Tier — lieber ein kleinerer Schwarm als einer in der Wand.
func _spawn_swarm(type_id: String, center: Vector3) -> void:
	var count: int = mini(randi_range(SWARM_MIN, SWARM_MAX), ENEMY_MAX - _enemies.size())
	for i in count:
		var a: float = randf() * TAU
		var r: float = randf_range(0.8, SWARM_SPREAD_M)
		var pos: Vector3 = center + Vector3(cos(a) * r, 0.0, sin(a) * r)
		if _blocked(pos):
			continue
		var e: Dictionary = _make_enemy(type_id)
		(e["node"] as Node3D).position = pos
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
	# Schwarm-Typen (CombatData: Ratten, Kläffer) treten NIE einzeln auf — einzeln sind sie
	# weder gefährlich noch schön, im Rudel sind sie beides. Die Kappe gilt weiterhin.
	if bool(CombatData.ENEMY_TYPES[type_id].get("swarm", false)):
		_spawn_swarm(type_id, pos)
		return
	var e: Dictionary = _make_enemy(type_id)
	(e["node"] as Node3D).position = pos
	add_child(e["node"])
	_enemies.append(e)


## Truhen einmalig setzen: eine am Mittelpunkt jedes Ortes AUSSER Rustwater. Zehn Stueck auf
## 5000 x 5000 m — das ist die Seltenheit, die eine Truhe wieder zu einem Fund macht. Der
## Heimathafen bleibt leer: Beute holt man sich draussen.
func _build_chests() -> void:
	for id in WorldManager.POIS.keys():
		if String(id) == "rustwater":
			continue
		_spawn_chest_at(WorldManager.poi_scene_position(String(id)))


func _spawn_chest_at(raw: Vector3) -> void:
	var pos: Vector3 = Vector3(raw.x, WorldManager.height_at(raw.x, raw.z), raw.z)
	var node := Node3D.new()
	var model: Node3D = AssetRegistry.instantiate("chest", AssetRegistry.height_of("chest"))
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
	var label: Label3D = _label(pos + Vector3(0.0, 1.3, 0.0), "📦 Truhe", Color(1.0, 0.85, 0.4), LBL_TRUHE, 120.0)
	_chests.append({ "node": node, "label": label, "pos": pos, "looted": false, "cd": 0.0 })


## Ortsschrift. Sperrt den Namen mit Leerzeichen, damit er wie eine Inschrift wirkt und nicht
## wie eine Beschriftung, und blendet ihn ueber vier Sekunden ein und wieder aus.
##
## Ausgeloest wird beim WECHSEL der Zone — beim Verlassen genauso wie beim Betreten, damit die
## offene Wueste auch als Ort benannt ist. Wer an der Grenze hin und her laeuft, bekommt sie
## trotzdem nur einmal: Der zuletzt angesagte Ort bleibt gemerkt.
const ZONE_TITLE_SEC: float = 4.0

func _process_zone_title(delta: float) -> void:
	if _zone_lbl == null:
		return
	var rel: Vector2 = WorldManager.scene_to_world(_player.position)
	var zone: String = WorldManager.zone_at(rel)
	if zone != _zone_shown:
		_zone_shown = zone
		_zone_t = ZONE_TITLE_SEC
		var name: String = "Offene Wüste" if zone == "" else String(WorldManager.poi(zone)["name"])
		_zone_lbl.text = " ".join(name.to_upper().split(""))
	if _zone_t <= 0.0:
		return
	_zone_t -= delta
	# Eine Sekunde auf, zwei stehen, eine ab.
	var t: float = ZONE_TITLE_SEC - _zone_t
	var a: float = clampf(t, 0.0, 1.0) * clampf(_zone_t, 0.0, 1.0)
	_zone_lbl.modulate = Color(0.98, 0.93, 0.80, a * 0.92)


## Naechste ungeoeffnete Truhe in Reichweite ({} = keine). Grundlage fuer das Hand-Symbol.
func _chest_in_range() -> Dictionary:
	for c in _chests:
		if not bool(c["looted"]) and _player.position.distance_to(c["pos"]) <= CHEST_INTERACT_M:
			return c
	return {}


## Truhen fuellen sich nach einer Weile wieder. Ohne das liefe die Welt nach zehn Funden
## endgueltig trocken — mit Sofort-Respawn waere die Seltenheit dahin.
func _process_chests(delta: float) -> void:
	for c in _chests:
		if not bool(c["looted"]):
			continue
		c["cd"] = float(c["cd"]) - delta
		if float(c["cd"]) <= 0.0:
			c["looted"] = false
			(c["node"] as Node3D).visible = true
			(c["label"] as Label3D).visible = true


## Truhe oeffnen: Der Inhalt FAELLT HERAUS, statt sich still in die Taschen zu buchen. Vorher
## wurde beim Vorbeilaufen automatisch geplündert und ein besseres Teil sofort angelegt — man
## sah nie, was man fand, und entschied nie etwas.
func _open_chest(c: Dictionary) -> void:
	if c.is_empty() or bool(c["looted"]):
		return
	c["looted"] = true
	c["cd"] = CHEST_RESPAWN_SEC
	(c["node"] as Node3D).visible = false
	(c["label"] as Label3D).visible = false
	var at: Vector3 = c["pos"]
	var gold: int = randi_range(18, 45)
	_drop(at, "gold", { "amount": gold })
	var pool: String = AmmoData.pool_for(_weapon_id)
	_drop(at, "ammo", { "pool": pool, "amount": AmmoData.roll_drop(pool) * 3 })
	if randf() < 0.5:
		_drop(at, "potion", { "amount": 1 })
	for i in randi_range(CHEST_GEAR_MIN, CHEST_GEAR_MAX):
		var rarity: String = ProgressionManager.roll_rarity(CHEST_RARITY_BIAS)
		var slot: String = EquipManager.GEAR_SLOTS[randi_range(0, EquipManager.GEAR_SLOTS.size() - 1)]
		_drop(at, "gear", ProgressionManager.make_gear(slot, rarity))
	_say("📦 Die Truhe springt auf.", 2.0)


## Legt ein Fundstueck auf den Boden. Die Beschriftung IST das Fundstueck: Aus Kamerahoehe
## erkennt man ein 30-cm-Objekt im Sand nicht, den Schriftzug darueber schon.
func _drop(at: Vector3, kind: String, data: Dictionary) -> void:
	var ang: float = randf() * TAU
	var r: float = sqrt(randf()) * LOOT_SCATTER_M   # Wurzel: gleichmaessig ueber die Flaeche
	var pos: Vector3 = at + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
	pos.y = WorldManager.height_at(pos.x, pos.z)   # Beute liegt auf dem Boden, nicht auf y = 0
	var text: String = ""
	var col: Color = Color.WHITE
	match kind:
		"gold":
			text = "💰 %d" % int(data["amount"])
			col = Color(1.0, 0.84, 0.35)
		"ammo":
			var p: Dictionary = AmmoData.POOLS[String(data["pool"])]
			text = "%s %d" % [String(p["icon"]), int(data["amount"])]
			col = p["color"]
		"potion":
			text = "🧪 Heiltrank"
			col = Color(0.95, 0.35, 0.45)
		"material":
			text = "🔩 %s" % String(data["id"])
			col = Color(0.72, 0.68, 0.60)
		"gear":
			# Kategorie als Beschriftung, Farbe = Seltenheit. Was es GENAU ist, zeigt erst das
			# naechstgelegene Stueck (`_process_ground`) — sonst steht der Boden voller Romane.
			text = String(ProgressionManager.GEAR_SLOTS[String(data["slot"])]["name"])
			col = RARITY_COLOR.get(String(data["rarity"]), Color.WHITE)
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.16, 0.28)
	node.mesh = mesh
	node.material_override = _mat(col)
	node.position = pos + Vector3(0.0, 0.08, 0.0)
	add_child(node)
	var label: Label3D = _label(pos + Vector3(0.0, 0.75, 0.0), text, col, LBL_BEUTE, 60.0)
	_ground.append({ "node": node, "label": label, "kind": kind, "data": data, "pos": pos })


func _clear_drop(d: Dictionary) -> void:
	(d["node"] as Node3D).queue_free()
	(d["label"] as Label3D).queue_free()
	_ground.erase(d)


## Naechstes AUSRUESTUNGS-Stueck in Handreichweite ({} = keins).
func _gear_in_range() -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = PICKUP_HAND_M
	for d in _ground:
		if String(d["kind"]) != "gear":
			continue
		var dist: float = _player.position.distance_to(d["pos"])
		if dist < best_d:
			best_d = dist
			best = d
	return best


## Bodenbeute je Frame: Gold, Munition, Traenke und Material saugt der Spieler beim
## Darueberlaufen auf; Ausruestung bleibt liegen und bekommt am naechsten Stueck einen
## Schimmer, damit klar ist, welches der Handgriff erwischt.
func _process_ground(delta: float) -> void:
	_shimmer = fmod(_shimmer + delta * 3.2, TAU)
	# Magnet-Spule vergroessert den Aufsammelradius (Prototyp-Einheiten -> Meter).
	var auto_r: float = PICKUP_AUTO_BASE_M * (float(PlayerStats.magnet_dist()) / float(PlayerStats.BASE_MAGNET))
	var near: Dictionary = _gear_in_range()
	for d in _ground.duplicate():
		var dist: float = _player.position.distance_to(d["pos"])
		var kind: String = String(d["kind"])
		if kind == "gear":
			var lbl: Label3D = d["label"]
			if d == near:
				# Schimmer: pulsierender Umriss um die Beschriftung. Billiger als ein Leuchten
				# und aus Kamerahoehe deutlich besser zu sehen.
				lbl.outline_size = 12
				lbl.outline_modulate = Color(1.0, 1.0, 1.0, 0.35 + 0.45 * (0.5 + 0.5 * sin(_shimmer)))
				lbl.text = "%s\n%s" % [String(ProgressionManager.GEAR_SLOTS[String(d["data"]["slot"])]["name"]),
					String(d["data"]["name"])]
			else:
				lbl.outline_size = 0
				lbl.text = String(ProgressionManager.GEAR_SLOTS[String(d["data"]["slot"])]["name"])
			continue
		if dist > auto_r:
			continue
		match kind:
			"gold":
				GameState.add_gold(int(d["data"]["amount"]))
			"ammo":
				AmmoData.add(String(d["data"]["pool"]), int(d["data"]["amount"]))
			"potion":
				GameState.add_potion(int(d["data"]["amount"]))
			"material":
				GameState.add_item(String(d["data"]["id"]), int(d["data"]["amount"]))
		_clear_drop(d)


## Ausruestung aufheben — der einzige Handgriff, der eine Entscheidung ist.
func _pick_up_gear() -> void:
	var d: Dictionary = _gear_in_range()
	if d.is_empty():
		return
	var gear: Dictionary = d["data"]
	if not BagManager.add(gear):
		_say("🎒 Der Beutel ist voll.", 2.5)
		return
	var rarity_name: String = String(ProgressionManager.RARITY[String(gear["rarity"])]["name"])
	_say("✦ %s %s eingesteckt" % [rarity_name, String(gear["name"])], 2.5)
	_clear_drop(d)


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


# ── Eingabe: virtueller Joystick (Touch) + Schuss-Knopf + Tastatur ────────────

func _input(event: InputEvent) -> void:
	# Eine Sequenz, die man aussitzen MUSS, ist beim zweiten Mal eine Zumutung. Jeder Tipp und
	# jede Taste bricht ab — und wird dabei verbraucht, damit derselbe Tipp nicht gleich noch
	# den Joystick startet.
	if _in_cine() and ((event is InputEventScreenTouch and event.pressed)
			or (event is InputEventMouseButton and event.pressed)
			or (event is InputEventKey and event.pressed and not event.echo)):
		_end_cine()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_pos[event.index] = event.position
		else:
			_touch_pos.erase(event.index)
			if event.index == _pinch_a or event.index == _pinch_b:
				_pinch_a = -1
				_pinch_b = -1
		if event.pressed:
			# Reihenfolge ist hier alles: Karte, dann Schuss-Knopf, dann erst der Joystick.
			# Der Joystick beansprucht sonst jeden Finger, der irgendwo aufsetzt.
			if _handle_overlay_tap(event.position):
				return
			if _fire_touch_id == -1 and _fire_btn != null and _fire_btn.hits(event.position):
				_fire_touch_id = event.index
				get_viewport().set_input_as_handled()
				return
			# Kneifen zum Zoomen. Der Joystick beansprucht den ERSTEN freien Finger — ein
			# zweiter waere danach nie eine Geste. Deshalb die Umdeutung: Kommt ein zweiter
			# Finger, waehrend der erste noch in der Totzone liegt (man hat also noch nicht
			# gelenkt), war es von Anfang an ein Kneifen. Wer schon steuert, behaelt den Stick.
			if _touch_id != -1 and _touch_id != MOUSE_STICK_ID and _pinch_a == -1 \
					and _touch_vec == Vector2.ZERO:
				_pinch_a = _touch_id
				_pinch_b = event.index
				_pinch_ref = _touch_start.distance_to(event.position)
				_pinch_zoom0 = _zoom_step()
				_end_stick()
				return
			if _touch_id == -1:
				_begin_stick(event.position, event.index)
		else:
			# Beide Finger einzeln freigeben — der Daumen auf dem Knopf geht hoch, ohne dass
			# der auf dem Joystick etwas davon merkt.
			if event.index == _fire_touch_id:
				_fire_touch_id = -1
			if event.index == _touch_id:
				_end_stick()
	elif event is InputEventScreenDrag:
		_touch_pos[event.index] = event.position
		if _pinch_a != -1 and _touch_pos.has(_pinch_a) and _touch_pos.has(_pinch_b):
			var spread: float = Vector2(_touch_pos[_pinch_a]).distance_to(Vector2(_touch_pos[_pinch_b]))
			# Auseinanderziehen holt heran (kleinere Stufe), zusammenziehen zoomt heraus.
			_set_zoom(_pinch_zoom0 - int((spread - _pinch_ref) / PINCH_PX_PER_STEP))
		elif event.index == _touch_id:
			_drag_stick(event.position)
	# Maus verhält sich exakt wie ein Finger — derselbe Joystick, damit man am Rechner das
	# testet, was auf dem Handy auch passiert (statt einer zweiten, abweichenden Steuerung).
	#
	# `is_emulating_touch_from_mouse()` ist kein Zierrat: Steht Godots Maus-Emulation an,
	# erzeugt EIN Klick zwei Ereignisse — erst einen Finger-Tipp, dann den Mausknopf. Beide
	# liefen hier durch, und weil `_handle_overlay_tap` ein Umschalter ist, ging die Weltkarte
	# im ersten auf und im zweiten sofort wieder zu: Sie liess sich nicht oeffnen. Die
	# Projekteinstellung ist inzwischen aus, aber die Abfrage bleibt — sonst holt das jemand
	# zurueck, ohne den Zusammenhang zu kennen.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not Input.is_emulating_touch_from_mouse():
		if event.pressed and _touch_id == -1:
			if _handle_overlay_tap(event.position):
				return
			# Auch mit der Maus muss der Knopf anklickbar sein: Was auf dem Handy geht, muss
			# am Rechner nachstellbar sein, sonst testet man eine andere Steuerung.
			if _fire_btn != null and _fire_btn.hits(event.position):
				_fire_mouse = true
				get_viewport().set_input_as_handled()
				return
			_begin_stick(event.position, MOUSE_STICK_ID)
		elif not event.pressed:
			_fire_mouse = false
			if _touch_id == MOUSE_STICK_ID:
				_end_stick()
	# Rechte Maustaste feuert direkt — links ist mit dem Joystick belegt.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_fire_mouse = event.pressed
	# Mausrad zoomt. Hoch = naeher heran, also eine Stufe KLEINER.
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_by(-1)
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_by(1)
	elif event is InputEventMouseMotion and _touch_id == MOUSE_STICK_ID \
			and not Input.is_emulating_touch_from_mouse():
		_drag_stick(event.position)
	# Leertaste: Halten feuert. Sie braucht auch das LOSLASSEN, deshalb steht sie vor dem
	# `pressed`-Filter der uebrigen Tasten.
	elif event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		_fire_key = event.pressed
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and _overlay_open():
			_close_character()
			_close_shop()
			_close_world_map()
		elif event.keycode == KEY_R:
			_begin_reload()
		elif event.keycode == KEY_C:
			_toggle_character()
		elif event.keycode == KEY_PLUS or event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_zoom_by(-1)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_zoom_by(1)
		elif event.keycode == KEY_M:
			if _map_is_open():
				_close_world_map()
			else:
				_open_world_map()
		elif event.keycode == KEY_Q:
			_cycle_tracked_quest()
		elif _overlay_open():
			pass   # bei offenem Overlay schluckt es die restlichen Tasten
		elif event.keycode == KEY_TAB:
			_cycle_weapon()
		elif event.keycode == KEY_E:
			# Dieselbe Rangfolge wie in der Aktionsleiste, damit Taste und Knopf nie etwas
			# Verschiedenes tun.
			var chest: Dictionary = _chest_in_range()
			var gear: Dictionary = _gear_in_range()
			var npc: Dictionary = _npc_in_range()
			if not chest.is_empty():
				_open_chest(chest)
			elif not gear.is_empty():
				_pick_up_gear()
			elif not npc.is_empty():
				_talk_to(String(npc["giver"]))
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			_fast_travel(event.keycode - KEY_1)


## Tipp auf eines der Overlays. Liefert `true`, wenn der Joystick ihn NICHT bekommen darf.
##
## Warum das hier steht und nicht als `_gui_input` in den Controls selbst: `_input` läuft VOR
## der GUI-Verarbeitung. Ein Tipp auf die Minikarte würde also erst den Joystick starten und
## danach die Karte öffnen — die Figur liefe los, während man nur nachsehen wollte.
##
## Der Laden ist der Sonderfall, an dem sich die Regel bricht: Er hat ECHTE Knöpfe, die die GUI
## verarbeiten muss. Ein Tipp DARAUF wird deshalb zwar vom Joystick ferngehalten, aber NICHT
## mit `set_input_as_handled()` verbraucht — sonst käme kein Kauf jemals an. Nur ein Tipp
## DANEBEN schließt den Laden und wird verbraucht.
func _handle_overlay_tap(at: Vector2) -> bool:
	if _char != null and _char.visible:
		# Puppe und Beutel-Raster sind GEZEICHNET, keine Knoepfe — sie bekommen ihren Tipp
		# deshalb nicht von der GUI, sondern hier von Hand. Muss VOR `hits_panel` stehen, sonst
		# wird der Tipp als „irgendwo auf der Tafel" abgetan und die Auswahl aendert sich nie.
		if _char.tap_panel(at):
			get_viewport().set_input_as_handled()
			return true
		if _char.hits_panel(at):
			return true   # Knopf auf der Tafel: durchreichen, aber nicht als Joystick werten
		_close_character()
		get_viewport().set_input_as_handled()
		return true
	if _shop != null and _shop.visible:
		if _shop.hits_panel(at):
			return true   # Knopf im Laden: durchreichen, aber nicht als Joystick werten
		_close_shop()
		get_viewport().set_input_as_handled()
		return true
	if _map_is_open():
		_close_world_map()
		get_viewport().set_input_as_handled()
		return true
	if _minimap != null and _minimap.get_global_rect().has_point(at):
		_open_world_map()
		get_viewport().set_input_as_handled()
		return true
	# Echte Knoepfe im HUD: vom Joystick fernhalten, aber an die GUI durchreichen.
	for b in _hud_buttons:
		var btn: Button = b
		if btn.visible and btn.is_visible_in_tree() and btn.get_global_rect().has_point(at):
			return true
	return false


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
	# Der Wechsel bricht ein laufendes Nachladen ab. Sonst waere Umschalten ein kostenloser
	# Weg, die Wartezeit zu ueberspringen — jede Waffe haelt ihr eigenes Magazin.
	_reload_left = 0.0
	# Bisher gibt es nur ein Waffenmodell. Statt den Karabiner in der Hand zu lassen, während
	# der Säure-Sprüher feuert, verschwindet er — lieber leere Hand als falsche Waffe.
	if _weapon_model != null:
		_weapon_model.visible = AssetRegistry.has_model("weapon_" + _weapon_id)
	var dt: String = String(CombatData.WEAPONS[_weapon_id]["type"])
	_say("%s %s (%s)" % [WEAPON_ICON[_weapon_id], String(CombatData.WEAPONS[_weapon_id]["name"]), dt], 2.0)


func _move_vector() -> Vector2:
	# Bei offenem Overlay steht die Figur. Sie ist verdeckt, also wäre jede Bewegung blind —
	# und man würde beim Kartenlesen oder Einkaufen ungewollt in eine Gegnergruppe laufen.
	if _overlay_open():
		return Vector2.ZERO
	var kb: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return kb if kb.length() > 0.05 else _touch_vec


# ── Spielschleife ─────────────────────────────────────────────────────────────

## Kamera folgt der Position des Spielers, NIE seiner Drehung (Diablo-Prinzip: die Welt behält
## ihre Orientierung, nur die Figur dreht sich). Weich nachgezogen, damit Richtungswechsel nicht
## ruckeln.
# ── Nahaufnahme: die Kamera als Erzaehler ─────────────────────────────────────
## Die Figuren sind Meshy-Modelle mit 1k-Textur — aus 12 m Iso-Entfernung sieht man davon
## nichts. Eine Quest anzunehmen ist der erste Moment im Spiel, in dem etwas ERZAEHLT wird;
## dafuer lohnt es sich, einmal heranzugehen.
##
## Bewusst klein gehalten: kein Sequenz-Editor, keine Kamerafahrten-Datei, kein Zustandsautomat.
## Eine Zielperson, eine Dauer, ein sanfter Zoom nach innen — das ist alles, was eine
## Nahaufnahme braucht, und alles Weitere waere Maschinerie fuer eine Sache, die es noch nicht
## gibt. Wer sie ausbauen will, verlaengert `_cine_frame()`.
##
## Zwei Dinge, die eine Nahaufnahme von einem Kamerafehler unterscheiden:
##  • **Man kann nichts tun.** Waehrend der Aufnahme sind Laufen und Schiessen gesperrt; sonst
##    rennt die Figur aus dem Bild, waehrend die Kamera ihr Gegenueber anschaut.
##  • **Man kommt raus.** Jeder Tipp und jede Taste bricht ab. Eine Sequenz, die man aussitzen
##    MUSS, ist beim zweiten Mal eine Zumutung.
const CINE_FOV: float = 34.0        # eng wie ein Portraitobjektiv, nicht wie das Spiel (50°)
const CINE_DIST_FROM: float = 3.6   # Abstand am Anfang …
const CINE_DIST_TO: float = 2.4     # … und am Ende: eine langsame Fahrt nach innen
## Wie lange die Fahrt nach innen dauert. Absichtlich UNABHAENGIG von der Dauer der Aufnahme:
## Sonst faehrt eine kurze Einstellung hektisch und eine lange in Zeitlupe, obwohl beide
## dieselbe Bewegung zeigen sollen.
const CINE_DOLLY_SEC: float = 2.0
const CINE_EYE_M: float = 1.62      # Augenhoehe der Figuren
const CINE_RATE: float = 6.0        # wie schnell die Kamera einschwenkt
const CINE_SIDE: float = 0.55       # seitlich versetzt — frontal wirkt wie ein Passfoto
var _cine: Node3D = null            # wen wir gerade ansehen (null = normale Kamera)
var _cine_left: float = 0.0
var _cine_total: float = 0.0
var _bars: Array = []               # die schwarzen Balken (oben; unten sitzt die Sprechtafel)
var _dialog: DialogBox              # die Sprechtafel
## Wen wir beim Gespraech zueinander drehen, und wie sie vorher standen.
var _face_a: Node3D = null
var _face_b: Node3D = null
var _face_back: float = 0.0         # urspruengliche Drehung von `_face_b`, zum Zuruecksetzen


## Nahaufnahme starten. `wer` ist die Zielperson, `secs` die Dauer.
func _play_closeup(wer: Node3D, secs: float) -> void:
	if wer == null or _cam == null:
		return
	_cine = wer
	_cine_total = maxf(secs, 0.3)
	_cine_left = _cine_total
	# Zueinander drehen. Ein Gespraech, bei dem beide geradeaus schauen, sieht aus wie zwei
	# Leute, die zufaellig nebeneinanderstehen — und in der Nahaufnahme faellt das sofort auf.
	_face_a = _player
	_face_b = wer
	_face_back = wer.rotation.y
	_set_hud_hidden(true)
	_set_cine_clean(true)
	_show_bars(true)
	_end_stick()


func _end_cine() -> void:
	if _cine == null:
		return
	_cine = null
	_cine_left = 0.0
	_face_a = null
	if _face_b != null and is_instance_valid(_face_b):
		# Die Zielperson dreht sich zurueck. Ohne das steht Mabel danach dauerhaft schraeg und
		# schaut einem hinterher, was auf Dauer unheimlicher ist als beabsichtigt.
		_face_b.rotation.y = _face_back
	_face_b = null
	if _dialog != null and _dialog.visible:
		_dialog.visible = false
	_show_bars(false)
	_set_cine_clean(false)
	_set_hud_hidden(false)


func _in_cine() -> bool:
	return _cine != null and is_instance_valid(_cine)


## Die schwarzen Balken. Sie tragen keine Information und sind trotzdem das Wichtigste an der
## Sache: Sie sagen „das hier ist erzaehlt, nicht gespielt", bevor die Kamera sich bewegt.
func _show_bars(an: bool) -> void:
	if _bars.is_empty():
		if not an or _hud_layer == null:
			return
		# Nur OBEN ein Balken. Unten sitzt die Sprechtafel, und die ist selbst dunkel gerahmt —
		# ein zweiter Balken darunter waere ein schwarzer Streifen unter einem schwarzen Rahmen.
		var r := ColorRect.new()
		r.color = Color(0.0, 0.0, 0.0, 0.92)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		r.offset_bottom = 78.0
		_hud_layer.add_child(r)
		_bars.append(r)
	for b in _bars:
		(b as ColorRect).visible = an


## Alles wegnehmen, was in einer Nahaufnahme nicht vorkommt.
##
## `_set_hud_hidden` allein reicht nicht: Es kuemmert sich um die Bedienelemente, nicht um
## Kopfzeile und Karte — und schon gar nicht um die schwebenden Weltbeschriftungen. Die sind in
## der Nahaufnahme das Schlimmste: Ein Ortsname ist auf 120 Punkt ausgelegt und aus zwei Metern
## Entfernung ein Buchstabengebirge quer durchs Bild. Die Sprechblase bleibt — sie IST die Szene.
func _set_cine_clean(an: bool) -> void:
	if _hud != null:
		_hud.visible = not an
	if _minimap != null:
		_minimap.visible = not an
	for c in get_children():
		if c is Label3D:
			(c as Label3D).visible = not an


## Der Punkt, auf den die Nahaufnahme zielt — knapp unter dem Scheitel.
##
## GEMESSEN am Modell, nicht geraten. Der erste Versuch nahm „Knotenposition plus 1,62 m
## Augenhoehe". Das stimmt nie ganz: Meshy legt den Ursprung eines Modells irgendwohin, und
## im Bild stand die Figur dann unten rechts, waehrend die Kamera auf leeren Sand zielte.
## Ueber die Netzgrenzen ist der Kopf da, wo der Kopf ist — bei jedem Modell, ohne Zahlen.
func _cine_head() -> Vector3:
	for c in _cine.get_children():
		if not (c is Node3D):
			continue
		var b: AABB = AssetRegistry.local_bounds(c as Node3D)
		if b.size.y < 0.2:
			continue
		var m: Transform3D = (c as Node3D).global_transform
		var scheitel: Vector3 = m * (b.position + Vector3(b.size.x * 0.5, b.size.y, b.size.z * 0.5))
		# Waagerecht die KNOTENPOSITION, senkrecht das gemessene Modell.
		#
		# Nur die Hoehe wird gemessen, nicht die Mitte: Der Huellquader eines animierten Modells
		# umfasst die Ruhepose mit ausgestreckten Armen, sein waagerechter Mittelpunkt liegt
		# deshalb um bis zu einem halben Meter neben der Figur — im Bild stand sie dann am Rand,
		# waehrend die Kamera auf leeren Sand zielte. Der Knoten dagegen steht per Definition da,
		# wo die Figur steht.
		return Vector3(_cine.global_position.x, scheitel.y - 0.16, _cine.global_position.z)
	return _cine.global_position + Vector3(0.0, CINE_EYE_M, 0.0)


## Wo steht die Kamera in diesem Augenblick der Aufnahme?
##
## Aus der BLICKRICHTUNG der Zielperson, leicht seitlich versetzt. Der erste Versuch nahm die
## Richtung des Spielers — und zeigte Mabels Hinterkopf: Die NPCs schauen zur Strassenmitte,
## der Spieler steht daneben. Eine Nahaufnahme, die das Gesicht nicht zeigt, ist keine.
## Genau frontal waere allerdings ein Passfoto, deshalb der Versatz.
func _cine_frame() -> Array:
	var kopf: Vector3 = _cine_head()
	# In Godot schaut ein Node3D entlang seiner NEGATIVEN Z-Achse. Vor ihm liegt also −z.
	var von: Vector3 = -_cine.global_transform.basis.z
	von.y = 0.0
	if von.length() < 0.2:
		von = _player.position - _cine.global_position
		von.y = 0.0
	if von.length() < 0.2:
		von = Vector3(0.0, 0.0, 1.0)
	von = von.normalized()
	var quer := Vector3(-von.z, 0.0, von.x)
	# Fortschritt 0 → 1 ueber `CINE_DOLLY_SEC`; die Kamera faehrt langsam heran.
	var t: float = clampf((_cine_total - _cine_left) / CINE_DOLLY_SEC, 0.0, 1.0)
	var dist: float = lerpf(CINE_DIST_FROM, CINE_DIST_TO, smoothstep(0.0, 1.0, t))
	var pos: Vector3 = kopf + von * dist + quer * CINE_SIDE + Vector3(0.0, 0.22, 0.0)
	return [pos, kopf]


## Spieler und Gegenueber drehen sich zueinander.
##
## Weich, nicht gesprungen: Ein harter Schnitt auf die neue Blickrichtung sieht aus, als haette
## jemand die Figur umgestellt. Ueber gut eine Viertelsekunde gedreht liest es sich als
## Zuwendung — und genau die ist der Grund, warum ueberhaupt gedreht wird.
##
## `lerp_angle` und nicht `lerpf`: Zwischen 170° und −170° liegen zwanzig Grad, nicht 340. Ohne
## das dreht sich die Figur einmal ganz herum, wenn das Gespraech ueber die Vorzeichengrenze
## geht — und das passiert genau bei jedem zweiten NPC.
const FACE_RATE: float = 7.0
func _process_facing(delta: float) -> void:
	if _face_a == null or _face_b == null:
		return
	if not is_instance_valid(_face_a) or not is_instance_valid(_face_b):
		return
	var k: float = clampf(delta * FACE_RATE, 0.0, 1.0)
	_face_a.rotation.y = lerp_angle(_face_a.rotation.y,
		_yaw_towards(_face_a.position, _face_b.position), k)
	_face_b.rotation.y = lerp_angle(_face_b.rotation.y,
		_yaw_towards(_face_b.position, _face_a.position), k)


## Blickrichtung von `von` nach `nach` als Node3D-Drehung um die Hochachse.
##
## Dieselbe Rechnung, mit der die Figur beim Laufen zum Laufvektor schaut
## (`rotation.y = atan2(-step.x, -step.z)`) — bewusst hier zentral, damit Laufen und Zuwenden
## nicht zwei verschiedene Vorstellungen von „vorn" haben.
static func _yaw_towards(von: Vector3, nach: Vector3) -> float:
	var d := Vector3(nach.x - von.x, 0.0, nach.z - von.z)
	if d.length() < 0.01:
		return 0.0
	return atan2(-d.x, -d.z)


func _process_camera(delta: float) -> void:
	if _cam == null:
		return
	if _in_cine():
		_cine_left -= delta
		var f: Array = _cine_frame()
		_cam.fov = lerpf(_cam.fov, CINE_FOV, clampf(delta * CINE_RATE, 0.0, 1.0))
		_cam.position = _cam.position.lerp(f[0], clampf(delta * CINE_RATE, 0.0, 1.0))
		_cam.look_at(f[1], Vector3.UP)
		if _cine_left <= 0.0:
			_end_cine()
		return
	# Zurueck in die Spielhaltung. Die Drehung wird NACHGEZOGEN statt zurueckgesetzt: `look_at`
	# hat sie waehrend der Aufnahme veraendert, und ein harter Sprung zurueck sieht aus wie ein
	# Ruckler. Winkelweise interpoliert, damit der Weg ueber ±180° nicht falsch herum geht.
	var ruhe := Vector3(deg_to_rad(-CAM_PITCH), deg_to_rad(CAM_YAW), 0.0)
	var k: float = clampf(delta * CINE_RATE, 0.0, 1.0)
	_cam.rotation = Vector3(
		lerp_angle(_cam.rotation.x, ruhe.x, k),
		lerp_angle(_cam.rotation.y, ruhe.y, k),
		lerp_angle(_cam.rotation.z, ruhe.z, k))
	_cam.fov = lerpf(_cam.fov, CAM_FOV, k)
	# Zoom weich nachziehen, dann die Position — beides mit derselben Zeitkonstanten-Logik.
	_cam_dist = lerpf(_cam_dist, float(CAM_ZOOM_STEPS[_zoom_step()]),
		clampf(delta * CAM_ZOOM_RATE, 0.0, 1.0))
	var want: Vector3 = _player.position + _cam_offset(_cam_dist)
	_cam.position = _cam.position.lerp(want, clampf(delta * CAM_FOLLOW, 0.0, 1.0))


func _process(delta: float) -> void:
	_process_movement(delta)
	_process_facing(delta)
	_process_camera(delta)
	_process_combat(delta)
	_process_enemies(delta)
	_process_hazards(delta)
	_process_spawns(delta)
	_process_chests(delta)
	_process_ground(delta)
	_process_zone_title(delta)
	_process_fog(delta)
	_process_interactions(delta)
	_process_trail(delta)
	_process_autosave(delta)
	_update_hud()


## Nebel aufdecken, wo der Spieler war.
##
## Nicht jeden Frame: Bei 4,7 m/s und 40-m-Zellen dauert es acht Sekunden, bis eine neue Zelle
## erreicht ist — sechzigmal pro Sekunde 25 Zellen zu prüfen, um in 99,8 % der Fälle „schon
## bekannt" zu antworten, ist verschenkte Rechenzeit. Viermal pro Sekunde reicht und deckt
## selbst bei Schnellreise nichts unabsichtlich zu.
const FOG_INTERVAL_SEC: float = 0.25
var _fog_cd: float = 0.0
func _process_fog(delta: float) -> void:
	_fog_cd -= delta
	if _fog_cd > 0.0:
		return
	_fog_cd = FOG_INTERVAL_SEC
	# Nur bei WIRKLICH neuen Zellen neu zeichnen. Die Karte zeichnet sich sonst ohnehin jeden
	# Frame; hier geht es um die Vollbildkarte, die es nicht tut.
	if FogOfWar.reveal(WorldManager.scene_to_world(_player.position)) > 0 and _world_map != null:
		_world_map.queue_redraw()


func _process_movement(delta: float) -> void:
	if _in_cine():
		return   # waehrend einer Nahaufnahme laeuft niemand aus dem Bild
	var mv: Vector2 = _move_vector()
	var moving: bool = mv.length() >= 0.05
	# Animation folgt der Bewegung, sobald ein animiertes Modell da ist. Kennt das Modell den
	# Clip nicht (oder ist es der Kapsel-Platzhalter), passiert schlicht nichts.
	#
	# Der Schuss-Clip des Rigs heisst `Run_and_Shoot` — er zeigt eine RENNENDE Figur, die
	# feuert. Deshalb kommt er nur zum Zug, wenn auch tatsaechlich gelaufen wird. Im Stand
	# waere er genau der Rutsch-Effekt, den die Gangart-Regel gerade beseitigt hat; dafuer
	# fehlt dem Rig schlicht ein Clip fuers Schiessen aus dem Stand.
	var clip: String = "idle"
	if moving:
		clip = "attack" if _fire_wanted() else _gait(WorldManager.PLAYER_SPEED_MS)
	AssetRegistry.play_clip(_player_model, clip)
	if not moving:
		return
	# Eingabe ist bildschirmbezogen: um die Kamera-Gierung zurückdrehen, damit „nach oben
	# ziehen" auch bei gedrehter Kamera nach oben läuft (sonst zieht es schräg).
	var dir: Vector2 = mv.rotated(-deg_to_rad(CAM_YAW))
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
	# Die Figur folgt dem Gelaende. Ohne diese Zeile liefe sie auf y = 0 durch jede Senke
	# hindurch — die Vertiefung waere blosse Kulisse.
	next.y = WorldManager.height_at(next.x, next.z)
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


## Liegt der Abzug an? Halten feuert dauerhaft im Waffentakt — bei 3 Schuss pro Sekunde waere
## Einzeltippen auf einem Touchscreen keine Steuerung, sondern eine Zumutung.
func _fire_wanted() -> bool:
	return (_fire_key or _fire_mouse or _fire_touch_id != -1) and not _overlay_open() \
		and _reload_left <= 0.0


## Nachladen anstossen. Laeuft ueber die Zeit und blockiert solange den Abzug — das ist der
## Preis, den eine Waffe mit grossem Magazin zahlt (die Gatling steht viereinhalb Sekunden
## wehrlos da). Ohne Vorrat passiert nichts ausser einem gedrosselten Hinweis: Ein Nachladen,
## das nichts bewirkt, waere schlimmer als gar keines.
func _begin_reload() -> void:
	if _reload_left > 0.0 or AmmoData.mag_full(_weapon_id):
		return
	if not AmmoData.can_reload(_weapon_id):
		if _dry_cd <= 0.0:
			_dry_cd = 1.5
			_say("🔫 %s aus — Waffe wechseln [Tab]"
				% String(AmmoData.POOLS[AmmoData.pool_for(_weapon_id)]["name"]), 1.5)
		return
	_reload_total = PlayerStats.reload_sec(_weapon_id)
	_reload_left = _reload_total


## Kampf. Gezielt wird automatisch auf den naechsten Gegner in Reichweite — es gibt keinen
## zweiten Stick zum Zielen, und den gaebe es auf dem Handy auch nicht sinnvoll. GESCHOSSEN
## wird aber nur auf Befehl: Vorher feuerte die Figur von selbst, sobald irgendetwas in die
## 11-m-Reichweite geriet. Damit war jeder Gegner tot, bevor man ihn ueberhaupt gesehen hatte,
## und der Kampf bestand darin, in die richtige Richtung zu laufen.
func _process_combat(delta: float) -> void:
	if _in_cine():
		return   # kein Abzug waehrend einer Nahaufnahme
	# Nach unten begrenzt, damit der Wert in langen Feuerpausen nicht ins Bodenlose laeuft.
	# Bei -1 s ist der naechste Druck ohnehin sofort ein Schuss.
	_fire_cd = maxf(_fire_cd - delta, -1.0)
	_dry_cd = maxf(_dry_cd - delta, 0.0)
	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			var geladen: int = AmmoData.refill_mag(_weapon_id)
			_reload_left = 0.0
			if geladen > 0 and geladen < AmmoData.mag_size(_weapon_id):
				_say("🔄 Nur %d Schuss geladen — der Vorrat geht zur Neige." % geladen, 2.0)
	var e: Dictionary = _nearest_enemy(SHOOT_RANGE_M)
	var wants: bool = _fire_wanted()
	# Der Knopf zeigt beides an: dass gedrueckt ist UND ob ueberhaupt jemand in Reichweite ist.
	# Ohne die zweite Anzeige waere „nichts passiert" nicht von „kaputt" zu unterscheiden.
	if _fire_btn != null:
		_fire_btn.set_state(wants, not e.is_empty())
	if not wants or e.is_empty() or _fire_cd > 0.0:
		return
	# Magazin statt Dauerfeuer (GDD §7.1.1). Ist es leer, wird von selbst nachgeladen — von
	# Hand geht es mit [R], bevor es leer ist.
	if not AmmoData.consume(_weapon_id):
		_begin_reload()
		return
	_fire_cd = float(PlayerStats.fire_ms(_weapon_id)) / 1000.0
	# ── Streuung: Der Schuss kann DANEBENGEHEN ────────────────────────────────
	# Gezielt wird automatisch, das bleibt so — aber Zielen und Treffen sind zweierlei. Die
	# Abweichung wird aus dem Streukegel der Waffe gewuerfelt und gegen die WINKELBREITE des
	# Gegners geprueft: Wie breit er aus dieser Entfernung erscheint, entscheidet, ob die
	# Abweichung noch auf ihm landet. Damit wird Streuung automatisch zur Reichweitenfrage,
	# ohne dass irgendwo eine Trefferwahrscheinlichkeit von Hand gesetzt waere.
	var to: Vector3 = (e["node"] as Node3D).position - _player.position
	var dist: float = maxf(Vector2(to.x, to.z).length(), 0.5)
	var half_deg: float = rad_to_deg(atan2(float(e["radius"]), dist))
	var dev_deg: float = randf_range(-1.0, 1.0) * PlayerStats.spread_deg(_weapon_id)
	var hit: bool = absf(dev_deg) <= half_deg
	# Der Leuchtspur folgt der ABWEICHUNG, nicht dem Ziel: Ein Fehlschuss muss zu sehen sein,
	# sonst wirkt er wie ein verschluckter Treffer.
	var aim: Vector3 = _player.position + Vector3(to.x, 0.0, to.z).rotated(Vector3.UP, deg_to_rad(dev_deg))
	_spawn_tracer(aim)
	if not hit:
		return
	var target: CombatTarget = e["target"]
	var damage_type: String = String(CombatData.WEAPONS[_weapon_id]["type"])
	var acid: int = CombatData.weapon_acid(_weapon_id, 0)
	var res: Dictionary = CombatEngine.resolve_hit(
		damage_type, target, PlayerStats.damage_per_bullet(_weapon_id), acid, Time.get_ticks_msec())
	var frac: float = clampf(float(target.health) / float(target.max_health), 0.0, 1.0)
	(e["bar"] as MeshInstance3D).scale.x = maxf(frac, 0.02)
	if bool(res["killed"]):
		GameState.add_kill()
		GameState.add_xp(CombatData.xp_for_kill(target))
		# Beute FAELLT, statt sich still zu verbuchen. Gold, Munition und Material zieht der
		# Spieler beim Darueberlaufen ein — dadurch hat auch ein erledigter Kampf noch eine
		# Handlung, statt nur eine Zahl im Kopfbereich zu erhoehen.
		var at: Vector3 = (e["node"] as Node3D).position
		_drop(at, "gold", { "amount": target.gold })
		var pool: String = AmmoData.pool_for(_weapon_id)
		_drop(at, "ammo", { "pool": pool, "amount": AmmoData.roll_drop(pool) })
		_roll_material_drop(at)
		_say("☠ %s erlegt" % String(CombatData.ENEMY_TYPES[target.type_id]["name"]), 1.6)
		(e["node"] as Node3D).queue_free()
		_enemies.erase(e)


## Material-Drop beim Kill (Schrott/Zahnrad/Dampfkern). Ohne diese Drops waeren die
## Sammel-Quests des QuestManagers in der Overworld gar nicht erfuellbar.
func _roll_material_drop(at: Vector3) -> void:
	for entry in DROP_TABLE:
		if randf() < float(entry[1]):
			_drop(at, "material", { "id": String(entry[0]), "amount": 1 })
			return


func _spawn_tracer(to_pos: Vector3) -> void:
	_tracer(_player.position + Vector3(0.0, 1.2, 0.0), Vector3(to_pos.x, 1.0, to_pos.z),
		TRACER_COLOR[_weapon_id])


## Ein Schuss als Strich, 70 ms lang. Eine Funktion fuer beide Richtungen: Seit die Gegner
## zurueckschiessen, gibt es zwei Quellen, und zwei Kopien derselben sieben Zeilen waeren
## genau die Stelle, an der eine Aenderung nur in einer Haelfte landet.
func _tracer(von: Vector3, nach: Vector3, farbe: Color) -> void:
	if not is_inside_tree():
		return           # Testlauf ohne Szenenbaum: es gibt kein Bild, in dem etwas aufblitzen kann
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, von.distance_to(nach))
	tracer.mesh = mesh
	tracer.material_override = _mat(farbe, true)
	add_child(tracer)
	tracer.position = (von + nach) / 2.0
	tracer.look_at(nach)
	get_tree().create_timer(0.07).timeout.connect(tracer.queue_free)


## Die Gegner: heranrücken, zuschlagen, Abstand halten.
##
## Vorher gab es zwei Zustände — laufen und „in Reichweite". In Reichweite floss Schaden je
## Sekunde, solange man dort stand: kein Schlag, kein Ausholen, keine Pause, und die
## Angriffs-Animation lief nebenher als Dauerschleife. Man verlor Leben, ohne dass irgendetwas
## im Bild dafür verantwortlich war.
##
## Jetzt hat ein Angriff einen ABLAUF: ausholen (`windup`) → treffen → nachladen (`cooldown`).
## Der Schaden fällt in dem Bild, in dem die Animation ihn zeigt, und wer in der Zeit aus der
## Reichweite geht, wird nicht getroffen. Die Schadensrate ist dieselbe geblieben
## (`contact × MELEE_INTERVAL_SEC` je Schlag) — es ändert sich nur, dass man sie sieht.
##
## Und Fernkämpfer kämpfen fern. Revolverheld und Konstrukt tragen in `CombatData` seit jeher
## einen `ranged`-Block, den niemand gelesen hat; sie sind bisher wie alle anderen bis auf zwei
## Meter herangerannt. Jetzt bleiben sie in ihrem Reichweitenband stehen und **weichen zurück**,
## wenn man ihnen zu nah kommt.
func _process_enemies(delta: float) -> void:
	for e in _enemies:
		var node: Node3D = e["node"]
		var zu := Vector3(_player.position.x - node.position.x, 0.0,
			_player.position.z - node.position.z)
		var d: float = zu.length()
		e["cooldown"] = maxf(0.0, float(e.get("cooldown", 0.0)) - delta)
		# Im Ausholen wird weder gelaufen noch neu entschieden — sonst bricht der Schlag ab,
		# sobald sich der Spieler einen Schritt bewegt, und man sähe nie einen ganzen.
		if float(e.get("windup", -1.0)) >= 0.0:
			if _tick_windup(e, d, delta):
				return                       # Spieler gestorben; `_enemies` ist neu
			continue
		if d > AGGRO_M:
			if not AssetRegistry.play_clip(e["model"], "idle"):
				AssetRegistry.rest(e["model"])
			_scurry(e, false)
			continue
		var dir: Vector3 = zu / maxf(d, 0.001)
		node.rotation.y = atan2(-dir.x, -dir.z)   # wach heißt: zum Spieler gedreht
		var weit: float = _attack_range(e)
		var nah: float = _min_range(e)
		if d > weit:
			_move_enemy(e, dir, 1.0, delta)
			AssetRegistry.play_clip(e["model"], _gait(_enemy_speed(e)))
		elif nah > 0.0 and d < nah:
			# Zu nah für einen Schützen. Rückwärts, ohne den Spieler aus dem Blick zu lassen —
			# langsamer als vorwärts, sonst kommt man ihm nie bei.
			_move_enemy(e, dir, -RETREAT_SPEED_MUL, delta)
			if not AssetRegistry.play_clip(e["model"], "retreat"):
				AssetRegistry.play_clip(e["model"], _gait(_enemy_speed(e)))
			if float(e["cooldown"]) <= 0.0:
				_begin_attack(e)
		else:
			_scurry(e, false)
			if float(e["cooldown"]) <= 0.0:
				_begin_attack(e)
			elif not AssetRegistry.play_clip(e["model"], "idle"):
				AssetRegistry.rest(e["model"])


## Tempo beim Rückwärtsgehen, als Anteil des Vorwärtstempos.
const RETREAT_SPEED_MUL: float = 0.62
## Kulanz beim Treffer: So weit darf man sich während des Ausholens aus der Reichweite bewegt
## haben und wird trotzdem getroffen. Ohne sie verfehlt ein Schlag schon, wenn man beim Ausholen
## normal weitergeht — und Ausweichen wäre nicht Können, sondern Zufall.
const ATTACK_FORGIVE_M: float = 0.8
## Farbe der gegnerischen Leuchtspur. Bewusst NICHT die der eigenen Waffen: Wer im Getümmel
## sehen soll, was auf ihn zufliegt, darf es nicht mit dem eigenen Feuer verwechseln.
const ENEMY_TRACER_COLOR: Color = Color(1.0, 0.42, 0.22)


## Ein Schritt Gegnerbewegung. `mul` < 0 heißt rückwärts.
##
## Steht dort ein Bauwerk, bleibt der Gegner stehen, statt hineinzulaufen. Das galt vorher für
## niemanden — solange alle nur vorwärts auf den Spieler zuliefen, fiel es kaum auf; ein
## Schütze, der rückwärts durch eine Hauswand weicht, dagegen sofort.
func _move_enemy(e: Dictionary, dir: Vector3, mul: float, delta: float) -> void:
	var node: Node3D = e["node"]
	var ziel: Vector3 = node.position + dir * _enemy_speed(e) * mul * delta
	if not _blocked(ziel):
		node.position = Vector3(ziel.x, WorldManager.height_at(ziel.x, ziel.z), ziel.z)
	_scurry(e, true)


## Fernkampf-Block eines Gegners (leer = Nahkämpfer).
func _ranged(e: Dictionary) -> Dictionary:
	var id: String = (e["target"] as CombatTarget).type_id
	return CombatData.ENEMY_TYPES[id].get("ranged", {})


## Entfernung, ab der dieser Gegner angreifen kann.
func _attack_range(e: Dictionary) -> float:
	var f: Dictionary = _ranged(e)
	return CONTACT_RANGE_M if f.is_empty() else float(f["max"]) * CombatData.RANGE_PX_TO_M


## Entfernung, unter der er zurückweicht (0 = weicht nicht).
func _min_range(e: Dictionary) -> float:
	var f: Dictionary = _ranged(e)
	return 0.0 if f.is_empty() else float(f["min"]) * CombatData.RANGE_PX_TO_M


## Holt aus: Animation an, Uhr gestellt. Der Treffer fällt in `_tick_windup`.
func _begin_attack(e: Dictionary) -> void:
	var fern: bool = not _ranged(e).is_empty()
	e["windup"] = CombatData.WINDUP_SHOT_SEC if fern else CombatData.WINDUP_MELEE_SEC
	AssetRegistry.play_clip(e["model"], "attack", false)


## Läuft das Ausholen ab und setzt den Treffer. `true` = der Spieler ist dabei gestorben.
func _tick_windup(e: Dictionary, d: float, delta: float) -> bool:
	_scurry(e, false)
	e["windup"] = float(e["windup"]) - delta
	if float(e["windup"]) > 0.0:
		return false
	e["windup"] = -1.0
	var fern: Dictionary = _ranged(e)
	e["cooldown"] = float(fern["rate"]) / 1000.0 if not fern.is_empty() \
		else CombatData.MELEE_INTERVAL_SEC
	# Wer während des Ausholens weggegangen ist, wird nicht getroffen. Das ist der ganze Grund
	# für das Ausholen: Ohne es gäbe es kein Zeitfenster, in dem Ausweichen etwas nützt.
	if d > _attack_range(e) + ATTACK_FORGIVE_M:
		return false
	var schaden: float = float(fern["dmg"]) if not fern.is_empty() \
		else float((e["target"] as CombatTarget).contact_dps) * CombatData.MELEE_INTERVAL_SEC
	if not fern.is_empty():
		_enemy_tracer(e)
	_hp -= schaden * CombatEngine.player_damage_taken_mul(0)
	if _hp <= 0.0:
		_respawn()
		return true
	return false


## Leuchtspur vom Gegner zum Spieler. Ohne sie ist ein Fernkämpfer ein unsichtbarer Schaden aus
## dem Nichts: Man verliert Leben und sieht nicht, woher.
func _enemy_tracer(e: Dictionary) -> void:
	var node: Node3D = e["node"]
	var hoehe: float = AssetRegistry.height_of(
		AssetRegistry.enemy_asset((e["target"] as CombatTarget).type_id))
	_tracer(node.position + Vector3(0.0, hoehe * 0.72, 0.0),
		_player.position + Vector3(0.0, 1.1, 0.0), ENEMY_TRACER_COLOR)


## Gangart zur Geschwindigkeit. Eine Geh-Animation bei 4,7 m/s (knapp 17 km/h) sieht aus, als
## rutsche die Figur ueber den Boden — der Fusskontakt passt schlicht nicht zum Tempo. Ab
## Laufgeschwindigkeit wird deshalb der Renn-Clip gespielt, darunter der Geh-Clip. Fehlt dem
## Modell die Rolle, faellt `play_clip` von selbst zurueck.
const RUN_THRESHOLD_MS: float = 2.6

func _gait(speed: float) -> String:
	return "run" if speed >= RUN_THRESHOLD_MS else "walk"


## Tempo eines Gegners aus seinen echten Werten (CombatData `speed`, 100 = Referenz) statt
## einer Pauschale — eine Ratte (122) huscht, ein Panzer soll nicht wie ein Grenzgänger traben.
func _enemy_speed(e: Dictionary) -> float:
	var type_id: String = (e["target"] as CombatTarget).type_id
	var s: float = float(CombatData.ENEMY_TYPES[type_id].get("speed", 100))
	return ENEMY_SPEED_MS * (s / 100.0)


## Ersatzbewegung für Modelle OHNE Lauf-Animation, phasenversetzt je Einheit. Kein Ersatz für
## eine echte Animation, aber ein Rudel reglos über den Sand gleitender Ratten sieht kaputt aus.
##
## Nach Klasse getrennt, sonst wird es albern: **Organisches** hüpft (Huschen, Trippeln),
## **Maschinen** wanken nur (ein hüpfender Panzer ist kein Panzer). Die Amplitude hängt an der
## Modellhöhe — eine 0,6-m-Ratte darf nicht so weit vom Boden wie ein 2-m-Konstrukt.
func _scurry(e: Dictionary, moving: bool) -> void:
	if bool(e.get("animated", false)) or e["model"] == null:
		return
	var model: Node3D = e["model"]
	if not moving:
		model.position.y = 0.0
		model.rotation.z = 0.0
		return
	var target: CombatTarget = e["target"]
	var height: float = AssetRegistry.height_of(AssetRegistry.enemy_asset(target.type_id))
	var t: float = Time.get_ticks_msec() / 1000.0 * SCURRY_HZ + float(e["phase"])
	if target.classification == CombatData.MECHANICAL:
		model.position.y = 0.0
		model.rotation.z = sin(t * 0.35) * SCURRY_ROLL_RAD   # schweres Wanken, kein Hüpfen
	else:
		model.position.y = absf(sin(t)) * SCURRY_HOP * height
		model.rotation.z = sin(t * 0.5) * SCURRY_ROLL_RAD


var _swamp_warned: float = 0.0
func _process_hazards(delta: float) -> void:
	var rel: Vector2 = WorldManager.scene_to_world(_player.position)
	# Smog-DOT (Gate 2) und Strahlensumpf (Gate 0): WorldManager rechnet, die Szene wendet an.
	var dot: int = WorldManager.smog_dot_damage(rel, delta)
	dot += WorldManager.swamp_dot_damage(rel, delta)
	if dot > 0:
		_hp -= float(dot)
		# Sagen, WAS passiert. Leben, das ohne Erklaerung sinkt, liest sich als Fehler; erst der
		# Satz macht aus dem Schaden eine Grenze, die man versteht und respektiert.
		var jetzt: float = Time.get_ticks_msec() / 1000.0
		if jetzt - _swamp_warned > 2.2:
			_swamp_warned = jetzt
			if WorldManager.is_in_swamp(rel):
				_say("☢ Strahlung! Der Sumpf frisst dich — ohne Schutzanzug kein Durchkommen.", 2.4)
			else:
				_say("☣ Smog! Ohne Alchemie-Filter überlebt das niemand.", 2.4)
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
	if _ammo_lbl != null:
		var pool: String = AmmoData.pool_for(_weapon_id)
		var mag: int = AmmoData.in_mag(_weapon_id)
		var col := Color(0.92, 0.90, 0.84)
		if _reload_left > 0.0:
			# Waehrend des Nachladens zaehlt die Restzeit — man muss WISSEN, wie lange man
			# noch wehrlos ist, sonst wirkt der blockierte Abzug wie ein Fehler.
			var voll: int = int(round((1.0 - _reload_left / maxf(_reload_total, 0.01)) * 8.0))
			_ammo_lbl.text = "🔄 %s%s  %.1f s" % ["▮".repeat(voll), "▯".repeat(8 - voll), _reload_left]
			col = Color(0.55, 0.78, 1.0)
		else:
			_ammo_lbl.text = "%s %d/%d   %d" % [String(AmmoData.POOLS[pool]["icon"]), mag,
				AmmoData.mag_size(_weapon_id), AmmoData.amount(pool)]
			if mag <= 0:
				col = Color(1.0, 0.34, 0.30)
			elif mag <= maxi(1, AmmoData.mag_size(_weapon_id) / 4):
				col = Color(1.0, 0.82, 0.25)
		_ammo_lbl.add_theme_color_override("font_color", col)
	_hud.text += "\n🔩 %d  ⚙ %d  🔆 %d" % [
		GameState.item_count("schrott"), GameState.item_count("zahnrad"), GameState.item_count("dampfkern")]
	if _minimap != null:
		var ep: Array = []
		for e in _enemies:
			ep.append((e["node"] as Node3D).position)
		_feed_map(_minimap, ep)
		# Die Weltkarte nur füttern, solange sie offen ist — sonst zeichnet ein unsichtbares
		# Control jeden Frame den ganzen Krater mit elf Ortsnamen neu.
		if _map_is_open():
			_feed_map(_world_map, ep)
	if Time.get_ticks_msec() / 1000.0 > _toast_until:
		_toast.text = ""
