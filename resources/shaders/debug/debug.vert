#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
} sl;

uniform vec3 u_point;
uniform float u_size;

void main() {
    gl_Position = sl.viewProjMat * vec4(u_point, 1.0);
    gl_PointSize = u_size;
}