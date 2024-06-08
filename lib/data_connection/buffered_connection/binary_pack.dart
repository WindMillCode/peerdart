import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:windmillcode_peerdart/data_connection/buffered_connection/buffered_connection.dart';
import 'package:windmillcode_peerdart/data_connection/buffered_connection/binary_pack_chunker.dart';
import 'package:windmillcode_peerdart/enums.dart';
import 'package:windmillcode_peerdart/logger.dart';
import 'package:windmillcode_peerdart/peer.dart';
import 'package:windmillcode_peerdart/peerdart-dart-binarypack/binarypack.dart';

class BinaryPack<ErrorType> extends BufferedConnection<ErrorType> {
  final chunker = BinaryPackChunker();
  @override
  final String serialization = SerializationType.Binary.value;

  Map<int, ChunkedData> _chunkedData = {};

  BinaryPack(String peerId, Peer provider, dynamic options) : super(peerId, provider, options);

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
    } catch (err, stack) {
      // Ignore errors in extracting peerData
    }

    if (peerData != null) {
      try {
        if (peerData['type'] == 'close') {
          close();
          return;
        }
      } catch (err, stack) {
        // data or chunk has not finsihed being sent
      }

      // Handle chunked data
      _handleChunk(deserializedData);
      return;
    }

    emit('data', deserializedData);
  }

  void _handleChunk(Map<dynamic, dynamic> data) {
    logger.chunk("chunk data ${data.toString()}");
    final id = data['__peerData'];
    final totalChunks = data['total'];
    final chunkNumber = data['n'];
    final chunkData = data['data'];

    // Initialize storage for chunks if not present
    if (!_chunkedData.containsKey(id)) {
      _chunkedData[id] = ChunkedData(
        data: List<Uint8List>.generate(totalChunks, (_) => Uint8List(0)),
        count: 0,
        total: totalChunks,
      );
    }

    // Store the chunk
    _chunkedData[id]!.data[chunkNumber] = Uint8List.fromList(chunkData);
    _chunkedData[id]!.count++;

    // Check if all chunks are received
    if (_chunkedData[id]!.total == _chunkedData[id]!.count) {
      // Concatenate all chunks to reconstruct the file
      var chunkedDataMap = _chunkedData;
      var targetChunkData = _chunkedData[id];
      final completeData = concatArrayBuffers(_chunkedData[id]!.data);

      // Clean up before making the recursive call to handleDataMessage
      _chunkedData.remove(id);

      // Handle the complete data
      handleDataMessage(RTCDataChannelMessage.fromBinary(completeData));
    }
  }

  @override
  Future<void> privateSend(dynamic data, bool chunked) async {
    final blob = pack(data);

    if (!chunked && blob.lengthInBytes > chunker.chunkedMTU) {
      await _sendChunks(Uint8List.view(blob));
      return;
    }

    bufferedSend(Uint8List.view(blob));
  }

  Future<void> _sendChunks(Uint8List blob) async {
    chunker.chunkedMTU = messageSize;
    final chunks = chunker.chunk(blob);
    logger.chunk('DC#$connectionId Try to send ${chunks.length} chunks...');

    for (final chunk in chunks) {
      logger.chunk('chunk data ${chunk.toString()}');
      await send(chunk, chunked: true);
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