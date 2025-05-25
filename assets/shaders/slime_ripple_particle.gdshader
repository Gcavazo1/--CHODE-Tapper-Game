shader_type canvas_item;

// === Adjustable Parameters in Godot ===

// Canvas size per particle (unchanged)
uniform vec2 iResolution = vec2(128.0, 128.0);

// Optional input texture (e.g. noise)
uniform sampler2D iChannel0 : hint_default_white;

// === New tweakable uniforms ===
uniform vec3 glitter_color = vec3(1.0, 0.5, 0.1);       // Tint of glitter
uniform float ripple_speed = 0.6;                       // Speed of wave motion
uniform float ripple_freq = 12.0;                       // Frequency of wave ripples
uniform float glitter_strength = 1.015;                 // Controls glitter density
uniform float glitter_sharpness = 100.0;                // Controls glitter sparkle sharpness
uniform float color_ripple_influence = 0.05;            // How much ripple affects color gradient

// === Wave Height Calculation ===
float GetHeight(vec2 uv) {
    if (uv.x < 0.0)
        return 1.0;

    float updown = sin(uv.x * ripple_freq + TIME * ripple_speed) * mix(1.0, 0.2, uv.x) * 0.12;
    float yspread = (uv.y - 0.5) * mix(1.0, 0.1, uv.x) + 0.5;
    float leftright = sin((yspread + updown) * 20.0);

    float checker = sin((uv.x + TIME * 0.05) * 40.0) * sin(uv.y * 10.0 - TIME * 1.0) * 0.5 + 0.5;

    float yCenterToEdge = (uv.y - 0.5) / 0.5;
    yCenterToEdge *= yCenterToEdge;
    float xpow = mix(0.17, 0.25, yCenterToEdge);

    float phase = fract(pow(uv.x, xpow) * 40.0 + leftright * 0.32 + checker * 0.2 + TIME * 0.1 * 1.4);
    float wave = cos(phase * 2.0 * 3.14159) * 0.5 + 0.5;

    float height = mix(1.0, wave, pow(uv.x, 0.8));
    return height;
}

// === Gradient Color Function ===
vec3 ColorFunction(float x) {
    const vec3 c0 = vec3(1.0, 1.0, 0.6) * 1.8;
    const vec3 c1 = vec3(1.0, 0.85, 0.3) * 1.1;
    const vec3 c2 = vec3(1.0, 0.55, 0.0) * 0.8;
    const vec3 c3 = vec3(0.5, 0.25, 0.0) * 0.5;
    const vec3 c4 = vec3(0.05, 0.02, 0.0);

    if (x < 0.4) {
        if (x < 0.1)
            return mix(c0, c1, x / 0.1);
        else
            return mix(c1, c2, (x - 0.1) / 0.3);
    } else {
        if (x < 0.6)
            return mix(c2, c3, (x - 0.4) / 0.2);
        else {
            x = min(x, 1.0);
            return mix(c3, c4, (x - 0.6) / 0.4);
        }
    }
}

// === Glitter Pattern Helpers ===
float sinsin_local_func(vec2 val) {
    return min(abs(sin(val.x) * sin(val.y)) * 1.2, 1.0);
}

float Glitter(vec2 uv_glitter) {
    uv_glitter *= 0.8;
    uv_glitter.x += sin(uv_glitter.y * 20.0) * 0.03;

    float x = sinsin_local_func((uv_glitter.xx * vec2(0.64, 0.77) + uv_glitter.yy * vec2(0.77, -0.64)) * 300.0);
    x *= sinsin_local_func((uv_glitter.xx * vec2(0.34, 0.94) + uv_glitter.yy * vec2(0.94, -0.34)) * 211.0);
    x *= sinsin_local_func((uv_glitter.xx * vec2(0.99, 0.12) + uv_glitter.yy * vec2(0.12, -0.99)) * 73.0);

    return pow(x * glitter_strength, glitter_sharpness);
}

// === Final Output ===
void fragment() {
    vec2 uv = UV;

    float height = GetHeight(uv);

    float dust = Glitter(uv + vec2(TIME * 0.04, height * -0.02));
    dust = mix(0.0, dust, uv.x); // fade toward left

    vec3 final_color_rgb = ColorFunction(uv.x + (height - 1.0) * color_ripple_influence);

    final_color_rgb += glitter_color * dust;

    vec4 base_texture_color = texture(TEXTURE, UV);
    COLOR = vec4(final_color_rgb, base_texture_color.a);
    COLOR.rgb = sqrt(COLOR.rgb); // gamma correction
}
