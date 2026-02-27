#version 300 es

out vec2 v_texCoords;

void main() {
    vec2 positions[6] = vec2[](
        // 1st triangle
        vec2(0.0,  0.0),  // center
        vec2(1.0,  0.0),  // right, center
        vec2(0.0,  1.0),  // center, top

        // 2nd triangle
        vec2(0.0,  1.0),  // center, top
        vec2(1.0,  0.0),  // right, center
        vec2(1.0,  1.0)   // right, top
    );

    vec2 xy = positions[gl_VertexID];
    gl_Position = vec4(xy * 2.0 - 1.0, 0.0, 1.0);
    v_texCoords = vec2(xy.x, xy.y);
}