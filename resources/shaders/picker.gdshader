// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 paint_color : source_color;
uniform vec4 albedo : source_color;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform float roughness : hint_range(0.0, 1.0, 0.01);


void vertex() {
}

void fragment() {
	float paint_liquid = smoothstep(0.35, 0.65, abs(dot(NORMAL, VIEW)));
	ALBEDO = mix(albedo.rgb, paint_color.rgb, paint_color.a * paint_liquid);
	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;
}
