import 'dart:async';

import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class Client {
  final ClientState state;

  Client({required this.state});

  int get clientId => state.clientId;
  String get name => state.name;
  int get color => state.color;
  UUID? get sceneId => state.sceneId;

  Stream<dynamic> get stream;

  void send(dynamic data);
  Future close([int? closeCode, String? closeReason]);

  bool get isClosed;
}

class HumanClient extends Client {
  final WebSocketChannel _socket;

  HumanClient({
    required WebSocketChannel socket,
    required super.state,
  }) : _socket = socket;

  @override
  Stream<dynamic> get stream => _socket.stream;

  @override
  void send(dynamic data) {
    _socket.sink.add(data);
  }

  @override
  Future close([int? closeCode, String? closeReason]) {
    return _socket.sink.close(closeCode, closeReason);
  }

  @override
  bool get isClosed => _socket.closeCode != null;
}

class VirtualClient extends Client {
  final _controller = StreamController<dynamic>.broadcast();
  @override
  late final Stream<dynamic> stream;

  VirtualClient({required super.state}) {
    stream = _controller.stream;
  }

  @override
  void send(dynamic data) {}

  @override
  Future<dynamic> close([int? closeCode, String? closeReason]) async {
    await _controller.close();
  }

  @override
  bool get isClosed => _controller.isClosed;

  void receiveMessageFrom(dynamic data) {
    _controller.add(data);
  }
}
