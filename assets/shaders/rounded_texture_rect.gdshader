shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 100.0) = 20.0; // Uniform radius for all corners in pixels

void fragment() {
    vec2 size = 1.0 / TEXTURE_PIXEL_SIZE; // Size of the TextureRect's texture in pixels
    
    // Calculate UV coordinates normalized to the actual pixel size of the control
    // This is important if the TextureRect node is scaled differently than its texture.
    // For simplicity, we'll assume the control size matches texture aspect ratio for now.
    // A more robust way involves passing control_size as another uniform if they can differ significantly.

    vec2 uv_px = UV * size; // Current pixel coordinate being processed

    // Calculate distance from each edge
    float dist_left = uv_px.x;
    float dist_right = size.x - uv_px.x;
    float dist_top = uv_px.y;
    float dist_bottom = size.y - uv_px.y;

    // Check if inside the corner regions
    bool in_top_left_corner = uv_px.x < corner_radius && uv_px.y < corner_radius;
    bool in_top_right_corner = (size.x - uv_px.x) < corner_radius && uv_px.y < corner_radius;
    bool in_bottom_left_corner = uv_px.x < corner_radius && (size.y - uv_px.y) < corner_radius;
    bool in_bottom_right_corner = (size.x - uv_px.x) < corner_radius && (size.y - uv_px.y) < corner_radius;

    float alpha = 1.0;

    if (in_top_left_corner) {
        if (distance(uv_px, vec2(corner_radius, corner_radius)) > corner_radius) {
            alpha = 0.0;
        }
    } else if (in_top_right_corner) {
        if (distance(uv_px, vec2(size.x - corner_radius, corner_radius)) > corner_radius) {
            alpha = 0.0;
        }
    } else if (in_bottom_left_corner) {
        if (distance(uv_px, vec2(corner_radius, size.y - corner_radius)) > corner_radius) {
            alpha = 0.0;
        }
    } else if (in_bottom_right_corner) {
        if (distance(uv_px, vec2(size.x - corner_radius, size.y - corner_radius)) > corner_radius) {
            alpha = 0.0;
        }
    } else {
        // Not in a corner, just check if outside the main rectangle (already implicitly handled by UVs)
        // No further clipping needed for straight edges if UVs are 0-1
    }

    // If outside the bounding box defined by the radii (i.e., in the "cut-off" part of a corner)
    // This simplified logic checks if the pixel is beyond the radius from the corner's center point.
    if ( (uv_px.x < corner_radius && uv_px.y < corner_radius && distance(uv_px, vec2(corner_radius, corner_radius)) > corner_radius) ||
         (uv_px.x > size.x - corner_radius && uv_px.y < corner_radius && distance(uv_px, vec2(size.x - corner_radius, corner_radius)) > corner_radius) ||
         (uv_px.x < corner_radius && uv_px.y > size.y - corner_radius && distance(uv_px, vec2(corner_radius, size.y - corner_radius)) > corner_radius) ||
         (uv_px.x > size.x - corner_radius && uv_px.y > size.y - corner_radius && distance(uv_px, vec2(size.x - corner_radius, size.y - corner_radius)) > corner_radius) )
    {
        alpha = 0.0;
    }
    
    COLOR = texture(TEXTURE, UV);
    COLOR.a *= alpha;
} 