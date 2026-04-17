#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

layout(location = 0) in vec3 a_position;

out vec3 v_localPosition;

void main() {
    vec4 viewPos = sl.viewMat * vec4(a_position, 0.0);
    vec4 clipPos = sl.projMat * viewPos;

    gl_Position = clipPos.xyww;
    v_localPosition = a_position;
}