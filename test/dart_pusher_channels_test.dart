import 'package:dart_pusher_channels/dart_pusher_channels.dart';
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

  group('Pusher Channel options uri must be convinient', () {
    test('Raw constructor', () {
      const withoutCluster = PusherChannelsOptions(
          scheme: 'ws',
          host: 'example.com',
          port: 12,
          key: 'API_KEY',
          protocol: 7);
      expect(
          withoutCluster.uri,
          Uri.parse(
              'ws://example.com:12/app/API_KEY?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const withCluster = PusherChannelsOptions(
          scheme: 'ws',
          host: 'example.com',
          port: 12,
          cluster: 'CLUSTER',
          key: 'API_KEY',
          protocol: 7);
      expect(
          withCluster.uri,
          Uri.parse(
              'ws://ws-CLUSTER.example.com:12/app/API_KEY?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const withPath = PusherChannelsOptions(
          scheme: 'ws',
          host: 'example.com',
          path: '/CUSTOM_PATH',
          port: 12,
          key: null,
          protocol: 7);
      expect(
          withPath.uri,
          Uri.parse(
              'ws://example.com:12/CUSTOM_PATH?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const keyNullPathNull = PusherChannelsOptions(
          scheme: 'ws',
          host: 'example.com',
          path: null,
          port: 12,
          key: null,
          protocol: 7);
      expect(
          keyNullPathNull.uri,
          Uri.parse(
              'ws://example.com:12/?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
    });
    test('.ws constructor', () {
      const withoutCluster = PusherChannelsOptions.ws(
          host: 'example.com', port: 12, key: 'API_KEY', protocol: 7);
      expect(
          withoutCluster.uri,
          Uri.parse(
              'ws://example.com:12/app/API_KEY?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const withCluster = PusherChannelsOptions.ws(
          host: 'example.com',
          port: 12,
          cluster: 'CLUSTER',
          key: 'API_KEY',
          protocol: 7);
      expect(
          withCluster.uri,
          Uri.parse(
              'ws://ws-CLUSTER.example.com:12/app/API_KEY?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const withPath = PusherChannelsOptions.ws(
          host: 'example.com',
          path: '/CUSTOM_PATH',
          port: 12,
          key: null,
          protocol: 7);
      expect(
          withPath.uri,
          Uri.parse(
              'ws://example.com:12/CUSTOM_PATH?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const keyNullPathNull = PusherChannelsOptions.ws(
          host: 'example.com', path: null, port: 12, key: null, protocol: 7);
      expect(
          keyNullPathNull.uri,
          Uri.parse(
              'ws://example.com:12/?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
    });
    test('.wss constructor', () {
      const withoutCluster = PusherChannelsOptions.wss(
          host: 'example.com', port: 443, key: 'API_KEY', protocol: 7);
      expect(
          withoutCluster.uri,
          Uri.parse(
              'wss://example.com:443/app/API_KEY?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const withCluster = PusherChannelsOptions.wss(
          host: 'example.com',
          port: 443,
          cluster: 'CLUSTER',
          key: 'API_KEY',
          protocol: 7);
      expect(
          withCluster.uri,
          Uri.parse(
              'wss://ws-CLUSTER.example.com:443/app/API_KEY?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const withPath = PusherChannelsOptions.wss(
          host: 'example.com',
          path: '/CUSTOM_PATH',
          port: 443,
          key: null,
          protocol: 7);
      expect(
          withPath.uri,
          Uri.parse(
              'wss://example.com:443/CUSTOM_PATH?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
      const keyNullPathNull = PusherChannelsOptions.wss(
          host: 'example.com', path: null, port: 12, key: null, protocol: 7);
      expect(
          keyNullPathNull.uri,
          Uri.parse(
              'wss://example.com:12/?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=7'));
    });
  });
}
