// FileName: dataconnection.dart

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/logger.dart';
import 'package:peerdart/negotiator.dart';
import 'package:peerdart/enums.dart';
import 'package:peerdart/peer.dart';
import 'package:peerdart/baseconnection.dart';
import 'package:peerdart/servermessage.dart';
import 'package:peerdart/peer_error.dart';
import 'package:peerdart/utils/random_token.dart';

// dynmaic of type DataConnectionErrorType & BaseConnectionErrorType
abstract class DataConnectionEvents<ErrorType extends String>
    extends EventsWithError<ErrorType> {
  void Function(dynamic data)? data;
  void Function()? open;

  DataConnectionEvents({required super.error});
}

abstract class DataConnection<ErrorType> extends BaseConnection {
  static const String idPrefix = "dc_";
  static const int maxBufferedAmount = 8 * 1024 * 1024;

  Negotiator<DataConnectionEvents, DataConnection>? _negotiator;
  // SerializationType
  abstract final String serialization;
  final bool reliable;

  @override
  // ConnectionType
  String get type => ConnectionType.Data.value;

  DataConnection(String peerId, Peer provider, dynamic options)
      : reliable = options.reliable ?? false,
        super(peerId, provider, options) {
    options.reliable = options.reliable;

    connectionId = options.connectionId ?? '$idPrefix${randomToken()}';
    label = options.label ?? connectionId;

    _negotiator = Negotiator(this);

    _negotiator!.startConnection(options.payload?.toJson() ??
        {
          'originator': true,
          'reliable': reliable,
        });
  }

  @override
  Future<void> initializeDataChannel(RTCDataChannel dc) async {
    dataChannel = dc;
    dataChannel?.onDataChannelState = (state) {
      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          logger.log('DC#$connectionId dc connection success');
          open = true;
          emit('open');
          break;
        case RTCDataChannelState.RTCDataChannelClosed:
          logger.log('DC#$connectionId dc closed for: $peer');
          close();
          break;
        default:
          // Handle other states if needed
          break;
      }
    };

    dataChannel?.onMessage = (RTCDataChannelMessage message) {
      logger.log('DC#$connectionId dc onmessage: ${message.text}');
      _handleDataMessage(message.text);
    };
  }

  void _handleDataMessage(dynamic data) {
    emit('data', data);
  }

  @override
  void close({bool flush = false}) {
    if (flush) {
      send({
        '__peerData': {
          'type': 'close',
        },
      });
      return;
    }

    _negotiator?.cleanup();
    _negotiator = null;

    if (provider != null) {
      provider?.removeConnection(this);
      provider = null;
    }

    if (dataChannel != null) {
      dataChannel!.onDataChannelState = null;
      dataChannel!.onMessage = null;
      dataChannel = null;
    }

    if (!open) return;

    open = false;

    emit('close');
  }

  Future<void> privateSend(dynamic data, bool chunked);

  void send(dynamic data, {bool chunked = false}) {
    if (!open) {
      emitError(DataConnectionErrorType.NotOpenYet.value,
          "Connection is not open. You should listen for the `open` event before sending messages.");
      return;
    }
    privateSend(data, chunked);
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    final payload = message.payload;

    if (message.type == ServerMessageType.Answer.value) {
      await _negotiator?.handleSDP(message.type, payload.sdp);
    } else if (message.type == ServerMessageType.Candidate.value) {
      await _negotiator?.handleCandidate(RTCIceCandidate(
          payload.candidate["candidate"],
          payload.candidate["sdpMid"],
          payload.candidate["sdpMLineIndex"]));
    } else {
      logger
          .warn('Unrecognized message type: ${message.type} from peer: $peer');
    }
  }
}
