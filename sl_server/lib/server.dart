import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:sl_server/web_socket_handler.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final Set<int> clients = {};

  var hasAnyCursorPositionChanged = false;

  Scope({required this.scopeId});
}

class Client {
  final WebSocketChannel socket;
  final int clientId;
  final int color;
  UUID scopeId = '';

  ViewPosition? viewPosition;

  Client({
    required this.socket,
    required this.clientId,
    required this.color,
  });
}

class Server {
  late final WebSocketHandler _webSocketHandler;
  final Map<int, Client> _clients = {};
  final Map<UUID, Scope> _scopes = {};
  var _nextClientId = 0;
  var _availableColors = List.from(_colors);
  late final Timer _tickTimer;

  Server() {
    _webSocketHandler = WebSocketHandler(_onConnection, null, null, null);
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
    _broadcastSetClients();
  }

  void _onConnection(WebSocketChannel socket, _) {
    final client = Client(
      socket: socket,
      clientId: _nextClientId++,
      color: _pickColor(),
    );
    _clients[client.clientId] = client;
    send(client, StcSetSelf(clientId: client.clientId));
    _broadcastSetClients();
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
      case CtsSetViewPosition setViewPosition:
        if (client.scopeId != setViewPosition.scopeId) {
          _setClientScope(client, setViewPosition.scopeId);
        }
        client.viewPosition = setViewPosition.value;
        _scopes[client.scopeId]!.hasAnyCursorPositionChanged = true;
        break;
    }
  }

  void _tick() {
    for (final scope in _scopes.values) {
      if (scope.hasAnyCursorPositionChanged) {
        _broadcastScopeSetCursorPositions(scope);
        scope.hasAnyCursorPositionChanged = false;
      }
    }
  }

  void _setClientScope(Client client, UUID scopeId) {
    _removeClientFromScope(client);
    if (scopeId.isEmpty) return;

    var scope = _scopes[scopeId] ?? (_scopes[scopeId] = Scope(scopeId: scopeId));
    scope.clients.add(client.clientId);
    client.scopeId = scopeId;
  }

  void _removeClientFromScope(Client client) {
    if (client.scopeId.isEmpty) return;
    final scope = _scopes[client.scopeId]!;
    scope.clients.remove(client.clientId);
    if (scope.clients.isEmpty) _scopes.remove(client.scopeId);
    client.scopeId = '';
  }

  int _pickColor() {
    if (_availableColors.isEmpty) _availableColors = List.from(_colors);
    return _availableColors.removeAt(_random.nextInt(_availableColors.length));
  }

  void _broadcastSetClients() {
    broadcast(
      StcSetClients(
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

  void _broadcastScopeSetCursorPositions(Scope scope) {
    broadcast(
      StcSetViewPositions(
        scopeId: scope.scopeId,
        values: Map.fromEntries(
          scope.clients.map((clientId) {
            final client = _clients[clientId]!;
            if (client.viewPosition == null) return null;
            return MapEntry(clientId, client.viewPosition!);
          }).nonNulls,
        ),
      ),
      only: scope.clients.map((clientId) => _clients[clientId]!),
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
