shader_type canvas_item;

// Uniforms you can set in the Inspector
uniform vec2 iResolution = vec2(128.0, 128.0); // Virtual resolution for the effect on each particle
uniform sampler2D iChannel0 : hint_default_white;   // Optional texture input, can be noise or anything

// Using Godot's built-in TIME instead of a separate iTime uniform
// const float iTime = TIME; // This is how you'd conceptually use it, direct usage of TIME is better.

// Original GetHeight function (adapted to use Godot's TIME)
float GetHeight( vec2 uv )
{
    if ( uv.x < 0.0 ) // This condition might need adjustment based on UV space (0-1)
        return 1.0;

    float updown = sin( uv.x * 12.0 + TIME * 0.6 ) * mix( 1.0, 0.2, uv.x ) * 0.12;
    float yspread = (uv.y - 0.5) * mix( 1.0, 0.1, uv.x ) + 0.5;
    float leftright = sin( (yspread + updown) * 20.0 );
    
    float checker = sin( (uv.x + TIME * 0.05) * 40.0 ) * sin( uv.y * 10.0 - TIME * 1.0 ) * 0.5 + 0.5;
    
    float yCenterToEdge = (uv.y - 0.5) / 0.5;
    yCenterToEdge *= yCenterToEdge;
    float xpow = mix( 0.17, 0.25, yCenterToEdge );
    
    float phase = fract( pow( uv.x, xpow ) * 40.0 + leftright * 0.32 + checker * 0.2 + TIME * 0.1 * 1.4 );
        
    float wave = cos( phase * 2.0 * 3.14159 ) * 0.5 + 0.5;
    
    float height = mix( 1.0, wave, pow( uv.x, 0.8 ) );
    return height;
}

// Original Color function
vec3 ColorFunction( float x ) // Renamed to avoid conflict with Godot's COLOR built-in
{
    const vec3 c0 = vec3( 1.0, 0.8, 0.5 ) * 1.8;
    const vec3 c1 = vec3( 1.0, 0.5, 0.25 ) * 1.1;
    const vec3 c2 = vec3( 0.5, 0.15, 0.4 ) * 0.8;
    const vec3 c3 = vec3( 0.2, 0.04, 0.35 ) * 0.5;
    const vec3 c4 = vec3( 0.001, 0.003, 0.05 );
    if ( x < 0.4 )
    {
        if ( x < 0.1 )
            return mix( c0, c1, x / 0.1 );
        else
        	return mix( c1, c2, (x - 0.1) / 0.3 );
    }
    else
    {
        if ( x < 0.6 )
        	return mix( c2, c3, (x - 0.4) / 0.2 );
        else
        {
    		x = min( x, 1.0 );
    		return mix( c3, c4, (x - 0.6) / 0.4 );
        }
    }
}

// Helper for sinsin, defined as a standard function for Godot 3.x compatibility
float sinsin_local_func(vec2 val) { // Renamed to avoid any potential conflict if defined globally
     return min( abs( sin( val.x ) * sin( val.y ) ) * 1.2, 1.0 );
}

// Original Glitter function (adapted to use Godot's TIME and iResolution uniform)
float Glitter( vec2 uv_glitter ) // Renamed uv to uv_glitter to avoid conflict if called with different uv
{
    uv_glitter *= 0.8;
    // This line made sense if iResolution was screen resolution.
    // For per-particle UVs, it might stretch based on particle's virtual iResolution.
    // uv_glitter.x *= iResolution.x / iResolution.y; 
    
    uv_glitter.x += sin( uv_glitter.y * 20.0 ) * 0.03;
    
    // Call the standard helper function
    float x = sinsin_local_func( (uv_glitter.xx * vec2( 0.64, 0.77 ) + uv_glitter.yy * vec2( 0.77, -0.64 )) * 300.0 );
    x *= sinsin_local_func( (uv_glitter.xx * vec2( 0.34, 0.94 ) + uv_glitter.yy * vec2( 0.94, -0.34 )) * 211.0 );
    x *= sinsin_local_func( (uv_glitter.xx * vec2( 0.99, 0.12 ) + uv_glitter.yy * vec2( 0.12, -0.99 )) * 73.0 );
    
    return pow( x * 1.015, 100.0 );
}

void fragment()
{
    // UV is the per-particle UV coordinate (0,0 to 1,1)
    vec2 uv = UV; 
    
    // If you want the effect to respect the iResolution uniform as its virtual canvas:
    // vec2 uv_scaled_for_effect = UV * iResolution; 
    // Then pass uv_scaled_for_effect or uv (normalized for the effect functions) to GetHeight, Glitter etc.
    // For now, using direct UV (0-1 range) for simplicity. The functions might expect a specific range.

    float height = GetHeight( uv );
    
    // The Glitter function's UV manipulation might need adjustment
    // depending on how you want it to appear on each particle.
    // Adding TIME to uv here makes the glitter pattern move across particles over time.
    // Height multiplication makes glitter react to the ripple.
    float dust = Glitter( uv + vec2( TIME * 0.04, height * -0.02 ) );
    dust = mix( 0.0, dust, uv.x ); // Fades glitter towards the left
    
    // Calculate base color from ripple height and uv position
    vec3 final_color_rgb = ColorFunction( uv.x + (height - 1.0) * 0.05 );
    
    // Add glitter to the color
    final_color_rgb += vec3( 1.0, 0.5, 0.1 ) * dust;
    
    // Sample the base texture assigned to the GPUParticles2D node
    vec4 base_texture_color = texture(TEXTURE, UV);
    
    // Apply the procedural color, but use the alpha from the base texture
    COLOR = vec4(final_color_rgb, base_texture_color.a);
    
    // Optional: Gamma correction (can make colors look richer)
    COLOR.rgb = sqrt(COLOR.rgb);
} 