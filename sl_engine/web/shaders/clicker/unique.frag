#version 300 es
precision highp float;

uniform uvec3 u_id;

out vec4 o_id;

void main() {
    o_id = vec4(vec3(u_id) / 255.0, 1.0);
}