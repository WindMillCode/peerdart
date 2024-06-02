import 'package:peerdart/logger.dart';
import 'package:peerdart/media_connection.dart';
import 'package:peerdart/data_connection/data_connection.dart';
import 'package:peerdart/enums.dart';
import 'package:peerdart/baseconnection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/utils/nodejs_adaptations.dart';

class Negotiator<Events extends ValidEventTypes,
    CT extends BaseConnection<dynamic /*Events */, String>> {
  final CT connection;

  Negotiator(this.connection);

  /// Returns a PeerConnection object set up correctly (for data, media).
  void startConnection(dynamic options) async {
    final peerConnection = await _startPeerConnection();

    // Set the connection's PC.
    connection.peerConnection = peerConnection;

    if (connection.type == ConnectionType.Media.value &&
        options['_stream'] != null) {
      _addTracksToConnection(options['_stream'], peerConnection);
    }

    // What do we need to do now?
    if (options['originator']) {
      final dataConnection = connection as DataConnection;

      final config = RTCDataChannelInit()
        ..ordered = options['reliable'] ?? false;

      final dataChannel = await peerConnection.createDataChannel(
        dataConnection.label,
        config,
      );
      dataConnection.initializeDataChannel(dataChannel);

      _makeOffer();
    } else {
      handleSDP('OFFER', options['sdp']);
    }
  }

  /// Start a PC.
  Future<RTCPeerConnection> _startPeerConnection() async {
    logger.log('Creating RTCPeerConnection.');

    final peerConnection =
        await createPeerConnection(connection.provider!.options.config);

    _setupListeners(peerConnection);

    return peerConnection;
  }

  /// Set up various WebRTC listeners.
  void _setupListeners(RTCPeerConnection peerConnection) {
    final peerId = connection.peer;
    final connectionId = connection.connectionId;
    final connectionType = connection.type;
    final provider = connection.provider;

    // ICE CANDIDATES.
    logger.log('Listening for ICE candidates.');

    peerConnection.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null || candidate.candidate == null) return;

      logger.log('Received ICE candidates for $peerId: ${candidate.toMap()}');

      provider?.socket.send({
        'type': ServerMessageType.Candidate.value,
        'payload': {
          'candidate': candidate.toMap(),
          'type': connectionType,
          'connectionId': connectionId,
        },
        'dst': peerId,
      });
    };

    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          logger.log(
              'iceConnectionState is failed, closing connections to $peerId');
          connection.emitError(BaseConnectionErrorType.NegotiationFailed.value,
              'Negotiation of connection to $peerId failed.');
          connection.close();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          logger.log(
              'iceConnectionState is closed, closing connections to $peerId');
          connection.emitError(BaseConnectionErrorType.ConnectionClosed.value,
              'Connection to $peerId closed.');
          connection.close();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          logger.log(
              'iceConnectionState changed to disconnected on the connection with $peerId');
          break;
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          peerConnection.onIceCandidate = null;
          break;
        default:
          break;
      }

      connection.emit('iceStateChanged', state.toString());
    };

    // DATACONNECTION.
    logger.log('Listening for data channel');
    // Fired between offer and answer, so options should already be saved in the options hash.
    peerConnection.onDataChannel = (RTCDataChannel event) {
      logger.log('Received data channel');

      final dataChannel = event;
      final connection =
          provider!.getConnection(peerId, connectionId) as DataConnection;

      connection.initializeDataChannel(dataChannel);
    };

    // MEDIACONNECTION.
    logger.log('Listening for remote stream');

    peerConnection.onTrack = (RTCTrackEvent event) {
      logger.log('Received remote stream');

      final stream = event.streams[0];
      final connection = provider!.getConnection(peerId, connectionId);

      if (connection!.type == ConnectionType.Media.value) {
        final mediaConnection = connection as MediaConnection;
        _addStreamToMediaConnection(stream, mediaConnection);
      }
    };
  }

  void cleanup() {
    logger.log('Cleaning up PeerConnection to ${connection.peer}');

    final peerConnection = connection.peerConnection;

    if (peerConnection == null) {
      return;
    }

    connection.peerConnection = null;

    // unsubscribe from all PeerConnection's events
    peerConnection.onIceCandidate = null;
    peerConnection.onIceConnectionState = null;
    peerConnection.onDataChannel = null;
    peerConnection.onTrack = null;

    final peerConnectionNotClosed = peerConnection.signalingState !=
        RTCSignalingState.RTCSignalingStateClosed;
    bool dataChannelNotClosed = false;

    final dataChannel = connection.dataChannel;

    if (dataChannel != null) {
      dataChannelNotClosed =
          dataChannel.state != RTCDataChannelState.RTCDataChannelClosed;
    }

    if (peerConnectionNotClosed || dataChannelNotClosed) {
      peerConnection.close();
    }
  }

  Future<void> _makeOffer() async {
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      final offer =
          await peerConnection!.createOffer(connection.options.constraints);

      logger.log('Created offer.');

      if (connection.options.sdpTransform != null &&
          connection.options.sdpTransform is Function) {
        offer.sdp = connection.options.sdpTransform(offer.sdp) ?? offer.sdp;
      }

      try {
        await peerConnection.setLocalDescription(offer);

        logger.log('Set localDescription: $offer for:${connection.peer}');

        var payload = {
          'sdp': offer,
          'type': connection.type,
          'connectionId': connection.connectionId,
          'metadata': connection.metadata,
        };

        if (connection.type == ConnectionType.Data.value) {
          final dataConnection = connection as DataConnection;

          payload.addAll({
            'label': dataConnection.label,
            'reliable': dataConnection.reliable,
            'serialization': dataConnection.serialization,
          });
        }

        provider!.socket.send({
          'type': ServerMessageType.Offer.value,
          'payload': payload,
          'dst': connection.peer,
        });
      } catch (err) {
        if (err !=
            'OperationError: Failed to set local offer sdp: Called in wrong state: kHaveRemoteOffer') {
          provider!.emitError(PeerErrorType.WebRTC.value, err);
          logger.log('Failed to setLocalDescription, $err');
        }
      }
    } catch (err,stack) {
    provider!.emitError(PeerErrorType.WebRTC.value, err);
      logger.log('Failed to createOffer, $err');
    }
  }

  Future<void> _makeAnswer() async {
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      final answer = await peerConnection!.createAnswer();
      logger.log('Created answer.');

      if (connection.options.sdpTransform != null &&
          connection.options.sdpTransform is Function) {
        answer.sdp = connection.options.sdpTransform(answer.sdp) ?? answer.sdp;
      }

      try {
        await peerConnection.setLocalDescription(answer);

        logger.log('Set localDescription: $answer for:${connection.peer}');

        provider!.socket.send({
          'type': ServerMessageType.Answer.value,
          'payload': {
            'sdp': answer,
            'type': connection.type,
            'connectionId': connection.connectionId,
          },
          'dst': connection.peer,
        });
      } catch (err) {
        provider!.emitError(PeerErrorType.WebRTC.value, err);
        logger.log('Failed to setLocalDescription, $err');
      }
    } catch (err) {
      provider!.emitError(PeerErrorType.WebRTC.value, err);
      logger.log('Failed to create answer, $err');
    }
  }

  /// Handle an SDP.
  Future<void> handleSDP(String type, dynamic sdp) async {
    sdp = RTCSessionDescription(sdp['sdp'], type);
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    logger.log('Setting remote description $sdp');

    try {
      await peerConnection!.setRemoteDescription(sdp);
      logger.log('Set remoteDescription:$type for:${connection.peer}');
      if (type == 'OFFER') {
        await _makeAnswer();
      }
    } catch (err) {
      provider!.emitError(PeerErrorType.WebRTC.value, err);
      logger.log('Failed to setRemoteDescription, $err');
    }
  }

  /// Handle a candidate.
  Future<void> handleCandidate(RTCIceCandidate ice) async {
    logger.log('handleCandidate: ${ice.toMap()}');

    try {
      await connection.peerConnection!.addCandidate(ice);
      logger.log('Added ICE candidate for:${connection.peer}');
    } catch (err) {
      connection.provider!.emitError(PeerErrorType.WebRTC.value, err);
      logger.log('Failed to handleCandidate, $err');
    }
  }

  void _addTracksToConnection(
      MediaStream stream, RTCPeerConnection peerConnection) {
    logger.log('add tracks from stream ${stream.id} to peer connection');

    stream.getTracks().forEach((track) {
      peerConnection.addTrack(track, stream);
    });
  }

  void _addStreamToMediaConnection(
      MediaStream stream, MediaConnection mediaConnection) {
    logger.log(
        'add stream ${stream.id} to media connection ${mediaConnection.connectionId}');

    mediaConnection.addStream(stream);
  }
}
