import 'dart:math';

String randomToken() {
  final random = Random();
  final token = random.nextDouble().toString().substring(2);
  return int.parse(token).toRadixString(36);
}
