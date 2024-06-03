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
    final deserializedData = unpack(message.binary);
    // PeerJS specific message
    dynamic peerData;
    try {
      peerData = deserializedData['__peerData'];
    } catch (err) {
      // Ignore errors in extracting peerData
    }

    if (peerData != null) {
      try {
        if (peerData['type'] == 'close') {
          close();
          return;
        }
      } catch (err) {
        // data or chunk has not finsihed being sent
      }

      // Handle chunked data
      _handleChunk(deserializedData);
      return;
    }

    emit('data', deserializedData);
  }

  void _handleChunk(Map<dynamic, dynamic> data) {

    final id = data['__peerData'];
    final totalChunks = data['total'];
    final chunkNumber = data['number'];
    final chunkData = data['data'];
    logger.log("chunk data ${chunkData.toString()}");

    // Initialize storage for chunks if not present
    if (!_chunkedData.containsKey(id)) {
      _chunkedData[id] = ChunkedData(
        data:
            List<Uint8List>.filled(totalChunks, Uint8List(0), growable: false),
        count: 0,
        total: totalChunks,
      );
    }

    // Store the chunk
    _chunkedData[id]!.data[chunkNumber] = Uint8List.view(chunkData.buffer);
    _chunkedData[id]!.count++;

    // Check if all chunks are received
    if (_chunkedData[id]!.total == _chunkedData[id]!.count) {
      // Concatenate all chunks to reconstruct the file
      final completeData = concatArrayBuffers(_chunkedData[id]!.data);

      // Clean up before making the recursive call to handleDataMessage
      _chunkedData.remove(id);

      // Handle the complete data
      handleDataMessage(RTCDataChannelMessage.fromBinary(completeData));
    }
  }

  @override
  Future<void> privateSend(dynamic data, bool chunked) async {
    final blob = await pack(data);
    if (blob.lengthInBytes > chunker.chunkedMTU) {
      _sendChunks(Uint8List.view(blob));
      return;
    }

    bufferedSend(Uint8List.view(blob));
  }

  void _sendChunks(Uint8List blob) {
    final chunks = chunker.chunk(blob);
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
