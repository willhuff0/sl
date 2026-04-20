#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

uniform mat4 u_modelMat;
uniform float u_screenScale;

layout(location = 0) in vec3 a_position;

void main() {
    mat4 modelViewProjMat = sl.viewProjMat * u_modelMat;

    // float w = (modelViewProjMat * vec4(0.0, 0.0, 0.0, 1.0)).w;
    // w *= u_screenScale;

    // gl_Position = modelViewProjMat * vec4(a_position * w, 1.0);
    gl_Position = modelViewProjMat * vec4(a_position, 1.0);
}