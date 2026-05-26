import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;
import 'package:sl_server/assets/asset_system.dart';
import 'package:sl_server/client.dart';
import 'package:sl_server/globals.dart';
import 'package:sl_server/path_provider.dart';
import 'package:sl_server/scenes/scene_system.dart';
import 'package:sl_server/web_socket_handler.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

class Server {
  final String projectId;

  final PathProvider pathProvider;
  final SqliteCrdt _database;

  late final WebSocketHandler _webSocketHandler;

  late final SceneSystem _sceneSystem;
  late final AssetSystem _assetSystem;

  final Map<int, Client> _clients = {};

  var _nextClientId = 0;
  var _availableColors = List.from(_colors);

  late final Timer _tickTimer;

  Server._(this.projectId, this.pathProvider, this._database) {
    _webSocketHandler = WebSocketHandler(_onConnection, null, null, Duration(seconds: 20));

    _sceneSystem = SceneSystem(this);
    _assetSystem = AssetSystem(this, _database);

    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
  }

  static Future<Server> openProject(String projectId, String rootPath) async {
    final absoluteRootPath = Directory(rootPath).absolute.path;
    await Directory(absoluteRootPath).create(recursive: true);

    final pathProvider = RootedPathProvider(rootPath: absoluteRootPath);
    final database = await openDatabase(pathProvider.getDatabasePath());

    return Server._(projectId, pathProvider, database);
  }

  static Future<Set<UUID>> _getAllAssetUuids(String absoluteRootPath) async {
    final pathProvider = RootedPathProvider(rootPath: absoluteRootPath);
    final database = await openDatabase(pathProvider.getDatabasePath());
    try {
      return await getAllAssetUuids(database);
    } finally {
      await database.close();
    }
  }

  // Clones the database to and places all new assets in a temp directory
  static Future<Server> openProjectNoMutate(String projectId, String rootPath) async {
    final absoluteRootPath = Directory(rootPath).absolute.path;
    await Directory(absoluteRootPath).create(recursive: true);

    final persistentUuids = await _getAllAssetUuids(absoluteRootPath);

    final pathProvider = MixedTempPathProvider(
      rootPath: absoluteRootPath,
      persistentUuids: persistentUuids,
    );
    await pathProvider.clearTemp();

    await File(pathProvider.getTempDatabasePath()).parent.create(recursive: true);
    await File(pathProvider.getPersistentDatabasePath()).copy(pathProvider.getTempDatabasePath());
    final database = await openDatabase(pathProvider.getDatabasePath());

    return Server._(projectId, pathProvider, database);
  }

  Future<void> dispose() async {
    _tickTimer.cancel();
    await _sceneSystem.dispose();
    await _database.close();
    await pathProvider.dispose();
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

  Future<void> addClient(Client client) async {
    _clients[client.clientId] = client;

    send(client, StcSetSelf(clientId: client.clientId));
    _broadcastClientStates();

    await _assetSystem.addClient(client);
  }

  Future<void> removeClient(Client client, {int? status, String? reason}) async {
    if (_clients.remove(client.clientId) == null || client.isClosed) return;
    print('Removing client ${client.clientId}');

    await client.close(status, reason);

    await _sceneSystem.removeClient(client);
    await _assetSystem.removeClient(client);

    if (_clients.isEmpty) {
      await ServerGlobalState.closeRoom(projectId);
      return;
    }

    _broadcastClientStates();

    try {
      await for (final data in client.stream) {
        await _onData(client, data);
      }
    } catch (e) {
      print('Error occurred while handling message for client ${client.clientId}: $e');
      await removeClient(client);
    }
    await removeClient(client);
  }

  ClientState _getNewClientState({String? name}) {
    final clientId = _nextClientId++;
    return ClientState(
      clientId: clientId,
      name: name ?? 'Anonymous $clientId',
      sceneId: null,
      color: _getNextClientColor(),
    );
  }

  Future<VirtualClient> addVirtualClient(String name) async {
    final client = VirtualClient(state: _getNewClientState(name: name));
    await addClient(client);
    return client;
  }

  void _onConnection(WebSocketChannel socket, _) async {
    final client = HumanClient(
      socket: socket,
      state: _getNewClientState(),
    );

    await addClient(client);
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
      StcSetGlobalState(
        clients: _clients.map(
          (clientId, client) => MapEntry(
            clientId,
            ClientState(
              clientId: clientId,
              name: client.name,
              sceneId: client.sceneId,
              color: client.color,
            ),
          ),
        ),
      ),
    );
  }

  void sendBinary(Client client, Uint8List bytes) {
    client.send(bytes);
  }

  void send(Client client, Message message) {
    client.send(
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
      client.send(encodedMessage);
    }
  }
}
