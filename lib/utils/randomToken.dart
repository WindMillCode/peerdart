import 'dart:math';

String randomToken() {
  return DateTime.now().millisecondsSinceEpoch.toRadixString(36) + (Random().nextDouble().toString().substring(2));
}
