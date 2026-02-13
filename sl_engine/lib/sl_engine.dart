import 'dart:js_interop';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart' as vm;
import 'package:web/web.dart' as web;

import 'node.dart';

late final web.WebGL2RenderingContext gl;
web.WebGLProgram? program;
web.WebGLVertexArrayObject? vao;
web.WebGLUniformLocation? uProjection;
web.WebGLUniformLocation? uView;
web.WebGLUniformLocation? uModel;
web.WebGLUniformLocation? uLightDir;
web.WebGLUniformLocation? uViewPos;

late web.HTMLCanvasElement _canvas;

// Scene Graph Root
Node rootNode = Node(name: 'Root');
Node cube1 = Node(name: 'Cube 1');
Node cube2 = Node(name: 'Cube 2');
Node cube3 = Node(name: 'Cube 3');

const vertexSource = '''#version 300 es
in vec3 a_position;
in vec3 a_normal;

uniform mat4 u_projection;
uniform mat4 u_view;
uniform mat4 u_model;

out vec3 v_normal;
out vec3 v_fragPos;

void main() {
    v_fragPos = vec3(u_model * vec4(a_position, 1.0));
    
    // Transform normal to world space (using inverse transpose to handle non-uniform scaling)
    v_normal = mat3(transpose(inverse(u_model))) * a_normal;
    
    gl_Position = u_projection * u_view * u_model * vec4(a_position, 1.0);
}
''';

const fragmentSource = '''#version 300 es
precision highp float;

in vec3 v_normal;
in vec3 v_fragPos;

uniform vec3 u_lightDir;
uniform vec3 u_viewPos;

out vec4 outColor;

void main() {
    vec3 objectColor = vec3(1.0, 0.5, 0.2); // Orange base
    vec3 lightColor = vec3(1.0, 1.0, 1.0);

    // Ambient
    float ambientStrength = 0.2;
    vec3 ambient = ambientStrength * lightColor;

    // Diffuse
    vec3 norm = normalize(v_normal);
    vec3 lightDir = normalize(-u_lightDir); // vector toward light
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;

    // Specular (Phong)
    float specularStrength = 0.5;
    vec3 viewDir = normalize(u_viewPos - v_fragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    vec3 specular = specularStrength * spec * lightColor;

    vec3 result = (ambient + diffuse + specular) * objectColor;
    outColor = vec4(result, 1.0); 
}
''';

void initialize(web.HTMLCanvasElement canvas) {
  _canvas = canvas;
  final context =
      canvas.getContext(
            'webgl2',
            {
              'powerPreference': 'high-performance',
              'antialias': true,
              'depth': true,
            }.jsify(),
          )
          as web.WebGL2RenderingContext?;
  if (context == null) throw Exception('Failed to get WebGL2 context!');
  gl = context;

  // Setup Shaders
  final vs = _createShader(web.WebGL2RenderingContext.VERTEX_SHADER, vertexSource);
  final fs = _createShader(web.WebGL2RenderingContext.FRAGMENT_SHADER, fragmentSource);
  program = _createProgram(vs, fs);

  uProjection = gl.getUniformLocation(program!, 'u_projection');
  uView = gl.getUniformLocation(program!, 'u_view');
  uModel = gl.getUniformLocation(program!, 'u_model');
  uLightDir = gl.getUniformLocation(program!, 'u_lightDir');
  uViewPos = gl.getUniformLocation(program!, 'u_viewPos');

  // Setup Cube Geometry with Normals
  // Format interleaved: x, y, z (pos), nx, ny, nz (normal)
  final vertices = Float32List.fromList([
    // Front face (Normal 0, 0, 1)
    -0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
    0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
    0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
    -0.5, -0.5, 0.5, 0.0, 0.0, 1.0,
    0.5, 0.5, 0.5, 0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5, 0.0, 0.0, 1.0,

    // Back face (Normal 0, 0, -1)
    -0.5, -0.5, -0.5, 0.0, 0.0, -1.0,
    -0.5, 0.5, -0.5, 0.0, 0.0, -1.0,
    0.5, 0.5, -0.5, 0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5, 0.0, 0.0, -1.0,
    0.5, 0.5, -0.5, 0.0, 0.0, -1.0,
    0.5, -0.5, -0.5, 0.0, 0.0, -1.0,

    // Top face (Normal 0, 1, 0)
    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
    -0.5, 0.5, 0.5, 0.0, 1.0, 0.0,
    0.5, 0.5, 0.5, 0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0,
    0.5, 0.5, 0.5, 0.0, 1.0, 0.0,
    0.5, 0.5, -0.5, 0.0, 1.0, 0.0,

    // Bottom face (Normal 0, -1, 0)
    -0.5, -0.5, -0.5, 0.0, -1.0, 0.0,
    0.5, -0.5, -0.5, 0.0, -1.0, 0.0,
    0.5, -0.5, 0.5, 0.0, -1.0, 0.0,
    -0.5, -0.5, -0.5, 0.0, -1.0, 0.0,
    0.5, -0.5, 0.5, 0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5, 0.0, -1.0, 0.0,

    // Right face (Normal 1, 0, 0)
    0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
    0.5, 0.5, -0.5, 1.0, 0.0, 0.0,
    0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
    0.5, -0.5, -0.5, 1.0, 0.0, 0.0,
    0.5, 0.5, 0.5, 1.0, 0.0, 0.0,
    0.5, -0.5, 0.5, 1.0, 0.0, 0.0,

    // Left face (Normal -1, 0, 0)
    -0.5, -0.5, -0.5, -1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5, -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5, -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5, -1.0, 0.0, 0.0,
    -0.5, 0.5, -0.5, -1.0, 0.0, 0.0,
  ]);

  vao = gl.createVertexArray();
  gl.bindVertexArray(vao);

  final buffer = gl.createBuffer();
  gl.bindBuffer(web.WebGL2RenderingContext.ARRAY_BUFFER, buffer);
  gl.bufferData(web.WebGL2RenderingContext.ARRAY_BUFFER, vertices.toJS, web.WebGL2RenderingContext.STATIC_DRAW);

  // Stride: 6 floats * 4 bytes = 24 bytes
  const stride = 24;

  final aPosition = gl.getAttribLocation(program!, 'a_position');
  gl.enableVertexAttribArray(aPosition);
  gl.vertexAttribPointer(aPosition, 3, web.WebGL2RenderingContext.FLOAT, false, stride, 0);

  final aNormal = gl.getAttribLocation(program!, 'a_normal');
  gl.enableVertexAttribArray(aNormal);
  // Offset: 3 floats * 4 bytes = 12 bytes
  gl.vertexAttribPointer(aNormal, 3, web.WebGL2RenderingContext.FLOAT, false, stride, 12);

  // Setup Scene Hierarchy
  rootNode.addChild(cube1);
  cube1.addChild(cube2);
  cube2.addChild(cube3);

  // Center the first cube roughly
  cube1.lPos = vm.Vector3(0.0, 0.0, 0.0);

  // Offset second cube and shrink
  cube2.lPos = vm.Vector3(2.0, 0.0, 0.0);
  cube2.lScale = vm.Vector3(0.7, 0.7, 0.7);

  // Offset third cube and shrink
  cube3.lPos = vm.Vector3(1.5, 0.0, 0.0);
  cube3.lScale = vm.Vector3(0.7, 0.7, 0.7);

  web.window.requestAnimationFrame(frame.toJS);
}

web.WebGLShader _createShader(int type, String source) {
  final shader = gl.createShader(type)!;
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!(gl.getShaderParameter(shader, web.WebGL2RenderingContext.COMPILE_STATUS) as bool)) {
    throw Exception(gl.getShaderInfoLog(shader));
  }
  return shader;
}

web.WebGLProgram _createProgram(web.WebGLShader vs, web.WebGLShader fs) {
  final prog = gl.createProgram()!;
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!(gl.getProgramParameter(prog, web.WebGL2RenderingContext.LINK_STATUS) as bool)) {
    throw Exception(gl.getProgramInfoLog(prog));
  }
  return prog;
}

void frame(num time) {
  // Update rotation
  double t = time / 1000.0;

  // Rotate cube1 around Y axis
  cube1.lRot = vm.Quaternion.axisAngle(vm.Vector3(0.0, 1.0, 0.0), t);

  // Rotate cube2 around Z axis (orbits cube1 because it's a child)
  cube2.lRot = vm.Quaternion.axisAngle(vm.Vector3(0.0, 1.0, 0.0), t * 1.5);

  // Rotate cube3 around X axis (orbits cube2)
  cube3.lRot = vm.Quaternion.axisAngle(vm.Vector3(0.0, 1.0, 0.0), t * 2.0);

  // Resize canvas if needed
  final width = _canvas.clientWidth;
  final height = _canvas.clientHeight;
  if (_canvas.width != width || _canvas.height != height) {
    _canvas.width = width;
    _canvas.height = height;
    gl.viewport(0, 0, width, height);
  }

  double aspectRatio = width / height;

  gl.clearColor(0.1, 0.1, 0.1, 1.0);
  gl.enable(web.WebGL2RenderingContext.DEPTH_TEST);
  gl.clear(web.WebGL2RenderingContext.COLOR_BUFFER_BIT | web.WebGL2RenderingContext.DEPTH_BUFFER_BIT);

  gl.useProgram(program);

  // Set Lighting Uniforms
  gl.uniform3f(uLightDir, -0.2, -1.0, -0.3); // Light from top-right-ish
  gl.uniform3f(uViewPos, 0.0, 2.0, 6.0); // Camera position (matches view matrix below)

  // Perspective Projection
  final projectionMatrix = vm.makePerspectiveMatrix(vm.radians(60.0), aspectRatio, 0.1, 100.0);
  final bufferP = Float32List(16);
  projectionMatrix.copyIntoArray(bufferP);
  gl.uniformMatrix4fv(uProjection, false, bufferP.toJS);

  // View Matrix (LookAt)
  final viewMatrix = vm.makeViewMatrix(
    vm.Vector3(0.0, 2.0, 6.0), // Camera position
    vm.Vector3(0.0, 0.0, 0.0), // Target
    vm.Vector3(0.0, 1.0, 0.0), // Up
  );
  final bufferV = Float32List(16);
  viewMatrix.copyIntoArray(bufferV);
  gl.uniformMatrix4fv(uView, false, bufferV.toJS);

  gl.bindVertexArray(vao);

  // Render Cube 1
  _drawNode(cube1);
  // Render Cube 2
  _drawNode(cube2);
  // Render Cube 3
  _drawNode(cube3);

  web.window.requestAnimationFrame(frame.toJS);
}

void _drawNode(Node node) {
  final matrix = node.getMatrix();
  final bufferM = Float32List(16);
  matrix.copyIntoArray(bufferM);
  gl.uniformMatrix4fv(uModel, false, bufferM.toJS);

  // 36 vertices for a cube (6 faces * 2 triangles * 3 vertices)
  gl.drawArrays(web.WebGL2RenderingContext.TRIANGLES, 0, 36);
}
