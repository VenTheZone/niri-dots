// Rebuild after editing:  /usr/lib/qt6/bin/qsb --qt6 -o halftone.frag.qsb halftone.frag
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 accent;
    vec2 res;
    float spin;
};

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 px = uv * res;
    float aspect = res.x / res.y;

    // big accent disc on the left fading out through halftone dots
    float d = length((uv - vec2(0.12, 0.5)) * vec2(aspect, 1.0));
    float tone = 1.0 - smoothstep(0.38, 0.64, d + 0.03 * sin(uv.y * 14.0 + spin));
    // ragged accent edge on the right
    tone = max(tone, smoothstep(0.9, 1.0, uv.x + 0.035 * sin(uv.y * 9.0 - spin)));

    vec2 rp = mat2(0.7071, -0.7071, 0.7071, 0.7071) * px;
    vec2 cell = fract(rp / 11.0) - 0.5;
    float r = 0.72 * sqrt(tone);
    float dotMask = 1.0 - smoothstep(r - 0.05, r + 0.05, length(cell));
    float a = max(dotMask, step(0.985, tone));

    fragColor = vec4(mix(vec3(0.02), accent.rgb, a), 1.0) * qt_Opacity;
}
