import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/peerdart.dart';
import 'package:peerdart/src/baseconnection.dart';
import 'package:peerdart/src/logger.dart';
import 'package:peerdart/src/negotiator.dart';
import 'package:peerdart/src/servermessage.dart';
import 'package:peerdart/src/util.dart';

class MediaConnection extends BaseConnection {
  MediaConnection(String peerId, Peer provider, PeerConnectOption? options) : super(peerId, provider, options) {
    _localStream = options?.stream;
    connectionId = options?.connectionId ?? _idPrefix + util.randomToken();
    _negotiator = Negotiator(this);
    if (_localStream != null) {
      _negotiator?.startConnection(options!.copyWith(originator: true, stream: _localStream));
    }
  }

  final String _idPrefix = 'mc_';
  late Negotiator? _negotiator;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  void addStream(MediaStream remoteStream) {
    logger.log('Receiving stream $remoteStream');
    _remoteStream = remoteStream;
    emit<MediaStream>('stream', remoteStream);
  }

  @override
  void dispose() {
    _negotiator?.cleanup();
    _negotiator = null;
    _stopMediaDevice();
    _localStream = null;
    _remoteStream = null;
    if (!open) return;
    open = false;
  }

  void _stopMediaDevice() {
    final tracks = _localStream?.getTracks();
    tracks?.forEach((track) async => await track.stop());
  }

  @override
  ConnectionType get type => ConnectionType.Media;

  @override
  void handleMessage(ServerMessage message) {
    final payload = message.payload;
    switch (message.type) {
      case ServerMessageType.Answer:
        _negotiator?.handleSDP(payload["sdp"]["type"], payload["sdp"]);
        open = true;
        break;
      case ServerMessageType.Candidate:
        _negotiator?.handleCandidate(RTCIceCandidate(
            payload["candidate"]["candidate"],
            payload["candidate"]["sdpMid"],
            payload["candidate"]["sdpMLineIndex"]));
        break;
      default:
        logger.warn("Unrecognized message type: ${message.type.type} from peer: $peer");
    }
  }

  void answer(MediaStream stream, {AnswerOption? callOptions}) {
    if (_localStream != null) {
      logger.warn("Local stream already exists on this MediaConnection. Are you answering a call twice?");
      return;
    }
    _localStream = stream;
    final op = PeerConnectOption(
        payload: PeerConnectOption(
            stream: _localStream,
            sdp: options!.payload!.sdp,
            connectionId: options!.payload!.connectionId,
            metadata: options!.payload!.metadata));
    _negotiator?.startConnection(op.payload!);
    final messages = provider?.getMessages(connectionId);
    if (messages != null) {
      for (var message in messages) {
        handleMessage(message);
      }
      open = true;
    }
  }
}
