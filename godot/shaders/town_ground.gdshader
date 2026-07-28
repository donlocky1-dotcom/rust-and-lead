shader_type spatial;
// Stadtboden von Rustwater: festgetretener heller Lehm.
//
// Warum nicht einfach die Sandtextur heller tönen: Auf einer 120-m-Scheibe wiederholt sich eine
// 2,5-m-Kachel achtundvierzigmal. Das sieht man — als regelmäßiges Gitter, das über den ganzen
// Platz läuft und sofort nach Computergrafik aussieht. Dieser Shader legt deshalb ZWEI
// Störungen über die gekachelte Textur: eine grobe (Verfärbungen, ausgetretene Stellen, ein
// paar Meter groß) und eine feine (Körnung). Beide haben Wellenlängen, die nicht auf die Kachel
// passen — dadurch verschwindet das Gitter, ohne dass eine zweite Textur nötig wäre.
//
// Der Boden ist bewusst GLEICHMÄSSIG hell: ein Stadtplatz ist plattgetreten, nicht wild.

uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform bool has_tex = false;
uniform sampler2D normal_tex : hint_normal;
uniform bool has_normal = false;
uniform float tex_scale = 24.0;              // Kachelwiederholungen über die ganze Scheibe

uniform vec3 base_color : source_color = vec3(0.80, 0.71, 0.54);   // heller Lehm
uniform vec3 dark_color : source_color = vec3(0.64, 0.55, 0.40);   // ausgetretene Stellen
uniform float mottle_scale = 0.055;          // grobe Verfärbung: ~18 m Wellenlänge
uniform float mottle_strength : hint_range(0.0, 1.0) = 0.30;
uniform float grain_scale = 1.7;             // feine Körnung: ~0,6 m
uniform float grain_strength : hint_range(0.0, 1.0) = 0.12;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.94;

varying vec3 world_pos;

// Zwei versetzte Sinuspaare statt echtem Rauschen: aus Kamerahöhe nicht zu unterscheiden,
// kostet aber nichts und braucht keine Textur.
float wobble(vec2 p, float f) {
	return (sin(p.x * f) * sin(p.y * f * 1.37)
		+ sin((p.x + p.y) * f * 0.61) * sin((p.x - p.y) * f * 0.83)) * 0.25 + 0.5;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz;
	vec3 col = base_color;
	if (has_tex) {
		// Die Textur liefert die Feinstruktur, die Grundfarbe kommt von uns — so bleibt der
		// Platz hell und gleichmäßig, egal wie dunkel die Vorlage ist.
		vec3 tex = texture(albedo_tex, uv / tex_scale).rgb;
		float luma = dot(tex, vec3(0.299, 0.587, 0.114));
		col *= (0.72 + 0.56 * luma);
	}
	col = mix(col, dark_color, wobble(uv, mottle_scale) * mottle_strength);
	col *= 1.0 - (1.0 - wobble(uv, grain_scale)) * grain_strength;
	ALBEDO = col;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, uv / tex_scale).rgb;
		NORMAL_MAP_DEPTH = 0.45;   // flach: ein getretener Platz hat keine Dünen
	}
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
}
