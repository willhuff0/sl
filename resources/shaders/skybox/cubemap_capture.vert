#version 300 es

uniform mat4 u_viewProjMat;

layout(location = 0) in vec3 a_position;

out vec3 v_localPosition;

void main() {
    gl_Position = u_viewProjMat * vec4(a_position, 1.0);
    v_localPosition = a_position;
}