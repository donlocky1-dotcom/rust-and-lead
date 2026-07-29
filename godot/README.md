# Rust & Lead — Godot 4 (Phase 2)

Logik-Backend **plus erste sichtbare Szene**: `scenes/Overworld.tscn` ist die Hauptszene —
der begehbare **Kraterboden im Produktions-Maßstab (5000×5000 m, GDD §1.4)**, komplett aus
den `WorldManager`-Daten generiert (Biome, Sektor-Tore, Kraterrand, alle POIs), mit
steuerbarem Spieler (4,7 m/s, Touch-Joystick + Tastatur) und erstem Kampf über die echte
`CombatEngine`. Basis: `docs/MASTER_GDD.md` (§1.4/§1.6 Welt, §2.3 State-Schema, §3 Kampagne).

**Auf dem Handy (Xogot):** Repo als ZIP laden (oder via Working Copy klonen), in Xogot
**den Unterordner `godot/` importieren** (dort liegt `project.godot`), Play drücken —
die Overworld startet in Rustwater. Ziehen = laufen, Gegner in Reichweite werden
automatisch beschossen. Erster Import dauert wegen der 3D-Assets etwas.
**Am Rechner:** die **Maus verhält sich wie ein Finger** — linke Taste gedrückt halten und
ziehen, der virtuelle Joystick erscheint am Aufsetzpunkt und die Figur dreht sich in die
gezogene Richtung. Damit testet man dieselbe Steuerung, die auf dem Handy läuft, statt einer
zweiten, abweichenden. Pfeiltasten gehen weiterhin.
**Interaktion:** Kommt man an einen NPC oder einen Bahnsteig heran, erscheint unten eine
**Aktionsleiste** — antippen genügt. Reden ist dadurch eine Entscheidung, kein Zufall des
Vorbeilaufens, und die Bahn ist ohne Tastatur benutzbar.
**Karte:** Oben rechts liegt die Nahansicht — ein Umkreis von **200 m** um die Figur, fein genug,
dass Gegner, Straße und Laufrichtung tatsächlich lesbar sind. **Antippen öffnet die Weltkarte**
mit dem ganzen 5000-m-Krater: alle Orte mit Namen, Sektorgrenzen, Biome, Iron-Rail-Trasse. Noch
ein Tipp schließt sie. Solange sie offen ist, steht die Figur.
**Schießen:** Unten rechts liegt der **Schuss-Knopf** — die Gegenhand zum Joystick unten links.
Halten feuert dauerhaft im Waffentakt. Gezielt wird weiterhin automatisch auf den nächsten
Gegner in Reichweite (es gibt keinen zweiten Stick zum Zielen), aber **abgedrückt wird nur von
Hand**. Der Knopf leuchtet auf, sobald jemand in Reichweite ist; ohne Ziel passiert beim Drücken
nichts. Am Rechner: **Leertaste** oder **rechte Maustaste** (links ist der Joystick).
**Gold ausgeben:** Bei **Silas Kupferauge** öffnet die Aktionsleiste die **Werkstatt** (Schaden,
Feuerrate, Panzerung, Tempo, Regeneration, Loot-Magnet — Kostenkurve und Höchststufen 1:1 aus
dem Prototyp), bei **Mamma Mabel** die **Geschäfte** (die vier Rustwater-Betriebe, die pro
aktiver Spielsekunde Einkommen abwerfen). Die Läden hängen bewusst an den *Leuten*, nicht an
ihren Häusern: Die Stadt wird von Hand umgestellt, und Destille und Labor haben noch gar kein
Modell. Tippen daneben oder `[Esc]` schließt.

> Körper-Ausbauten (Panzerung, Laufbeine, Kühlsystem, Magnet-Spule) sind vor dem **Reveal**
> gesperrt und stehen als „🔒 ???" in der Liste — wer sich für einen Menschen hält, lässt sich
> keine Hydraulik einbauen. Danach ändern auch die übrigen Teile ihren Namen: aus „Schneller
> Hahn" wird „Kolben-Frequenz".

**Beute liegt am Boden (Diablo-Achse).** Truhen sind **selten und stehen fest** — genau eine am
Mittelpunkt jedes Ortes außer Rustwater, zehn im ganzen Krater. Kommt man heran, erscheint das
**Hand-Symbol**; beim Öffnen **fällt der Inhalt heraus**. Gold, Munition, Tränke und Material
sammeln sich beim **Darüberlaufen** von selbst auf (Radius wächst mit der Magnet-Spule).
**Ausrüstung bleibt liegen**: Die Beschriftung nennt die **Kategorie**, ihre **Farbe die
Seltenheit** (grau · blau · violett · gold), und das nächstgelegene Stück bekommt einen
**Schimmer** und seinen vollen Namen — nur das lässt sich mit der Hand aufheben. Gegner lassen
ihre Beute genauso fallen.

**Waffen (GDD §7.1):** Fünf Profile, die sich wirklich unterscheiden — der Feuertakt spannt sich
über den **Faktor zwölf**. Der 🔫 **Blei-Karabiner** kracht einmal pro Sekunde und trifft hart
und genau; die 🌀 **Messing-Gatling** feuert vierzehnmal pro Sekunde, streut aber so weit, dass
sie auf voller Reichweite nur noch gut ein Drittel trifft. Dazwischen ⚡ Volt-Karabiner,
🧪 Säure-Sprüher und 🔥 Dampf-Brenner. `[Tab]` schaltet um.

> **Streuung** ist keine Zufallszahl, sondern Geometrie: Die Abweichung wird gegen die
> Winkelbreite des Gegners geprüft, und ein Fehlschuss ist an der Leuchtspur zu sehen. Deshalb
> wird die Gatling nah tödlich und weit nutzlos, ohne dass das als Regel irgendwo steht.
> Verengen lässt sich der Kegel über den Mod-Wert **`accuracy`** auf Ausrüstung.

**Munition & Nachladen (GDD §7.1.1):** Zweistufig — geschossen wird aus dem **Magazin**,
nachgefüllt aus dem **Vorrat**. Was Blei verschießt, zieht 🧨 Munition (180), der Rest
🔷 Energiekristalle (120). Erst das Magazin erzeugt den Rhythmus aus Feuern und Deckung:

| Waffe | Magazin | Feuerdauer | Nachladen | Zyklus |
| :-- | --: | --: | --: | --: |
| Blei-Karabiner | 10 | 8,5 s | 2,2 s | 10,8 s |
| Messing-Gatling | 60 | 4,2 s | **4,5 s** | 9,0 s |
| Volt-Karabiner | 10 | 4,2 s | 2,4 s | 6,7 s |
| Säure-Sprüher | 24 | 5,8 s | 2,8 s | 8,6 s |
| Dampf-Brenner | 40 | 5,2 s | 3,2 s | 8,6 s |

Über den ganzen Zyklus gerechnet liegen alle fünf zwischen 31 und 43 Schaden pro Sekunde — der
**Spitzenschaden** dagegen zwischen 40 und 86. Die Waffen unterscheiden sich also stark darin,
*wie* sie liefern, und wenig darin, *wie viel*. Die Gatling kauft ihre 86 mit viereinhalb
Sekunden Wehrlosigkeit.

Nachgeladen wird automatisch bei leerem Magazin oder von Hand mit `[R]`, auch halbvoll. Ein
Waffenwechsel **bricht ab** — sonst wäre Umschalten ein kostenloser Weg um die Wartezeit herum.
Verkürzen lässt sich die Dauer über den Werkstatt-Ausbau **Schnellader** (−8 % je Stufe) und den
Item-Wert **`reload`** (−1 % je Punkt), zusammen gedeckelt bei 60 %. Der Perk **Munitionsgurt**
hebt jetzt endlich den Vorrat (+25 je Rang) — er stand seit jeher in der Tabelle und wirkte
nirgends. Unter dem Schuss-Knopf steht `Magazin/Größe  Vorrat`, beim Nachladen ein Balken mit
Restzeit.

**Charakter (`[C]` oder 🎽 oben links):** zwei Reiter. **Ausrüstung** zeigt Getragenes, das
Werte-Blatt und den Beutel — anlegen, ablegen, verschrotten. Der Beutel ist ein Grid: eine
Rüstung belegt 2×2 Plätze, eine Waffe 2×1. **Fähigkeiten** gibt die Perk-Punkte aus, die bei
jedem Aufstieg anfallen; gesperrte Perks nennen daneben, was ihnen fehlt.

Tastatur: `[Leertaste]` schießen, `[Tab]` Waffe, `[E]` aufheben/öffnen/ansprechen, `[C]`
Charakter, `[M]` Karte, `[Esc]` schließen, `[1]`–`[5]` Iron Rail (nur am Bahnsteig, GDD §1.4a).

**Zoom (`＋`/`－` unter der Minikarte, Mausrad, `[+]`/`[−]`, Kneifen):** vier Stufen von **7,5 m**
bis **16 m** Kameraabstand — nah für Stadt und Dungeon, fern für lange Wüstenwege. Gemessen an
der Bildhöhe ist die Figur dabei 25,7 % → 20,3 % → 15,4 % → **12,1 %**; die weiteste Stufe trifft
damit genau die 12–15 % der Diablo-Vorlagen. Die Stufe steht im Spielstand.

> **Von Hand, nicht automatisch.** Automatisches Zoomen nimmt die Entscheidung ab und wechselt
> im falschen Moment — beim Betreten der Stadt mitten im Gefecht, oder im Sekundentakt am
> Ortsrand. Wann man Übersicht und wann man Details braucht, weiß nur, wer gerade spielt.

## Licht: Schatten sind der Unterschied

Bis zuletzt warf in der Szene **nichts einen Schatten** — eine einzelne Sonne ohne
`shadow_enabled`, dazu Umgebungslicht auf 0,8. Zwischen Licht- und Schattenseite lag damit nur
der Faktor **2,4**, und deshalb wirkte jedes Objekt flach aufgeklebt statt auf dem Boden
stehend. Jetzt sind es **6,0** (Sonne 1,6 gegen Umgebung 0,32), plus:

* **Zwei Schattenkaskaden auf 60 m.** Wir sehen 15 m weit; 60 m decken alles ab, was ins Bild
  kommt, und geben der Nahzone die volle Auflösung einer 2048er Karte. Der flache Boden ist vom
  Schattenwurf ausgenommen — er kann keinen werfen und ist die größte Geometrie der Szene.
* **Filmic-Tonemapping** statt Godots linearer Vorgabe, die helle Sandflächen ausbleichen lässt.
* **Dünne Luftperspektive** (Nebeldichte 0,0007), damit Entfernung sichtbar wird — bewusst
  schwach, weil Kraterrand und Eisernes Herz als Landmarken am Horizont lesbar bleiben müssen.

> Der Renderer steht auf **mobile** (wegen Xogot). Damit gibt es kein SSAO und keine
> volumetrische Beleuchtung — Schatten, Tonemapping und Tiefennebel dagegen schon.

**Ortsschrift:** Beim Betreten eines Ortes zieht sein Name groß und gesperrt über die
Bildmitte und blendet über vier Sekunden wieder weg. Auch das Verlassen wird angesagt
(„OFFENE WÜSTE"), damit die Wildnis ein Ort ist und kein Nichts.

## Topografie: Senken sind eine Formel, kein Modell

Der Boden war eine flache Platte bei y = 0, und die Figur bekam ihr y nie von irgendwoher — ein
modelliertes Gelände wäre Kulisse geblieben, durch die man hindurchspaziert.

Stattdessen liefert **`WorldManager.height_at(x, z)`** für jeden Punkt der Welt die Bodenhöhe.
Aus derselben Funktion entstehen das sichtbare Netz **und** die Höhe, auf der Spieler, Gegner
und Beute stehen. Eine Quelle, mehrere Verbraucher — ein Modell mit getrennter Kollision liefe
früher oder später auseinander.

Formen stehen als Daten in **`WorldManager.TERRAIN`** — vier Zahlen je Senke:

| Feld | Bedeutung |
| :-- | :-- |
| `radius` | Rand der Senke; dort ist die Höhe wieder 0 |
| `depth` | Tiefe in der Mitte |
| `rim` | Höhe des Auswurfwalls direkt außerhalb |
| `rim_width` | Breite des Walls als Anteil des Radius |

Das Profil hat zwei Abschnitte, beide mit **waagerechtem Anschluss** — es gibt keine Kante:

1. **Schale** `-depth · (1 − smoothstep(t))` — in der Mitte flach (dort steht etwas gerade), am
   Rand flach, am steilsten auf halbem Weg.
2. **Wall** `rim · sin²(…)` — der Auswurf eines Einschlags, ebenfalls an beiden Enden waagerecht.

**Die Schrotthalde** (an den Schrott-Minen) misst 30 m im Durchmesser bei 4 m Tiefe. Gemessen:
steilste Stelle **21,8°** auf halber Flanke, größter Höhensprung auf 5 cm Weg **unter 4 cm**,
außerhalb des Walls exakt 0,000 m. Das Netz kostet 16 200 Dreiecke.

Die flache Restfläche wird um jede Form **ausgeschnitten** (Rechteck-Subtraktion), sonst läge
sie über der Senke. Ein Test prüft, dass Restfläche + Löcher exakt die Weltfläche ergeben.

> Wo Gelände geformt ist, entfällt die Landmarken-Säule des Ortes — sie stand sonst mitten im
> Kratergrund und sperrte ihn.

## Die Stadt im Editor bearbeiten

`scenes/Rustwater.tscn` ist eine **normale, editierbare Szene**: jedes Haus ein Knoten, den man
im 3D-Fenster anfassen, verschieben und drehen kann. Doppelklick im Dateisystem, und die Stadt
steht sichtbar da.

Beim Start lädt `OverworldView` diese Szene und leitet die **Kollision aus den tatsächlichen
Positionen** ab — verschobene Häuser nehmen ihre Sperre mit, ohne dass im Code eine Zahl
geändert wird. Das gilt auch für die **Palisade**: Sie wird nicht mehr vom Code als Kreis
gebaut, sondern hier von Hand gestellt.

### Bauteile aus `scenes/parts/`

**Nicht die GLBs aus `assets/models/` in die Szene ziehen** — die kommen im Rohmaßstab. Ein
Palisadenstück ist so 1,91 m lang und 0,75 m hoch (kniehoch) und steckt zur Hälfte im Boden.

Stattdessen liegen unter **`scenes/parts/`** fertige Bauteile: richtige Größe, richtige
Blickrichtung, Unterkante exakt auf Y = 0. Hineinziehen, hinschieben, fertig — Häuser
(`saloon`, `forge`, `water_tower`, `shack_a`–`d`), Mauerstücke (`palisade_a`–`e`) und das Tor
(`gate`). Neu erzeugen, wenn ein Asset dazukommt:

```
godot --headless --path . res://tools/MakeParts.tscn
```

**Gruppieren ist erlaubt:** Dreißig Mauerstücke unter einem gemeinsamen `Node3D` bleiben
einzeln kollidierbar — `_register_town` läuft durch Ordnerknoten hindurch und vermisst die
Teile darin, nicht die Gruppe als Ganzes.

**Mauern werden nicht geschrumpft.** Häuser bekommen 18 % Abzug auf ihre Kollision, weil
Vordächer und Schornsteine in der Bounding-Box stecken. Bei einer Mauer wäre derselbe Abzug ein
Loch: Gemessen ergeben drei aneinandergesetzte Stücke mit Gebäude-Schrumpf **sieben begehbare
Lücken auf 17 m**, ohne ihn null. Erkannt wird das am Asset-Namen
(`AssetRegistry.is_wall` — alles mit `palisade`, `gate`, `wall`, `mauer`, `zaun`, `fence`).

**Zwei Regeln beim Umstellen:**
* **Fassaden zur Kamera.** Die Kamera steht immer 20° südöstlich (`CAM_YAW`) — Häuser, die
  einander anschauen, zeigen dem Spieler die Rückseite. Alle Fronten sollten in etwa dieselbe
  Richtung weisen, mit ein paar Grad Streuung.
* **Unterkante auf Y = 0.** Die Bauteile aus `scenes/parts/` bringen das schon mit.

**Warum die Overworld-Szene im Editor leer aussieht:** Boden, Biome, Kraterrand, Straßen,
Trasse und Dekor entstehen zur Laufzeit aus den `WorldManager`-Daten — 5000 × 5000 m lassen
sich nicht sinnvoll von Hand stellen. Sichtbar wird das erst mit **Play**. Nur die Stadt ist
als echte Szene ausgelagert, weil genau dort Layout-Arbeit anfällt.

## Dateien
- `scripts/GameState.gd` — globaler Laufzeit-Zustand (Single Source of Truth).
- `scripts/QuestManager.gd` — Quests, Fraktions-Locking, Kapitel-Progression, Reveal.
- `scripts/CombatData.gd` — Kampf-Registries: Schadensarten, Waffen, Gegner-Statblöcke,
  `xp_for_kill()`, `weapon_acid()` (statische Klasse, `class_name`).
- `scripts/CombatTarget.gd` — veränderlicher Kampf-Zustand einer Einheit (Leben,
  Panzerung, Stun/DOT); `from_type(type, {elite, superboss, depth})` inkl.
  Tiefen-Skalierung für Multilevel-Dungeons (GDD §1.6).
- `scripts/CombatEngine.gd` — **Modul 1:** mathematische Kampf-/Mitigations-Engine:
  `calculate()` (Matrix + Flanken-Logik), `apply_status()`, `tick_dot()`, `resolve_hit()`,
  `mitigate_damage()` / `player_damage_taken_mul()` (alles `static`).
- `scripts/TycoonManager.gd` — **Modul 2:** aktive Rustwater-Wirtschaft (Node-Autoload):
  Sekunden-Tick nur bei aktiver Spielzeit, Kostenkurve, Ripple-Booster.
- `scripts/GridInventoryBackend.gd` — **Modul 3:** reines Grid-Inventar (`class_name`,
  instanziierbar): Footprint-Prüfung, Insert/Remove, Auto-Platzierung.
- `scripts/ProgressionManager.gd` — **Itemization & Perks** (GDD §7.4.3/§7.5.1/§7.5.2/§8.1):
  Seltenheiten, Affixe mit Roll-Varianz (deterministisch via `quality_roll`), legendäre Kräfte
  (`make_gear`, `force_power` für Boss-Drops), Tech-Module — sowie der **Fallout-Perk-Baum**
  (Zweige/Tiers/Kapsteine mit xor, Kauf, Respec) über `GameState`. Alles seedbar/testbar.
- `scripts/RiftManager.gd` — **Abstieg-Endlosmodus** (GDD §7.5.6/§8.1): rotierende Biome (alle 5
  Ebenen), Zufalls-Modifikatoren, Tiefen-Skalierung (Leben/Dichte/Elite-Zahl), Superboss-Kadenz.
- `scripts/EquipManager.gd` — **Loadout & legendäre Sets** (GDD §7.4/§7.4.4): Equip-Slots
  (Anlegen/Ablegen, Slot-Akzeptanz), Stat-Aggregation, getragene Legendaries — und **Set-Boni**,
  die Stats geben oder eine Kraft *verleihen* (`has_power` meldet sie wie ein getragenes Legendary).
- `scripts/PlayerStats.gd` — **effektive Kampfwerte** (Kapstein, GDD §6/§7.5): aggregiert **alle**
  Systeme zu den finalen Zahlen — Basis-Waffe + Werkstatt-Upgrades + Loadout + Perks +
  getragene/Set-verliehene legendäre Kräfte (Schaden, Feuerrate, Krit, Rüstung/Mitigation,
  max. Leben, Tempo, Regen, Magnet, Spread/Pierce, Loot). Formeln 1:1 aus dem Prototyp, deterministisch.
- `scripts/AssetRegistry.gd` — **Asset-Pipeline**: logischer Name → 3D-Modell mit
  automatischem **Fallback auf Primitives**, wenn die Datei (noch) fehlt. Macht Modelle
  beliebiger Herkunft einbaufertig: Skalierung auf die Zielhöhe in Metern (inkl. verschachtelter
  glTF-Transforms), **Unterkante auf Y = 0** (generierte Assets haben den Pivot fast nie am
  Boden) und Blickrichtungs-Korrektur über `YAW_DEG`.
  Spielt außerdem **Animationen** ab (`play_clip("walk"/"idle"/"attack"/…)`) und findet die
  Clips über Namensteile — „Walking", „Armature|Walk", „laufen" landen alle auf derselben Rolle,
  niemand muss Exporte umbenennen. Fehlt eine Rolle, steht das Modell still; nichts bricht.
  Neues Asset = **GLB ablegen**, kein Code-Change (Export-Einstellungen, Pfade & Zielhöhen:
  `assets/README.md`).
- `scripts/OverworldView.gd` + `scenes/Overworld.tscn` — **sichtbare Overworld** (GDD §1.4/§1.4a/§1.6):
  generiert den 5000-m-Krater zur Laufzeit aus `WorldManager` (Boden, Biom-Zonen, Sprengtor-/
  Smog-Linie, Kraterrand + Rand-Tunnel, POI-Landmarken, Eisernes-Herz-Turm), Spieler mit
  virtuellem Joystick, Gegner-Rudel + Auto-Feuer via `PlayerStats`/`CombatEngine`. Trägt auch
  die **bauliche Begrenzung** (§1.4a): Häuser, Palisade mit vier Toren und Turmbeine sperren
  über `_solid_box/_solid_pillar/_solid_ring` → `_blocked()` — dieselben Zahlen bauen die Optik
  und die Kollision. Nur Primitives — keine Asset-Abhängigkeit, läuft sofort in Xogot/Editor/headless.
- `scripts/SaveManager.gd` — **Persistenz** (GDD §2.3): serialisiert/lädt den `GameState`
  (inkl. Loadout; Dictionary/JSON, defensiv gegen JSON-Floats & fehlende Felder) inkl. Datei-Slots (`user://`).
- `scripts/EncounterManager.gd` — **Mini-Dungeons & Unique-Champions** (GDD §7.5.6a/§8.2):
  Kritter-Hallen-Themen (Roll), Champion-Wurf (~30 %), Champion-Aufbau (×6 HP, benannt, Boss) und
  der Champion-Beute-Kontrakt (garantiertes Legendary; Item-Gen via `ProgressionManager` offen).
- `scripts/MemoryManager.gd` — **roter Faden** (GDD §7.5.12a/b/§8.3): Erinnerungs-Walzen
  (geordnete 16er-Kette, Drop-Logik 3 %/50 %) & Familien-Bogen (Providence-Cut-Memorials,
  gestufte Gräber, `bury_family`, Codex/Erfolge) — alles über `GameState` (`class_name`, `static`).
- `scripts/WorldManager.gd` — Weltgeografie, Gating & **Biom-Zonierung** (GDD §1.6/§1.7/§1.6.3):
  POI-Registry mit Koordinaten, Sektor-Logik, die drei Tore (Sprengtore, Smog-Linie, Fraktions-
  Feindseligkeit) und die aus dem Prototyp portierten **Biom-Zonen** (Palette/Flora/Gegner-Leitmix,
  ans Sektor-Gating gebunden) — alles als aus `GameState` abgeleitete Abfragen (`class_name`, `static`).
  Dazu die **Weltstruktur** (§1.4a): `ROUTES`/`on_route()` (Pisten als Wegführung, keine Sperre),
  `zone_at()`/`zone_radius()`/`is_safe_zone()` (Aktionszonen) und `RAIL_STATIONS`/`rail_segments()`
  (Iron Rail). `is_walkable()` begrenzt nur noch den Kraterrand — die Wüste ist offen.

## Weltgeografie & Gating (WorldManager)
Koordinaten: Ursprung SW-Ecke, X = W→O, Y = S→N (0…2000). Alle Gate-Zustände sind aus
`GameState` abgeleitet (kein Doppel-Zustand).

```gdscript
WorldManager.sector_of_pos(Vector2(1000, 1600))   # 3
WorldManager.poi_position("eisernes_herz")        # (1000, 1950)
WorldManager.dungeon_floors("schmelzoefen_vulcan")# 4 (multilevel)

# Gate 1 — Sprengtore (Y=800): erst nach Kapitel 4 offen.
WorldManager.is_blast_gate_open()                 # current_chapter >= 5
WorldManager.can_cross_blast_line(from_y, to_y)   # blockt Nord-Querung, wenn zu

# Gate 2 — Smog-Linie (Y=1500): tödlicher DOT ohne Alchemie-Filter (Labor Stufe 3).
GameState.set_building_level("laboratory", 3)     # schaltet den Filter frei
WorldManager.has_alchemie_filter()                # true
var dmg := WorldManager.smog_dot_damage(player.global_position_2d, delta)  # 0 mit Filter

# Gate 3 — Fraktions-Feindseligkeit (nach Gildenwahl):
QuestManager.choose_guild("rebels")
WorldManager.is_base_hostile("sektor01")          # true  (fremdes HQ -> Geschützturm-Aggro)
WorldManager.is_base_friendly("fort_freedom")     # true  (eigene Gilde)

# Biom-Zonierung (§1.6.3) — geografische Zonen mit eigenem Gegner-Mix, ans Gating gebunden:
WorldManager.biome_at(Vector2(1120, 1080))        # "rostwald" (Sektor 2, Wildnis)
WorldManager.biome_at(Vector2(0, 1600))           # "smog_oedland" (Sektor 3)
WorldManager.pick_enemy_type("kupfer_hochland", true)   # bevorzugt Konstrukte (industriell)
WorldManager.is_biome_unlocked("smog_oedland")    # false ohne Alchemie-Filter (erbt Sektor-3-Gate)
```

## Modul 1 — Kampf-Backend (CombatEngine)
`CombatData`, `CombatTarget` und `CombatEngine` sind `class_name`-Klassen (statisch bzw.
per `.new()`), **kein Autoload nötig**. Wechselwirkungs-Matrix & Werte entsprechen exakt
dem verifizierten Web-Prototyp (Master-GDD §6.2/§6.3).

```gdscript
var now := Time.get_ticks_msec()
# Gegner aus dem Roster (optional Elite/Superboss/Tiefe):
var guard := CombatTarget.from_type("konstrukt")            # MECHANICAL, armor 15
var titan := CombatTarget.from_type("goliath", {"superboss": true, "depth": 2})

# Treffer eines galvanischen Volt-Karabiners auf den Automaten:
var hit := CombatEngine.resolve_hit(CombatData.GALVANIC, guard, 40, 0, now)
# hit == { damage: 100, effect: "SHORT_CIRCUIT_STUN"(40%), immune: false, killed: false }

# Front-Immunität: frontal 0 Kinetik, bis Säure die Panzerung auf 0 ätzt; Flanke umgeht sie.
CombatEngine.calculate(CombatData.KINETIC, titan, 40).damage            # 0 (frontal, armor>0)
CombatEngine.calculate(CombatData.KINETIC, titan, 40, 10, false).damage # Flanke: max(1, 40-armor)

# DOT/Stun pro Frame verarbeiten:
if not guard.is_stunned(now):
    pass  # Bewegung/Angriff erlaubt
CombatEngine.tick_dot(guard, now, get_process_delta_time())

# Eingehender Schaden am Spieler (exakte Mitigations-Formel 100/(100+armor*9)):
var taken := CombatEngine.mitigate_damage(raw_damage, player_armor)
```

## Modul 2 — Aktive Wirtschaft (TycoonManager, Autoload)
Sekunden-Tick **nur bei aktiver Spielzeit** (kein Offline-Ertrag, kein Zeitstempel):
```gdscript
TycoonManager.income_per_sec()               # Σ level*income_per (ganzzahlig)
TycoonManager.upgrade_cost("forge")          # base_cost * (level+1), evtl. -10% (Forge-Boost)
TycoonManager.try_upgrade("forge")           # prüft Gold & Max, bucht ganzzahlig ab
TycoonManager.activate_boost("saloon", 60.0) # 60 aktive Sek: +15% Schmiede-Einkommen (Ripple)
TycoonManager.sell_value(200)                # +20% mit aktivem Destille-Boost
```

## Modul 3 — Grid-Inventar (GridInventoryBackend, instanziierbar)
```gdscript
var grid := GridInventoryBackend.new(10, 8)                   # 10x8 Zellen
var f := GridInventoryBackend.footprint("armor")             # Vector2i(2,2)
grid.can_fit_item(0, 0, f.x, f.y)                            # true
grid.insert_item(101, 0, 0, f.x, f.y)                       # belegt (0,0)-(1,1) mit uid 101
grid.find_first_empty_space(3, 1)                           # erster Platz für schwere Waffe
grid.place_first(102, 3, 1)                                 # Loot-Drop automatisch platzieren
grid.remove_item(101)                                       # Zellen der uid wieder frei
```

## Godot-Projekt & Tests
Die **Projekt-Wurzel ist dieser `godot/`-Ordner** (`project.godot`), also `res:// == godot/`.
Autoloads sind dort bereits registriert (Reihenfolge zählt); die `class_name`-Klassen
(CombatEngine, CombatData, CombatTarget, WorldManager, GridInventoryBackend) brauchen
**keinen** Autoload-Eintrag.

| Reihenfolge | Name | Pfad |
| :-- | :-- | :-- |
| 1 | `GameState` | `res://scripts/GameState.gd` |
| 2 | `QuestManager` | `res://scripts/QuestManager.gd` |
| 3 | `TycoonManager` | `res://scripts/TycoonManager.gd` |

**Headless-Tests** (abhängigkeitsfrei, kein GUT-Addon) — **zwei Pässe** bei einem kalten
Checkout ohne `.godot/`-Cache: erst importieren (baut den `class_name`-Global-Cache), dann
ausführen. Ohne den ersten Pass melden die `class_name`-Klassen (`CombatEngine`, `WorldManager`
…) beim allerersten Lauf „Identifier … not declared".

```sh
godot --headless --path godot --editor --quit                    # Pass 1: Import + Klassen-Cache
godot --headless --path godot res://tests/TestRunner.tscn        # Pass 2: Tests, Exit 0/1
godot --headless --path godot res://scenes/Overworld.tscn --quit-after 30   # Szenen-Smoke
```
(Hauptszene ist jetzt die Overworld — die Tests laufen deshalb über den expliziten Szenenpfad.)
`tests/TestRunner.gd` prüft alle Module deterministisch gegen die GDD-Werte
(Schadens-Matrix & Mitigation, Status/DOT, Quest-Fluss & Reveal, Gilden-Lock,
Tycoon-Tick/Kosten/Ripple, Grid-Platzierung, Welt-Gates, **Biom-Zonierung**,
**Erinnerungs-Walzen & Familien-Bogen**, **Mini-Dungeons & Champions**, **Itemization & Perks**,
**Abstieg-Endlosmodus**, **Persistenz**, **Loadout & legendäre Sets**, **effektive Kampfwerte
(Kapstein)**) und beendet mit
Exit-Code 0 (alles grün) bzw. 1.

Bei jedem Push/PR fährt der **CI-Workflow** (`.github/workflows/godot-backend.yml`) genau diese
Prüfung automatisch: `gdparse` + Godot-4.3-Headless (Import-Pass + TestRunner) gegen eine
asset-freie Projektkopie.

> **Verifiziert:** Godot **4.3.stable**, headless — **340/340 Checks grün, Exit 0**.
> Die **gesamte Spiel-Logik** ist portiert; offen bleibt nur die Präsentations-/Render-Schicht.
> Der schwere 3D-Asset-Import unter `assets/models`
> verlangsamt Pass 1; für reine Logik-Tests kann man Scripts/Tests/`project.godot` in ein
> asset-freies Verzeichnis kopieren und dort testen.

**Statische Prüfung ohne Godot-Runtime** (`gdtoolkit` von PyPI — nützlich, wenn kein
Godot-Binary verfügbar ist, z. B. in CI/Sandbox):

```sh
pip install gdtoolkit
gdparse scripts/*.gd tests/*.gd     # Syntax/Parse-Check (Exit 0 = ok)
gdlint  scripts/*.gd tests/*.gd     # Stil/Struktur (die breiten Daten-Tabellen
                                    # lösen bewusst `max-line-length` aus)
```
`gdparse` fängt Syntaxfehler vor dem Editor ab; die Laufzeit-Verifikation bleibt der
Headless-Test oben.

## Quest-Zustandsmaschine
```
available ──accept_quest()──▶ active ──complete_quest()──▶ done
```
- **Kill-Quests** (Rebellen, Eiserne Gilde, Kopfgelder): Bei Annahme wird
  `GameState.kills` als `quest_base[id]` eingefroren. Fortschritt = `kills − quest_base[id]`.
  Das Kampfsystem ruft bei jedem Tod `GameState.add_kill()` auf.
- **Collect-Quests** (Schmuggler, `q_scrap`): prüfen `GameState.inventory`; bei Abgabe
  werden die Items **atomar abgezogen** (schlägt der Abzug fehl, bricht die Abgabe ab).

### Schutz vor Doppel-Eingaben & Korruption
- `accept_quest` nur aus `available` → keine erneute `quest_base`-Neusetzung.
- `complete_quest` nur aus `active` **und** nur bei serverseitig geprüfter Erfüllung →
  keine doppelte Belohnung, kein Abschluss ohne Zielerreichung.
- `choose_guild` ist eine Einmal-Entscheidung (Kapitel-5-Gate, `chosen_guild == null`).
- `trigger_chapter_4_reveal` ist idempotent (kein Doppel-Reveal).

## Fraktions-Locking (Kapitel-5-Gate)
```gdscript
QuestManager.choose_guild("rebels")   # nur bei current_chapter == 5 && chosen_guild == null
# danach:
QuestManager.can_access_guild("rebels")   # true
QuestManager.can_access_guild("corp")     # false  -> fremde Gilden gesperrt
QuestManager.accept_quest("q_corp5")      # false  -> "guild_locked"
```

## Kapitel-4-Reveal (Zugüberfall)
```gdscript
QuestManager.trigger_chapter_4_reveal()   # reveal_playing = true, is_revealed = true
# ... Cutscene (REVEAL_LINES) spielt ...
QuestManager.finish_reveal()              # reveal_playing = false, Kapitel -> 5
```

## Minimalbeispiel
```gdscript
# Kapitel 5 erreicht, Reveal geschehen:
QuestManager.choose_guild("rebels")
QuestManager.accept_quest("q_rebels5")     # Kill-Quest: 12 Konzern-Schergen
# Kampfsystem meldet Kills:
for i in 12: GameState.add_kill()
QuestManager.check_quest_progress("q_rebels5")  # {current=12, target=12, complete=true}
QuestManager.complete_quest("q_rebels5")   # +250 Gold, +125 XP, +1 Dampfkern, Kapitel -> 8
```

## Enthaltene Quests (Master-GDD §4.2 / §4.3)
Hub: `q_bounty`, `q_scrap`, `q_rats` · Rebellen: `q_rebels5/8/12` ·
Eiserne Gilde: `q_corp5/8/12` · Schmuggler: `q_smug5/8/12`.
