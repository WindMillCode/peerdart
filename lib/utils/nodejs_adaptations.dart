import 'dart:convert';
import 'dart:typed_data';

class TextEncoderCommon {
  final String encoding = 'utf-8';
}

class TextEncoder extends TextEncoderCommon {
  Uint8List encode([String input = '']) {
    return utf8.encode(input);
  }

  TextEncoderEncodeIntoResult encodeInto(String source, Uint8List destination) {
    var bytes = utf8.encode(source);
    var length = bytes.length;

    if (destination.length < length) {
      length = destination.length;
    }

    for (var i = 0; i < length; i++) {
      destination[i] = bytes[i];
    }

    return TextEncoderEncodeIntoResult(read: length, written: length);
  }
}

class TextEncoderEncodeIntoResult {
  final int read;
  final int written;

  TextEncoderEncodeIntoResult({required this.read, required this.written});
}
