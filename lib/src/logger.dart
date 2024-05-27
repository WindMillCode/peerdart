import 'enums.dart';

const _logPrefix = 'PeerDart: ';

class Logger {
  Logger() {
    _print = (LogLevel logLevel, dynamic message) {
      var msg = '$_logPrefix ${message.toString()}';
      if (logLevel == LogLevel.All) {
        print(msg);
      } else if (logLevel == LogLevel.Warnings) {
        print("WARNING $msg");
      } else if (logLevel == LogLevel.Errors) {
        print("ERROR $msg");
      }
    };
  }

  var logLevel = LogLevel.Disabled;

  void log(dynamic message) {
    if (logLevel == LogLevel.All) {
      _print(LogLevel.All, message);
    }
  }

  void warn(dynamic message) {
    if (logLevel == LogLevel.Warnings) {
      _print(LogLevel.Warnings, message);
    }
  }

  void error(dynamic message) {
    if (logLevel == LogLevel.Errors) {
      _print(LogLevel.Errors, message);
    }
  }

  void setLogFunction(Function(LogLevel level, dynamic message) fn) {
    _print = fn;
  }

  late void Function(LogLevel level, dynamic message) _print;
}

final logger = Logger();
