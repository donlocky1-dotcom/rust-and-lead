# Video

## Du musst mir nichts schicken

`ffmpeg` ist kein Codec, den man weitergibt, sondern ein Programm — und es ist hier schon
installiert. Die Umwandlung ist gelaufen, das Ergebnis liegt daneben. Wenn du später ein
weiteres Video hast: **einfach die MP4 in den Chat ziehen**, den Rest mache ich.

Falls du es doch selbst umwandeln willst — auf dem Mac einmalig `brew install ffmpeg`, dann:

```
ffmpeg -i eingabe.mp4 -c:v libtheora -q:v 7 -an ausgabe.ogv
```

## Warum überhaupt umwandeln

Godot 4 spielt über `VideoStreamPlayer` **nur Ogg Theora** (`.ogv`). MP4/H.264 kann es nicht,
und zwar absichtlich nicht — Lizenzgründe, kein Versehen. Es gibt keinen Schalter dafür.

## `intro_muellkippe` — Intro: der Held erwacht auf der Müllkippe

| | |
|---|---|
| Quelle | `intro_muellkippe.mp4` · 1280 × 720 · 24 fps · 15,0 s · 10,5 MB · H.264, keine Tonspur |
| Einbaufertig | `intro_muellkippe.ogv` · 11,2 MB · Theora `-q:v 7` |

Die Quelle bleibt liegen. Theora ist ein alter Codec; jede spätere Umwandlung soll wieder vom
Original ausgehen und nicht von einer schon einmal zerdrückten Fassung.

### Warum `-q:v 7`

Gemessen gegen die Quelle (PSNR, Y-Kanal — höher ist näher am Original):

| Stufe | Größe | PSNR Y |
|---|---|---|
| `-q:v 6` | 7,9 MB | 39,6 dB |
| **`-q:v 7`** | **11,2 MB** | **41,4 dB** |
| `-q:v 8` | 15,1 MB | 42,7 dB |

Über 40 dB sieht man den Unterschied zum Original bei bewegtem Bild nicht mehr; darunter fängt
das Rauschen in den dunklen Flächen an zu klumpen, und das Intro ist fast durchgehend dunkel.
Von 7 auf 8 kostet 4 MB für 1,3 dB, die niemand sieht. Also 7 — dabei bleibt die Datei ungefähr
so groß wie die Quelle, das Repo wächst nicht unverhältnismäßig.

## Eingebaut ist es noch nicht

Bewusst: Es liegt als **Rückfallebene** da, nicht als beschlossene Sache. Die Alternative ist,
den Anfang **in der Engine** zu spielen statt als Film — die Grube steht als 3D-Szene da,
mitsamt Lokomotivenwrack und der Lache in der Mitte, in der die Figur liegt, und für
Kamerafahrten gibt es seit dem Anflug auf Rustwater eine fertige Maschinerie
(`OverworldView._play_flight`).

Was dafür spricht: Es sieht aus wie das Spiel, weil es das Spiel IST. Kein Bruch in der
Auflösung, kein Bruch im Bildstil, keine 11 MB im Paket — und der Spieler kann es abbrechen,
ohne dass ein Film hängen bleibt. Was dagegen spricht: Ein gerenderter Film kann Dinge zeigen,
die die Engine nicht kann.

Sag Bescheid, welche der beiden Fassungen es werden soll.
