# Asset-Credits & Lizenzen

Umgebungs- und Prop-Assets stammen von **[Poly Haven](https://polyhaven.com)** und sind
**CC0 (Public Domain)**. CC0 erfordert keine Namensnennung — dieser Nachweis dient der
Herkunft und Nachvollziehbarkeit. Jedes Paket: glTF + `.bin` + PBR-Texturen
(diff = Albedo, nor_gl = Normal (OpenGL), arm = AO/Roughness/Metallic gepackt), 1k = 1024px.

Charaktere entstehen in **[Meshy](https://www.meshy.ai)** — eigene Generierung inklusive
Auto-Rigging und Animations-Paket.

## Charaktere (`models/characters/`)
| Datei | Beschreibung | Einsatz | Herkunft |
| :-- | :-- | :-- | :-- |
| `player.glb` | Spieler-Chassis, gerigged (24 Joints), 20 Animationen, 18,9 k Dreiecke, 2k-Textur | Overworld-Spielfigur | Meshy (eigene Generierung) |

## NPCs (`models/npcs/`)
| Datei | Beschreibung | Einsatz | Herkunft |
| :-- | :-- | :-- | :-- |
| `mabel.glb` | Mamma „Rusty" Mabel, gerigged (24 Joints), 6 Animationen, 20,1 k Dreiecke, 1,70 m | Saloon-Wirtin, Quest `q_bounty` | Meshy (eigene Generierung) |
| `silas.glb` | Silas „Kupferauge" Finch, gerigged, 4 Animationen, 19,6 k Dreiecke, 1,75 m | Schmied, Quest `q_scrap` | Meshy (eigene Generierung) |
| `doc.glb` | Doktor „Doc" Aris, gerigged, 4 Animationen, 19,5 k Dreiecke, 1,80 m | Feldarzt, Quest `q_rats` | Meshy (eigene Generierung) |

Alle drei tragen **dasselbe 24-Knochen-Rig wie der Spieler** und dasselbe Animationspaket
(`Stand_and_Chat` als Ruhepose, dazu Walking/Running). Sie stehen an ihrem Platz und schauen
zum Stadtplatz.

## Gegner (`models/enemies/`)
| Datei | Beschreibung | Einsatz | Herkunft |
| :-- | :-- | :-- | :-- |
| `konstrukt.glb` | Kleiner Panzer, statisch (kein Rig), 15 k Dreiecke (von 1,41 Mio. reduziert), PBR mit Normal- und Metallic-Roughness-Map | Konzern-Konstrukt (Maschine, §8.4) | Meshy (eigene Generierung) |
| `fauna.glb` | Ratte, gerigged aber ohne Animationen, 7,9 k Dreiecke, PBR mit Normal- und Metallic-Roughness-Map | Ölfresser-Ratte (organisch, Schwarm) | Meshy (eigene Generierung) |

Alles aufbereitet mit `tools/prepare_meshy_glb.py` (Dreiecks-Budget, 4k→2k-Texturen,
Selbstleuchten/BLEND/doubleSided/metallicFactor bereinigt): Spieler 40,7 → 2,3 MB,
Panzer 51,8 → 3,8 MB, Ratte 26,3 → 4,0 MB. Clip-Zuordnung: `AssetRegistry.CLIP_OVERRIDES`.

## Gebäude (`models/buildings/`)
| Datei | Beschreibung | Einsatz | Herkunft |
| :-- | :-- | :-- | :-- |
| `saloon.glb` | Gatling-Saloon, 14 k Dreiecke (von 1,06 Mio.), im Spiel 13,3 × 11,9 m, 8,5 m hoch | Township-Kern (§2.2 Auftragsbrett) | Meshy (eigene Generierung) |
| `forge.glb` | Eiserne Schmiede, 14 k Dreiecke (von 1,46 Mio.), 10,0 × 9,4 m, 7,0 m hoch | Handelsposten (§2.2) | Meshy (eigene Generierung) |
| `shack_a…d.glb` | Vier Hütten-Bauweisen: 8 k / 6 k / 6 k / 11,9 k Dreiecke (aus 0,83–1,82 Mio.), 5,3–7,2 m breit, 4,0–5,2 m hoch | Hüttenring (10 Stück, reihum gemischt, zusätzlich gedreht und leicht skaliert) | Meshy (eigene Generierung) |
| `water_tower.glb` | Wasserturm, 10 k Dreiecke (von 0,93 Mio.), 9,4 × 8,0 m, 18 m hoch | Rustwaters Silhouette | Meshy (eigene Generierung) |
| `gate.glb` | Geschlossenes Palisadentor, 8 k Dreiecke (von 0,94 Mio.), 8,0 m breit, 6,0 m hoch | verriegeltes Nordtor | Meshy (eigene Generierung) |
| `palisade_a…e.glb` | Fünf Wandstück-Varianten, je 1,5 k Dreiecke, 7,6–8,6 m lang, 3,4 m hoch, 1k-Texturen | Stadtmauer-Ring (~60 Stück, zufällig gemischt) | Meshy (eigene Generierung) |

## Waffen (`models/weapons/`)
| Datei | Beschreibung | Einsatz | Herkunft |
| :-- | :-- | :-- | :-- |
| `karabiner.glb` | Blei-Karabiner, 4 k Dreiecke (von 108 k), 1,0 m lang, 1k-Texturen | In der rechten Hand des Spielers (`RightHand`) | Meshy (eigene Generierung) |

Die Waffe wird über die **Länge** skaliert, nicht über die Höhe (`AssetRegistry.TARGET_LENGTH`):
Ein Karabiner ist 40 cm hoch und einen Meter lang — auf 1 m Höhe skaliert wäre er 4,75 m lang.

Die Palisaden bekommen bewusst nur 1k-Texturen und 1,5 k Dreiecke: sie stehen rund sechzigmal
im Ring, da zählt jedes Dreieck sechzigfach.

## Umgebung / Boden & Felsen (`models/environment/`)
| Ordner | Beschreibung | Einsatz | Lizenz |
| :-- | :-- | :-- | :-- |
| `gravelly_sand_1k/` | Kiesiger Sandboden (tileable Plane) | Wüsten-/Sektor-1-Boden | CC0 · Poly Haven |
| `sand_rocks_small_01_1k/` | Kleine Sandsteine (Scatter-Detail) | Boden-Streuung | CC0 · Poly Haven |
| `namaqualand_cliff_02_1k/` | Felsklippe | Sektorgrenzen, Canyon (Rogue's Landing) | CC0 · Poly Haven |
| `namaqualand_boulder_03_1k/` | Findling/Felsbrocken | Deckung, Landschafts-Dekor | CC0 · Poly Haven |

## Gameplay-Items (`models/items/`)
| Ordner | Beschreibung | Passt zu | Lizenz |
| :-- | :-- | :-- | :-- |
| `treasure_chest_1k/` | Schatztruhe | Loot-Kisten (§7.7), Boss-/Cache-Beute | CC0 · Poly Haven |
| `stick_grenade_1k/` | Stielhandgranate | Säure-/Elektrofeld-Wurf-Granate (§7.2) | CC0 · Poly Haven |

## Deko / Props (`models/props/`)
| Ordner | Beschreibung | Passt zu | Lizenz |
| :-- | :-- | :-- | :-- |
| `ammo_box_1k/` | Munitionskiste | Loot-Kisten, Basen, Kampfzonen | CC0 · Poly Haven |
| `worn_metal_rack_1k/` | Abgenutztes Metallregal | Werkstatt, Händler, Lager | CC0 · Poly Haven |
| `chemistry_set_1k/` | Chemie-/Alchemie-Set | Alchemie-Raffinerie/Labor (§1.7.2) | CC0 · Poly Haven |
| `industrial_wall_lamp_1k/` | Industrie-Wandlampe | Gaslampen-Beleuchtung (Saloon, Rogue's Landing) | CC0 · Poly Haven |
| `tool_cart_1k/` | Werkzeugwagen | Eiserne Schmiede, Werkstatt | CC0 · Poly Haven |

## Hinweise
- Godot importiert glTF automatisch (bin + Texturen liegen daneben, relative Pfade).
- `arm`-Texturen entsprechen der glTF-ORM-Konvention (AO/Roughness/Metallic) — Godot
  ordnet sie beim Import korrekt zu.
- Bei weiterem Wachstum der Asset-Bibliothek **Git LFS** erwägen (aktuell ~53 MB direkt
  versioniert).
