// Rebuild after editing:  /usr/lib/qt6/bin/qsb --qt6 -o crt.frag.qsb crt.frag
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float noise;
};

layout(binding = 1) uniform sampler2D src;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void main() {
    vec2 cc = qt_TexCoord0 - 0.5;
    float r2 = dot(cc, cc);
    vec2 uv = 0.5 + cc * (1.0 + 0.18 * r2);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, qt_Opacity);
        return;
    }

    float jitter = (hash(vec2(floor(uv.y * 120.0), floor(time * 30.0))) - 0.5) * 0.03 * noise;
    uv.x += jitter;

    float s = 0.0025 + 0.012 * noise;
    vec3 c = vec3(texture(src, uv + vec2(s, 0.0)).r,
                  texture(src, uv).g,
                  texture(src, uv - vec2(s, 0.0)).b);

    c *= 0.82 + 0.18 * sin(uv.y * 1100.0);                      // scanlines
    c += 0.05 * smoothstep(0.96, 1.0, sin(uv.y * 3.0 - time * 1.4)); // rolling bar
    float grain = hash(uv * 900.0 + fract(time) * 37.0);
    c = mix(c, vec3(grain), 0.06 + 0.9 * noise);                 // static
    c *= 1.0 - 1.6 * r2;                                         // vignette

    fragColor = vec4(c, 1.0) * qt_Opacity;
}
