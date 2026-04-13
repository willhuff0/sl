import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:sl_editor/client/file_system.dart';
import 'package:sl_editor/client/systems/asset_system_old.dart';
import 'package:sl_editor/client/systems/scene_system.dart';
import 'package:sl_editor/client/view_manager.dart';
import 'package:sl_engine/logger.dart';
import 'package:sl_shared/sl_shared.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const tickInterval = Duration(milliseconds: 1000);

class Client {
  final WebSocketChannel _socket;
  final SqliteCrdt _database;
  late final ClientId _clientId;

  final _onClientStatesChangedController = StreamController<UnmodifiableMapView<int, ClientState>>.broadcast();
  late final Stream<UnmodifiableMapView<int, ClientState>> onClientStatesChanged;
  Map<int, ClientState> _clientStates = {};

  late final SceneSystem sceneSystem;
  late final AssetSystem assetSystem;

  late final StreamSubscription _listenSubscription;
  late final Timer _tickTimer;

  static Future<Client> connect({
    required Uri serverUri,
  }) async {
    await SlFileSystem.init('test-room');
    final database = await openDatabase('test-room/db.sqlite3');
    final socket = WebSocketChannel.connect(serverUri);
    await socket.ready;
    return Client._(socket: socket, database: database);
  }

  static late Client _instance;
  static Client get() {
    return _instance;
  }

  Client._({
    required WebSocketChannel socket,
    required SqliteCrdt database,
  }) : _socket = socket,
       _database = database {
    _tickTimer = Timer.periodic(tickInterval, (_) => _tick());
    onClientStatesChanged = _onClientStatesChangedController.stream;

    sceneSystem = SceneSystem(this);
    assetSystem = AssetSystem(this, _database);

    ViewManager.init();

    _instance = this;
    _listen();
  }

  void dispose() {
    _listenSubscription.cancel();
    _socket.sink.close();
    _tickTimer.cancel();
    assetSystem.dispose();
  }

  void _listen() async {
    await for (final data in _socket.stream) {
      await _onData(data);
    }
  }

  Future<void> _onData(dynamic data) async {
    if (data is Uint8List) {
      print('Client received ${data.length} bytes');
    } else {
      print('Client received: $data');
    }

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
      case StcSetClientGlobalStates setClientGlobalStates:
        _clientStates = setClientGlobalStates.states;
        if (!_clientStates.containsKey(_clientId)) {
          Logger.log('Leaving because StcSetClientGlobalStates did not contain an entry for this client.', .info);
          _leave();
          return;
        }
        _onClientStatesChangedController.add(UnmodifiableMapView(_clientStates));
        break;
      case StcLocalChangeDecisions localChangeDecisions:
        switch (localChangeDecisions.system) {
          case StateTrackerSystem.scene:
            sceneSystem.stateTracker.handleChangeDecisions(localChangeDecisions);
            break;
          case StateTrackerSystem.asset:
            // _assetSystem.stateTracker.handleChangeDecisions(localChangeDecisions);
            break;
        }
        break;
      case StcRemoteChanges remoteChanges:
        switch (remoteChanges.system) {
          case StateTrackerSystem.scene:
            sceneSystem.stateTracker.handleRemoteChanges(remoteChanges);
            break;
          case StateTrackerSystem.asset:
            // _assetSystem.stateTracker.handleRemoteChanges(remoteChanges);
            break;
        }
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
