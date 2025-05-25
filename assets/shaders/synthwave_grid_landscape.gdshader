shader_type canvas_item;

// Godot's built-in uniforms
// uniform float iTime : hint_range(0.0, 1000.0); // Replaced by TIME
uniform vec2 iResolution = vec2(1024.0, 768.0); // Default resolution, update from script for dynamic sizing

// Constants
const vec3 BG = vec3(0.0, 0.0, 0.0);
const float EPS = 0.001;
const float FOVH = 70.0;
const float D = 0.1;
const float MAX_DIST = 30.0;
const int MAX_ITER = 400;
const float AMBIENT = 0.1; 
const int FSAA = 2; // For Anti-Aliasing (can be performance heavy)
const float GRID_DIM = 1.0;
uniform bool JUMP = false; 

// Global for time, but will be handled by TIME uniform.
// float jTime; // Not needed as TIME will handle time-based animations

float sq(float x) {
    return x * x;
}

// From https://www.shadertoy.com/view/Msf3WH
vec2 hashv(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(in vec2 p) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

    vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    vec2 o = vec2(m, 1.0 - m);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n = h * h * h * h * vec3(dot(a, hashv(i + 0.0)), dot(b, hashv(i + o)), dot(c, hashv(i + 1.0)));
    return dot(n, vec3(70.0));
}

// From https://www.shadertoy.com/view/WttXWX
int hash(int x) {
    x ^= x >> 16;
    x *= 0x7feb352d;
    x ^= x >> 15;
    x *= 0x846ca68b;
    x ^= x >> 16;
    return x;
}

float hash_float(vec2 vf) {
    int offset = vf.x < 0.0 ? 13 : 0;
    ivec2 vi = ivec2(abs(vf));
    int h = hash(vi.x + (vi.y << 16) + offset);
    return float(h & 0x7fffffff) / float(0x7fffffff);
}

float vertex_height(vec2 vf) {
    float offset = -2.0 + 2.0 * smoothstep(5.0, 8.0, abs(vf.x));
    float amplitude = mix(0.5, 2.0, smoothstep(7.0, 12.0, abs(vf.x)));
    return amplitude * hash_float(vf) + offset + (JUMP ? 0.2 * abs(sin(4.0 * TIME)) : 0.0); // Using TIME
}

// Adapted from https://www.shadertoy.com/view/tsScRK
float height_and_color_map(vec2 proj) {
    proj /= GRID_DIM;
    proj.x -= 0.5;
    vec2 d = fract(proj);
    proj -= d;
    bool gd = dot(d, vec2(1.0)) < 1.0;
    vec2 pt = proj + (gd ? vec2(0.0) : vec2(1.0)); 
    
    float n2 = vertex_height(proj + vec2(1.0, 0.0));
    float n3 = vertex_height(proj + vec2(0.0, 1.0));
    float nt = vertex_height(pt);
    
    float nmid = mix(n2, n3, d.y);
    float nv, dx;
    if (gd) {
        nv = mix(nt, n3, d.y); 
        dx = d.x / (1.0 - d.y);
    } else {
        nv = mix(n2, nt, d.y); 
        dx = (1.0 - d.x) / (d.y);
    }
    return mix(nv, nmid, dx);
}

// Signed distance function that defines the scene.
float sdf(in vec3 pos) {
    return pos.y - height_and_color_map(pos.xz);
}

// Ray marching engine.
void rayMarcher(in vec3 cameraPos, in vec3 lookDir, in vec2 screenDim, in vec2 uv_coord, 
                inout vec3 col_ref) { // Changed col to col_ref to avoid conflict with outer scope
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 lookPerH = normalize(cross(lookDir, up));
    vec3 lookPerV = normalize(cross(-lookDir, lookPerH));
    vec3 screenCenter = cameraPos + lookDir;
    vec3 screenPos = screenCenter + 0.5 * screenDim.x * uv_coord.x * lookPerH
                                 + 0.5 * screenDim.y * uv_coord.y * lookPerV;
    
    vec3 rayDir = normalize(screenPos - cameraPos);
    
    float t = 0.0;
    float dist;
    vec3 pos;
    int iter = 0;
    do {
        pos = cameraPos + t * rayDir;
        dist = sdf(pos);
        t += 0.5 * dist; 
        iter++;
    } while (iter < MAX_ITER && dist < MAX_DIST && dist > EPS);
    
    if (dist <= EPS) {
        vec3 new_col = vec3(0.0, 0.0, 0.0);
        
        vec3 nml = normalize(vec3(
            sdf(pos + vec3(EPS, 0.0, 0.0)) - dist, 
            sdf(pos + vec3(0.0, EPS, 0.0)) - dist,
            sdf(pos + vec3(0.0, 0.0, EPS)) - dist
        ));

        float dx_grid = mod(pos.x - GRID_DIM / 2.0, GRID_DIM); // Renamed dx to dx_grid
        dx_grid = min(dx_grid, GRID_DIM - dx_grid);
        float dz_grid = mod(pos.z, GRID_DIM); // Renamed dz to dz_grid
        dz_grid = min(dz_grid, GRID_DIM - dz_grid);
        
        float col_t = smoothstep(4.0, 7.0, abs(pos.x));
        vec3 col_dark = mix(vec3(0.3, 0.0, 0.3), vec3(0.1, 0.2, 0.3), col_t);
        vec3 col_bright = mix(vec3(1.0, 0.9, 1.0), vec3(0.9, 1.0, 1.0), col_t);
        vec3 lightDir = vec3(0.0, -0.5, 1.0); 
        
        new_col = mix(new_col, col_dark, clamp(dot(-lightDir, nml), 0.0, 1.0));
        new_col = mix(col_bright, new_col, smoothstep(0.02, 0.04, min(dx_grid, dz_grid)));
        
        col_ref = mix(new_col, col_ref, smoothstep(28.0, 30.0, cameraPos.z - pos.z));
    }
}

vec4 sampleColor(in vec2 sampleCoord) {
    float aspectRatio = iResolution.x / iResolution.y;
    float screenWidth = 2.0 * D * tan(0.5 * radians(FOVH)); 

    vec3 cameraPos = vec3(0.0, 0.0, -2.0 * TIME); // Using TIME
    vec3 lookDir = vec3(0.0, 0.0, -D);
    vec2 screenDim = vec2(screenWidth, screenWidth / aspectRatio);

    vec2 uv_normalized = 2.0 * sampleCoord / iResolution.xy - 1.0;
    
    vec2 uvf = 2.0 * (sampleCoord - iResolution.xy / 2.0) / iResolution.y;
    
    vec3 col_val = BG; // Renamed col to col_val
    
    float noiseVal = noise(60.0 * uvf);
    float whiteIntensity = smoothstep(0.6, 1.0, noiseVal);
    col_val = mix(col_val, vec3(1.0, 1.0, 1.0), whiteIntensity);
    
    const vec2 sun_c = vec2(0.0, 0.25);
    const float sun_r = 0.4;
    if (length(uvf - sun_c) < sun_r) {
        vec3 sun_col = mix(vec3(1.0, 0.4, 0.8), vec3(1.0, 1.0, 0.3), (uv_normalized.y - sun_c.y + sun_r) / (2.0 * sun_r));
        const float BAND_HEIGHT = 0.02;
        float dy_sun = mod(uvf.y, BAND_HEIGHT) / BAND_HEIGHT; // Renamed dy to dy_sun
        col_val = mix(sun_col, vec3(0.0, 0.0, 0.0), smoothstep(0.25, 0.35, abs(dy_sun - 0.5)));
    }
    
    rayMarcher(cameraPos, lookDir, screenDim, uv_normalized, col_val);

    return vec4(col_val, 1.0);
}

void fragment() {
    vec4 colSum = vec4(0.0);
    for (int i = 0; i < FSAA; i++) {
        for (int j = 0; j < FSAA; j++) {
            colSum += sampleColor(FRAGCOORD.xy + vec2(float(i) / float(FSAA), float(j) / float(FSAA)));
        }
    }
    COLOR = colSum / float(FSAA * FSAA);
    COLOR.a = 1.0; 
} 