import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;
import 'package:sl_server/assets/asset_system.dart';
import 'package:sl_server/scenes/scene_system.dart';
import 'package:sl_server/web_socket_handler.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

const tickInterval = Duration(milliseconds: 400);

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
  final SqliteCrdt _database;

  late final WebSocketHandler _webSocketHandler;

  late final SceneSystem _sceneSystem;
  late final AssetSystem _assetSystem;

  final Map<int, Client> _clients = {};

  var _nextClientId = 0;
  var _availableColors = List.from(_colors);

  late final Timer _tickTimer;

  Server._(this.rootPath, this._database) {
    _webSocketHandler = WebSocketHandler(_onConnection, null, null, Duration(seconds: 20));

    _sceneSystem = SceneSystem(this);
    _assetSystem = AssetSystem(this, _database);

    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
  }

  static Future<Server> create(String rootPath) async {
    final absoluteRootPath = Directory(rootPath).absolute.path;
    await Directory(absoluteRootPath).create(recursive: true);
    return Server._(absoluteRootPath, await openDatabase(p.join(absoluteRootPath, 'db.sqlite3')));
  }

  Future<void> dispose() async {
    _tickTimer.cancel();
    await _sceneSystem.dispose();
    await _database.close();
  }

  WebSocketHandler getWebSocketHandler() {
    return _webSocketHandler;
  }

  Future<shelf.Response> handleGetThumb(shelf.Request req) {
    return _assetSystem.handleGetThumb(req);
  }

  Future<shelf.Response> handlePostThumb(shelf.Request req) {
    return _assetSystem.handlePostThumb(req);
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

    await _assetSystem.addClient(client);

    try {
      await for (final data in socket.stream) {
        await _onData(client, data);
      }
    } catch (e) {
      print('Error occurred while handling message for client ${client.clientId}: $e');
      await removeClient(client);
    }
    await removeClient(client);
  }

  Future<void> _onData(Client client, dynamic data) async {
    // if (data is Uint8List) {
    //   print('From ${client.clientId} server received ${data.length} bytes');
    // } else {
    //   print('From ${client.clientId} server received: $data');
    // }

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
      default:
        if (await _sceneSystem.handleMessage(client, message)) break;
        if (await _assetSystem.handleMessage(client, message)) break;
        print('Server has no handler for message with class ${message.messageClass}');
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

  void sendBinary(Client client, Uint8List bytes) {
    client.socket.sink.add(bytes);
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
