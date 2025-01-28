shader_type spatial;
render_mode cull_disabled;

uniform sampler2D color_palette : filter_nearest, repeat_enable;
uniform float quadrant_angle = 0.0;
const float outer_radius_ratio = 0.92;
uniform float inner_radius_ratio = 0.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float palette_size = float(textureSize(color_palette, 0).x);
	vec2 center = vec2(.5);
	vec2 offset = (UV - center) * vec2(1, -1);
	float r = length(offset) * 2.0;

	vec2 qd = vec2(cos(quadrant_angle), sin(quadrant_angle)); // quadrant_direction;
	vec2 dx = qd; // normalize(quadrant_direction);
	//vec2 rotated_offset = mat2(dx, vec2(-dx.y, dx.x)) * offset;
	vec2 rotated_offset = mat2(vec2(dx.x, -dx.y), vec2(dx.y, dx.x)) * offset;
	float angle = atan(rotated_offset.y, rotated_offset.x) / PI;
	float x = abs(angle);
	//float f = (x < 2./11. ? 121./40.*x*x : 1.1*x-.1);
	//float f = (x < 2./21. ? 441./80.*x*x : 1.05*x-.05);
	//float f = pow(x, deform);
	float X1 = 1.9 / palette_size;
	float X2 = 2.8 / palette_size;
	float g1 = 0.5;
	float f = x < X1 ? x * g1 : (x < X2 ? ((x-X1) / (X2-X1) * (X2 - X1 * g1) + X1*g1) : x);
	float quadrant = sign(angle) * f * .5;
	float tex_coord = quadrant + quadrant_angle / (2. * PI) + .5 / palette_size;
	vec3 color = texture(color_palette, vec2(tex_coord, 0)).rgb;
	float border_r = .04;
	float r_offset = mix(0.08, 0.0, clamp(pow(abs(angle), 1.7) * palette_size * 2.8, 0, 1));
	//float r_offset = (x / f - 1.0) * 0.07;
	float disk = r < outer_radius_ratio+r_offset && r > inner_radius_ratio-r_offset ? 1.0 : 0.0;
	ALPHA = disk;
	//ALBEDO = (
		//r > outer_radius_ratio-border_r+r_offset ||
		//r < inner_radius_ratio+border_r-r_offset ||
		//(0.5-abs(fract(tex_coord * float(palette_size))-.5))*2.0 < 0.2
		 //? vec3(1) : color
	//);
	float aar = 0.01;
	float aaa = aar * 5.0;
	ALBEDO = mix(vec3(1), color,
		smoothstep(outer_radius_ratio-border_r+r_offset+aar, outer_radius_ratio-border_r+r_offset-aar, r) *
		smoothstep(inner_radius_ratio+border_r-r_offset-aar, inner_radius_ratio+border_r-r_offset+aar, r) *
		smoothstep(0.2-aaa, 0.2+aaa, (0.5-abs(fract(tex_coord * palette_size)-.5))*2.0)
	);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
