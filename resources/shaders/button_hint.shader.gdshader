// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_disable;
//uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.001) = .5;

uniform float roughness : hint_range(0.0, 1.0);
uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);


void vertex() {
}

void fragment() {
	vec2 offset = (UV - vec2(.5)) * 2.0;

	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = mix(albedo.rgb, albedo_tex.rgb, albedo_tex.a);

	METALLIC = metallic;
	SPECULAR = specular;
	ROUGHNESS = roughness;

	ALPHA = 1.0 - smoothstep(0.95, 1.0, dot(offset, offset));
	//ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}
