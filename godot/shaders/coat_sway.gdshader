shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
// Mantel-Schwung (GDD §1.5a) — der Saum reagiert auf Bewegung, ohne Stoffsimulation.
//
// Warum kein SoftBody/Cloth: echte Simulation kostet auf dem Handy pro Figur mehr als der
// gesamte Rest der Szene und neigt zu Zappeln, wenn die Bildrate schwankt. Ein Vertex-Shader
// kostet praktisch nichts, ist bildratenunabhängig und aus der Spielkamera nicht vom
// simulierten Stoff zu unterscheiden.
//
// Prinzip: Jeder Punkt bekommt ein Gewicht danach, wie weit er UNTER der Aufhängung liegt —
// an den Schultern 0 (der Mantel sitzt fest), am Saum 1. Damit wird
//   • nachgezogen  (der Stoff bleibt hinter der Bewegung zurück),
//   • angehoben    (schnelles Laufen hebt den Saum),
//   • geflattert   (Wind, zwei überlagerte Frequenzen, damit es nicht wie ein Metronom wirkt).
//
// `cull_disabled`, weil man bei einem wehenden Mantel die Innenseite sieht — anders als bei
// einer geschlossenen Figur, wo doppelseitiges Rendern nur Füllrate kostet.

uniform sampler2D albedo_tex : source_color, hint_default_white;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D normal_tex : hint_normal;
uniform bool has_normal = false;
uniform sampler2D orm_tex : hint_default_white;   // glTF-Konvention: R=AO, G=Rauheit, B=Metall
uniform bool has_orm = false;
uniform float roughness : hint_range(0.0, 1.0) = 0.75;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

// Aufhängung und Länge in Modellkoordinaten — die Szene misst sie aus den Mesh-Bounds,
// damit der Shader zu jedem Mantel passt, ohne dass jemand Zahlen abschreibt.
uniform float coat_top = 1.7;
uniform float coat_length = 1.7;

uniform vec3 sway_dir = vec3(0.0, 0.0, 1.0);   // Laufrichtung, im lokalen Raum des Mantels
uniform float sway_amount : hint_range(0.0, 1.5) = 0.0;   // 0 = Stand, 1 = volle Laufgeschwindigkeit
uniform float wind : hint_range(0.0, 1.0) = 0.3;          // Grundflattern im Stand
uniform float drag = 0.42;        // wie weit der Stoff zurückbleibt (m bei voller Geschwindigkeit)
uniform float lift = 0.16;        // wie weit der Saum steigt
uniform float flutter_amp = 0.05;
uniform float stiff_top : hint_range(0.5, 4.0) = 2.2;   // je größer, desto ruhiger die Schultern

void vertex() {
	float w = clamp((coat_top - VERTEX.y) / max(coat_length, 0.001), 0.0, 1.0);
	w = pow(w, stiff_top);   // Schultern bleiben ruhig, unten wird es weich
	// Nachziehen: entgegen der Laufrichtung.
	VERTEX -= sway_dir * (drag * sway_amount * w);
	VERTEX.y += lift * sway_amount * w;
	// Flattern: zwei Frequenzen, versetzt über die Breite — sonst schwingt der ganze Saum
	// wie ein Brett im Takt.
	float phase = TIME * 5.5 + VERTEX.x * 3.1;
	float f = sin(phase) * 0.6 + sin(phase * 1.73 + 1.1) * 0.4;
	float strength = flutter_amp * w * (wind + sway_amount);
	VERTEX += vec3(f * 0.35, f * 0.25, f) * strength;
}

void fragment() {
	ALBEDO = (texture(albedo_tex, UV) * albedo_color).rgb;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	if (has_orm) {
		vec3 orm = texture(orm_tex, UV).rgb;
		AO = orm.r;
		AO_LIGHT_AFFECT = 1.0;
		ROUGHNESS = orm.g * roughness;
		METALLIC = orm.b * metallic;
	} else {
		ROUGHNESS = roughness;
		METALLIC = metallic;
	}
	// Beidseitig sichtbar: die Rückseite muss ihre Normale drehen, sonst ist die Innenseite
	// des Mantels schwarz.
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
}
