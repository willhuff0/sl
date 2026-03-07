#version 300 es
precision highp float;

uniform uvec3 u_color;

out vec4 o_color;

void main() {
    o_color = vec4(vec3(u_color) / 255.0, 1.0);
}