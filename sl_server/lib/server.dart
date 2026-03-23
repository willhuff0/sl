import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:sl_server/database/database.dart';
import 'package:sl_server/state_tracker.dart';
import 'package:sl_server/web_socket_handler.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

const tickInterval = Duration(milliseconds: 100);

final _random = Random();
final List<int> _colors = [
  0xffef4444,
  0xfff59e0b,
  0xff84cc16,
  0xff06b6d4,
  0xffa855f7,
  0xffec4899,
];

class Scope {
  final UUID scopeId;
  final Map<int, ClientScopeState> clients = {};

  var hasAnyClientStateChanged = false;

  Scope({required this.scopeId});
}

class Client {
  final WebSocketChannel socket;
  ClientState state;

  int get clientId => state.clientId;
  UUID? get scopeId => state.scopeId;
  int get color => state.color;

  Client({
    required this.socket,
    required this.state,
  });
}

class Server {
  final String rootPath;

  late final WebSocketHandler _webSocketHandler;
  late final Database _database;
  late final StateTracker _stateTracker;

  final Map<int, Client> _clients = {};
  final Map<UUID, Scope> _scopes = {};

  var _nextClientId = 0;
  var _availableColors = List.from(_colors);

  late final Timer _tickTimer;

  Server(this.rootPath) {
    _webSocketHandler = WebSocketHandler(_onConnection, null, null, null);
    _database = Database(p.join(rootPath, 'db'));
    _stateTracker = StateTracker(this);
    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
  }

  void dispose() {
    _tickTimer.cancel();
  }

  WebSocketHandler getWebSocketHandler() {
    return _webSocketHandler;
  }

  Future<void> kickClient(Client client, {int? status, String? reason}) async {
    print('Kicking client ${client.clientId}');

    await client.socket.sink.close(status, reason);
    _clients.remove(client.clientId);
    _removeClientFromScope(client);
    _broadcastClientStates();
  }

  void _onConnection(WebSocketChannel socket, _) {
    final client = Client(
      socket: socket,
      state: ClientState(
        clientId: _nextClientId++,
        scopeId: null,
        color: _getNextClientColor(),
      ),
    );
    _clients[client.clientId] = client;
    send(client, StcSetSelf(clientId: client.clientId));
    _broadcastClientStates();
    socket.stream.listen((data) => _onData(client, data))
      ..onError((_) => kickClient(client))
      ..onDone(() => kickClient(client));
  }

  void _onData(Client client, dynamic data) {
    print('From ${client.clientId} server received: $data');

    final json = jsonDecode(data) as Map<String, dynamic>;
    final messageAndHeader = MessageAndHeader.fromJson(json);

    _handleMessage(client, messageAndHeader.messageInstance);
  }

  void _handleMessage(Client client, Message message) {
    switch (message) {
      case CtsSetScopeState setScopeState:
        _setClientScopeState(client, setScopeState.scopeId, setScopeState.state);
        break;
      case CtsStateChanges stateChanges:
        _stateTracker.handleClientChanges(client, stateChanges);
        break;
    }
  }

  void _tick() {
    for (final scope in _scopes.values) {
      if (scope.hasAnyClientStateChanged) {
        _broadcastClientScopeStates(scope);
        scope.hasAnyClientStateChanged = false;
      }
    }
  }

  void _setClientScopeState(Client client, UUID? scopeId, ClientScopeState? newState) {
    if (scopeId == null || newState == null) {
      _removeClientFromScope(client);
      return;
    }
    if (scopeId != client.scopeId) {
      _removeClientFromScope(client);
    }

    var scope = _scopes[scopeId] ?? (_scopes[scopeId] = Scope(scopeId: scopeId));
    scope.clients[client.clientId] = newState;
    scope.hasAnyClientStateChanged = true;

    client.state.scopeId = scopeId;
  }

  void _removeClientFromScope(Client client) {
    if (client.scopeId == null) return;

    final scope = _scopes[client.scopeId]!;
    scope.clients.remove(client.clientId);

    if (scope.clients.isEmpty) _scopes.remove(client.scopeId);
    client.state.scopeId = null;
  }

  int _getNextClientColor() {
    if (_availableColors.isEmpty) _availableColors = List.from(_colors);
    return _availableColors.removeAt(_random.nextInt(_availableColors.length));
  }

  void _broadcastClientStates() {
    broadcast(
      StcSetClientGlobalStates(
        states: _clients.map(
          (clientId, client) => MapEntry(
            clientId,
            ClientState(
              clientId: clientId,
              scopeId: client.scopeId,
              color: client.color,
            ),
          ),
        ),
      ),
    );
  }

  void _broadcastClientScopeStates(Scope scope) {
    broadcast(
      StcSetClientScopeStates(
        scopeId: scope.scopeId,
        states: scope.clients,
      ),
      only: scope.clients.keys.map((clientId) => _clients[clientId]!),
    );
  }

  void send(Client client, Message message) {
    client.socket.sink.add(
      jsonEncode(
        MessageAndHeader(
          messageClass: message.messageClass,
          messageInstance: message,
        ),
      ),
    );
  }

  void sendToEach(Message? Function(Client) messageFactory) {
    for (final client in _clients.values) {
      final message = messageFactory(client);
      if (message == null) continue;
      send(client, message);
    }
  }

  void broadcast(dynamic message, {Iterable<Client>? only, Set<Client>? except}) {
    final encodedMessage = message.toJson();
    for (final client in only ?? _clients.values) {
      if (except?.contains(client) ?? false) continue;
      client.socket.sink.add(
        jsonEncode(
          MessageAndHeader(
            messageClass: message.messageClass,
            messageInstance: encodedMessage,
          ),
        ),
      );
    }
  }
}
