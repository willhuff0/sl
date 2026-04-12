import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:sl_server/systems/asset_system.dart';
import 'package:sl_shared/src/database/database.dart' as db;
import 'package:sl_server/systems/scene_system.dart';
import 'package:sl_server/web_socket_handler.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

const tickInterval = Duration(milliseconds: 1000);

final _random = Random();
final List<int> _colors = [
  0xffef4444,
  0xfff59e0b,
  0xff84cc16,
  0xff06b6d4,
  0xffa855f7,
  0xffec4899,
];

class Client {
  final WebSocketChannel socket;
  ClientState state;

  int get clientId => state.clientId;
  int get color => state.color;
  UUID? get sceneId => state.sceneId;

  Client({
    required this.socket,
    required this.state,
  });
}

class Server {
  final String rootPath;

  late final WebSocketHandler _webSocketHandler;
  late final db.Database _database;

  late final SceneSystem _sceneSystem;
  late final AssetSystem _assetSystem;

  final Map<int, Client> _clients = {};

  var _nextClientId = 0;
  var _availableColors = List.from(_colors);

  late final Timer _tickTimer;

  Server(this.rootPath) {
    _webSocketHandler = WebSocketHandler(_onConnection, null, null, null);
    _database = db.Database(p.join(rootPath, 'db.sqlite3'));

    _sceneSystem = SceneSystem(this);
    _assetSystem = AssetSystem(this, _database);

    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
  }

  void dispose() {
    _tickTimer.cancel();
  }

  WebSocketHandler getWebSocketHandler() {
    return _webSocketHandler;
  }

  UnmodifiableMapView<int, Client> getClients() {
    return UnmodifiableMapView(_clients);
  }

  Future<void> removeClient(Client client, {int? status, String? reason}) async {
    print('Removing client ${client.clientId}');

    await client.socket.sink.close(status, reason);
    _clients.remove(client.clientId);

    await _sceneSystem.removeClient(client);
    await _assetSystem.removeClient(client);

    _broadcastClientStates();
  }

  void _onConnection(WebSocketChannel socket, _) async {
    final clientId = _nextClientId++;
    final client = Client(
      socket: socket,
      state: ClientState(
        clientId: clientId,
        sceneId: null,
        color: _getNextClientColor(),
      ),
    );
    _clients[client.clientId] = client;
    send(client, StcSetSelf(clientId: client.clientId));
    _broadcastClientStates();

    try {
      await for (final data in socket.stream) {
        await _onData(client, data);
      }
    } catch (e) {
      print('Error occurred while handling message for client ${client.clientId}');
      await removeClient(client);
    }
    await removeClient(client);
  }

  Future<void> _onData(Client client, dynamic data) async {
    print('From ${client.clientId} server received: (${data.runtimeType}) $data');

    switch (data) {
      case String string:
        final json = jsonDecode(string) as Map<String, dynamic>;
        final messageAndHeader = MessageAndHeader.fromJson(json);

        await _handleMessage(client, messageAndHeader.messageInstance);
        break;
      case Uint8List bytes:
        await _assetSystem.handleBinary(client, bytes);
        break;
    }
  }

  Future<void> _handleMessage(Client client, Message message) async {
    switch (message) {
      case CtsStateChanges stateChanges:
        switch (stateChanges.system) {
          case StateTrackerSystem.scene:
            await _sceneSystem.stateTracker.handleClientChanges(client, stateChanges);
            break;
          case StateTrackerSystem.asset:
            await _assetSystem.handleClientChanges(client, stateChanges);
            break;
        }
        break;
      default:
        if (await _sceneSystem.handleMessage(client, message)) break;
        if (await _assetSystem.handleMessage(client, message)) break;
        break;
    }
  }

  void _tick() {
    _sceneSystem.tick();
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
              sceneId: client.sceneId,
              color: client.color,
            ),
          ),
        ),
      ),
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
    final encodedMessage = jsonEncode(
      MessageAndHeader(
        messageClass: message.messageClass,
        messageInstance: message.toJson(),
      ),
    );
    for (final client in only ?? _clients.values) {
      if (except?.contains(client) ?? false) continue;
      client.socket.sink.add(encodedMessage);
    }
  }
}
