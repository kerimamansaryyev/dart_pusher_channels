import 'package:meta/meta.dart';

typedef LogHandler = void Function(Object? o);

abstract class PusherChannelsPackageLogger {
  static bool _logsEnabled = false;
  static LogHandler _handler = print;

  @internal
  static void log(Object? object) {
    if (_logsEnabled) {
      _handler(object);
    }
  }

  static void enableLogs({LogHandler? handler}) {
    _handler = handler ?? _handler;
    _logsEnabled = true;
  }

  static void disableLogs() {
    _logsEnabled = false;
  }
}
