#version 300 es

uniform mat4 u_modelMat;
uniform mat4 u_viewProjMat;

layout(location = 0) in vec3 a_position;

void main() {
    gl_Position = u_viewProjMat * u_modelMat * vec4(a_position, 1.0);
}