import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/widgets/cursors.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const tickInterval = Duration(milliseconds: 100);

final _otherCursorPositionController = StreamController<List<(int color, ViewPosition)>>.broadcast();
final otherCursorPositionStream = _otherCursorPositionController.stream;

class Scope {
  final UUID scopeId;
  Map<int, ViewPosition> cursorPositions = {};

  Scope({required this.scopeId});
}

class Client {
  final WebSocketChannel _socket;
  late final ClientId _clientId;

  final _onClientStatesChangedController = StreamController<UnmodifiableMapView<int, ClientState>>.broadcast();
  late final Stream<UnmodifiableMapView<int, ClientState>> onClientStatesChanged;
  Map<int, ClientState> _clientStates = {};

  Scope? _scope;

  late final Timer _tickTimer;

  late final StreamSubscription _listenSubscription;
  late final StreamSubscription<ViewPosition> _ownCursorPositionSubscription;
  ViewPosition? _changedOwnViewPosition;

  static late Client _instance;

  static Future<Client> connect({
    required Uri serverUri,
  }) async {
    final socket = WebSocketChannel.connect(serverUri);
    await socket.ready;
    return Client._(socket: socket);
  }

  static Client get() {
    return _instance;
  }

  Client._({required WebSocketChannel socket}) : _socket = socket {
    _listenSubscription = _socket.stream.listen(_onData);
    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
    onClientStatesChanged = _onClientStatesChangedController.stream;
    _ownCursorPositionSubscription = ownCursorPositionStream.listen(_onOwnCursorPositionChanged);
    _instance = this;
  }

  void dispose() {
    _listenSubscription.cancel();
    _socket.sink.close();
    _tickTimer.cancel();
    _ownCursorPositionSubscription.cancel();
  }

  Future<void> _onData(dynamic data) async {
    print('Client received: $data');

    if (_socket.closeCode != null) return;
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
          Logger.log('Leaving because StcSetClients did not contain an entry for this client.', .info);
          _leave();
          return;
        }
        _onClientStatesChangedController.add(UnmodifiableMapView(_clientStates));
        break;
      case StcSetViewPositions setCursorPositions:
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
    if (_changedOwnViewPosition != null) {
      if (_scope != null) {
        send(
          CtsSetViewPosition(
            scopeId: _scope!.scopeId,
            value: _changedOwnViewPosition,
          ),
        );
      }
      _changedOwnViewPosition = null;
    }
    if (StateTracker.hasLocalChanges()) {
      StateTracker.submitLocalChanges();
    }
  }

  void _onOwnCursorPositionChanged(ViewPosition cursorPosition) {
    _changedOwnViewPosition = cursorPosition;
  }

  Future<void> _leave() async {
    await _socket.sink.close();
  }

  void send(Message message) {
    _socket.sink.add(
      jsonEncode(
        MessageAndHeader(
          messageClass: message.messageClass,
          messageInstance: message,
        ),
      ),
    );
  }

  UnmodifiableMapView<int, ClientState> getClientStates() => UnmodifiableMapView(_clientStates);
  ClientState getSelfClientState() => _clientStates[_clientId]!;
  int getClientId() => _clientId;
}
