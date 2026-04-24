// shader_daynight_modulate.gdshader
// Placeholder day-night color modulation shader

shader_type canvas_item;

uniform float brightness : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = TEXTURE;
    COLOR = tex_color * tint_color * brightness;
}