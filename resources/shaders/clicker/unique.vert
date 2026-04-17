#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

uniform mat4 u_modelMat;

layout(location = 0) in vec3 a_position;

void main() {
    gl_Position = sl.viewProjMat * u_modelMat * vec4(a_position, 1.0);
}