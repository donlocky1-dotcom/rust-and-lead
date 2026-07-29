shader_type spatial;
// Gleisbett der Iron Rail: Schotter mit Schwellen — **prozedural statt als Geometrie**.
//
// Rustwater–Zugdepot sind allein 1186 m. Bei 0,7 m Schwellenabstand waeren das rund 1700
// Schwellen auf EINEM Abschnitt, ueber das ganze Netz mehrere Tausend. Als Einzelobjekte ist
// das nicht bezahlbar, und als wiederholte Textur bräuchte es ein Asset, das niemand gebaut
// hat. Der Shader zeichnet sie stattdessen aus der Position im Modell — exakt gleichmaessig,
// beliebig lang, ohne ein einziges zusaetzliches Dreieck.
//
// Der Takt kommt aus der UV-KOORDINATE, nicht aus der lokalen Position: Die Trasse ist ein
// gelaendefolgender Streifen und kein gedrehter Balken mehr (sonst deckte sie jede Senke zu wie
// ein Brett). `_add_ribbon` legt Meter in die UV — quer in u, laengs in v.

uniform vec3 ballast_color : source_color = vec3(0.30, 0.27, 0.24);
uniform vec3 sleeper_color : source_color = vec3(0.22, 0.16, 0.11);
uniform float sleeper_spacing = 0.75;   // Mitte zu Mitte, in Metern
uniform float sleeper_width = 0.26;     // Breite einer Schwelle, in Metern
uniform float sleeper_reach = 2.6;      // bis hierhin (halbe Breite) liegen Schwellen

void fragment() {
	// Abstand zur naechsten Schwellenmitte entlang der Strecke (UV.y = Meter laengs).
	float along = UV.y / sleeper_spacing;
	float dist = abs(fract(along) - 0.5) * sleeper_spacing;
	// Nur innerhalb der Schwellenlaenge; ausserhalb ist blanker Schotter (UV.x = Meter quer).
	float across = step(abs(UV.x), sleeper_reach);
	float on_sleeper = (1.0 - step(sleeper_width * 0.5, dist)) * across;

	// Schotter bekommt eine feine, unregelmaessige Koernung, damit die Flaeche nicht wie
	// lackiert wirkt — zwei versetzte Sinuswellen reichen aus dieser Kameradistanz.
	float grain = sin(UV.x * 37.0) * sin(UV.y * 41.0) * 0.5 + 0.5;
	vec3 stone = ballast_color * (0.82 + 0.36 * grain);

	ALBEDO = mix(stone, sleeper_color, on_sleeper);
	ROUGHNESS = mix(0.95, 0.78, on_sleeper);
	METALLIC = 0.0;
}
