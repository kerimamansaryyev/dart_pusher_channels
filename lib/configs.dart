import 'package:meta/meta.dart';
import 'package:dart_pusher_channels/api.dart';

/// Package configurations.
abstract class PusherChannelsPackageConfigs {
  static bool _logsEnabled = false;

  /// Makes logs visible. If logs are enabled, you will able to see logs from different structures of the package.
  /// For example, event logs from [ConnectionDelegate]s.
  /// <br/>
  /// Logs are done with [print] function and will be printed to the console that you app is running on.
  static void enableLogs() {
    _logsEnabled = true;
  }

  /// Makes logs invisible
  static void disableLogs() {
    _logsEnabled = false;
  }

  /// Use to check if logs are enabled.
  static bool get logsEnabled => _logsEnabled;
}

/// Logger that used across all the package.
abstract class PusherChannelsPackageLogger {
  /// Wraps print by condition of [PusherChannelsPackageConfigs.logsEnabled]
  static void log(Object? object) {
    if (PusherChannelsPackageConfigs.logsEnabled) print(object);
  }

  /// Mock for testing
  @visibleForTesting
  static void logTest(Object? object, [void Function(bool)? callBack]) {
    callBack?.call(PusherChannelsPackageConfigs.logsEnabled);
    log(object);
  }
}
