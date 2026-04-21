#version 300 es

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

layout(std140) uniform Renderer {
    mat4 modelMat;
    mat3 normalMat;
} renderer;

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec4 a_tangent;
layout(location = 3) in vec2 a_uv_0;
layout(location = 4) in vec2 a_uv_1;
layout(location = 5) in vec2 a_uv_2;
layout(location = 6) in vec2 a_uv_3;

out vec3 v_position;
out vec3 v_normal;
out vec3 v_tangent;
out vec3 v_bitangent;
out vec2 v_uv_0;
out vec2 v_uv_1;
out vec2 v_uv_2;
out vec2 v_uv_3;

void main() {
    vec4 position = renderer.modelMat * vec4(a_position, 1.0);
    v_position = vec3(position);
    v_normal = renderer.normalMat * a_normal;
    v_tangent = renderer.normalMat * a_tangent.xyz;
    v_bitangent = cross(v_normal, v_tangent) * a_tangent.w;
    v_uv_0 = a_uv_0;
    v_uv_1 = a_uv_1;
    v_uv_2 = a_uv_2;
    v_uv_3 = a_uv_3;

    gl_Position = sl.viewProjMat * position;
}