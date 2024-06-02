import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/logger.dart';
import 'package:peerdart/peer.dart';
import 'package:peerdart/data_connection/data_connection.dart';

abstract class StreamConnection extends DataConnection {
  final int chunkSize = 1024 * 8 * 4;

  // StreamController for handling data sending
  final _sendController = StreamController<Uint8List>();

  // StreamController for handling data receiving
  final _receiveController = StreamController<Uint8List>();

  StreamConnection(String peerId, Peer provider, dynamic options)
      : super(peerId, provider, {...options, 'reliable': true}) {
    // Listen to the send stream and process the chunks
    _sendController.stream.transform(_chunkTransformer()).listen((chunk) {
      _sendChunk(chunk);
    });

    // Listen to the receive stream and process the messages
    _receiveController.stream.listen((message) {
      emit('data', message);
    });
  }

  // StreamTransformer to handle chunking
  StreamTransformer<Uint8List, Uint8List> _chunkTransformer() {
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        for (int split = 0; split < data.length; split += chunkSize) {
          sink.add(data.sublist(split, split + chunkSize));
        }
      },
    );
  }

  // Method to send chunks through the data channel
  Future<void> _sendChunk(Uint8List chunk) async {
    final completer = Completer<void>();
    dataChannel?.onBufferedAmountLow = (int remaining) {
      if (!completer.isCompleted) completer.complete();
    };

    if ((dataChannel?.bufferedAmount ?? 0) >
        DataConnection.maxBufferedAmount - chunk.length) {
      await completer.future;
    }

    try {
      dataChannel?.send(RTCDataChannelMessage.fromBinary(chunk));
    } catch (e) {
      logger.error('DC#$connectionId Error when sending: $e');
      close();
    }
  }

  // Method to handle incoming messages from the data channel
  void _handleMessage(RTCDataChannelMessage message) {
    if (message.isBinary) {
      _receiveController.add(message.binary);
    } else {
      _receiveController.add(Uint8List.fromList(message.text.codeUnits));
    }
  }

  @override
  Future<void> initializeDataChannel(RTCDataChannel dc) async {
    super.initializeDataChannel(dc);
    dataChannel = dc;
    dataChannel?.bufferedAmountLowThreshold =
        DataConnection.maxBufferedAmount ~/ 2;
    dataChannel?.onMessage = _handleMessage;
  }

  // Method to send data
  void sendData(Uint8List data) {
    _sendController.add(data);
  }

  @override
  void close({bool flush = false}) {
    _sendController.close();
    _receiveController.close();
    super.close();
  }
}
