import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:sl_editor/client/view_manager.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:vector_math/vector_math.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const tickInterval = Duration(milliseconds: 1000);

Vector4 _intToVec4Color(int value) {
  final color = Color(value);
  return Vector4(color.r, color.g, color.b, color.a);
}

class Scope {
  final UUID scopeId;
  Map<int, ClientSceneState> states = {};

  Scope({required this.scopeId});
}

class Client {
  final WebSocketChannel _socket;
  late final ClientId _clientId;

  late final RpcPeer rpc;

  final _onClientStatesChangedController = StreamController<UnmodifiableMapView<int, ClientState>>.broadcast();
  late final Stream<UnmodifiableMapView<int, ClientState>> onClientStatesChanged;
  Map<int, ClientState> _clientStates = {};

  Scope? _scope;

  late final StreamSubscription _listenSubscription;
  late final Timer _tickTimer;

  static Future<Client> connect({
    required Uri serverUri,
  }) async {
    final socket = WebSocketChannel.connect(serverUri);
    await socket.ready;
    return Client._(socket: socket);
  }

  static late Client _instance;
  static Client get() {
    return _instance;
  }

  Client._({required WebSocketChannel socket}) : _socket = socket {
    rpc = RpcPeer(sendCallback: _sendRpc);
    _listenSubscription = _socket.stream.listen(_onData);
    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
    onClientStatesChanged = _onClientStatesChangedController.stream;
    ViewManager.init();
    _instance = this;
  }

  void dispose() {
    _listenSubscription.cancel();
    _socket.sink.close();
    _tickTimer.cancel();
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
        _scope!.states[_clientId] = ClientSceneState(viewPosition: null);
        break;
      case StcSetClientGlobalStates setClientGlobalStates:
        _clientStates = setClientGlobalStates.states;
        if (!_clientStates.containsKey(_clientId)) {
          Logger.log('Leaving because StcSetClientGlobalStates did not contain an entry for this client.', .info);
          _leave();
          return;
        }
        _onClientStatesChangedController.add(UnmodifiableMapView(_clientStates));
        break;
      case StcSetClientSceneStates setClientScopeStates:
        if (_scope?.scopeId != setClientScopeStates.sceneId) {
          _sendScopeState();
          return;
        }
        _scope!.states = setClientScopeStates.states;
        ViewManager.setRemoteViewPositions(
          Map.fromEntries(
            _scope!.states.entries
                .where((entry) => entry.value.viewPosition != null)
                .map(
                  (entry) => MapEntry(entry.key, (
                    _intToVec4Color(_clientStates[entry.key]!.color),
                    entry.value.viewPosition!,
                  )),
                ),
          ),
        );
        break;
      case StcLocalChangeDecisions localChangeDecisions:
        StateTracker.handleChangeDecisions(localChangeDecisions);
        break;
      case StcRemoteChanges remoteChanges:
        StateTracker.handleRemoteChanges(remoteChanges);
        break;
      case PtpRpc jsonRpc:
        rpc.handleMessage(jsonRpc.message);
        break;
    }
  }

  void _tick() {
    if (_scope != null && ViewManager.hasViewChangedAndUpdate()) {
      _scope!.states[_clientId]!.viewPosition = ViewManager.getViewPosition();
      _sendScopeState();
    }
    if (StateTracker.hasLocalChanges()) {
      StateTracker.submitLocalChanges();
    }
  }

  Future<void> _leave() async {
    await _socket.sink.close();
  }

  void _sendRpc(dynamic message) {
    send(
      PtpRpc(
        message: message,
      ),
    );
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

  void _sendScopeState() {
    send(
      CtsSetSceneState(
        sceneId: _scope?.scopeId,
        state: _scope?.states[_clientId],
      ),
    );
  }

  UnmodifiableMapView<int, ClientState> getClientStates() => UnmodifiableMapView(_clientStates);
  ClientState getSelfClientState() => _clientStates[_clientId]!;
  int getClientId() => _clientId;
}
