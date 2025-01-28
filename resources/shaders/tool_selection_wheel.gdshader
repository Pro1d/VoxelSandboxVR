shader_type spatial;
render_mode cull_disabled;

uniform float cos_half_quadrant_size = 0.924;
uniform vec2 quadrant_direction = vec2(1.0, 0.0);
uniform float quadrant_opacity = 1.0;
uniform float inner_radius_ratio = 0.4;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 center = vec2(.5);
	vec2 offset = (UV - center) * vec2(1, -1);
	float r = length(offset);
	float disk = r < 0.5 && r > inner_radius_ratio * .5 ? 1.0 : 0.0;
	float quadrant = dot(quadrant_direction, offset / r) > cos_half_quadrant_size ? 1.0: 0.0;
	ALBEDO = mix(vec3(1.0), vec3(0.8), quadrant * quadrant_opacity);
	ALPHA = disk;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
