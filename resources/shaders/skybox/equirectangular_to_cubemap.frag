#version 300 es
precision highp float;

uniform sampler2D u_equirectangularMap;

in vec3 v_localPosition;

out vec4 o_color;

const float PI = 3.14159265359;

void main() {
    vec3 position = normalize(v_localPosition);

    vec2 uv = vec2(atan(position.x, position.z), asin(position.y));
    uv *= vec2(1.0 / (2.0 * PI), 1.0 / PI);
    uv += 0.5;

    vec3 color = texture(u_equirectangularMap, uv).rgb;
    color = min(color, vec3(100.0));

    o_color = vec4(color, 1.0);
}