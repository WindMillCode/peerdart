// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:events_emitter/events_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/enums.dart';
import 'package:peerdart/peer.dart';
import 'package:peerdart/servermessage.dart';
import 'package:peerdart/utils/nodejs_adaptations.dart';

import 'peerError.dart';

abstract class BaseConnectionEvents<ErrorType extends String>
    extends EventsWithError<ErrorType> {
  void Function()? close;
  void Function(RTCIceConnectionState)? iceStateChanged;

  BaseConnectionEvents({required super.error});
}

abstract class BaseConnection<SubClassEvents extends EventsWithError<ErrorType>,
        ErrorType extends String >
    extends EventEmitterWithError<ErrorType, SubClassEvents> {
  BaseConnection(this.peer, this.provider, this.options) {
    metadata = options.metadata;
  }

  bool _open = false;

  /// Any type of metadata associated with the connection,
  /// passed in by whoever initiated the connection.
  dynamic metadata;
  late String connectionId;
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;

  late String label;

  bool get open => _open;
  set open(bool value) {
    _open = value;
  }

  Peer? provider;
  final dynamic options;
  final String peer;

  // ConnectionType
  String get type;

  void close();

  void handleMessage(ServerMessage message);

  Future<void> initializeDataChannel(RTCDataChannel dc);
}
