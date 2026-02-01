library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SmoothScrollController extends ScrollController {
  SmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    super.onAttach,
    super.onDetach,
  });

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _ScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

/// Scroll animation duration
const _duration = Duration(milliseconds: 250);

/// Threshold to determine a touchpad
const _touchDelta = 20.0;

/// Minimum movement delta for a single mouse wheel event
const _minDelta = 100.0;

/// Maximum movement delta for mouse wheel
const _maxDelta = 300.0;

/// When multiple scroll events are triggered in the same direction before the animation finishes,
/// an acceleration is accumulated until the final speed reaches the [_maxDelta] threshold.
const _speedUpDelta = 25.0;

class _ScrollPosition extends ScrollPositionWithSingleContext {
  _ScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  }) {
    controller =
        AnimationController.unbounded(
            value: pixels,
            duration: _duration,
            vsync: context.vsync,
          )
          ..addListener(_listener)
          ..addStatusListener(_statusListener);
  }

  /// Animation controller for scrolling; its value stays in sync with [pixels].
  /// When [pointerScroll] receives mouse events, it converts a single delta into
  /// multiple target [pixels] values via animation.
  late final AnimationController controller;

  /// Final target scroll position
  double targetPosition = 0.0;

  /// Accumulated speed when repeatedly scrolling quickly in the same direction
  double currentSpeed = 0.0;

  /// Whether the scroll is in the forward direction
  bool? isForwardScroll;

  /// When [targetPosition] reaches the top or bottom, subsequent mouse scroll events will be ignored
  bool? _ignoreUpScroll;
  bool? _ignoreDownScroll;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Listener for animation status when scrolling ends; cleans up resources
  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      currentSpeed = 0.0;
      isScrollingNotifier.value = false;
      isForwardScroll = null;
      _ignoreUpScroll = null;
      _ignoreDownScroll = null;

      didEndScroll();
      context.setIgnorePointer(false);
    }
  }

  /// Listener for scrolling animation; performs scrolling logic
  void _listener() {
    if (controller.value == pixels) return;
    final double oldPixels = pixels;
    correctPixels(controller.value); // directly update offset
    notifyListeners(); // notify so the UI scrolls
    didUpdateScrollPositionBy(pixels - oldPixels); // inform scrollbars of the change
  }

  /// Override pointer scroll logic to support smooth mouse scrolling
  @override
  void pointerScroll(double delta) {
    if (delta == 0.0) {
      goIdle();
      return;
    }

    // On web, if the touchpad has taken over handling, ignore the code below
    if (touchHandler(delta)) return;

    // Ignore pointer hit testing while scrolling
    context.setIgnorePointer(true);

    // Sync scroll position to the animation controller (offsets caused by dragging the scrollbar,
    // touchpad swipes, or other non-mouse-wheel interactions)
    if (controller.value != pixels) controller.value = pixels;

    // Scrolling down
    if (delta > 0) {
      if (_ignoreDownScroll == true) return;

      final $delta = max(_minDelta, delta);
      if (isForwardScroll == null) {
        goIdle();
        // In scroll direction terms: scrolling up is forward, scrolling down is reverse
        updateUserScrollDirection(ScrollDirection.reverse);
        isScrollingNotifier.value = true;
        didStartScroll();
        isForwardScroll = true;
        targetPosition = pixels + $delta;
      }
      // If animation hasn't finished and we receive another incremental event in the same direction,
      // only compute the final target position.
      else if (isForwardScroll == true) {
        currentSpeed += _speedUpDelta;
        targetPosition += min($delta + currentSpeed, _maxDelta);
      }
      // If an upward scroll animation hasn't finished and the mouse scrolls down (opposite direction),
      // interrupt the current animation, reset speed, and compute a new target starting from current position.
      else {
        updateUserScrollDirection(ScrollDirection.reverse);
        _ignoreUpScroll = null;
        isForwardScroll = true;
        currentSpeed = 0.0;
        targetPosition = controller.value + $delta;
      }

      if (targetPosition >= maxScrollExtent) {
        _ignoreDownScroll = true;
        targetPosition = maxScrollExtent;
      }
    }
    // Scrolling up - logic mirrors the section above
    else {
      if (_ignoreUpScroll == true) return;

      final $delta = min(-_minDelta, delta);
      if (isForwardScroll == null) {
        goIdle();
        updateUserScrollDirection(ScrollDirection.forward);
        isScrollingNotifier.value = true;
        didStartScroll();
        isForwardScroll = false;
        targetPosition = pixels + $delta;
      } else if (isForwardScroll == false) {
        currentSpeed += _speedUpDelta;
        targetPosition += max($delta - currentSpeed, -_maxDelta);
      } else {
        updateUserScrollDirection(ScrollDirection.forward);
        _ignoreDownScroll = null;
        isForwardScroll = false;
        currentSpeed = 0.0;
        targetPosition = controller.value + $delta;
      }

      if (targetPosition <= minScrollExtent) {
        _ignoreUpScroll = true;
        targetPosition = minScrollExtent;
      }
    }

    controller.animateTo(targetPosition, curve: Curves.decelerate);
  }

  // =========================================================================
  // Web touchpad handling:
  // On non-web clients touchpad scrolling doesn't enter pointerScroll, but web does not
  // differentiate between mouse and touchpad. Keep this logic until Flutter fixes that.
  bool? triggerTouch;
  Timer? _triggerTouchTimer;

  void _addTriggerTouchTimer() {
    _triggerTouchTimer = Timer(Duration(milliseconds: 100), () {
      triggerTouch = null;
      _triggerTouchTimer = null;
    });
  }

  bool touchHandler(double delta) {
    if (delta.abs() <= _touchDelta && triggerTouch == null) {
      triggerTouch = true;
      super.pointerScroll(delta);
      _addTriggerTouchTimer();
      return true;
    }

    if (triggerTouch == true) {
      if (_triggerTouchTimer != null) {
        _triggerTouchTimer!.cancel();
        _triggerTouchTimer = null;
      }
      super.pointerScroll(delta);
      _addTriggerTouchTimer();
      return true;
    }

    return false;
  }

  // =========================================================================
}
