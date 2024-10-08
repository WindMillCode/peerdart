import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:windmillcode_peerdart/data_connection/data_connection.dart';
import 'package:windmillcode_peerdart/logger.dart';

abstract class BufferedConnection<ErrorType> extends DataConnection<ErrorType> {
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
      handleDataMessage(message);
    };
  }

  void handleDataMessage(RTCDataChannelMessage message) {
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

    // logger.chunk("Current Buffer ${dataChannel!.bufferedAmount}");
    // logger.chunk("Max Buffer ${DataConnection.MAX_BUFFERED_AMOUNT}");
    // logger.chunk("Percent of max ${dataChannel!.bufferedAmount! / DataConnection.MAX_BUFFERED_AMOUNT}");

    if ((dataChannel?.bufferedAmount ?? 0) > (DataConnection.MAX_BUFFERED_AMOUNT * .8)) {
      _buffering = true;
      Future.delayed(const Duration(milliseconds: 50), () {
        _buffering = false;
        _tryBuffer();
      });
      return false;
    }

    try {
      dynamic message = RTCDataChannelMessage.fromBinary(msg);
      dataChannel?.send(message);
      message = null;
    } catch (err, stack) {
      logger.error('DC#$connectionId Error when sending: $err');
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
