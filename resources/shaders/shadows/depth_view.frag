#version 300 es
precision highp float;
precision highp sampler2DArray;

uniform sampler2DArray u_depthMap;
uniform uint u_cascades;

in vec2 v_texCoords;

out vec4 o_color;

void main() {
    uint x = uint(v_texCoords.x * 2.0);
    uint y = uint(v_texCoords.y * 2.0);
    uint cascade = x + y * 2u;

    if (cascade >= u_cascades) {
        discard;
    }

    vec2 sampleTexCoord = vec2(v_texCoords.xy * 2.0) - vec2(x, y);

    float depth = texture(u_depthMap, vec3(sampleTexCoord, float(cascade))).r;
    o_color = vec4(depth, depth, depth, 1.0);
}