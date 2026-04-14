#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 viewMat;
    vec3 viewPos;
} sl;

layout(std140) uniform Renderer {
    mat4 modelMat;
    mat3 normalMat;
} renderer;

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 3) in vec2 a_uv;

out vec3 v_position;
out vec3 v_normal;
out vec2 v_uv;

void main() {
    vec4 position = renderer.modelMat * vec4(a_position, 1.0);
    v_position = vec3(position);
    v_normal = renderer.normalMat * a_normal;
    v_uv = a_uv;

    gl_Position = sl.viewProjMat * position;
}