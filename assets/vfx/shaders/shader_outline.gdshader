// shader_outline.gdshader
// Placeholder outline shader for highlighting

shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(1.0, 4.0) = 2.0;

void fragment() {
    vec4 tex_color = TEXTURE;
    vec2 size = TEXTURE_PIXEL_SIZE;

    vec4 outline = vec4(0.0);
    for (float i = -outline_width; i <= outline_width; i += 1.0) {
        for (float j = -outline_width; j <= outline_width; j += 1.0) {
            vec4 neighbor = texture(TEXTURE, UV + vec2(i, j) * size);
            outline = max(outline, neighbor);
        }
    }

    if (tex_color.a < 0.1) {
        COLOR = outline_color * outline.a;
    } else {
        COLOR = tex_color;
    }
}