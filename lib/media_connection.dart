// FileName: media_connection.dart

import 'package:peerdart/baseconnection.dart';
import 'package:peerdart/option_interfaces.dart';
import 'package:peerdart/peer_error.dart';
import 'package:peerdart/servermessage.dart';
import 'package:peerdart/util.dart';
import 'package:peerdart/logger.dart';
import 'package:peerdart/negotiator.dart';
import 'package:peerdart/enums.dart';
import 'package:peerdart/peer.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/utils/random_token.dart';

class MediaConnectionEvents extends EventsWithError<String> {
  void Function(MediaStream)? stream;
  void Function()? willCloseOnRemote;

  MediaConnectionEvents({required super.error});
}

class MediaConnection extends BaseConnection<MediaConnectionEvents, String> {
  static const String ID_PREFIX = "mc_";
  String label = '';

  Negotiator<MediaConnectionEvents, MediaConnection>? negotiator;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  MediaConnection(String peerId, Peer provider, dynamic options)
      : super(peerId, provider, options) {
    _localStream = options['_stream'];
    connectionId = options.connectionId ?? '$ID_PREFIX${randomToken()}';

    negotiator = Negotiator(this);

    if (_localStream != null) {
      negotiator!.startConnection({
        '_stream': _localStream,
        'originator': true,
      });
    }
  }

  @override
  String get type => ConnectionType.Media.value;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  @override
  Future<void> initializeDataChannel(RTCDataChannel dc) async {
    dataChannel = dc;

    dataChannel?.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        logger.log('DC#$connectionId dc connection success');
        emit('willCloseOnRemote');
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        logger.log('DC#$connectionId dc closed for: $peer');
        close();
      }
    };
  }

  void addStream(MediaStream remoteStream) {
    logger.log('Receiving stream $remoteStream');

    _remoteStream = remoteStream;
    emit('stream', remoteStream);
  }

  @override
  Future<void> handleMessage(ServerMessage message) async {
    final type = message.type;
    final payload = message.payload;

    if (type == ServerMessageType.Answer.value) {
      await negotiator!.handleSDP(type, payload.sdp);
      open = true;
    } else if (type == ServerMessageType.Candidate.value) {
      await negotiator!.handleCandidate(payload.candidate);
    } else {
      logger.warn('Unrecognized message type: $type from peer: $peer');
    }
  }

  void answer([MediaStream? stream, AnswerOption? options]) {
    options ??= AnswerOption();
    if (_localStream != null) {
      logger.warn(
          'Local stream already exists on this MediaConnection. Are you answering a call twice?');
      return;
    }

    _localStream = stream!;

    if (options.sdpTransform != null) {
      this.options.sdpTransform = options.sdpTransform;
    }

    negotiator!.startConnection({
      ...options.payload.toMap(),
      '_stream': stream,
    });

    final messages = provider!.getMessages(connectionId);
    for (final message in messages) {
      handleMessage(message);
    }

    open = true;
  }

  @override
  void close() {
    if (negotiator != null) {
      negotiator!.cleanup();
      negotiator = null;
    }

    _localStream = null;
    _remoteStream = null;

    if (provider != null) {
      provider!.removeConnection(this);
      provider = null;
    }

    if (options != null && options._stream != null) {
      options._stream = null;
    }

    if (!open) return;

    open = false;
    emit('close');
  }
}
