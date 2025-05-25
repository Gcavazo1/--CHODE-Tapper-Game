shader_type canvas_item;

// Default resolution, update from script for dynamic sizing
uniform vec2 iResolution = vec2(1024.0, 768.0); 

void fragment() {
    // Normalized pixel coordinates (from 0 to 1) using node's actual resolution
    vec2 uv = FRAGCOORD.xy / iResolution.xy; 
    
    // Center the coordinates and adjust aspect ratio for tunnel projection
    // This creates a coordinate system where (0,0) is the center,
    // and the shorter side spans from -1 to 1.
    vec2 p = (2.0 * FRAGCOORD.xy - iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // Convert to polar coordinates for the tunnel effect
    float r = length(p); // Distance from center
    float a = atan(p.y, p.x); // Angle in radians
    
    // Create the tunnel effect with warping based on distance from center
    float tunnel_depth_factor = 1.0 / (r + 0.5); // Inverse relationship with radius
    
    // Animate the tunnel movement by fracting the Z-coordinate over time
    // Using built-in TIME
    float z = fract(tunnel_depth_factor + TIME * 0.5); 
    
    // Create grid lines for the tunnel
    float numLines = 20.0;
    float lineThickness = 0.03;
    
    // Radial lines
    float radialLines = abs(fract(a / PI * numLines * 0.5) - 0.5);
    radialLines = smoothstep(0.0, lineThickness, radialLines);
    
    // Circular lines
    float circLines = abs(fract(z * numLines) - 0.5);
    circLines = smoothstep(0.0, lineThickness, circLines);
    
    // Combine the lines
    float lines = min(radialLines, circLines);
    
    // Define colors
    const vec3 BLACK = vec3(0.0, 0.0, 0.0);
    const vec3 NEON_GREEN = vec3(0.0, 1.0, 0.4);
    const vec3 NEON_PINK = vec3(1.0, 0.1, 0.8);
    const vec3 WHITE = vec3(1.0, 1.0, 1.0);
    
    vec3 final_color_val = BLACK; // Start with black background. Renamed to avoid conflict.
    
    // Alternate line color
    // Using built-in TIME
    vec3 lineColor = mix(
        NEON_GREEN, 
        NEON_PINK, 
        sin(a * 5.0 + TIME) * 0.5 + 0.5 
    );
    
    // White "highway" circular lines
    // Using built-in TIME
    float whiteCircles = step(0.95, sin(z * 30.0 + TIME)); 
    lineColor = mix(lineColor, WHITE, whiteCircles * 0.7);
    
    // Apply lines to background
    final_color_val = mix(final_color_val, lineColor, (1.0 - lines) * z * 2.5);
    
    // Pulsing horizon glow
    // Using built-in TIME
    float horizon = smoothstep(0.6, 0.0, abs(p.y + 0.2)); 
    float horizonPulse = sin(TIME * 0.5) * 0.5 + 0.5;
    vec3 horizonColor = mix(NEON_PINK, NEON_GREEN, horizonPulse);
    final_color_val = mix(final_color_val, horizonColor, horizon * 0.5 * z);
    
    // Subtle white scanlines (using the original 'uv' for screen-space effect)
    float scanline_effect = sin(uv.y * iResolution.y * 1.5) * 0.03; // uv.y is [0,1]
    final_color_val = mix(final_color_val, WHITE, scanline_effect * z);
    
    // Stars (noise-based, using original 'uv')
    float stars = step(0.997, fract(sin(dot(uv, vec2(12.9898, 78.233)) * 43758.5453)));
    vec3 starColor = mix(NEON_GREEN, NEON_PINK, fract(a));
    final_color_val = mix(final_color_val, starColor, stars * 0.8);
    
    // Pulsing white glow at the very center
    // Using built-in TIME
    float centerGlow = smoothstep(0.3 + sin(TIME) * 0.1, 0.0, r); 
    final_color_val = mix(final_color_val, WHITE, centerGlow * 0.7);
    
    // Dark vignette
    float vignette_effect = smoothstep(1.0, 0.3, r);
    final_color_val *= vignette_effect;
    
    COLOR = vec4(final_color_val, 1.0);
} 