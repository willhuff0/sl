#version 300 es
precision highp float;

uniform sampler2D u_unblurredTexture;
uniform sampler2D u_blurredTexture;
uniform vec4 u_color;

in vec2 v_texCoords;

out vec4 o_color;

void main() {
    float unblurred = texture(u_unblurredTexture, v_texCoords).r;
    float blurred = texture(u_blurredTexture, v_texCoords).r;

    float diff = abs(unblurred - blurred);
    float alpha = smoothstep(0.0, 0.25, diff);

    o_color = vec4(u_color.rgb, u_color.a * alpha);
}