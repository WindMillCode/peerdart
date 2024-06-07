import 'dart:typed_data';

class BinaryPackChunker {
  // final int chunkedMTU = 16384;
  int chunkedMTU = 8192;
  // final int chunkedMTU = 4096;

  // Binary stuff

  int _dataCount = 1;

  List<Map<String, dynamic>> chunk(Uint8List blob) {
    List<Map<String, dynamic>> chunks = [];
    int size = blob.length;
    int total = (size / chunkedMTU).ceil();

    int index = 0;
    int start = 0;

    while (start < size) {
      int end = (start + chunkedMTU).clamp(0, size);
      Uint8List b = blob.sublist(start, end);

      var chunk = {
        '__peerData': _dataCount,
        'n': index,
        'data': b,
        'total': total,
      };

      chunks.add(chunk);

      start = end;
      index++;
    }

    _dataCount++;

    return chunks;
  }
}

Uint8List concatArrayBuffers(List<Uint8List> bufs) {
  int size = 0;
  for (var buf in bufs) {
    size += buf.length;
  }
  Uint8List result = Uint8List(size);
  int offset = 0;
  for (var buf in bufs) {
    result.setRange(offset, offset + buf.length, buf);
    offset += buf.length;
  }
  return result;
}
