import 'dart:async';
import 'dart:convert';

import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/widgets/cursors.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const tickInterval = Duration(milliseconds: 100);

final _otherCursorPositionController = StreamController<List<(int color, CursorPosition)>>.broadcast();
final otherCursorPositionStream = _otherCursorPositionController.stream;

class Scope {
  final UUID scopeId;
  Map<int, CursorPosition> cursorPositions = {};

  Scope({required this.scopeId});
}

class Client {
  late final WebSocketChannel socket;
  late final ClientId _clientId;
  Map<int, ClientState> _clientStates = {};
  ClientState get _clientState => _clientStates[_clientId]!;
  // int _acknowledgementTimestamp = 0;
  Scope? _scope;
  late final Timer _tickTimer;
  late final StreamSubscription<CursorPosition> _ownCursorPositionSubscription;
  CursorPosition? _changedOwnCursorPosition;

  static late Client _instance;

  static Future<Client> connect({
    required Uri serverUri,
  }) async {
    final socket = WebSocketChannel.connect(serverUri);
    await socket.ready;
    return _instance = Client._(socket: socket);
  }

  static Client get() {
    return _instance;
  }

  Client._({required this.socket}) {
    socket.stream.listen(_onData);
    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
    _ownCursorPositionSubscription = ownCursorPositionStream.listen(_onOwnCursorPositionChanged);
  }

  void dispose() {
    _tickTimer.cancel();
    _ownCursorPositionSubscription.cancel();
  }

  Future<void> _onData(dynamic data) async {
    print('Client received: $data');

    if (socket.closeCode != null) return;
    final json = jsonDecode(data) as Map<String, dynamic>;
    final messageAndHeader = MessageAndHeader.fromJson(json);
    _handleMessage(messageAndHeader.messageInstance);
  }

  Future<void> _handleMessage(Message message) async {
    switch (message) {
      case StcSetSelf setSelf:
        _clientId = setSelf.clientId;
        _scope = Scope(scopeId: 'test-scope-id');
        break;
      case StcSetClients setClients:
        _clientStates = setClients.states;
        if (!_clientStates.containsKey(_clientId)) {
          _leave();
          return;
        }
        break;
      case StcSetCursorPositions setCursorPositions:
        if (_scope?.scopeId != setCursorPositions.scopeId) return;
        _scope!.cursorPositions = setCursorPositions.values;
        _otherCursorPositionController.add(
          setCursorPositions.values.entries
              .where((entry) => entry.key != _clientId)
              .map((entry) => (_clientStates[entry.key]!.color, entry.value))
              .toList(),
        );
        break;
    }
  }

  void _tick() {
    if (_changedOwnCursorPosition != null) {
      if (_scope != null) {
        sendNoAck(
          CtsSetCursorPosition(
            scopeId: _scope!.scopeId,
            value: _changedOwnCursorPosition,
          ),
        );
      }
      _changedOwnCursorPosition = null;
    }
    if (StateTracker.hasLocalChanges()) {
      StateTracker.submitLocalChanges();
    }
  }

  void _onOwnCursorPositionChanged(CursorPosition cursorPosition) {
    _changedOwnCursorPosition = cursorPosition;
  }

  Future<void> _leave() async {
    await socket.sink.close();
  }

  void sendNoAck(Message message) {
    socket.sink.add(
      jsonEncode(
        MessageAndHeader(
          // acknowledgementTimestamp: -1,
          messageClass: message.messageClass,
          messageInstance: message,
        ),
      ),
    );
  }

  void send(Message message) {
    socket.sink.add(
      jsonEncode(
        MessageAndHeader(
          // acknowledgementTimestamp: ++_acknowledgementTimestamp,
          messageClass: message.messageClass,
          messageInstance: message,
        ),
      ),
    );
  }
}
