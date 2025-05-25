shader_type canvas_item;

// Default resolution, update from script for dynamic sizing if needed
uniform vec2 iResolution = vec2(1024.0, 768.0);

// New Camera-like Uniforms
uniform float zoom : hint_range(0.1, 10.0) = 1.0; // Zoom level (1.0 = no zoom, <1 = zoom out, >1 = zoom in)
uniform vec2 pan_offset = vec2(0.0, 0.0);      // Pan offset in normalized [-1,1] style space

void fragment() {
    // Original UV calculation based on screen pixels, normalized to [-1, 1]
    vec2 base_uv = (FRAGCOORD.xy / iResolution.xy) * 2.0 - 1.0;
    
    // Apply aspect correction
    float aspect = iResolution.x / iResolution.y;
    base_uv.x *= aspect;

    // --- Apply Pan and Zoom ---
    // 1. Apply Pan: Translate the coordinate system.
    vec2 panned_uv = base_uv - pan_offset;

    // 2. Apply Zoom: Scale the coordinate system.
    vec2 zoomed_uv = panned_uv / zoom;
    // --- End Pan and Zoom ---

    // Use 'zoomed_uv' for all subsequent calculations
    vec2 uv = zoomed_uv;
    
    vec2 pos = vec2(0.0, 0.0); // Center of the ripple in the current UV space
    
    float dist = length(uv - pos);
    
    // Adjust ripple radius speed by zoom to keep its perceived screen speed somewhat consistent
    float rippleRadius = TIME / zoom; 
    
    float diff = rippleRadius - dist;
    
    float func = sin(PI * diff);
    
    // Apply ripple distortion to the already zoomed and panned UV.
    uv += uv * func * 0.1; 
    
    float stripes = 10.0;
    float thickness = 10.0;
    
    vec2 a = sin(stripes * 0.5 * PI * uv - PI/2.0);
    vec2 b = abs(a);
    
    vec3 color_val = vec3(0.0);
    color_val += 1.0 * exp(-thickness * b.x * (0.8 + 0.5 * sin(PI * TIME))); 
    color_val += 1.0 * exp(-thickness * b.y);
    color_val += 0.5 * exp(-(thickness/4.0) * b.x);
    color_val += 0.5 * exp(-(thickness/3.0) * b.y);
    
    float ddd = exp(-5.5 * clamp(pow(dist, 3.0), 0.0, 1.0));
    
    vec3 t = vec3(uv.x * 0.5 + 0.5 * sin(TIME), uv.y * 0.5 + 0.5 * cos(TIME), pow(cos(TIME), 4.0)) + 0.5;
    
    COLOR = vec4(color_val * t * ddd, 1.0);
} 