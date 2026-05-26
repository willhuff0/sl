import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sl_editor/client/assets/asset_system.dart';
import 'package:sl_editor/client/scenes/scene_system.dart';
import 'package:sl_editor/client/view_manager.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const tickInterval = Duration(milliseconds: 400);

class Client {
  final String projectId;
  final Uri serverUri;

  late final WebSocketChannel _socket;
  late final ClientId _clientId;

  final _onClientStatesChangedController = StreamController<UnmodifiableMapView<int, ClientState>>.broadcast();
  late final Stream<UnmodifiableMapView<int, ClientState>> onClientStatesChanged;
  Map<int, ClientState> _clientStates = {};

  late final SceneSystem sceneSystem;
  late final AssetSystem assetSystem;

  late final StreamSubscription _listenSubscription;
  late final Timer _tickTimer;

  static Future<Client> connect({
    required String projectId,
    required Uri serverUri,
    void Function()? onDisconnected,
    void Function()? onFailedToConnect,
  }) async {
    final sharedDatabase = await openDatabaseInMemory(); // await openDatabase(p.join(projectId, 'db.sqlite3'));
    final socket = WebSocketChannel.connect(
      serverUri.replace(
        scheme: kReleaseMode ? 'wss' : 'ws',
        path: '/rooms/join',
        queryParameters: {
          'project': projectId,
        },
      ),
    );
    final client = Client._(
      projectId: projectId,
      serverUri: serverUri,
      socket: socket,
    );
    client.assetSystem = await AssetSystem.create(client, sharedDatabase, projectId);
    await socket.ready;
    unawaited(client._listen().then((_) => onDisconnected?.call()));
    return client;
  }

  static late Client _instance;
  static Client get() {
    return _instance;
  }

  Client._({
    required this.projectId,
    required this.serverUri,
    required WebSocketChannel socket,
  }) : _socket = socket {
    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
    onClientStatesChanged = _onClientStatesChangedController.stream;

    sceneSystem = SceneSystem(this);

    ViewManager.init();

    _instance = this;
  }

  void dispose() {
    _listenSubscription.cancel();
    _socket.sink.close();
    _tickTimer.cancel();
  }

  Future<void> _listen() async {
    await for (final data in _socket.stream) {
      await _onData(data);
    }
  }

  Future<void> _onData(dynamic data) async {
    // if (data is Uint8List) {
    //   print('Client received ${data.length} bytes');
    // } else {
    //   print('Client received: $data');
    // }

    if (_socket.closeCode != null) return;

    switch (data) {
      case String string:
        final json = jsonDecode(string) as Map<String, dynamic>;
        final messageAndHeader = MessageAndHeader.fromJson(json);
        await _handleMessage(messageAndHeader.messageInstance);
        break;
      case Uint8List bytes:
        await assetSystem.handleBinary(bytes);
        break;
    }
  }

  Future<void> _handleMessage(Message message) async {
    switch (message) {
      case StcSetSelf setSelf:
        _clientId = setSelf.clientId;
        break;
      case StcSetGlobalState setClientGlobalStates:
        _clientStates = setClientGlobalStates.clients;
        if (!_clientStates.containsKey(_clientId)) {
          Logger.log('Leaving because StcSetClientGlobalStates did not contain an entry for this client.', .info);
          await _leave();
          return;
        }
        _onClientStatesChangedController.add(UnmodifiableMapView(_clientStates));
        break;
      default:
        if (await sceneSystem.handleMessage(message)) break;
        if (await assetSystem.handleMessage(message)) break;
        print('Client has no handler for message with class ${message.messageClass}');
        break;
    }
  }

  void _tick() {
    sceneSystem.tick();
  }

  Future<void> _leave() async {
    await _socket.sink.close();
  }

  void sendBinary(Uint8List bytes) {
    _socket.sink.add(bytes);
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
