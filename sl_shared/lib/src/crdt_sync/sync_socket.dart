// Original: https://github.com/cachapa/crdt_sync

import 'dart:async';

import 'package:crdt/crdt.dart';

typedef Handshake = ({
  String nodeId,
  Hlc lastModified,
  Map<String, dynamic>? data,
});

class SyncSocket {
  final void Function(Map<String, dynamic> data) send;
  final void Function(int? code, String? reason) onDisconnect;
  final void Function(CrdtChangeset changeset) onChangeset;
  final bool verbose;

  final String localNodeId;

  final _handshakeCompleter = Completer<Handshake>();

  /// Begin managing the socket:
  /// 1. Perform handshake.
  /// 2. Monitor for incoming changesets.
  /// 3. Send local changesets on demand.
  /// 4. Disconnect when done.
  SyncSocket(
    this.localNodeId, {
    required this.send,
    required this.onDisconnect,
    required this.onChangeset,
    required this.verbose,
  });

  /// Monitor handshake completion. Useful for establishing connections.
  Future<Handshake> receiveHandshake() => _handshakeCompleter.future;

  /// Send local handshake
  void sendHandshake(String nodeId, Hlc lastModified, Object? data) => send({
    'node_id': nodeId,
    'last_modified': lastModified,
    'data': data,
  });

  /// Send local changeset
  void sendChangeset(CrdtChangeset changeset) => send(changeset..removeWhere((key, value) => value.isEmpty));

  void receive(Map<String, dynamic> message) {
    _log('⬇️ $message');
    if (!_handshakeCompleter.isCompleted) {
      // The first message is a handshake
      _handshakeCompleter.complete((
        nodeId: message['node_id'] as String,
        // Modified timestamps always use the local node id
        lastModified: Hlc.parse(message['last_modified'] as String).apply(nodeId: localNodeId),
        data: message['data'] as Map<String, dynamic>?,
      ));
    } else {
      // Merge into crdt
      final changeset = parseCrdtChangeset(message);
      onChangeset(changeset);
    }
  }

  void close([int? code, String? reason]) {
    onDisconnect(code, reason);
  }

  void _log(String msg) {
    if (verbose) print(msg);
  }
}
