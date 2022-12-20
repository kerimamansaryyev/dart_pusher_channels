import 'package:meta/meta.dart';

typedef LogHandler = void Function(Object? o);

/// An abstract singleton that logs different events of this package.
///
/// The loggins is disabled by default.
///
/// This package's internal members use the [log] to log the events.
/// It is possible to pass the custom handler accepting the logs of type [String]
/// via the [enableLogs] method (which implicitly enables loggins).
///
/// The logs may be disabled by the [disableLogs] method.
abstract class PusherChannelsPackageLogger {
  static bool _logsEnabled = false;
  static LogHandler _handler = print;

  /// An internal API to log [object]s
  @internal
  static void log(Object? object) {
    if (_logsEnabled) {
      _handler(object);
    }
  }

  /// Enables logs. If the custom [handler] is not provided - then [print] function will be used.
  static void enableLogs({LogHandler? handler}) {
    _handler = handler ?? print;
    _logsEnabled = true;
  }

  /// Disables logs.
  static void disableLogs() {
    _logsEnabled = false;
  }
}
