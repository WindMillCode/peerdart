import 'dart:typed_data';

class BufferBuilder {
  List<int> _pieces;
  List<ByteBuffer> _parts;

  BufferBuilder()
      : _pieces = [],
        _parts = [];

  void appendBuffer(ByteBuffer data) {
    flush();
    _parts.add(data);
  }

  void append(int data) {
    _pieces.add(data);
  }

  void flush() {
    if (_pieces.isNotEmpty) {
      var buf = Uint8List.fromList(_pieces);
      _parts.add(buf.buffer);
      _pieces = [];
    }
  }

  ByteBuffer toArrayBuffer() {
    List<ByteBuffer> buffer = [];
    for (var part in _parts) {
      buffer.add(part);
    }
    return concatArrayBuffers(buffer);
  }

  ByteBuffer concatArrayBuffers(List<ByteBuffer> bufs) {
    int size = 0;
    for (var buf in bufs) {
      size += buf.lengthInBytes;
    }
    var result = Uint8List(size);
    int offset = 0;
    for (var buf in bufs) {
      var view = Uint8List.view(buf);
      result.setAll(offset, view);
      offset += buf.lengthInBytes;
    }
    return result.buffer;
  }
}
