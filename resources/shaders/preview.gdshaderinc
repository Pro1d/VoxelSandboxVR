const vec3 to_luminance = vec3(.299, .587, .114);
const float thickness = 0.030;
const float aa = 0.01;

uniform vec3 grid_offset = vec3(0.0);
uniform float alpha = 1.0;
uniform vec4 albedo : source_color;
uniform vec4 details_albedo : source_color;
uniform float margin = 0.01;
uniform bool draw_cross = false;
//uniform vec3 box_size = vec3(3,2,1);
varying vec2 uv;
varying vec2 uv2;
varying vec2 uv2_size;

void vertex() {
	vec3 n = abs(NORMAL);
	//vec2 face_size;
	vec2 uv_offset;
	if (n.x > 0.001) {
		uv = VERTEX.yz;
		//face_size = box_size.yz;
		uv_offset = grid_offset.yz;
	} else if (n.y > 0.001) {
		uv = VERTEX.zx;
		//face_size = box_size.zx;
		uv_offset = grid_offset.zx;
	} else {// (n.z > 0.0)
		uv = VERTEX.xy;
		//face_size = box_size.xy;
		uv_offset = grid_offset.xy;
	}
	vec2 face_size = abs(uv) - vec2(margin);
	uv2 = uv - fract(face_size - uv_offset);
	uv2_size = abs(uv);//face_size * .5 + vec2(margin);
}

void fragment() {
	vec2 edge = smoothstep(uv2_size - (thickness*.5 + aa/uv2_size), uv2_size - thickness*.5, abs(uv));
	vec2 cell = abs(fract(uv2) - .5) * 2.0;

	float shape = max(edge.x, edge.y);
	
	if (draw_cross) {
		float x_shape = 1.0 - smoothstep(thickness*1.7 - aa, thickness*1.7, abs(cell.x - cell.y));
		x_shape *= 1.0 - smoothstep(0.15 - aa, 0.15, dot(cell, cell));
		shape = max(shape, x_shape);
	} else { // draw corner
		vec2 grid = smoothstep(1.0 - (thickness + aa) , 1.0 - thickness, cell);
		vec2 corner = smoothstep(0.7 - aa , 0.7 - 0. , cell);
		shape = max(
			shape,
			mix(.3, 1.0, float(FRONT_FACING)) * max(grid.x, grid.y) * min(corner.x, corner.y)
		);
	}

	vec2 offset = abs(uv / uv2_size);
	float r = length(offset) / 1.41;
	float gradient = mix(.15, 1., r * r * r);
	float alpha_fill = alpha * gradient;
	float alpha_line = shape;

	float lum = dot(albedo.rgb, to_luminance);
	vec3 color_fill = albedo.rgb;
	vec3 color_line = details_albedo.rgb; //mix(albedo.rgb, vec3(step(lum, .7)), 0.65);

	// blending: line over fill
	float a = mix(alpha_fill, 1.0, alpha_line);
	#ifdef ALPHA_PASS
	if (a >= 0.99)
		discard;
	ALPHA = a;
	#else
	if (a < 0.99)
		discard;
	#endif
	ALBEDO = mix(color_fill, color_line, alpha_line);
}
