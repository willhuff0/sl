#version 300 es
precision mediump float;

#define SAMPLE_COUNT 6

const float OFFSETS[SAMPLE_COUNT] = float[](
    -4.378621204796657,
    -2.431625915613778,
    -0.4862426846689485,
    1.4588111840004858,
    3.4048471718931532,
    5.0
);

const float WEIGHTS[SAMPLE_COUNT] = float[](
    0.09461172151436463,
    0.20023097066826712,
    0.2760751120037518,
    0.24804559825032563,
    0.14521459357563646,
    0.035822003987654526
);

uniform sampler2D u_inputTexture;
uniform vec2 u_blurDirection;

in vec2 v_texCoords;

out float o_color;

void main() {
    ivec2 dimensions = textureSize(u_inputTexture, 0);
    float result = 0.0;
    for (int i = 0; i < SAMPLE_COUNT; i++) {
        vec2 offset = u_blurDirection * OFFSETS[i] / vec2(dimensions);
        float weight = WEIGHTS[i];
        result += texture(u_inputTexture, v_texCoords + offset).r * weight;
    }
    o_color = result;
}