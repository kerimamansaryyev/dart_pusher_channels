import 'package:dart_pusher_channels/configs.dart';
import 'package:test/test.dart';

void main() {
  test('Test enabling/disabling logs', () {
    PusherChannelsPackageConfigs.enableLogs();
    PusherChannelsPackageLogger.logTest(
        'hello', (isEnabled) => expect(isEnabled, true));
    PusherChannelsPackageConfigs.disableLogs();
    PusherChannelsPackageLogger.logTest(
        'hello', (isEnabled) => expect(isEnabled, false));
  });
}
