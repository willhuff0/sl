// Original: https://github.com/cachapa/crdt_sync

import 'dart:async';

import 'package:crdt/crdt.dart';

import 'crdt_sync.dart';

const defaultPingInterval = Duration(seconds: 20);

typedef ServerOnConnect = void Function(CrdtSync crdtSync, Object? customData);

/// Upgrades an incoming connection to a WebSocket and synchronizes the provided
/// [crdt].
///
/// [pingInterval] defines the WebSocket heartbeat frequency and allows the
/// server to identify and release stale connections. This is highly
/// recommended since stale connections keep database subscriptions which
/// cause queries to be run on every change.
/// Defaults to 20 seconds, set to [null] to disable.
///
Future<CrdtSync> upgrade(
  Crdt crdt, {
  required void Function(Map<String, dynamic> data) send,
  Duration? pingInterval = defaultPingInterval,
  ServerHandshakeDataBuilder? handshakeDataBuilder,
  ChangesetBuilder? changesetBuilder,
  RecordValidator? validateRecord,
  ChangesetMapper? mapIncomingChangeset,
  ServerOnConnect? onConnect,
  OnDisconnect? onDisconnect,
  OnChangeset? onChangesetReceived,
  OnChangeset? onChangesetSent,
  bool verbose = false,
}) async {
  late final CrdtSync crdtSync;
  return crdtSync = CrdtSync.server(
    crdt,
    send: send,
    handshakeDataBuilder: handshakeDataBuilder,
    changesetBuilder: changesetBuilder,
    validateRecord: validateRecord,
    mapIncomingChangeset: mapIncomingChangeset,
    onConnect: (_, customData) => onConnect?.call(crdtSync, customData),
    onDisconnect: onDisconnect,
    onChangesetReceived: onChangesetReceived,
    onChangesetSent: onChangesetSent,
    verbose: verbose,
  );
}
