import 'dart:math';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/input.dart';
import 'package:vector_math/vector_math.dart';

const _sprintMultiplier = 2.5;

class FlyCamera {
  double sensitivity;
  double speed;
  double fov;
  double near;
  double far;

  Vector3 _position;
  double _pitch;
  double _yaw;

  FlyCamera({
    this.sensitivity = 45.0,
    this.speed = 5.0,
    this.fov = 70.0,
    this.near = 0.1,
    this.far = 1000.0,
    Vector3? position,
    double? pitch,
    double? yaw,
  }) : _position = position ?? Vector3.zero(),
       _pitch = pitch ?? 0.0,
       _yaw = yaw ?? 0.0;

  (Vector3, Matrix4 view, Matrix4 proj) tick(double dt) {
    final aspectRatio = canvas.width / canvas.height;

    // scroll

    // look
    _pitch = max(min(_pitch - Input.getMouseDelta().y * sensitivity / 800.0, 89.99), -89.99);
    _yaw += Input.getMouseDelta().x * sensitivity / 800.0;

    final forward = Vector3(
      cos(radians(_pitch)) * cos(radians(_yaw)),
      sin(radians(_pitch)),
      cos(radians(_pitch)) * sin(radians(_yaw)),
    ).normalized();
    final right = forward.cross(Vector3(0.0, 1.0, 0.0)).normalized();

    var moveInput = Vector3.zero();
    if (Input.isKeyHeld(Key.w)) moveInput.z += 1.0;
    if (Input.isKeyHeld(Key.s)) moveInput.z -= 1.0;
    if (Input.isKeyHeld(Key.d)) moveInput.x += 1.0;
    if (Input.isKeyHeld(Key.a)) moveInput.x -= 1.0;
    moveInput.normalize();

    final move = right * moveInput.x + forward * moveInput.z;
    if (Input.isKeyHeld(Key.e)) move.y += 1.0;
    if (Input.isKeyHeld(Key.q)) move.y -= 1.0;
    move.normalize();

    final sprint = Input.isKeyHeld(Key.shiftLeft) ? _sprintMultiplier : 1.0;

    _position += move * (speed * sprint * dt);

    return (
      _position,
      makeViewMatrix(_position, _position + forward, Vector3(0.0, 1.0, 0.0)),
      makePerspectiveMatrix(radians(fov), aspectRatio, near, far),
    );
  }
}
