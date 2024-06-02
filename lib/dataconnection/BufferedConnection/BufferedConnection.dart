import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/dataconnection/dataconnection.dart';
import 'package:peerdart/logger.dart';

abstract class BufferedConnection extends DataConnection {
  List<Uint8List> _buffer = [];
  int _bufferSize = 0;
  bool _buffering = false;

  BufferedConnection(super.peerId, super.provider, super.options);

  int get bufferSize => _bufferSize;

  @override
  Future<void> initializeDataChannel(RTCDataChannel dc) async {
    super.initializeDataChannel(dc);
    dataChannel = dc;
    dataChannel?.onMessage = (RTCDataChannelMessage message) {
      if (message.isBinary) {
        _handleDataMessage(message);
      } else {
        _handleDataMessage(message);
      }
    };
  }

  void _handleDataMessage(RTCDataChannelMessage message) {
    super.emit('data', message);
  }

  void bufferedSend(Uint8List msg) {
    if (_buffering || !_trySend(msg)) {
      _buffer.add(msg);
      _bufferSize = _buffer.length;
    }
  }

  bool _trySend(Uint8List msg) {
    if (!open) {
      return false;
    }

    if ((dataChannel?.bufferedAmount ?? 0) > DataConnection.maxBufferedAmount) {
      _buffering = true;
      Future.delayed(const Duration(milliseconds: 50), () {
        _buffering = false;
        _tryBuffer();
      });
      return false;
    }

    try {
      dataChannel?.send(RTCDataChannelMessage.fromBinary(msg));
    } catch (e) {
      logger.error('DC#$connectionId Error when sending: $e');
      _buffering = true;
      close();
      return false;
    }

    return true;
  }

  void _tryBuffer() {
    if (!open) {
      return;
    }

    if (_buffer.isEmpty) {
      return;
    }

    Uint8List msg = _buffer[0];
    if (_trySend(msg)) {
      _buffer.removeAt(0);
      _bufferSize = _buffer.length;
      _tryBuffer();
    }
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
    _buffer.clear();
    _bufferSize = 0;
    super.close();
  }
}
