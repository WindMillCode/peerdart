import 'dart:io';


class Supports {
  final bool isIOS = Platform.isIOS;

  bool isWebRTCSupported() {
    return true;
  }

  bool isBrowserSupported() {
    return true;
  }

  String getBrowser() {
    return "flutter";
  }

  int getVersion() {
    return 1;
  }

  bool isUnifiedPlanSupported() {
    return true;
  }

  @override
  String toString() {
    return '''Supports:
    browser: ${getBrowser()}
    version: ${getVersion()}
    isIOS: $isIOS
    isWebRTCSupported: ${isWebRTCSupported()}
    isBrowserSupported: ${isBrowserSupported()}
    isUnifiedPlanSupported: ${isUnifiedPlanSupported()}''';
  }
}

final supports = Supports();
