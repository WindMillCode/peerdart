const String LOG_PREFIX = "PeerJS: ";

/*
Prints log messages depending on the debug level passed in. Defaults to 0.
0  Prints no logs.
1  Prints only errors.
2  Prints errors and warnings.
3  Prints all logs.
*/
enum LogLevel {
  /**
   * Prints no logs.
   */
  Disabled,
  /**
   * Prints only errors.
   */
  Errors,
  /**
   * Prints errors and warnings.
   */
  Warnings,
  /**
   * Prints all logs.
   */
  All,
}

class Logger {
  LogLevel _logLevel = LogLevel.Disabled;

  LogLevel get logLevel => _logLevel;

  set logLevel(LogLevel logLevel) {
    _logLevel = logLevel;
  }

  void log(dynamic args) {
    if (_logLevel.index >= LogLevel.All.index) {
      _print(LogLevel.All, args);
    }
  }

  void warn(dynamic args) {
    if (_logLevel.index >= LogLevel.Warnings.index) {
      _print(LogLevel.Warnings, args);
    }
  }

  void error(dynamic args) {
    if (_logLevel.index >= LogLevel.Errors.index) {
      _print(LogLevel.Errors, args);
    }
  }

  void setLogFunction(void Function(LogLevel logLevel, dynamic args) fn) {
   _customPrint = fn;
  }

  static void Function(LogLevel, dynamic) _customPrint = _defaultPrint;

  static void _defaultPrint(LogLevel logLevel, dynamic rest) {
    var copy = [LOG_PREFIX, rest];

    for (var i = 0; i < copy.length; i++) {
      if (copy[i] is Error) {
        copy[i] = "(${copy[i].name}) ${copy[i].message}";
      }
    }

    if (logLevel.index >= LogLevel.All.index) {
      print(copy.join(' '));
    } else if (logLevel.index >= LogLevel.Warnings.index) {
      print("WARNING ${copy.join(' ')}");
    } else if (logLevel.index >= LogLevel.Errors.index) {
      print("ERROR ${copy.join(' ')}");
    }
  }

  void _print(LogLevel logLevel, dynamic rest) {
    _customPrint(logLevel, rest);
  }
}

final logger = Logger();
