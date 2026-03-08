#version 300 es
precision highp float;

uniform sampler2D u_texture;

in vec2 v_texCoords;

out vec4 o_color;

void main() {
    vec4 color = texture(u_texture, v_texCoords);
    // if (color.a < 0.5) {
    //     discard;
    // }
    o_color = color;
}