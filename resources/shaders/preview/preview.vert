#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

uniform mat4 u_modelMat;
uniform mat3 u_normalMat;

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;

out vec3 v_position;
out vec3 v_normal;

void main() {
    vec4 position = u_modelMat * vec4(a_position, 1.0);
    v_position = vec3(position);
    v_normal = u_normalMat * a_normal;

    gl_Position = sl.viewProjMat * position;
}