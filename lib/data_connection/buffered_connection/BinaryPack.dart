import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:peerdart/data_connection/buffered_connection/buffered_connection.dart';
import 'package:peerdart/data_connection/buffered_connection/binary_pack_chunker.dart';
import 'package:peerdart/enums.dart';
import 'package:peerdart/logger.dart';
import 'package:peerdart/peer.dart';
import 'package:peerdart/peerdart-dart-binarypack/binarypack.dart';

class BinaryPack<ErrorType> extends BufferedConnection<ErrorType> {
  final chunker = BinaryPackChunker();
  @override
  final String serialization = SerializationType.Binary.value;

  Map<int, ChunkedData> _chunkedData = {};

  BinaryPack(String peerId, Peer provider, dynamic options)
      : super(peerId, provider, options);

  @override
  void close({bool flush = false}) {
    super.close(flush: flush);
    _chunkedData = {};
  }

  @override
  void handleDataMessage(RTCDataChannelMessage message) {
    final byteBuffer = message.binary.buffer;
    final deserializedData = unpack(byteBuffer);

    // PeerJS specific message
    final peerData = deserializedData['__peerData'];
    if (peerData != null) {
      if (peerData['type'] == 'close') {
        close();
        return;
      }

      // Chunked data -- piece things back together.
      _handleChunk(deserializedData);
      return;
    }

    emit('data', deserializedData);
  }

  void _handleChunk(Map<String, dynamic> data) {
    final id = data['__peerData'];
    final chunkInfo = _chunkedData[id] ??
        ChunkedData(
          data: [],
          count: 0,
          total: data['total'],
        );

    chunkInfo.data[data['n']] = Uint8List.view(data['data'].buffer);
    chunkInfo.count++;
    _chunkedData[id] = chunkInfo;

    if (chunkInfo.total == chunkInfo.count) {
      // Clean up before making the recursive call to `handleDataMessage`.
      _chunkedData.remove(id);

      // We've received all the chunks--time to construct the complete data.
      final completeData = concatArrayBuffers(chunkInfo.data);
      handleDataMessage(RTCDataChannelMessage.fromBinary(completeData));
    }
  }

  @override
  void send(dynamic data, {bool chunked=false}) async {
    final blob = await pack(data);
    if (blob.lengthInBytes > chunker.chunkedMTU) {
      _sendChunks(blob);
      return;
    }

    bufferedSend(Uint8List.view(blob));
  }

  void _sendChunks(ByteBuffer blob) {
    final chunks = chunker.chunk(Uint8List.view(blob));
    logger.log('DC#$connectionId Try to send ${chunks.length} chunks...');

    for (final chunk in chunks) {
      send(chunk, chunked: true);
    }
  }
}

class ChunkedData {
  List<Uint8List> data;
  int count;
  int total;

  ChunkedData({
    required this.data,
    required this.count,
    required this.total,
  });
}
