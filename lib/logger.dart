const String LOG_PREFIX = "PeerDart: ";

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
  /**
   * prints data Chunks
   */
  DataChunk
}

class Logger {
  LogLevel _logLevel = LogLevel.Disabled;

  LogLevel get logLevel => _logLevel;

  set logLevel(LogLevel logLevel) {
    _logLevel = logLevel;
  }

  void chunk(dynamic args) {
    if (_logLevel.index >= LogLevel.DataChunk.index) {
      _print(LogLevel.DataChunk, args);
    }
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
      print("$LOG_PREFIX ${copy.join(' ')}");
    } else if (logLevel.index >= LogLevel.Warnings.index) {
      print("$LOG_PREFIX WARNING ${copy.join(' ')}");
    } else if (logLevel.index >= LogLevel.Errors.index) {
      print("$LOG_PREFIX ERROR ${copy.join(' ')}");
    }
  }

  void _print(LogLevel logLevel, dynamic rest) {
    _customPrint(logLevel, rest);
  }
}

final logger = Logger();
