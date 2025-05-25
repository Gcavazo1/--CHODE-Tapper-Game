shader_type canvas_item;

// Godot's built-in uniforms
// uniform float iTime : hint_range(0.0, 1000.0); // Replaced by TIME
uniform vec2 iResolution = vec2(1024.0, 768.0); // Default resolution, update from script for dynamic sizing

// Camera-like controls
uniform float zoom : hint_range(0.1, 10.0) = 1.0; // Zoom level
uniform vec2 pan_offset = vec2(0.0, 0.0); // Pan offset

float pulse(float cn, float wi, float x) {
    return 1.0 - smoothstep(0.0, wi, abs(x - cn));
}

float hash11(float n) {
    return fract(sin(n) * 43758.5453);
}

vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

vec2 field(in vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    vec2 m = vec2(1.0);
    vec2 o = hash22(n) * 0.17;
    vec2 r = f + o - 0.5;
    float d = abs(r.x) + abs(r.y);
    if (d < m.x) {
        m.x = d;
        m.y = hash11(dot(n, vec2(1.0, 2.0)));
    }
    return vec2(m.x, m.y);
}

void fragment() {
    // Normalized pixel coordinates (from -0.5 to 0.5)
    vec2 uv = FRAGCOORD.xy / iResolution.xy - 0.5;
    uv.x *= iResolution.x / iResolution.y * 0.9;
    // --- Apply pan and zoom ---
    uv = (uv - pan_offset) / zoom;
    // --- End pan and zoom ---
    uv *= 4.0;
    
    vec2 p = uv * 0.01;
    p *= 1.0 / (p - 1.0); 
    
    // Global movement
    uv.y += TIME * 1.2;
    uv.x += sin(TIME * 0.3) * 0.8;
    vec2 buv = uv;
    
    vec3 col = vec3(0.0);
    for (float i = 1.0; i <= 26.0; i++) {
        vec2 rn = field(uv);
        uv -= p * (i - 25.0) * 0.2;
        rn.x = pulse(0.35, 0.02, rn.x + rn.y * 0.15);
        col += rn.x * vec3(sin(rn.y * 10.0), cos(rn.y) * 0.2, sin(rn.y) * 0.5);
    }
    
    // Animated grid layers
    buv *= mat2(vec2(0.707, 0.707), vec2(-0.707, 0.707));
    
    float rz2 = 0.4 * (sin(buv * 10.0 + 1.0).x * 40.0 - 39.5) * (sin(uv.x * 10.0) * 0.5 + 0.5);
    vec3 col2 = vec3(0.2, 0.4, 2.0) * rz2 * (sin(2.0 + TIME * 2.1 + (uv.y * 2.0 + uv.x * 10.0)) * 0.5 + 0.5);
    
    float rz3 = 0.3 * (sin(buv * 10.0 + 4.0).y * 40.0 - 39.5) * (sin(uv.x * 10.0) * 0.5 + 0.5);
    vec3 col3 = vec3(1.9, 0.4, 2.0) * rz3 * (sin(TIME * 4.0 - (uv.y * 10.0 + uv.x * 2.0)) * 0.5 + 0.5);
    
    col = max(max(col, col2), col3);
    
    COLOR = vec4(col, 1.0);
} 