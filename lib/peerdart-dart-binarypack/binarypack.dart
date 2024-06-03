import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:msgpack_dart/msgpack_dart.dart';

typedef Packable = dynamic;
typedef Unpackable = dynamic;

ByteBuffer pack(Packable data) {
  return serialize(data).buffer;

}

Unpackable unpack(Uint8List data) {
   return deserialize(data);
}

// Packer and Unpacker classes as shown in your previous implementation
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

class Unpacker {
  int index;
  ByteBuffer dataBuffer;
  Uint8List dataView;
  int length;

  Unpacker(this.dataView)
      : index = 0,
        dataBuffer = dataView.buffer,
        length = dataView.lengthInBytes;

  Unpackable unpack() {
    int type = unpackUint8();
    if (type < 0x80) {
      return type;
    } else if ((type ^ 0xe0) < 0x20) {
      return (type ^ 0xe0) - 0x20;
    }

    int size;
    if ((size = type ^ 0xa0) <= 0x0f) {
      return unpackRaw(size);
    } else if ((size = type ^ 0xb0) <= 0x0f) {
      return unpackString(size);
    } else if ((size = type ^ 0x90) <= 0x0f) {
      return unpackArray(size);
    } else if ((size = type ^ 0x80) <= 0x0f) {
      return unpackMap(size);
    }

    switch (type) {
      case 0xc0:
        return null;
      case 0xc1:
        return null;
      case 0xc2:
        return false;
      case 0xc3:
        return true;
      case 0xca:
        return unpackFloat();
      case 0xcb:
        return unpackDouble();
      case 0xcc:
        return unpackUint8();
      case 0xcd:
        return unpackUint16();
      case 0xce:
        return unpackUint32();
      case 0xcf:
        return unpackUint64();
      case 0xd0:
        return unpackInt8();
      case 0xd1:
        return unpackInt16();
      case 0xd2:
        return unpackInt32();
      case 0xd3:
        return unpackInt64();
      case 0xd8:
        size = unpackUint16();
        return unpackString(size);
      case 0xd9:
        size = unpackUint32();
        return unpackString(size);
      case 0xda:
        size = unpackUint16();
        return unpackRaw(size);
      case 0xdb:
        size = unpackUint32();
        return unpackRaw(size);
      case 0xdc:
        size = unpackUint16();
        return unpackArray(size);
      case 0xdd:
        size = unpackUint32();
        return unpackArray(size);
      case 0xde:
        size = unpackUint16();
        return unpackMap(size);
      case 0xdf:
        size = unpackUint32();
        return unpackMap(size);
    }
  }

  int unpackUint8() {
    int byte = dataView[index] & 0xff;
    index++;
    return byte;
  }

  int unpackUint16() {
    var bytes = read(2);
    int uint16 = (bytes[0] & 0xff) * 256 + (bytes[1] & 0xff);
    index += 2;
    return uint16;
  }

  int unpackUint32() {
    var bytes = read(4);
    int uint32 = ((bytes[0] * 256 + bytes[1]) * 256 + bytes[2]) * 256 + bytes[3];
    index += 4;
    return uint32;
  }

  int unpackUint64() {
    var bytes = read(8);
    int uint64 = ((((((bytes[0] * 256 + bytes[1]) * 256 + bytes[2]) * 256 + bytes[3]) * 256 + bytes[4]) * 256 + bytes[5]) * 256 + bytes[6]) * 256 + bytes[7];
    index += 8;
    return uint64;
  }

  int unpackInt8() {
    int uint8 = unpackUint8();
    return uint8 < 0x80 ? uint8 : uint8 - (1 << 8);
  }

  int unpackInt16() {
    int uint16 = unpackUint16();
    return uint16 < 0x8000 ? uint16 : uint16 - (1 << 16);
  }

  int unpackInt32() {
    int uint32 = unpackUint32();
    return uint32 < (1 << 31) ? uint32 : uint32 - (1 << 32);
  }

  int unpackInt64() {
    int uint64 = unpackUint64();
    return uint64 < (1 << 63) ? uint64 : uint64 - (1 << 64);
  }

  ByteBuffer unpackRaw(int size) {
    if (length < index + size) {
      throw Exception('BinaryPackFailure: index is out of range $index $size $length');
    }
    var buf = dataBuffer.asUint8List(index, size);
    index += size;
    return buf.buffer;
  }

  String unpackString(int size) {
    var bytes = read(size);
    return utf8.decode(bytes);
  }

  List<Unpackable> unpackArray(int size) {
    var objects = List<Unpackable>.filled(size, null);
    for (var i = 0; i < size; i++) {
      objects[i] = unpack();
    }
    return objects;
  }

  Map<String, Unpackable> unpackMap(int size) {
    var map = <String, Unpackable>{};
    for (var i = 0; i < size; i++) {
      var key = unpack() as String;
      map[key] = unpack();
    }
    return map;
  }

double unpackFloat() {
  int uint32 = unpackUint32();
  int sign = uint32 >> 31;
  int exp = ((uint32 >> 23) & 0xff) - 127;
  int fraction = (uint32 & 0x7fffff) | 0x800000;
  return (sign == 0 ? 1 : -1) * fraction * pow(2, exp - 23).toDouble();
}


double unpackDouble() {
  int h32 = unpackUint32();
  int l32 = unpackUint32();
  int sign = h32 >> 31;
  int exp = ((h32 >> 20) & 0x7ff) - 1023;
  int hfrac = (h32 & 0xfffff) | 0x100000;
  double frac = hfrac * pow(2, exp - 20).toDouble() + l32 * pow(2, exp - 52).toDouble();
  return (sign == 0 ? 1 : -1) * frac;
}


  Uint8List read(int length) {
    var j = index;
    if (j + length <= this.length) {
      var bytes = dataView.sublist(j, j + length);
      index += length;
      return bytes;
    } else {
      throw Exception('BinaryPackFailure: read index out of range');
    }
  }
}

class Packer {
  final BufferBuilder _bufferBuilder = BufferBuilder();
  final Utf8Encoder _textEncoder = Utf8Encoder();

  ByteBuffer getBuffer() {
    return _bufferBuilder.toArrayBuffer();
  }

  void pack(Packable value) {
    if (value is String) {
      packString(value);
    } else if (value is num) {
      if (value.floor() == value) {
        packInteger(value.toInt());
      } else {
        packDouble(value);
      }
    } else if (value is bool) {
      if (value) {
        _bufferBuilder.append(0xc3);
      } else {
        _bufferBuilder.append(0xc2);
      }
    } else if (value == null) {
      _bufferBuilder.append(0xc0);
    } else if (value is List) {
      packArray(value);
    } else if (value is ByteBuffer) {
      packBin(Uint8List.view(value));
    } else if (value is DateTime) {
      packString(value.toString());
    } else if (value is Map) {
      packObject(value);
    } else {
      throw Exception('Type "${value.runtimeType}" not yet supported');
    }
    _bufferBuilder.flush();
  }

  void packBin(Uint8List blob) {
    int length = blob.length;

    if (length <= 0x0f) {
      packUint8(0xa0 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xda);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xdb);
      packUint32(length);
    } else {
      throw Exception('Invalid length');
    }
    _bufferBuilder.appendBuffer(blob.buffer);
  }

  void packString(String str) {
    var encoded = _textEncoder.convert(str);
    int length = encoded.length;

    if (length <= 0x0f) {
      packUint8(0xb0 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xd8);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xd9);
      packUint32(length);
    } else {
      throw Exception('Invalid length');
    }
    _bufferBuilder.appendBuffer(encoded.buffer);
  }

  void packArray(List<Packable> ary) {
    int length = ary.length;
    if (length <= 0x0f) {
      packUint8(0x90 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xdc);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xdd);
      packUint32(length);
    } else {
      throw Exception('Invalid length');
    }

    for (var item in ary) {
      pack(item);
    }
  }

  void packObject(Map<dynamic, Packable> obj) {
    var keys = obj.keys.toList();
    int length = keys.length;
    if (length <= 0x0f) {
      packUint8(0x80 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xde);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xdf);
      packUint32(length);
    } else {
      throw Exception('Invalid length');
    }

    for (var key in keys) {
      pack(key);
      pack(obj[key]);
    }
  }

  void packUint8(int num) {
    _bufferBuilder.append(num);
  }

  void packUint16(int num) {
    _bufferBuilder.append(num >> 8);
    _bufferBuilder.append(num & 0xff);
  }

  void packUint32(int num) {
    int n = num & 0xffffffff;
    _bufferBuilder.append((n & 0xff000000) >>> 24);
    _bufferBuilder.append((n & 0x00ff0000) >>> 16);
    _bufferBuilder.append((n & 0x0000ff00) >>> 8);
    _bufferBuilder.append(n & 0x000000ff);
  }

  void packUint64(int num) {
    int high = num ~/ 2 ^ 32;
    int low = num % 2 ^ 32;
    _bufferBuilder.append((high & 0xff000000) >>> 24);
    _bufferBuilder.append((high & 0x00ff0000) >>> 16);
    _bufferBuilder.append((high & 0x0000ff00) >>> 8);
    _bufferBuilder.append(high & 0x000000ff);
    _bufferBuilder.append((low & 0xff000000) >>> 24);
    _bufferBuilder.append((low & 0x00ff0000) >>> 16);
    _bufferBuilder.append((low & 0x0000ff00) >>> 8);
    _bufferBuilder.append(low & 0x000000ff);
  }

  void packInt8(int num) {
    _bufferBuilder.append(num & 0xff);
  }

  void packInt16(int num) {
    _bufferBuilder.append((num & 0xff00) >> 8);
    _bufferBuilder.append(num & 0xff);
  }

  void packInt32(int num) {
    _bufferBuilder.append((num >> 24) & 0xff);
    _bufferBuilder.append((num & 0x00ff0000) >>> 16);
    _bufferBuilder.append((num & 0x0000ff00) >>> 8);
    _bufferBuilder.append(num & 0x000000ff);
  }

  void packInt64(int num) {
    int high = num ~/ 2 ^ 32;
    int low = num % 2 ^ 32;
    _bufferBuilder.append((high & 0xff000000) >>> 24);
    _bufferBuilder.append((high & 0x00ff0000) >>> 16);
    _bufferBuilder.append((high & 0x0000ff00) >>> 8);
    _bufferBuilder.append(high & 0x000000ff);
    _bufferBuilder.append((low & 0xff000000) >>> 24);
    _bufferBuilder.append((low & 0x00ff0000) >>> 16);
    _bufferBuilder.append((low & 0x0000ff00) >>> 8);
    _bufferBuilder.append(low & 0x000000ff);
  }

  void packInteger(int num) {
    if (num >= -0x20 && num <= 0x7f) {
      _bufferBuilder.append(num & 0xff);
    } else if (num >= 0x00 && num <= 0xff) {
      _bufferBuilder.append(0xcc);
      packUint8(num);
    } else if (num >= -0x80 && num <= 0x7f) {
      _bufferBuilder.append(0xd0);
      packInt8(num);
    } else if (num >= 0x0000 && num <= 0xffff) {
      _bufferBuilder.append(0xcd);
      packUint16(num);
    } else if (num >= -0x8000 && num <= 0x7fff) {
      _bufferBuilder.append(0xd1);
      packInt16(num);
    } else if (num >= 0x00000000 && num <= 0xffffffff) {
      _bufferBuilder.append(0xce);
      packUint32(num);
    } else if (num >= -0x80000000 && num <= 0x7fffffff) {
      _bufferBuilder.append(0xd2);
      packInt32(num);
    } else if (num >= -0x8000000000000000 && num <= 0x7fffffffffffffff) {
      _bufferBuilder.append(0xd3);
      packInt64(num);
    } else if (num >= 0x0000000000000000 && num <= 0xffffffffffffffff) {
      _bufferBuilder.append(0xcf);
      packUint64(num);
    } else {
      throw Exception('Invalid integer');
    }
  }

  void packDouble(num value) {
    int sign = 0;
    if (value < 0) {
      sign = 1;
      value = -value;
    }
    int exp = (log(value) / ln2).floor();
    num frac0 = value / (1 << exp) - 1;
    int frac1 = (frac0 * (1 << 52)).floor();
    int b32 = 1 << 32;
    int h32 = (sign << 31) | ((exp + 1023) << 20) | ((frac1 ~/ b32) & 0x0fffff);
    int l32 = frac1 % b32;
    _bufferBuilder.append(0xcb);
    packInt32(h32);
    packInt32(l32);
  }
}
