#version 300 es
precision highp float;

in vec3 v_position;
in vec3 v_normal;

out vec4 o_color;

void main() {
    vec3 N = normalize(v_normal);
    vec3 L = normalize(vec3(-3.0, 5.0, 2.0) - v_position);
    // Lambert's cosine law
    float lambertian = max(dot(N, L), 0.0);
    float specular = 0.0;
    if(lambertian > 0.0) {
        vec3 R = reflect(-L, N);      // Reflected light vector
        vec3 V = normalize(-v_position); // Vector to viewer
        // Compute the specular term
        float specAngle = max(dot(R, V), 0.0);
        specular = pow(specAngle, 50.0);
    }
    o_color = vec4(vec3(0.2, 0.2, 0.2) +
                lambertian * vec3(1.0, 0.8, 1.0) +
                specular * vec3(1.0, 1.0, 0.8), 1.0);
}