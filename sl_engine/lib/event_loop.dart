// import 'dart:collection';

// abstract interface class EventListener {
//   Future<void> init() async {}

//   void tick(double time, double dt) {}
//   void physicsTick(double time, double dt) {}
//   void render() {}

//   void dispose() {}
// }

// class EventLoop {
//   static final SplayTreeMap<int, Set<EventListener>> _listeners = SplayTreeMap();

//   static void register(EventListener listener, {int order = 0}) {
//     final orderSet = _listeners[order] ??= {};
//     orderSet.add(listener);
//   }

//   static Future<void> init() async {
//     for (final orderSet in _listeners.values) {
//       await Future.wait(
//         orderSet.map(
//           (listener) => listener.init(),
//         ),
//       );
//     }
//   }

//   static void tick(double time, double dt) {
//     for (final orderSet in _listeners.values) {
//       for (final listener in orderSet) {
//         listener.tick(time, dt);
//       }
//     }
//   }

//   static void physicsTick(double time, double dt) {
//     for (final orderSet in _listeners.values) {
//       for (final listener in orderSet) {
//         listener.physicsTick(time, dt);
//       }
//     }
//   }

//   static void render() {
//     for (final orderSet in _listeners.values) {
//       for (final listener in orderSet) {
//         listener.render();
//       }
//     }
//   }

//   static void dispose() {
//     for (final orderSet in _listeners.values) {
//       for (final listener in orderSet) {
//         listener.dispose();
//       }
//     }
//   }
// }
