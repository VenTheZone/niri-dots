// Rebuild after editing:  /usr/lib/qt6/bin/qsb --qt6 -o wall.frag.qsb wall.frag
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 accent;
    vec4 shade;
    vec2 mouse;
    float aspect;
    float radius;
    float spot;
    float reveal;
    float progress;
    float mode;
};

layout(binding = 1) uniform sampler2D cur;
layout(binding = 2) uniform sampler2D prev;

float hash(float n) { return fract(sin(n) * 43758.5453); }

float transition(vec2 uv) {
    vec2 d = (uv - 0.5) * vec2(aspect, 1.0);
    float dist = length(d);
    float far = length(vec2(aspect, 1.0) * 0.5) + 0.1;
    if (mode < 0.5) return progress;                                          // fade
    if (mode < 1.5) return clamp((progress * 1.2 - uv.x) / 0.2, 0.0, 1.0);    // wipe
    if (mode < 2.5) return clamp((progress * far - dist) / 0.1, 0.0, 1.0);    // grow
    if (mode < 3.5) return clamp((dist - (1.0 - progress) * far + 0.1) / 0.1, 0.0, 1.0); // outer
    float a = fract(atan(d.x, -d.y) / 6.2831853);                             // clock
    return clamp((progress * 1.05 - a) / 0.05, 0.0, 1.0);
}

vec3 poster(vec2 uv) {
    return mix(texture(prev, uv).rgb, texture(cur, uv).rgb, transition(uv));
}

void main() {
    vec2 uv = qt_TexCoord0;

    // glitch peaks halfway through a reveal flip or a wallpaper change
    float g = max(sin(3.14159 * reveal), 0.4 * sin(3.14159 * progress));
    float seed = floor((reveal + progress) * 24.0);
    float band = floor(uv.y * 36.0);
    float bn = hash(band * 1.37 + seed * 7.13);
    if (bn > 1.0 - 0.45 * g) uv.x += (hash(band + seed) - 0.5) * 0.18 * g;

    float split = 0.008 * g;
    vec3 c = vec3(poster(uv + vec2(split, 0.0)).r,
                  poster(uv).g,
                  poster(uv - vec2(split, 0.0)).b);

    // inverted duotone: darks become the accent, lights sink into the shade
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 duo = mix(accent.rgb, shade.rgb, smoothstep(0.02, 0.85, lum));

    vec2 dm = (qt_TexCoord0 - mouse) * vec2(aspect, 1.0);
    float torch = (1.0 - smoothstep(radius * 0.35, radius, length(dm))) * spot;
    float flip = clamp(reveal + (bn - 0.5) * g, 0.0, 1.0);

    fragColor = vec4(mix(duo, c, max(torch, flip)), 1.0) * qt_Opacity;
}
