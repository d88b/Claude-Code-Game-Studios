shader_type canvas_item;

// 水波参数
uniform float wave_speed = 0.5;
uniform float wave_strength = 0.02;
uniform float wave_frequency = 8.0;

// 颜色控制
uniform vec4 deep_color : source_color = vec4(0.05, 0.15, 0.45, 0.9);
uniform vec4 shallow_color : source_color = vec4(0.1, 0.35, 0.75, 0.7);

void fragment() {
    vec2 uv = SCREEN_UV;

    // 多层正弦波叠加模拟水波
    float wave1 = sin(UV.x * wave_frequency + TIME * wave_speed) * 0.5;
    float wave2 = sin(UV.y * wave_frequency * 0.7 + TIME * wave_speed * 1.3) * 0.3;
    float wave3 = sin((UV.x + UV.y) * wave_frequency * 0.5 + TIME * wave_speed * 0.8) * 0.2;
    float wave = (wave1 + wave2 + wave3) * wave_strength;

    // UV 偏移产生水波扭曲效果
    vec2 distorted_uv = SCREEN_UV + vec2(wave, wave * 0.5);

    // 采样屏幕纹理实现折射效果
    vec4 screen_color = texture(SCREEN_TEXTURE, distorted_uv);

    // 水色混合
    float depth = 1.0 - distorted_uv.y;
    vec4 water_color = mix(deep_color, shallow_color, depth);
    water_color.rgb += vec3(0.1, 0.15, 0.2) * (wave * 10.0); // 高光

    // 混合屏幕和水色
    float alpha = mix(0.6, 0.8, sin(TIME * wave_speed) * 0.5 + 0.5);
    COLOR = mix(screen_color, water_color, alpha);
}
