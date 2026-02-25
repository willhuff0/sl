#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
} sl;

uniform mat4 u_modelMat;

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;

out vec3 v_position;
out vec3 v_normal;

void main() {
    vec4 position = u_modelMat * vec4(a_position, 1.0);
    gl_Position = sl.viewProjMat * position;
    v_position = vec3(position);
    v_normal = a_normal;
}