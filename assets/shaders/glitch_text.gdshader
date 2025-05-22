shader_type canvas_item;

uniform float scanline_count : hint_range(0, 180) = 50.0;
uniform float scanline_speed : hint_range(-5.0, 5.0) = 1.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.3;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.0015;
uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Get base texture
    vec2 uv = SCREEN_UV;
    
    // Time-based effects
    float time = TIME * time_scale;
    
    // Scanlines effect
    float scanline = sin(uv.y * scanline_count + time * scanline_speed) * 0.5 + 0.5;
    scanline = pow(scanline, 1.5) * 0.05;
    
    // Random glitch effect
    float glitch = step(0.96, random(vec2(floor(time * 10.0), floor(uv.y * 20.0)))) * glitch_intensity;
    vec2 glitch_offset = vec2(glitch * 0.03 * random(vec2(time, uv.y)), 0.0);
    
    // Apply distortion
    vec2 distortion = vec2(
        sin(uv.y * 10.0 + time) * cos(uv.x * 5.0 - time * 0.5) * distortion_strength,
        sin(uv.x * 15.0 - time) * sin(uv.y * 7.0 + time * 0.2) * distortion_strength
    );
    
    // Apply all effects
    vec2 final_uv = uv + distortion + glitch_offset;
    vec4 color = texture(TEXTURE, final_uv);
    
    // Add noise
    float noise = random(uv + vec2(time * 0.1, 0.0)) * noise_strength;
    
    // Final color with scanlines and noise
    COLOR = color + vec4(scanline) + vec4(noise);
} 