#!/usr/bin/env python3
"""Bereitet gelieferte Oberflaechen-Grafiken fuer das Spiel auf.

Aufruf:  python3 tools/prepare_ui.py <quellordner> [zielordner]
Vorgabe fuer den Zielordner: godot/assets/ui/

Warum ein Werkzeug und nicht von Hand: Bildgeneratoren liefern immer dieselben vier Macken,
und zwar bei JEDEM Satz. Von Hand nachbessern heisst, sie beim naechsten Satz wieder
nachzubessern — und beim uebernaechsten zu vergessen, welche Ecke man zuletzt gestempelt hat.

Was es tut:

1. **Doppelte Endungen aufraeumen.** Gemini liefert `icon_plate.png.png` und
   `portrait_mabel.png.jpg`. Godot laedt nach exaktem Pfad; ein zweites `.png` macht die Datei
   unsichtbar.
2. **JPEG nach PNG.** Zwei der drei Bildnisse kamen ohne Alphakanal. Fuer ein gefuelltes
   Quadrat ist das egal, aber im Projekt soll ein Dateityp liegen, nicht zwei.
3. **Das Funkel-Wasserzeichen entfernen.** Gemini setzt ein blasses ✦ in eine Ecke. Auf dem
   Pergament der Sprechtafel liegt es mitten im Text; auf einem Bildnis ist es ein weisser
   Fleck. Geheilt wird mit dem Mittelwert eines Rings um die Stelle — auf einer glatten Flaeche
   sieht man davon nichts.
4. **Eingebaute Rahmen abschneiden.** Ein Bildnis kam mit gemaltem Rahmen. Den Rahmen legt die
   Oberflaeche selbst darueber (`portrait_frame.png`); ein zweiter ergibt einen doppelten.
5. **Verkleinern.** Ein 1024er Sinnbild fuer eine 41-px-Zelle sind 4 MB Grafikspeicher fuer
   etwas, das nie groesser als 80 px erscheint.

Alles Weitere (Luft um das Motiv) rechnet das Spiel selbst weg, siehe `DialogBox._set_portrait`.
"""
import sys
import pathlib
from PIL import Image, ImageFilter

# Zielkantenlaenge je Art. Der Tafelrahmen bleibt gross: Er wird auf einem Telefon mit 2400 px
# Breite fast in Originalgroesse gezeichnet, alles darunter wuerde weich.
GROESSE = {"icon_": 256, "portrait_frame": 512, "portrait_": 512,
	"btn_": 256, "footprint": 128, "doll_body": 512}
## Der Tafelrahmen wird auf 240 px Hoehe gebracht. Grund: Sein Eisenband misst 15 % der
## Bildhoehe — bei 480 px sind das 73 px je Seite, also 146 px allein fuer die beiden Baender.
## Die Sprechtafel ist aber nur 168 px hoch. Beim 9-Patch bleiben die Ecken in ORIGINALGROESSE
## stehen; das Band haette die Tafel restlos ausgefuellt und der Text laege darunter. Auf 240 px
## sind es 37 px je Seite, und dazwischen bleibt Pergament fuer drei Zeilen.
HOEHE = {"dialog_frame": 240}

## Stellen, an denen das Funkelzeichen sitzt, und woher der Ersatz kommt.
##   name: (x, y, breite, hoehe, quelle_dx, quelle_dy, spiegeln)
##
## Von Hand eingetragen und nicht gesucht: Das Zeichen ist blasser als der helle Fleck in der
## Mitte des Pergaments, jede automatische Suche findet zuerst den. Bei einem neuen Satz mit
## anderen Massen hier nachtragen — die Stelle ist in zwei Minuten abgelesen.
FUNKEL = {
	# Pergament: ein Stueck von weiter links holen, dort ist derselbe glatte Verlauf.
	"dialog_frame": (1990, 286, 110, 104, -320, 0, False),
	# Schwarzer Bildnisgrund neben Docs Schulter: von der anderen Seite spiegeln.
	"portrait_doc": (830, 846, 118, 112, -560, 0, True),
	# Die Niete unten rechts: die unten LINKS spiegeln, der Rahmen ist symmetrisch.
	"portrait_frame": (800, 816, 168, 160, -608, 0, True),
}


def heile(im: Image.Image, angabe) -> Image.Image:
	"""Fleck mit einem STUECK VON NEBENAN ueberdecken, weich eingeblendet.

	Der erste Versuch nahm den Mittelwert eines Rings und legte ihn als Flaeche darueber. Im
	Kontaktabzug war das Ergebnis genau das, wonach es klingt: ein flacher Klotz mitten im Bild,
	sichtbarer als das Zeichen davor. Ein Stueck echtes Material von nebenan bringt Koernung und
	Verlauf gleich mit — und mit weichem Rand sieht man die Naht nicht.
	"""
	x, y, w, h, dx, dy, spiegeln = angabe
	quelle = im.crop((x + dx, y + dy, x + dx + w, y + dy + h))
	if spiegeln:
		quelle = quelle.transpose(Image.FLIP_LEFT_RIGHT)
	# Weiche Maske: in der Mitte voll, zum Rand hin auslaufend.
	maske = Image.new("L", (w, h), 0)
	rand = max(4, min(w, h) // 5)
	maske.paste(255, (rand, rand, w - rand, h - rand))
	maske = maske.filter(ImageFilter.GaussianBlur(rand * 0.6))
	im.paste(quelle, (x, y), maske)
	return im


def karo_weg(im: Image.Image, name: str) -> Image.Image:
	"""Das EINGEMALTE Karomuster in echte Transparenz verwandeln.

	Der teuerste Fund dieses Satzes: Kein einziges Bild war wirklich freigestellt. Gemini malt
	das Schachbrett, mit dem Bildprogramme Transparenz ANZEIGEN, als Pixel ins Bild. Im
	Kontaktabzug sieht das aus wie ein sauberer Freisteller — im Spiel lag ueber dem Bildnis von
	Mabel ein graues Karo, weil der „durchsichtige" Rahmen keiner war.

	Erkennbar ist es an zwei Dingen zugleich: Es ist vollkommen NEUTRAL (R = G = B, das Motiv
	ist ueberall rostig oder ledrig) und es besteht aus genau ZWEI Toenen (255 und 194). Beides
	zusammen trifft kein gemaltes Material — ein Metallglanz hat immer einen Farbstich.

	Bildnisse sind ausgenommen: Die sind ein gefuelltes Quadrat, dort gehoert nichts weg. Bei
	ihnen schneidet `bildnis_feld` das Karo ohnehin ab.
	"""
	if name.startswith("portrait_") and name != "portrait_frame":
		return im
	import numpy as np
	a = np.asarray(im).astype(int)
	rgb = a[:, :, :3]
	neutral = (rgb.max(axis=2) - rgb.min(axis=2)) <= 8
	if neutral.mean() < 0.05:
		return im
	# Welche NEUTRALEN Toene kommen so oft vor, dass sie Flaeche sein muessen?
	#
	# Der erste Anlauf hatte die beiden Toene fest eingetragen (255 und 194) — die waren aber
	# nur bei einem der elf Bilder richtig. Bei den anderen blieb das halbe Karo stehen: die
	# weissen Felder weg, die grauen da. Jetzt werden sie je Bild gesucht.
	wert = rgb.mean(axis=2).astype(int)
	werte, anzahl = np.unique(wert[neutral], return_counts=True)
	gesamt = float(wert.size)
	toene = [int(w) for w, n in zip(werte, anzahl) if n / gesamt > 0.035]
	if not toene:
		return im
	# Von der dunkelsten bis zur hellsten gefundenen Stufe ALLES neutrale wegnehmen, nicht nur
	# die Stufen selbst. Dazwischen liegen die weichgezeichneten Nahtlinien der Karos — beim
	# ersten Versuch blieben sie als feines graues Gitter stehen, das im Spiel wie ein Kratzer
	# ueber jedem Sinnbild lag.
	unten, oben = min(toene) - 10, max(toene) + 10
	karo = neutral & (wert >= unten) & (wert <= oben)
	if karo.mean() < 0.05:
		return im          # kein nennenswertes Karo — Bild war schon freigestellt
	alpha = a[:, :, 3].copy()
	alpha[karo] = 0
	a[:, :, 3] = alpha
	a[:, :, 3] = _splitter_weg(alpha)
	return Image.fromarray(a.astype("uint8"), "RGBA")


def _splitter_weg(alpha):
	"""Einzelne deckende Krümel im leeren Feld entfernen.

	Uebrig bleiben nach dem Freistellen zwei Sorten Muell: das Funkel-Wasserzeichen (das auf
	fast jedem Sinnbild sitzt und zu hell fuer die Karo-Erkennung ist) und ein paar Karo-Ecken.
	Beides sind kleine Inseln mitten im Nichts, waehrend das Motiv eine grosse zusammenhaengende
	Flaeche ist. Gemessen wird deshalb die Nachbarschaft: Wer in einem 31er-Fenster weniger als
	ein Zehntel deckende Nachbarn hat, gehoert nicht zum Motiv.
	"""
	import numpy as np
	deckend = (alpha > 40).astype(float)
	# 113er Fenster, nicht 31er: Das Funkelzeichen misst rund 30 Pixel und war in einem kleinen
	# Fenster dicht genug, um durchzurutschen. Bei 113 kommt es auf 7 % Nachbarschaft, ein
	# Gewehrlauf von 20 Pixeln Breite dagegen auf 18 % — dazwischen passt die Schwelle bequem.
	k = 56
	pad = np.pad(deckend, k, mode="constant")
	summe = pad.cumsum(0).cumsum(1)
	h, w = deckend.shape
	fenster = (summe[2 * k:2 * k + h, 2 * k:2 * k + w] - summe[0:h, 2 * k:2 * k + w]
		- summe[2 * k:2 * k + h, 0:w] + summe[0:h, 0:w]) / float((2 * k) ** 2)
	aus = alpha.copy()
	aus[fenster < 0.11] = 0
	return aus


def bildnis_feld(im: Image.Image) -> tuple:
	"""Sucht das eigentliche Bildnis: das dunkle Feld ohne Rahmen und ohne Umgebung.

	Zwei Schritte, weil zwei verschiedene Sachen im Weg liegen koennen:

	1. **Was ausserhalb liegt.** Entweder durchsichtig (PNG) oder das helle Karomuster, das die
	   JPEG-Wandlung eingebacken hat. Beides ist leicht zu erkennen: durchsichtig, oder hell UND
	   fast farblos. Alles andere gehoert zum Bild.
	2. **Ein gemalter Rahmen.** Doc kam in einem Metallrahmen. Der ist deutlich HELLER als der
	   schwarze Bildnisgrund — also von aussen nach innen schrumpfen, solange der Randstreifen
	   hell ist. Bei Mabel und Silas ist schon der erste Streifen dunkel, da passiert nichts.

	Der erste Versuch lief stattdessen von der Mitte jeder Kante nach innen, bis es dunkel wurde.
	Bei Doc ging das gut, bei Mabel nicht: Ihr Motiv reicht bis an den unteren Rand des Quadrats,
	der Lauf von unten traf ihre Lederschuerze statt der Kante und schnitt ihr 135 Pixel
	Schulter ab.
	"""
	import numpy as np
	a = np.asarray(im).astype(int)
	rgb, alpha = a[:, :, :3], a[:, :, 3]
	hell = rgb.mean(axis=2)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	draussen = (alpha < 120) | ((hell > 170) & (sat < 14))
	drin = ~draussen

	def block(anteile):
		markiert = anteile > 0.5
		bester, laenge, start = None, 0, None
		for i, wert in enumerate(list(markiert) + [False]):
			if wert and start is None:
				start = i
			elif not wert and start is not None:
				if i - start > laenge:
					laenge, bester = i - start, (start, i)
				start = None
		return bester

	senkrecht = block(drin.mean(axis=1))
	waagerecht = block(drin.mean(axis=0))
	if senkrecht is None or waagerecht is None:
		return (0, 0, im.width, im.height)
	y0, y1 = senkrecht
	x0, x1 = waagerecht
	# Schritt 2: gemalten Rahmen abschaelen.
	for _ in range(200):
		if x1 - x0 < im.width * 0.4 or y1 - y0 < im.height * 0.4:
			break
		# Nach FARBIGKEIT abschaelen, nicht nach Helligkeit. Docs Rahmen ist dunkles Metall,
		# also genauso dunkel wie der Bildnisgrund — aber er ist rostig und damit farbig,
		# waehrend der Grund fast neutrales Schwarz ist. Ein Helligkeitsvergleich hat den
		# Rahmen deshalb glatt uebersehen und ihn stehen lassen.
		ring_sat = np.concatenate([sat[y0, x0:x1], sat[y1 - 1, x0:x1],
			sat[y0:y1, x0], sat[y0:y1, x1 - 1]])
		ring_hell = np.concatenate([hell[y0, x0:x1], hell[y1 - 1, x0:x1],
			hell[y0:y1, x0], hell[y0:y1, x1 - 1]])
		if np.median(ring_sat) < 16.0 and np.median(ring_hell) < 70.0:
			break              # schon beim Bildnisgrund angekommen
		x0, y0, x1, y1 = x0 + 2, y0 + 2, x1 - 2, y1 - 2
	if x1 - x0 < im.width * 0.35 or y1 - y0 < im.height * 0.35:
		return (0, 0, im.width, im.height)
	return (x0, y0, x1, y1)


def zielgroesse(name: str) -> int:
	for schluessel, wert in GROESSE.items():
		if name.startswith(schluessel):
			return wert
	return 0


def main() -> int:
	if len(sys.argv) < 2:
		print(__doc__)
		return 2
	quelle = pathlib.Path(sys.argv[1])
	ziel = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 \
		else pathlib.Path(__file__).resolve().parents[1] / "assets" / "ui"
	ziel.mkdir(parents=True, exist_ok=True)

	for datei in sorted(quelle.iterdir()):
		if not datei.is_file():
			continue
		# `icon_plate.png.png` -> `icon_plate`,  `portrait_mabel.png.jpg` -> `portrait_mabel`
		name = datei.name
		while "." in name:
			name = name.rsplit(".", 1)[0]
		im = Image.open(datei).convert("RGBA")
		vorher = im.size
		notizen = []

		im = karo_weg(im, name)

		if name in FUNKEL:
			im = heile(im, FUNKEL[name])
			notizen.append("Funkelzeichen geheilt")

		# Ein Bildnis mit gemaltem Rahmen: auf das Bild darin beschneiden.
		if name.startswith("portrait_") and name != "portrait_frame":
			k = bildnis_feld(im)
			if k != (0, 0, im.width, im.height):
				im = im.crop(k)
				notizen.append("auf %dx%d beschnitten" % im.size)

		# Der Fussabdruck kam als weisse Sohle auf GRAUEM Grund statt auf durchsichtigem. So
		# gezeichnet waere im Spiel ein graues Rechteck im Sand und der Abdruck darin. Die
		# Helligkeit IST hier die Deckung: Weiss deckt, Grau nicht. Die Farbe kommt ohnehin vom
		# Spiel (die Spur leuchtet bernsteinfarben), also wird alles auf Weiss gesetzt.
		if name == "footprint":
			import numpy as np
			a = np.asarray(im).astype(float)
			hell = a[:, :, :3].mean(axis=2)
			tief, hoch = hell.min(), hell.max()
			deckung = np.clip((hell - tief) / max(hoch - tief, 1.0), 0.0, 1.0)
			# Unterste 45 % ganz weg, damit der graue Grund nicht als Schleier stehenbleibt.
			deckung = np.clip((deckung - 0.45) / 0.55, 0.0, 1.0)
			neu_a = np.dstack([np.full_like(hell, 255.0), np.full_like(hell, 255.0),
				np.full_like(hell, 255.0), deckung * 255.0]).astype("uint8")
			im = Image.fromarray(neu_a, "RGBA")
			k = im.getbbox()
			if k:
				im = im.crop(k)
			notizen.append("freigestellt (%dx%d)" % im.size)

		if name in HOEHE and im.height != HOEHE[name]:
			f = HOEHE[name] / im.height
			im = im.resize((round(im.width * f), HOEHE[name]), Image.LANCZOS)
			notizen.append("auf %dx%d gebracht" % im.size)

		z = zielgroesse(name)
		if z and name not in HOEHE and max(im.size) > z:
			faktor = z / max(im.size)
			im = im.resize((max(1, round(im.width * faktor)), max(1, round(im.height * faktor))),
				Image.LANCZOS)
			notizen.append("auf %dx%d verkleinert" % im.size)

		aus = ziel / (name + ".png")
		im.save(aus)
		print("%-18s %sx%s -> %s   %s"
			% (name, vorher[0], vorher[1], aus.name, ", ".join(notizen) or "unveraendert"))
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
