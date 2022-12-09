import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:test/test.dart';

// Ignoring for test purposes
// ignore: long-method
void main() {
  group('custom options |', () {
    test(
      '.uri must give full link',
      () {
        final options = PusherChannelsOptions.custom(
          uriResolver: (metaData) => Uri(
            scheme: 'ws',
            host: 'custom.com',
            path: '/my/custom/path/',
            queryParameters: metaData.getQueryParameters(),
          ),
          metadata: const PusherChannelsOptionsMetadata(
            client: 'javascript',
            protocol: 6,
            version: '1.1.3',
          ),
        );
        expect(
          options.uri.toString(),
          'ws://custom.com/my/custom/path/?client=javascript&version=1.1.3&protocol=6',
        );
      },
    );
  });
  group(
    'non-custom options |',
    () {
      test(
        'changing metadata changes query parameters',
        () {
          const otherMetadata = PusherChannelsOptionsMetadata(
            client: 'javascript',
            protocol: 5,
            version: '1.1.0',
          );
          final clusteredOptions = PusherChannelsOptions.fromCluster(
            scheme: 'ws',
            cluster: 'cluster',
            host: 'custom.com',
            key: 'key',
            port: 80,
            shouldSupplyMetadataQueries: true,
            metadata: otherMetadata,
          );
          final hostOptions = PusherChannelsOptions.fromHost(
            scheme: 'ws',
            host: 'custom.com',
            key: 'key',
            port: 80,
            shouldSupplyMetadataQueries: true,
            metadata: otherMetadata,
          );
          expect(
            clusteredOptions.uri.queryParameters,
            {
              'client': otherMetadata.client,
              'version': otherMetadata.version,
              'protocol': otherMetadata.protocol.toString(),
            },
          );
          expect(
            hostOptions.uri.queryParameters,
            {
              'client': otherMetadata.client,
              'version': otherMetadata.version,
              'protocol': otherMetadata.protocol.toString(),
            },
          );
        },
      );
      test(
        'setting shouldSupplyQueryParameters to false removes queryParameters',
        () {
          final clusteredOptions = PusherChannelsOptions.fromCluster(
            scheme: 'ws',
            cluster: 'cluster',
            host: 'custom.com',
            key: 'key',
            port: 80,
            shouldSupplyMetadataQueries: false,
          );
          final hostOptions = PusherChannelsOptions.fromHost(
            scheme: 'ws',
            host: 'custom.com',
            key: 'key',
            port: 80,
            shouldSupplyMetadataQueries: false,
          );
          expect(
            hostOptions.uri.queryParameters.isEmpty,
            true,
          );
          expect(
            clusteredOptions.uri.queryParameters.isEmpty,
            true,
          );
        },
      );
      test('testing full link', () {
        final clusteredOptions = PusherChannelsOptions.fromCluster(
          scheme: 'ws',
          cluster: 'cluster',
          host: 'custom.com',
          key: 'key',
          port: 80,
        );
        final hostOptions = PusherChannelsOptions.fromHost(
          scheme: 'ws',
          host: 'custom.com',
          key: 'key',
          port: 80,
        );
        final clusteredOptionsUri = clusteredOptions.uri;
        final hostOptionsUri = hostOptions.uri;
        expect(
          hostOptionsUri.toString(),
          'ws://custom.com:80/app/key?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=$kLatestAvailablePusherProtocol',
        );
        expect(
          clusteredOptionsUri.toString(),
          'ws://ws-cluster.custom.com:80/app/key?client=dart&version=$kDartPusherChannelsLibraryVersion&protocol=$kLatestAvailablePusherProtocol',
        );
      });
    },
  );
  group(
    'clustered options |',
    () {
      test('default host gives ws-cluster.pusher.com', () {
        final options = PusherChannelsOptions.fromCluster(
          scheme: 'ws',
          cluster: 'cluster',
          key: 'key',
        );
        expect(options.uri.host, 'ws-cluster.pusher.com');
      });
      test('assigning custom host gives ws-cluster.custom.com', () {
        final options = PusherChannelsOptions.fromCluster(
          scheme: 'ws',
          cluster: 'cluster',
          host: 'custom.com',
          key: 'key',
        );
        expect(options.uri.host, 'ws-cluster.custom.com');
      });
      test('path is /app/key', () {
        final options = PusherChannelsOptions.fromCluster(
          scheme: 'ws',
          cluster: 'cluster',
          key: 'key',
        );
        expect(options.uri.path, '/app/key');
      });
    },
  );
}
