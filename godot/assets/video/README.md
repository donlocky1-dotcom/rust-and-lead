# Video

## `intro_muellkippe.mp4` — Intro: der Held erwacht auf der Müllkippe

Liegt hier als **Quelle**, nicht als einbaufertiges Asset. Godot 4 spielt von Haus aus nur
**Ogg Theora** (`.ogv`) über `VideoStreamPlayer`; MP4/H.264 kann es nicht, und zwar
absichtlich nicht (Lizenzgründe). Eingebaut wird es erst nach der Umwandlung:

```
ffmpeg -i intro_muellkippe.mp4 -c:v libtheora -q:v 8 -c:a libvorbis -q:a 5 intro_muellkippe.ogv
```

Theora ist ein alter Codec — für ein kurzes Intro reicht die Qualität, die Datei wird aber
deutlich größer als das MP4. Wenn das stört, ist die Alternative, das Intro **in der Engine**
zu spielen statt als Film: Die Grube steht ja bereits als 3D-Szene da, mitsamt Lokomotivenwrack
und der Lache in der Mitte, in der die Figur liegen kann. Die Kamerafahrt dafür kann dieselbe
Maschinerie benutzen wie die Nahaufnahmen im Gespräch (`OverworldView._play_closeup`).
