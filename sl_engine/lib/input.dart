import 'dart:collection';
import 'dart:js_interop';

import 'package:sl_engine/gl/gl.dart';
import 'package:sl_engine/logger.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web/web.dart' as web;

class Input {
  static late final Map<String, Key> _codeToKey;

  static final Set<Key> _down = {};
  static final Set<Key> _held = {};
  static final Set<Key> _up = {};

  static var _mouseDelta = Vector2.zero();
  static var _mouseScrollDelta = 0.0;

  static late bool _hasFocus;

  static void init({bool editorMode = false}) {
    _codeToKey = Map.fromEntries(Key.values.map((key) => MapEntry(key.code, key)));

    web.document.addEventListener('keydown', _onKeyDown.toJS);
    web.document.addEventListener('keyup', _onKeyUp.toJS);

    if (editorMode) {
      _hasFocus = false;

      canvas.addEventListener('mousedown', _editorMouseDown.toJS);
      canvas.addEventListener('mouseup', _editorMouseUp.toJS);
    } else {
      _hasFocus = web.document.hasFocus();

      canvas.addEventListener('click', _onClick.toJS);
    }

    web.document.addEventListener('pointerlockchange', _onPointerLockChange.toJS);

    canvas.addEventListener('mousemove', _onMouseMove.toJS);
    canvas.addEventListener('wheel', _onWheel.toJS);
  }

  static void postTick() {
    _down.clear();
    _up.clear();

    _mouseDelta = Vector2.zero();
    _mouseScrollDelta = 0.0;
  }

  static bool isKeyDown(Key key) => _down.contains(key);
  static bool isKeyHeld(Key key) => _held.contains(key);
  static bool isKeyUp(Key key) => _up.contains(key);

  static UnmodifiableSetView<Key> getKeysDown() => UnmodifiableSetView(_down);
  static UnmodifiableSetView<Key> getKeysHeld() => UnmodifiableSetView(_held);
  static UnmodifiableSetView<Key> getKeysUp() => UnmodifiableSetView(_up);

  static Vector2 getMouseDelta() => _mouseDelta;
  static double getMouseScrollDelta() => _mouseScrollDelta;

  static void _onKeyDown(web.KeyboardEvent event) {
    if (!_hasFocus) return;

    final key = _codeToKey[event.code];
    if (key == null) {
      Logger.log('Unrecognized key code \'${event.code}\'');
      return;
    }

    _down.add(key);
    _held.add(key);
    _up.remove(key);
  }

  static void _onKeyUp(web.KeyboardEvent event) {
    if (!_hasFocus) return;

    final key = _codeToKey[event.code];
    if (key == null) {
      Logger.log('Unrecognized key code \'${event.code}\'');
      return;
    }

    _down.remove(key);
    _held.remove(key);
    _up.add(key);
  }

  static void _onClick(web.PointerEvent event) async {
    await canvas
        .requestPointerLock(
          web.PointerLockOptions(
            unadjustedMovement: true,
          ),
        )
        .toDart;
  }

  static void _editorMouseDown(web.MouseEvent event) async {
    if (event.button != 2) return;
    await canvas
        .requestPointerLock(
          web.PointerLockOptions(
            unadjustedMovement: true,
          ),
        )
        .toDart;
  }

  static void _editorMouseUp(web.MouseEvent event) async {
    if (event.button != 2) return;
    web.document.exitPointerLock();
  }

  static void _onPointerLockChange() {
    if (web.document.pointerLockElement == canvas) {
      _hasFocus = true;
    } else {
      _down.clear();
      _held.clear();
      _up.clear();

      _mouseDelta = Vector2.zero();
      _mouseScrollDelta = 0.0;

      _hasFocus = false;
    }
  }

  static void _onMouseMove(web.MouseEvent event) {
    if (!_hasFocus) return;

    _mouseDelta += Vector2(event.movementX, event.movementY);
  }

  static void _onWheel(web.WheelEvent event) {
    if (!_hasFocus) return;

    _mouseScrollDelta += event.deltaY;
  }
}

enum Key {
  escape('Escape'),
  alpha0('Digit0'),
  alpha1('Digit1'),
  alpha2('Digit2'),
  alpha3('Digit3'),
  alpha4('Digit4'),
  alpha5('Digit5'),
  alpha6('Digit6'),
  alpha7('Digit7'),
  alpha8('Digit8'),
  alpha9('Digit9'),
  minus('Minus'),
  equal('Equal'),
  backspace('Backspace'),
  tab('Tab'),
  q('KeyQ'),
  w('KeyW'),
  e('KeyE'),
  r('KeyR'),
  t('KeyT'),
  y('KeyY'),
  u('KeyU'),
  i('KeyI'),
  o('KeyO'),
  p('KeyP'),
  bracketLeft('BracketLeft'),
  bracketRight('BracketRight'),
  enter('Enter'),
  controlLeft('ControlLeft'),
  a('KeyA'),
  s('KeyS'),
  d('KeyD'),
  f('KeyF'),
  g('KeyG'),
  h('KeyH'),
  j('KeyJ'),
  k('KeyK'),
  l('KeyL'),
  semicolon('Semicolon'),
  quote('Quote'),
  backquote('Backquote'),
  shiftLeft('ShiftLeft'),
  backslash('Backslash'),
  z('KeyZ'),
  x('KeyX'),
  c('KeyC'),
  v('KeyV'),
  b('KeyB'),
  n('KeyN'),
  m('KeyM'),
  comma('Comma'),
  period('Period'),
  slash('Slash'),
  shiftRight('ShiftRight'),
  numpadMultiply('NumpadMultiply'),
  altLeft('AltLeft'),
  space('Space'),
  capsLock('CapsLock'),
  f1('F1'),
  f2('F2'),
  f3('F3'),
  f4('F4'),
  f5('F5'),
  f6('F6'),
  f7('F7'),
  f8('F8'),
  f9('F9'),
  f10('F10'),
  numLock('NumLock'),
  scrollLock('ScrollLock'),
  numpad7('Numpad7'),
  numpad8('Numpad8'),
  numpad9('Numpad9'),
  numpadSubtract('NumpadSubtract'),
  numpad4('Numpad4'),
  numpad5('Numpad5'),
  numpad6('Numpad6'),
  numpadAdd('NumpadAdd'),
  numpad1('Numpad1'),
  numpad2('Numpad2'),
  numpad3('Numpad3'),
  numpad0('Numpad0'),
  numpadDecimal('NumpadDecimal'),
  intlBackslash('IntlBackslash'),
  f11('F11'),
  f12('F12'),
  numpadEnter('NumpadEnter'),
  controlRight('ControlRight'),
  numpadDivide('NumpadDivide'),
  printScreen('PrintScreen'),
  altRight('AltRight'),
  home('Home'),
  arrowUp('ArrowUp'),
  pageUp('PageUp'),
  arrowLeft('ArrowLeft'),
  arrowRight('ArrowRight'),
  end('End'),
  arrowDown('ArrowDown'),
  pageDown('PageDown'),
  insert('Insert'),
  delete('Delete'),
  metaLeft('MetaLeft'),
  metaRight('MetaRight'),
  contextMenu('ContextMenu'),
  ;

  final String code;

  const Key(this.code);
}
