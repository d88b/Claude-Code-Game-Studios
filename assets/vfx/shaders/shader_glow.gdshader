// shader_glow.gdshader
// Placeholder glow shader for visual effects

shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);

void fragment() {
    vec4 tex_color = TEXTURE;
    vec4 glow = glow_color * glow_intensity;
    COLOR = tex_color + glow * tex_color.a;
}