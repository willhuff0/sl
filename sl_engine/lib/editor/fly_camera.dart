import 'dart:math';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/input.dart';
import 'package:vector_math/vector_math.dart';

const _sprintMultiplier = 2.5;

class FlyCamera {
  double lookSensitivity;
  double scrollSensitivity;
  double speed;
  double fov;
  double near;
  double far;

  Vector3 _position;
  double _pitch;
  double _yaw;

  var _scrollSpeedMultiplier = 1.0;

  (Vector3 position, Matrix4 view, Matrix4 proj)? _state;
  (Vector3 position, Quaternion orientation, double fov)? _viewPosition;

  FlyCamera({
    this.lookSensitivity = 45.0,
    this.scrollSensitivity = 0.1,
    this.speed = 5.0,
    this.fov = 70.0,
    this.near = 0.1,
    this.far = 1000.0,
    Vector3? position,
    double? pitch,
    double? yaw,
  }) : _position = position ?? Vector3.zero(),
       _pitch = pitch ?? 0.0,
       _yaw = yaw ?? 0.0 {
    Input.onFocusChanged.listen((focused) {
      _scrollSpeedMultiplier = 1.0;
    });
  }

  void tick(double dt) {
    final aspectRatio = canvas.width / canvas.height;

    // scroll
    _scrollSpeedMultiplier = max(_scrollSpeedMultiplier - Input.getMouseScrollDelta() * scrollSensitivity, 0.1);

    // look
    _pitch = min(max(_pitch - Input.getMouseDelta().y * lookSensitivity / 800.0, -89.99), 89.99);
    _yaw += Input.getMouseDelta().x * lookSensitivity / 800.0;

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

    _position += move * (speed * _scrollSpeedMultiplier * sprint * dt);

    _state = (
      _position,
      makeViewMatrix(_position, _position + forward, Vector3(0.0, 1.0, 0.0)),
      makePerspectiveMatrix(radians(fov), aspectRatio, near, far),
    );
    _viewPosition = (
      _position,
      Quaternion.euler(_yaw, _pitch, 0.0),
      fov,
    );
  }

  (Vector3 position, Matrix4 view, Matrix4 proj)? getState() => _state;
  (Vector3 position, Quaternion orientation, double fov)? getViewPosition() => _viewPosition;
}
