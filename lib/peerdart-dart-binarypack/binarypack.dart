import 'dart:math';
import 'dart:typed_data';

import 'package:peerdart/peerdart-dart-binarypack/bufferbuilder.dart';
import 'package:peerdart/utils/nodejs_adaptations.dart';

typedef Packable = dynamic;
typedef Unpackable = dynamic;

T unpack<T extends Unpackable>(ByteBuffer data) {
  final unpacker = Unpacker(data);
  return unpacker.unpack() as T;
}

Future<ByteBuffer> pack(Packable data) async {
  final packer = Packer();
  await packer.pack(data);
  return packer.getBuffer();
}

class Unpacker {
  int index;
  final ByteBuffer dataBuffer;
  final Uint8List dataView;
  final int length;

  Unpacker(this.dataBuffer)
      : index = 0,
        dataView = Uint8List.view(dataBuffer),
        length = dataBuffer.lengthInBytes;

  Unpackable unpack() {
    final type = unpackUint8();
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
      case 0xd4:
        return null;
      case 0xd5:
        return null;
      case 0xd6:
        return null;
      case 0xd7:
        return null;
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
      default:
        throw UnimplementedError();
    }
  }

  int unpackUint8() {
    final byte = dataView[index] & 0xff;
    index++;
    return byte;
  }

  int unpackUint16() {
    final bytes = read(2);
    final uint16 = (bytes[0] & 0xff) * 256 + (bytes[1] & 0xff);
    index += 2;
    return uint16;
  }

  int unpackUint32() {
    final bytes = read(4);
    final uint32 =
        ((bytes[0] * 256 + bytes[1]) * 256 + bytes[2]) * 256 + bytes[3];
    index += 4;
    return uint32;
  }

  int unpackUint64() {
    final bytes = read(8);
    final uint64 =
        ((((((bytes[0] * 256 + bytes[1]) * 256 + bytes[2]) * 256 + bytes[3]) *
                    256 +
                bytes[4]) *
            256 +
        bytes[5]) *
            256 +
        bytes[6]) *
        256 +
        bytes[7];
    index += 8;
    return uint64;
  }

  int unpackInt8() {
    final uint8 = unpackUint8();
    return uint8 < 0x80 ? uint8 : uint8 - (1 << 8);
  }

  int unpackInt16() {
    final uint16 = unpackUint16();
    return uint16 < 0x8000 ? uint16 : uint16 - (1 << 16);
  }

  int unpackInt32() {
    final uint32 = unpackUint32();
    return uint32 < 0x80000000 ? uint32 : uint32 - (1 << 32);
  }

  int unpackInt64() {
    final uint64 = unpackUint64();
    return uint64 < 0x8000000000000000 ? uint64 : uint64 - (1 << 64);
  }

  ByteBuffer unpackRaw(int size) {
    if (length < index + size) {
      throw RangeError(
          'BinaryPackFailure: index is out of range $index $size $length');
    }
    final buf = dataBuffer.asUint8List(index, size);
    index += size;
    return buf.buffer;
  }

  String unpackString(int size) {
    final bytes = read(size);
    return String.fromCharCodes(bytes);
  }

  List<Unpackable> unpackArray(int size) {
    final objects = List<Unpackable>.filled(size, null);
    for (var i = 0; i < size; i++) {
      objects[i] = unpack();
    }
    return objects;
  }

  Map<String, Unpackable> unpackMap(int size) {
    final map = <String, Unpackable>{};
    for (var i = 0; i < size; i++) {
      final key = unpack() as String;
      map[key] = unpack();
    }
    return map;
  }

  double unpackFloat() {
    final uint32 = unpackUint32();
    final sign = uint32 >> 31;
    final exp = ((uint32 >> 23) & 0xff) - 127;
    final fraction = (uint32 & 0x7fffff) | 0x800000;
    return (sign == 0 ? 1 : -1) * fraction * (1 << (exp - 23)).toDouble();
  }


  double unpackDouble() {
    final h32 = unpackUint32();
    final l32 = unpackUint32();
    final sign = h32 >> 31;
    final exp = ((h32 >> 20) & 0x7ff) - 1023;
    final hfrac = (h32 & 0xfffff) | 0x100000;
    final frac = (hfrac * (1 << (exp - 20)).toDouble()) + (l32.toDouble() / (1 << (52 - exp)).toDouble());
    return (sign == 0 ? 1 : -1) * frac;
  }


  Uint8List read(int length) {
    final j = index;
    if (j + length <= this.length) {
      final view = dataView.sublist(j, j + length);
      index += length;
      return view;
    } else {
      throw RangeError('BinaryPackFailure: read index out of range');
    }
  }
}

class Packer {
  final BufferBuilder _bufferBuilder = BufferBuilder();
  final TextEncoder _textEncoder = TextEncoder();

  ByteBuffer getBuffer() {
    return _bufferBuilder.toArrayBuffer();
  }

  Future<void> pack(Packable value) async {
    if (value is String) {
      packString(value);
    } else if (value is num) {
      if (value.floor() == value) {
        packInteger(value);
      } else {
        packDouble(value as double);
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
      final res = packArray(value);
      await res;
    } else if (value is ByteBuffer) {
      packBin(Uint8List.view(value));
    } else if (value is ByteData) {
      packBin(Uint8List.view(value.buffer, value.offsetInBytes, value.lengthInBytes));
    } else if (value is DateTime) {
      packString(value.toIso8601String());
    } else if (value is Map<String, Packable>) {
      final res = packObject(value);
      await res;
    } else {
      throw ArgumentError('Type "${value.runtimeType}" not yet supported');
    }
    _bufferBuilder.flush();
  }

  void packBin(Uint8List blob) {
    final length = blob.length;

    if (length <= 0x0f) {
      packUint8(0xa0 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xda);
      packUint16(length);
    } else if

 (length <= 0xffffffff) {
      _bufferBuilder.append(0xdb);
      packUint32(length);
    } else {
      throw ArgumentError('Invalid length');
    }
    _bufferBuilder.appendBuffer(blob.buffer);
  }

  void packString(String str) {
    final encoded = _textEncoder.encode(str);
    final length = encoded.length;

    if (length <= 0x0f) {
      packUint8(0xb0 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xd8);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xd9);
      packUint32(length);
    } else {
      throw ArgumentError('Invalid length');
    }
    _bufferBuilder.appendBuffer(encoded.buffer);
  }

  Future<void> packArray(List<Packable> ary) async {
    final length = ary.length;
    if (length <= 0x0f) {
      packUint8(0x90 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xdc);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xdd);
      packUint32(length);
    } else {
      throw ArgumentError('Invalid length');
    }

    for (var value in ary) {
      await pack(value);
    }
  }

  void packInteger(num value) {
    int intValue = value.toInt();
    if (intValue >= -0x20 && intValue <= 0x7f) {
      _bufferBuilder.append(intValue & 0xff);
    } else if (intValue >= 0x00 && intValue <= 0xff) {
      _bufferBuilder.append(0xcc);
      packUint8(intValue);
    } else if (intValue >= -0x80 && intValue <= 0x7f) {
      _bufferBuilder.append(0xd0);
      packInt8(intValue);
    } else if (intValue >= 0x0000 && intValue <= 0xffff) {
      _bufferBuilder.append(0xcd);
      packUint16(intValue);
    } else if (intValue >= -0x8000 && intValue <= 0x7fff) {
      _bufferBuilder.append(0xd1);
      packInt16(intValue);
    } else if (intValue >= 0x00000000 && intValue <= 0xffffffff) {
      _bufferBuilder.append(0xce);
      packUint32(intValue);
    } else if (intValue >= -0x80000000 && intValue <= 0x7fffffff) {
      _bufferBuilder.append(0xd2);
      packInt32(intValue);
    } else if (value >= -0x8000000000000000 && value <= 0x7fffffffffffffff) {
      _bufferBuilder.append(0xd3);
      packInt64(intValue);
    } else if (value >= 0x0000000000000000 && value <= 0xffffffffffffffff) {
      _bufferBuilder.append(0xcf);
      packUint64(intValue);
    } else {
      throw ArgumentError('Invalid integer');
    }
  }

  void packDouble(double value) {
    int sign = 0;
    if (value < 0) {
      sign = 1;
      value = -value;
    }
    final exp = (value == 0 ? 0 : (log(value) / log(2)).floor());
    final frac0 = value / (1 << exp) - 1;
    final frac1 = (frac0 * (1 << 52)).floor();
    final b32 = (1 << 32);
    final h32 = (sign << 31) | ((exp + 1023) << 20) | ((frac1 ~/ b32) & 0x0fffff);
    final l32 = frac1 % b32;
    _bufferBuilder.append(0xcb);
    packInt32(h32);
    packInt32(l32);
  }

  Future<void> packObject(Map<String, Packable> obj) async {
    final keys = obj.keys.toList();
    final length = keys.length;
    if (length <= 0x0f) {
      packUint8(0x80 + length);
    } else if (length <= 0xffff) {
      _bufferBuilder.append(0xde);
      packUint16(length);
    } else if (length <= 0xffffffff) {
      _bufferBuilder.append(0xdf);
      packUint32(length);
    } else {
      throw ArgumentError('Invalid length');
    }

    for (var key in keys) {
      await pack(key);
      await pack(obj[key]);
    }
  }

  void packUint8(int value) {
    _bufferBuilder.append(value);
  }

  void packUint16(int value) {
    _bufferBuilder.append(value >> 8);
    _bufferBuilder.append(value & 0xff);
  }

  void packUint32(int value) {
    final n = value & 0xffffffff;
    _bufferBuilder.append((n & 0xff000000) >>> 24);
    _bufferBuilder.append((n & 0x00ff0000) >>> 16);
    _bufferBuilder.append((n & 0x0000ff00) >>> 8);
    _bufferBuilder.append(n & 0x000000ff);
  }

  void packUint64(int value) {
    final high = (value / (1 << 32)).floor();
    final low = value % (1 << 32);
    _bufferBuilder.append((high & 0xff000000) >>> 24);
    _bufferBuilder.append((high & 0x00ff0000) >>> 16);
    _bufferBuilder.append((high & 0x0000ff00) >>> 8);
    _bufferBuilder.append(high & 0x000000ff);
    _bufferBuilder.append((low & 0xff000000) >>> 24);
    _bufferBuilder.append((low & 0x00ff0000) >>> 16);
    _bufferBuilder.append((low & 0x0000ff00) >>> 8);
    _bufferBuilder.append(low & 0x000000ff);
  }

  void packInt8(int value) {
    _bufferBuilder.append(value & 0xff);
  }

  void packInt16(int value) {
    _bufferBuilder.append((value & 0xff00) >> 8);
    _bufferBuilder.append(value & 0xff);
  }

  void packInt32(int value) {
    _bufferBuilder.append((value >>> 24) & 0xff);
    _bufferBuilder.append((value & 0x00ff0000) >>> 16);
    _bufferBuilder.append((value & 0x0000ff00) >>> 8);
    _bufferBuilder.append(value & 0x000000ff);
  }

  void packInt64(int value) {
    final high = (value / (1 << 32)).floor();
    final low = value % (1 << 32);
    _bufferBuilder.append((high & 0xff000000) >>> 24);
    _bufferBuilder.append((high & 0x00ff0000) >>> 16);
    _bufferBuilder.append((high & 0x0000ff00) >>> 8);
    _bufferBuilder.append(high & 0x000000ff);
    _bufferBuilder.append((low & 0xff000000) >>> 24);
    _bufferBuilder.append((low & 0x00ff0000) >>> 16);
    _bufferBuilder.append((low & 0x0000ff00) >>> 8);
    _bufferBuilder.append(low & 0x000000ff);
  }
}

