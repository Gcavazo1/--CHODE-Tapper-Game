shader_type canvas_item;

uniform vec4 light_color : source_color = vec4(1.0, 0.8, 0.6, 1.0); // Light color (e.g., warm white)
uniform vec2 light_pos_uv = vec2(0.5, 0.0); // Light position in normalized UV coordinates (0,0 top-left, 1,1 bottom-right)
uniform float light_radius : hint_range(0.0, 2.0) = 0.5; // Radius of the light effect in UV space
uniform float light_intensity : hint_range(0.0, 5.0) = 1.5; // Intensity of the light
uniform float edge_smoothness : hint_range(0.01, 0.5) = 0.1; // How soft the light falloff is

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV); // Get the sprite's texture color
	
	// Calculate distance from the current pixel to the light_pos_uv
	// We might want to adjust how distance is calculated based on sprite aspect ratio if needed
	float dist = distance(UV, light_pos_uv);
	
	// Calculate light attenuation
	// smoothstep creates a soft falloff: 0 outside radius, 1 inside (radius - smoothness)
	float attenuation = smoothstep(light_radius, light_radius - edge_smoothness, dist);
	
	// Apply light color and intensity
	vec3 lighted_color = tex_color.rgb + (light_color.rgb * attenuation * light_intensity);
	
	// Combine with original texture alpha
	COLOR = vec4(lighted_color, tex_color.a);
	// For a more "additive" light effect, you could try:
	// COLOR = vec4(tex_color.rgb + light_color.rgb * attenuation * light_intensity, tex_color.a);
	// COLOR.rgb = clamp(COLOR.rgb, vec3(0.0), vec3(1.0)); // Optional: clamp if colors go > 1
} 