library pusher_channels_options;

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:meta/meta.dart';

part 'clustered_options.dart';
part 'host_options.dart';
part 'custom_options.dart';

typedef PusherChannelsOptionsCustomUriResolver = Uri Function(
  PusherChannelsOptionsMetadata metadata,
);

mixin _QuerySupplyMixin on PusherChannelsOptions {
  PusherChannelsOptionsMetadata get metadata;
  bool get shouldSupplyMetadataQueries;

  @protected
  Map<String, String>? get queryParameters {
    if (!shouldSupplyMetadataQueries) {
      return null;
    }
    return metadata.getQueryParameters();
  }
}

@immutable
class PusherChannelsOptionsMetadata {
  final String client;
  final int protocol;
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

  Map<String, String> getQueryParameters() => {
        'client': client,
        'version': version,
        'protocol': protocol.toString(),
      };
}

@immutable
abstract class PusherChannelsOptions {
  Uri get uri;

  const factory PusherChannelsOptions.fromCluster({
    required String scheme,
    required String cluster,
    required String key,
    bool shouldSupplyMetadataQueries,
    String host,
    int? port,
    PusherChannelsOptionsMetadata metadata,
  }) = _ClusteredOptions;

  const factory PusherChannelsOptions.fromHost({
    required String scheme,
    required String host,
    required String key,
    int? port,
    bool shouldSupplyMetadataQueries,
    PusherChannelsOptionsMetadata metadata,
  }) = _HostOptions;

  const factory PusherChannelsOptions.custom({
    required PusherChannelsOptionsCustomUriResolver uriResolver,
    PusherChannelsOptionsMetadata metadata,
  }) = _CustomOptions;
}
