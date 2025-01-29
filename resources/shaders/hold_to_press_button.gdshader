// NOTE: Shader automatically converted from Godot Engine 4.3.stable's CanvasItemMaterial.

shader_type canvas_item;
render_mode blend_mix;

uniform vec4 progress_color : source_color;
uniform float progress_angle : hint_range(0.0, 6.283184, 0.01) = 0.0;
uniform float progress_radius : hint_range(0.0, 1.0, 0.1) = 0.9;
uniform float half_thickness : hint_range(0.0, 1.0, 0.001) = 0.06;

void fragment() {
	vec2 offset = (UV - vec2(.5)) * 2.0;
	float radius = length(offset);
	float angle = atan(-offset.x, offset.y) + PI;
	COLOR = mix(
		COLOR,
		progress_color,
		(1.0 - smoothstep(half_thickness, half_thickness + 0.04, abs(radius - progress_radius))) *
		step(angle, progress_angle) *
		(1.0 - smoothstep(progress_angle, progress_angle + 0.01, angle))
	);
}