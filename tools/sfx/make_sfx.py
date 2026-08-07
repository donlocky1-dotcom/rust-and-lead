#!/usr/bin/env python3
"""Erzeugt die Waffengeraeusche — synthetisch, nicht gesammelt.

Warum synthetisch und nicht heruntergeladen: Ein Aufnahme-Archiv bringt Lizenzfragen mit, die
das ganze Projekt betreffen, und liefert trotzdem selten genau den Charakter, den eine Szene
braucht. Hier ist der Charakter die Vorgabe — "richtig peitschend" —, und der laesst sich
bauen: Ein Gewehrschuss besteht aus drei Dingen, die man einzeln regeln kann.

  1. **Der Knall (crack).** Die Ueberschall-Kugel zieht eine N-Welle hinter sich her. Das ist
     der peitschende Anteil, und er ist SEHR kurz — anderthalb Millisekunden — und sehr hoch.
     Wer ihn weglaesst, bekommt einen Boeller.
  2. **Der Muendungsknall (blast).** Das expandierende Gas. Breiter, tiefer, ~35 ms. Das ist
     die Wucht.
  3. **Der Nachhall.** In der Wueste kommt er von den Kraterwaenden: einzelne, spaete
     Rueckwuerfe statt eines gleichmaessigen Raumhalls, und mit jedem Rueckwurf duempfer, weil
     Luft hohe Frequenzen zuerst schluckt. Nachts traegt kuehle Luft weiter — deshalb laenger
     und weicher als am Tag.

Aufruf:  python3 tools/sfx/make_sfx.py
Ausgabe: godot/assets/audio/*.ogg  (Vorbis, mono — 3D-Ton in Godot braucht mono)
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 48000
HIER = os.path.dirname(os.path.abspath(__file__))
ZIEL = os.path.abspath(os.path.join(HIER, "..", "..", "godot", "assets", "audio"))
rng = np.random.default_rng(20260807)


def n(sek):
    return int(SR * sek)


def rausch(sek):
    return rng.standard_normal(n(sek))


def tiefpass(x, hz, pole=1):
    """Tiefpass, `pole` Stufen hintereinander (je 6 dB/Oktave).

    Eine Stufe reicht fuer eine Tendenz und NICHT, um eine Bandbreite zu setzen: Bei 6 dB je
    Oktave liegt eine Oktave ueber der Eckfrequenz immer noch die halbe Amplitude an. Beim
    Karabinerknall hat genau das die erste Messung erklaert — trotz Eckfrequenz 6 kHz lag der
    Schwerpunkt bei 8,6 kHz. Zwei Stufen setzen ihn dorthin, wo er hingehoert.
    """
    for _ in range(pole):
        x = _tiefpass1(x, hz)
    return x


def _tiefpass1(x, hz):
    a = np.exp(-2.0 * np.pi * hz / SR)
    y = np.empty_like(x)
    z = 0.0
    for i in range(len(x)):
        z = (1.0 - a) * x[i] + a * z
        y[i] = z
    return y


def hochpass(x, hz):
    return x - tiefpass(x, hz)


def huelle(sek, an_ms, ab_ms):
    """Anschlag und Abfall. Der Anschlag ist der Unterschied zwischen Knall und Schlag."""
    t = np.arange(n(sek)) / SR
    an = 1.0 - np.exp(-t / max(an_ms / 1000.0, 1e-6))
    ab = np.exp(-t / max(ab_ms / 1000.0, 1e-6))
    return an * ab


def ring(sek, hz, ab_ms, streu=0.0):
    """Eine ausklingende Sinusschwingung — der metallische Anteil an einem Klacken."""
    t = np.arange(n(sek)) / SR
    f = hz * (1.0 + streu * np.exp(-t / 0.01))
    return np.sin(2.0 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (ab_ms / 1000.0))


def lege(spur, ab_sek, teil, pegel=1.0):
    i = n(ab_sek)
    m = min(len(teil), len(spur) - i)
    if m > 0:
        spur[i:i + m] += teil[:m] * pegel


def normieren(x, spitze=0.92):
    x = x - np.mean(x)
    s = np.max(np.abs(x))
    return x * (spitze / s) if s > 0 else x


def schuss(nacht=True):
    """Der Karabiner. Peitschend heisst: Knall zuerst, Wucht danach, Hall zuletzt."""
    laenge = 2.6 if nacht else 1.7
    y = np.zeros(n(laenge))

    # 1. Der Peitschenknall. Kurz, mit brutalem Anschlag — das ist der Charakter.
    #
    # BANDBEGRENZT, und das ist der Unterschied zwischen Peitsche und Zischen. Der erste Anlauf
    # war nur hochpassgefiltert; ein einpoliger Hochpass auf weissem Rauschen laesst die Energie
    # bis Nyquist weiter ansteigen, und nachgemessen lag der Schwerpunkt der ersten fuenf
    # Millisekunden bei 11 kHz. Das ist kein Knall, das ist ein "tss". Ein Gewehrknall hat sein
    # Gewicht bei 3–5 kHz — also oben UND unten begrenzen.
    crack = tiefpass(hochpass(rausch(0.05), 1300.0), 4200.0, 3) * huelle(0.05, 0.04, 1.7)
    lege(y, 0.0, crack, 1.0)
    # Ein zweiter, hoeherer Anteil direkt darauf: Die N-Welle hat zwei Flanken, und mit nur
    # einer klingt sie flach.
    lege(y, 0.0018,
         tiefpass(hochpass(rausch(0.03), 2600.0), 7000.0, 2) * huelle(0.03, 0.03, 1.1), 0.5)

    # 2. Der Muendungsknall. Breiter und tiefer, gibt dem Schuss Koerper.
    blast = tiefpass(rausch(0.12), 1500.0) * huelle(0.12, 0.25, 32.0)
    lege(y, 0.0012, blast, 0.85)
    # Und ganz unten ein Stoss, der eher gefuehlt als gehoert wird.
    lege(y, 0.002, tiefpass(rausch(0.2), 160.0) * huelle(0.2, 1.2, 55.0), 0.5)

    # 3. Die Rueckwuerfe von den Kraterwaenden. Einzeln gesetzt, nicht als Raumhall: In einer
    #    Wueste gibt es keine Waende in Zimmergroesse, sondern wenige weit entfernte Flanken.
    #    Jeder spaetere Rueckwurf ist leiser UND dumpfer — Luft schluckt Hoehen zuerst.
    if nacht:
        wuerfe = [(0.085, 0.30, 2600.0), (0.180, 0.20, 1500.0), (0.330, 0.13, 900.0),
                  (0.560, 0.085, 600.0), (0.870, 0.05, 420.0), (1.280, 0.028, 300.0)]
    else:
        wuerfe = [(0.075, 0.24, 2800.0), (0.160, 0.14, 1700.0), (0.300, 0.07, 1000.0),
                  (0.500, 0.035, 700.0)]
    for ab, pegel, hz in wuerfe:
        w = tiefpass(rausch(0.28), hz) * huelle(0.28, 3.0, 45.0)
        lege(y, ab, w, pegel)
    # Darueber ein leiser, gleichmaessig auslaufender Schwanz — die Summe aller Rueckwuerfe,
    # die zu spaet und zu schwach sind, um einzeln zu zaehlen.
    schwanz = tiefpass(rausch(laenge), 700.0) * np.exp(
        -np.arange(n(laenge)) / SR / (0.55 if nacht else 0.30))
    lege(y, 0.06, schwanz, 0.16 if nacht else 0.10)
    return normieren(y)


def repetieren():
    """Der Kammerstengel: zurueck, Huelse raus, vor, verriegelt.

    Vier Ereignisse mit Pausen dazwischen — genau die Pausen machen daraus eine Handlung statt
    eines Rasselns. Jedes ist ein Anschlag plus ein metallischer Nachklang; die Tonhoehen sind
    verschieden, weil verschieden schwere Teile verschieden klingen.
    """
    y = np.zeros(n(0.72))

    def klack(hz1, hz2, ab_ms, rausch_ms, pegel):
        t = np.zeros(n(0.2))
        # Auch hier oben begrenzen: Ein Metallklacken hat seinen Biss bei 2–8 kHz, alles
        # darueber ist Bandrauschen und klingt nach Kunststoff.
        lege(t, 0.0, tiefpass(hochpass(rausch(0.02), 1600.0), 5500.0, 2)
             * huelle(0.02, 0.05, rausch_ms), 0.9)
        lege(t, 0.0, ring(0.2, hz1, ab_ms, 0.35), 0.55)
        lege(t, 0.0, ring(0.2, hz2, ab_ms * 0.6, 0.5), 0.3)
        return t * pegel

    # Griff hoch und zurueck — hell, leicht.
    lege(y, 0.000, klack(2600.0, 4100.0, 22.0, 2.0, 0.55))
    # Das Schleifen des Verschlusses.
    lege(y, 0.030, tiefpass(hochpass(rausch(0.13), 900.0), 5000.0)
         * huelle(0.13, 8.0, 45.0), 0.16)
    # Die Huelse springt heraus und trifft irgendwo auf — der duennste, hellste Klang.
    lege(y, 0.135, klack(5200.0, 7400.0, 30.0, 1.2, 0.30))
    # Verschluss nach vorn, Patrone wird geschoben.
    lege(y, 0.300, klack(1900.0, 3300.0, 26.0, 2.5, 0.62))
    lege(y, 0.320, tiefpass(hochpass(rausch(0.10), 700.0), 4000.0)
         * huelle(0.10, 6.0, 35.0), 0.14)
    # Und verriegelt. Der satteste Klang, weil hier Masse auf Masse trifft.
    lege(y, 0.430, klack(1400.0, 3000.0, 38.0, 3.5, 0.95))
    return normieren(y, 0.80)


def schreiben(name, daten):
    os.makedirs(ZIEL, exist_ok=True)
    wav = os.path.join(ZIEL, name + ".wav")
    ogg = os.path.join(ZIEL, name + ".ogg")
    with wave.open(wav, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes((np.clip(daten, -1.0, 1.0) * 32767.0).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav,
                    "-c:a", "libvorbis", "-q:a", "6", ogg], check=True)
    os.remove(wav)
    print("  %-28s %6.1f kB  %5.2f s" % (name + ".ogg",
                                         os.path.getsize(ogg) / 1024.0,
                                         len(daten) / SR))


if __name__ == "__main__":
    print("Waffengeraeusche:")
    schreiben("karabiner_schuss_nacht", schuss(nacht=True))
    schreiben("karabiner_schuss_tag", schuss(nacht=False))
    schreiben("karabiner_repetieren", repetieren())
    sys.exit(0)
