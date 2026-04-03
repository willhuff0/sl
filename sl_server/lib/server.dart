import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:sl_server/systems/assets.dart';
import 'package:sl_server/database/database.dart' as db;
import 'package:sl_server/state_tracker.dart';
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

  Future<void> kickClient(Client client, {int? status, String? reason}) async {
    print('Kicking client ${client.clientId}');

    await client.socket.sink.close(status, reason);
    _clients.remove(client.clientId);

    _sceneSystem.removeClient(client);

    _broadcastClientStates();
  }

  void _onConnection(WebSocketChannel socket, _) {
    final clientId = _nextClientId++;
    final client = Client(
      socket: socket,
      // rpc: RpcPeer(sendCallback: (message) => _sendRpc(clientId, message)),
      state: ClientState(
        clientId: clientId,
        sceneId: null,
        color: _getNextClientColor(),
      ),
    );
    // _registerClientRpcHandlers(client);
    _clients[client.clientId] = client;
    send(client, StcSetSelf(clientId: client.clientId));
    _broadcastClientStates();
    socket.stream.listen((data) => _onData(client, data))
      ..onError((_) => kickClient(client))
      ..onDone(() => kickClient(client));
  }

  // void _registerClientRpcHandlers(Client client) {
  //   _assets.registerRpcHandlers(client);
  // }

  void _onData(Client client, dynamic data) {
    print('From ${client.clientId} server received: $data');

    final json = jsonDecode(data) as Map<String, dynamic>;
    final messageAndHeader = MessageAndHeader.fromJson(json);

    _handleMessage(client, messageAndHeader.messageInstance);
  }

  void _handleMessage(Client client, Message message) {
    switch (message) {
      case CtsStateChanges stateChanges:
        switch (stateChanges.system) {
          case StateTrackerSystem.scene:
            _sceneSystem.stateTracker.handleClientChanges(client, stateChanges);
            break;
          case StateTrackerSystem.asset:
            _assetSystem.stateTracker.handleClientChanges(client, stateChanges);
            break;
        }
        break;
      default:
        if (_sceneSystem.handleMessage(client, message)) break;
        if (_assetSystem.handleMessage(client, message)) break;
        break;
    }
  }

  void _tick() {
    _sceneSystem.tick();
    _assetSystem.tick();
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

  // void _sendRpc(int clientId, dynamic message) {
  //   send(
  //     _clients[clientId]!,
  //     PtpRpc(
  //       message: message,
  //     ),
  //   );
  // }

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
