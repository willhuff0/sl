#version 300 es
precision highp float;

uniform samplerCube u_cubeMap;

in vec3 v_localPosition;

out vec4 o_color;

void main() {
    // vec3 color = textureLod(u_cubeMap, v_localPosition, 1.0).rgb;
    vec3 color = texture(u_cubeMap, v_localPosition).rgb;

    color = color / (color + vec3(1.0)); // Reinhard
    // color = 1.0 - exp(-color * 1.0); // ACES

    color = pow(color, vec3(1.0 / 2.2));

    o_color = vec4(color, 1.0);
}