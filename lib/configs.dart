import 'package:dart_pusher_channels/api.dart';

typedef LogHandler = void Function(Object? o);

/// Package configurations.
abstract class PusherChannelsPackageConfigs {
  static bool _logsEnabled = false;
  static LogHandler _handler = print;
  static const defaultPingWaitPongDuration = Duration(seconds: 10);

  /// Use to check if logs are enabled.
  static bool get logsEnabled => _logsEnabled;

  /// The handler log function.
  static LogHandler get handler => _handler;

  /// Makes logs visible. If logs are enabled, you will able to see logs from different structures of the package.
  /// For example, event logs from [ConnectionDelegate]s.
  /// <br/>
  /// Logs are done with [handler] if specified. Otherwise, they will be printed
  /// to console using [print].
  static void enableLogs({LogHandler? handler}) {
    if (handler != null) {
      _handler = handler;
    } else {
      _handler = print;
    }

    _logsEnabled = true;
  }

  /// Makes logs invisible
  static void disableLogs() {
    _logsEnabled = false;
  }
}

/// Logger that used across all the package.
abstract class PusherChannelsPackageLogger {
  /// Wraps print by condition of [PusherChannelsPackageConfigs.logsEnabled]
  static void log(Object? object) {
    if (PusherChannelsPackageConfigs.logsEnabled) {
      PusherChannelsPackageConfigs.handler(object);
    }
  }
}
