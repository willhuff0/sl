// import 'dart:async';

// const _rpcTimeout = Duration(milliseconds: 2000);

// class RpcPeer {
//   final void Function(dynamic) sendCallback;

//   final Map<String, Future<(String? error, dynamic)> Function(dynamic)> _methods = {};

//   final Map<int, Completer> _calls = {};
//   var _nextCallId = 0;

//   RpcPeer({required this.sendCallback});

//   void registerMethod(String name, Future<(String? error, dynamic)> Function(dynamic) method) {
//     _methods[name] = method;
//   }

//   Future<dynamic> callRemoteMethod(String name, dynamic params) {
//     final id = _nextCallId++;
//     final call = _calls[id] = Completer();
//     sendCallback(
//       {
//         'id': id,
//         'method': name,
//         'params': ?params,
//       },
//     );
//     return call.future.timeout(
//       _rpcTimeout,
//       onTimeout: () {
//         _calls.remove(id);
//         return Future.error(TimeoutException('RPC $name timed out.'));
//       },
//     );
//   }

//   Future<void> handleMessage(Map<String, dynamic> message) async {
//     final id = message['id']!;
//     final methodName = message['method'];
//     if (methodName != null) {
//       // message is call
//       final method = _methods[methodName]!;
//       final params = message['params'];

//       final (error, response) = await method(params);
//       sendCallback(
//         {
//           'id': id,
//           'error': ?error,
//           'response': ?response,
//         },
//       );
//     } else {
//       // message is reply
//       final response = message['response'];
//       final call = _calls[id];
//       if (call != null) {
//         call.complete(response);
//       }
//     }
//   }
// }
