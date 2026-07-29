# Bild-Prompts für die Schrottgrube

Die Grube bei den Schrott-Minen ist der Ort, an dem der Held erwacht — das erste Bild des
Spiels. Vorlage sind die drei Bilder aus dem Chat: ein Loch mit steilen Erdwänden, dessen
Grund von Rand zu Rand unter Metall verschwindet, mit einer Lache in der Mitte.

**Gebaut ist bereits:** die Grube selbst (30 m Durchmesser, 5 m tief, 66°-Wände, eine Rampe
im Nordosten), die Lache, Geröll auf der Lippe und ein Schrottteppich aus 128 Stücken.

**Was fehlt, ist Vielfalt.** Der Teppich besteht heute aus fünf Modellen — zwei Schrotthaufen
und drei Fass-/Kisten-Stapel, jeweils in einer normalen und einer verrosteten Fassung. Bei
128 Stücken sieht man die Wiederholung. In der Vorlage liegen dagegen erkennbar
*verschiedene Maschinen* durcheinander: Kessel, Speichenräder, Rohre, Gitterrahmen,
Schaltschränke. Genau die acht unten fehlen.

---

## Regeln (wichtiger als bei allem bisher)

* **Wenig Dreiecke, wirklich wenig.** Jedes dieser Teile liegt zehn- bis zwanzigfach in der
  Grube. Ziel sind **800–1 500 Dreiecke**. Das Aufbereitungs-Skript reduziert zwar, aber bei
  den zwei vorhandenen Schrotthaufen bleibt es bei 6 600 bzw. 3 600 hängen — sie bestehen aus
  vielen losen Einzelteilen, und jede Bruchkante wird als Rand geschützt. **Ein Stück, das
  zusammenhängt, lässt sich viel weiter reduzieren als eine lose Ansammlung.** Deshalb bitte
  jeweils EIN Objekt, nicht eine Gruppe.
* **512er Textur genügt.** Die Stücke sind auf dem Bildschirm handgroß.
* **Silhouette ist alles.** Ein Speichenrad erkennt man am Umriss, ein Kessel an der Wölbung.
  Nieten und Schrauben sieht man nie.
* **Rost, nicht Lack.** Braunrot, Orangerost, stumpfes Grau. Kein Glanz, keine Farbe.
* **Liegend, nicht stehend.** Alles hier ist hingefallen. Ein aufrecht stehendes Modell muss
  ich im Spiel kippen, und dann steht es auf einer Kante.

Ablauf wie gehabt: Bild erzeugen → **Meshy Image to 3D** → in den Chat, ich mache den Rest
(`prepare_meshy_glb.py`, Rostfassung, Registrierung, Einbau).

---

## 1. Liegender Kessel (`props/scrap_boiler.glb`) — 2,4 m lang

Das prägendste Einzelteil der Vorlage: In allen drei Bildern liegt mindestens ein solcher
Tank quer im Haufen.

```
A single rusted industrial boiler tank lying on its side, grim-dark steampunk western style,
shown alone as a 3D game asset concept, seen from a high three-quarter angle roughly 45
degrees above the horizon.
A riveted cylindrical iron boiler about 2.4 metres long and 1.1 metres across, one domed end
cap intact with a heavy bolted flange, the other end torn open and crumpled inward. A short
stub of pipe and a broken pressure gauge mount still attached near the top. The surface is
deeply pitted with rust, seams and rivet lines clearly readable in the silhouette.
Dark brown-red rust, patches of flaked grey paint, dust in the pitting.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire object visible and centered with margin on all sides. Single connected object, no loose
debris around it. No people, no text, no lettering, no logos, no watermark. Photorealistic PBR
game asset, very low polygon count, high detail.
```

## 2. Großes Speichenrad (`props/scrap_flywheel.glb`) — 1,8 m Durchmesser

Der zweite Wiedererkennungswert der Vorlage. Bitte **halb liegend**, an eine Kante gelehnt —
ein flach liegendes Rad verschwindet im Haufen, ein aufrecht stehendes fällt um.

```
A large cast-iron spoked flywheel from a steam engine, lying tilted at an angle as if fallen,
grim-dark steampunk western style, shown alone as a 3D game asset concept, seen from a high
three-quarter angle roughly 45 degrees above the horizon.
A heavy wheel roughly 1.8 metres across with eight thick tapered spokes, a broad flat rim and a
massive hub with a square keyway. Two spokes are cracked through, one is missing entirely. The
wheel rests tilted at about thirty degrees, one edge dug into the ground.
Dark rust brown throughout, orange corrosion blooms on the rim, the hub almost black.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire wheel visible and centered with margin on all sides. Single connected object. No people,
no text, no logos, no watermark. Photorealistic PBR game asset, very low polygon count, high
detail.
```

## 3. Rohrbündel (`props/scrap_pipes.glb`) — 2,8 m lang

Der Lückenfüller. Lange dünne Formen sind das, was einem Haufen die Unordnung gibt — alles
Kompakte stapelt sich zu Klumpen.

```
A bundle of rusted iron pipes lying loosely together, grim-dark steampunk western style, shown
alone as a 3D game asset concept, seen from a high three-quarter angle roughly 45 degrees above
the horizon.
Five or six heavy pipes of different diameters, roughly 2.8 metres long, lying roughly parallel
but splayed apart at one end, two of them bent, one with a flanged coupling still bolted on and
one crushed flat at the tip. A loop of rusted wire holds two of them together near the middle.
Deep rust brown, darker inside the pipe mouths, pale dust along the upper surfaces.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire bundle visible and centered with margin on all sides. No people, no text, no logos, no
watermark. Photorealistic PBR game asset, very low polygon count, high detail.
```

## 4. Gitterrahmen / Leiterstück (`props/scrap_frame.glb`) — 3,0 m lang

Im mittleren Bild deutlich zu sehen: schräg aus dem Haufen ragende Rahmen. Sie brechen die
Silhouette auf und sorgen dafür, dass der Haufen nicht wie ein Hügel aussieht.

```
A twisted section of riveted iron lattice framework, like a torn-off piece of a gantry or
walkway, grim-dark steampunk western style, shown alone as a 3D game asset concept, seen from a
high three-quarter angle roughly 45 degrees above the horizon.
Two parallel angle-iron rails about 3 metres long joined by diagonal cross braces and a few
surviving grating slats, the whole piece bent and wrung out of true, one corner torn where the
rivets ripped through. Ragged bolt holes along the broken end.
Rust brown, black in the shadowed hollows, bare scratched steel on one bent edge.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire piece visible and centered with margin on all sides. No people, no text, no logos, no
watermark. Photorealistic PBR game asset, very low polygon count, high detail.
```

## 5. Schaltschrank (`props/scrap_cabinet.glb`) — 1,9 m hoch, liegend

Der „Kühlschrank" aus deinem dritten Bild — das große kastige Ding, das dem Haufen Masse gibt.
Bitte **umgekippt** modellieren.

```
A heavy iron machine cabinet lying toppled on its side, grim-dark steampunk western style,
shown alone as a 3D game asset concept, seen from a high three-quarter angle roughly 45 degrees
above the horizon.
A riveted steel cabinet roughly 1.9 metres tall, 0.9 wide and 0.7 deep, lying on its side. One
door hangs open on a single surviving hinge, revealing an empty interior with a few broken
brass fittings and a cut cable stub. A row of round gauge bezels and two lever switches on the
front face, all glass gone.
Rust brown over flaked dark green paint, brass fittings tarnished almost black.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire cabinet visible and centered with margin on all sides. No people, no text, no lettering,
no numbers on the gauges, no logos, no watermark. Photorealistic PBR game asset, very low
polygon count, high detail.
```

## 6. Kolben mit Stange (`props/scrap_piston.glb`) — 2,2 m lang

```
A broken steam engine piston with its connecting rod, grim-dark steampunk western style, shown
alone as a 3D game asset concept, seen from a high three-quarter angle roughly 45 degrees above
the horizon.
A thick cylinder about 0.9 metres long with a bolted end cap, from which a polished steel rod
roughly 1.3 metres long protrudes, ending in a heavy forked crosshead with a snapped pin. The
cylinder wall is split along one seam. The rod is the only part not fully rusted — it still has
a dull metallic sheen with rust creeping in from both ends.
Rust brown cylinder, dull grey steel rod, black grease residue at the joints.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire object visible and centered with margin on all sides. No people, no text, no logos, no
watermark. Photorealistic PBR game asset, very low polygon count, high detail.
```

## 7. Blechhaufen / verbogene Platten (`props/scrap_plates.glb`) — 2,0 m breit

Die Füllmasse. Flach, unregelmäßig, schließt die Lücken zwischen den großen Stücken — davon
brauche ich am meisten, und es ist zugleich das billigste Modell.

```
A low heap of buckled sheet-metal plates, grim-dark steampunk western style, shown alone as a
3D game asset concept, seen from a high three-quarter angle roughly 50 degrees above the
horizon.
Six or seven rusted iron sheets roughly 2 metres across in total, stacked and slumped over each
other at shallow angles, edges torn and curled, one plate folded almost double, another
perforated with a row of rivet holes. The heap is low and spread out, no higher than half a
metre.
Rust brown and orange, some plates almost black, thin sand drift caught in the folds.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire heap visible and centered with margin on all sides. No people, no text, no logos, no
watermark. Photorealistic PBR game asset, very low polygon count, high detail.
```

## 8. Zahnradgruppe (`props/scrap_gears.glb`) — 1,2 m breit

Kleinteil-Charakter: Das ist es, was aus „Metallschrott" **Steampunk**-Schrott macht.

```
A cluster of rusted iron gears and cogs fused together by corrosion, grim-dark steampunk
western style, shown alone as a 3D game asset concept, seen from a high three-quarter angle
roughly 50 degrees above the horizon.
Four or five toothed gear wheels of different sizes, the largest about 0.8 metres across,
jammed together at odd angles with a bent shaft running through two of them and a length of
heavy chain draped over the group. Several teeth are broken off. Total spread roughly 1.2
metres, low and compact.
Deep rust brown and orange, the chain almost black, pale dust in the tooth gaps.
Plain neutral mid-grey background, no ground plane, no cast shadows, even soft studio lighting.
Entire cluster visible and centered with margin on all sides. No people, no text, no logos, no
watermark. Photorealistic PBR game asset, very low polygon count, high detail.
```

---

## Was ich damit mache

Jedes Stück bekommt automatisch eine **verrostete Zweitfassung** (`tools/rust_variant.py`,
färbt nur die Farbtextur um) — aus acht Modellen werden also sechzehn Varianten. Zusammen mit
den fünf vorhandenen komme ich auf 26. Bei 128 Stücken in der Grube liegt dann im Schnitt
jedes fünfmal, gedreht, gekippt, unterschiedlich groß und teilweise vergraben. Das ist die
Schwelle, ab der man aufhört, Wiederholungen zu sehen.

## Was ich NICHT brauche

* **Keine Erdwände, keine Grube als Modell.** Die Form ist eine Formel
  (`WorldManager.TERRAIN`) — dadurch kennt der Spieler-Code in jedem Punkt die exakte
  Bodenhöhe, ohne dass irgendwo Kollisionsgeometrie liegen muss.
* **Keine Lache.** Steht als Scheibe im Code.
* **Keine Steine für den Rand.** Dafür laufen die vorhandenen CC0-Modelle.
