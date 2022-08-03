import 'package:dart_pusher_channels/configs.dart';
import 'package:test/test.dart';

import 'utils/log_grabber.dart';

void main() {
  group('logs', () {
    test('should enable and disable logs', () {
      grabLogs((printedLogs) {
        PusherChannelsPackageConfigs.enableLogs();
        PusherChannelsPackageLogger.log('hello');
        expect(printedLogs.length, 1);
        expect(printedLogs[0], 'hello');

        PusherChannelsPackageConfigs.disableLogs();
        PusherChannelsPackageLogger.log('bye');
        expect(printedLogs.length, 1);
      });
    });

    test('should use a custom log handler', () {
      grabLogs((printedLogs) {
        final handledLines = <String>[];

        PusherChannelsPackageConfigs.enableLogs(
          handler: (o) => handledLines.add(o.toString()),
        );
        PusherChannelsPackageLogger.log('hello');
        PusherChannelsPackageLogger.log('123');

        expect(handledLines, ['hello', '123']);
        expect(printedLogs, isEmpty);

        PusherChannelsPackageConfigs.enableLogs();
        PusherChannelsPackageLogger.log('hello');
        expect(handledLines.length, 2);
        expect(printedLogs.length, 1);
        expect(printedLogs[0], 'hello');
      });
    });
  });
}
