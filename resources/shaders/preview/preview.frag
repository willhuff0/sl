#version 300 es
precision highp float;

layout(std140) uniform SL {
    mat4 viewProjMat;
    mat4 projMat;
    mat4 viewMat;
    vec3 viewPos;
    highp uint radianceMipLevelCount;
} sl;

in vec3 v_position;
in vec3 v_normal;

out vec4 o_color;

const vec3 lightPos = vec3(3.0, 5.0, 4.0);
const vec3 lightColor = vec3(1.0, 0.8, 1.0);
const vec3 objectColor = vec3(0.8, 1.0, 1.0);
const vec3 ambientColor = vec3(0.1, 0.08, 0.1);

void main() {
    vec3 ambient = ambientColor;

    vec3 N = normalize(v_normal);
    vec3 L = normalize(lightPos - v_position);
    vec3 diffuse = max(dot(N, L), 0.0) * lightColor;

    vec3 V = normalize(sl.viewPos - v_position);
    vec3 R = reflect(-L, N);
    vec3 specular = pow(max(dot(V, R), 0.0), 32.0) * lightColor;

    o_color = vec4((ambient + diffuse + specular) * objectColor, 1.0);
}