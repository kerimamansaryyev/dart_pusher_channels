library pusher_channels_options;

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:meta/meta.dart';

part 'clustered_options.dart';
part 'host_options.dart';
part 'custom_options.dart';

typedef PusherChannelsOptionsCustomUriResolver = Uri Function(
  PusherChannelsOptionsMetadata metadata,
);

/// Provides [queryParameters] that are used as the metadata injected into this [uri].
mixin _QuerySupplyMixin on PusherChannelsOptions {
  PusherChannelsOptionsMetadata get metadata;
  bool get shouldSupplyMetadataQueries;

  /// Query parameters that are derived from [PusherChannelsOptionsMetadata.getQueryParameters]
  @protected
  Map<String, String>? get queryParameters {
    if (!shouldSupplyMetadataQueries) {
      return null;
    }
    return metadata.getQueryParameters();
  }
}

/// A data class that keeps metadata that is sent with [PusherChannelsOptions.uri] while connecting to a server.
///
/// See: [Pusher Channel Protocol docs](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/)
@immutable
class PusherChannelsOptionsMetadata {
  /// A client name.
  ///
  /// [PusherChannelsOptionsMetadata.byDefault] sets it as `dart`.
  final String client;

  /// The Pusher Protocol version.
  ///
  /// More on this:
  /// - [kLatestAvailablePusherProtocol]
  final int protocol;

  /// The version of the client library.
  ///
  /// More on this:
  /// - [kDartPusherChannelsLibraryVersion]
  final String version;

  const PusherChannelsOptionsMetadata({
    required this.client,
    required this.protocol,
    required this.version,
  });

  const PusherChannelsOptionsMetadata.byDefault()
      : this(
          client: 'dart',
          protocol: kLatestAvailablePusherProtocol,
          version: kDartPusherChannelsLibraryVersion,
        );

  /// Provides the metadata as [Map].
  Map<String, String> getQueryParameters() => {
        'client': client,
        'version': version,
        'protocol': protocol.toString(),
      };
}

/// Options passed to instances of [PusherChannelsClient].
///
/// - Use [PusherChannelsOptions.fromCluster] if your url has a pattern like:
///   `{scheme}://ws-{cluster_name}.{host}:{port}/app/{key}`.
///
///   Example:
///   ```dart
///   const testOptions = PusherChannelsOptions.fromCluster(
///      scheme: 'wss',
///      cluster: 'mt1',
///      key: 'a0173cd5499b34d93109',
///      port: 443,
///    );
///   ```
///
/// - Use [PusherChannelsOptions.fromHost] if you have the Pusher Channels installed to your server under
///   your own domain host.
///
///   Example:
///   ```dart
///   const testOptions = PusherChannelsOptions.fromHost(
///     scheme: 'wss',
///     host: 'my.domain.com',
///     key: 'my_key',
///   );
///   ```
/// - Use [PusherChannelsOptions.custom], if the all above use-cases don't suit yours, providing [PusherChannelsOptionsCustomUriResolver].
///
///   Example:
///   ```dart
///   final testOptions = PusherChannelsOptions.custom(
///     uriResolver: (_) => Uri.parse('https://my.domain.com/my/path')
///   );
///   ```
///
@immutable
abstract class PusherChannelsOptions {
  /// A resultant url used to connect by [PusherChannelsClient]
  Uri get uri;

  /// Use this if your url has a pattern like:
  ///   `{scheme}://ws-{cluster_name}.{host}:{port}/app/{key}`.
  ///
  /// The [scheme] is usually `ws` or `wss`.
  ///
  /// The [key] is your Pusher Channels app key.
  ///
  /// The [host] defaults to [kDefaultPusherChannelsHost].
  ///
  /// The [metadata] defaults to an instance created with [PusherChannelsOptionsMetadata.byDefault]
  const factory PusherChannelsOptions.fromCluster({
    required String scheme,
    required String cluster,
    required String key,
    bool shouldSupplyMetadataQueries,
    String host,
    int? port,
    PusherChannelsOptionsMetadata metadata,
  }) = _ClusteredOptions;

  /// Use this if you have the Pusher Channels installed to your server under
  /// your own domain host.
  ///
  /// The [scheme] is usually `ws` or `wss`.
  ///
  /// The [key] is your Pusher Channels app key.
  ///
  /// The [host] defaults to [kDefaultPusherChannelsHost].
  ///
  /// The [metadata] defaults to an instance created with [PusherChannelsOptionsMetadata.byDefault]
  const factory PusherChannelsOptions.fromHost({
    required String scheme,
    required String host,
    required String key,
    int? port,
    bool shouldSupplyMetadataQueries,
    PusherChannelsOptionsMetadata metadata,
  }) = _HostOptions;

  /// Using this constructor you can set your custom [Uri] providing [uriResolver].
  const factory PusherChannelsOptions.custom({
    required PusherChannelsOptionsCustomUriResolver uriResolver,
    PusherChannelsOptionsMetadata metadata,
  }) = _CustomOptions;
}
