import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
  static final _onFocusChangedController = StreamController<bool>.broadcast();
  static final onFocusChanged = _onFocusChangedController.stream;

  // Raw mouse input is only supported on recent browsers.
  // When a request fails, permanently fall back to adjusted pointer-lock input.
  static bool _useUnadjustedMovement = true;

  // Some browsers emit a huge movement delta right around pointer-lock.
  // Drop the first move after locking so the camera doesn't snap around wildly.
  static bool _ignoreNextMouseMove = false;

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

  static void _onClick(web.PointerEvent event) {
    _requestPointerLock();
  }

  static void _editorMouseDown(web.MouseEvent event) {
    if (event.button != 2) return;
    _requestPointerLock();
  }

  static void _editorMouseUp(web.MouseEvent event) {
    if (event.button != 2) return;
    _hasFocus = false;
    web.document.exitPointerLock();
  }

  static void _requestPointerLock() {
    // package:web types requestPointerLock() as returning a non-null Promise,
    // but legacy browsers return `undefined`, toDart and awaiting which errors.
    // Call via callMethod so the return is nullable and the null check isn't optimized out.
    final promise = _useUnadjustedMovement ? canvas.callMethod<JSPromise<JSAny?>?>('requestPointerLock'.toJS, web.PointerLockOptions(unadjustedMovement: true)) : canvas.callMethod<JSPromise<JSAny?>?>('requestPointerLock'.toJS);

    // the request was still issued (in adjusted mode), nothing to await.
    if (promise == null) return;

    unawaited(
      promise.toDart.catchError((Object error) {
        if (_useUnadjustedMovement && _isNotSupportedError(error)) {
          // Raw input isn't supported. Fall back to adjusted input and retry.
          _useUnadjustedMovement = false;
          _requestPointerLock();
        } else {
          Logger.log('Pointer lock request was denied: $error');
        }
        return null;
      }),
    );
  }

  static bool _isNotSupportedError(Object error) {
    final js = error as JSAny?;
    if (js == null || !js.isA<JSObject>()) return false;
    final name = (js as JSObject).getProperty('name'.toJS);
    return name.isA<JSString>() && (name as JSString).toDart == 'NotSupportedError';
  }

  static void _onPointerLockChange() {
    if (web.document.pointerLockElement == canvas) {
      _ignoreNextMouseMove = true;
      _hasFocus = true;
      _onFocusChangedController.add(_hasFocus);
    } else {
      _down.clear();
      _held.clear();
      _up.clear();

      _mouseDelta = Vector2.zero();
      _mouseScrollDelta = 0.0;

      _hasFocus = false;
      _onFocusChangedController.add(_hasFocus);
    }
  }

  static void _onMouseMove(web.MouseEvent event) {
    if (!_hasFocus) return;

    if (_ignoreNextMouseMove) {
      _ignoreNextMouseMove = false;
      return;
    }

    _mouseDelta += Vector2(event.movementX, event.movementY);
  }

  static void _onWheel(web.WheelEvent event) {
    if (!_hasFocus) return;

    _mouseScrollDelta += event.deltaY / 100.0;
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
