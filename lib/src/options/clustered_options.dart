part of pusher_channels_options;

@immutable
class _ClusteredOptions with PusherChannelsOptions, _QuerySupplyMixin {
  final String scheme;
  final String host;
  final String cluster;
  final int? port;
  final String key;

  @override
  final PusherChannelsOptionsMetadata metadata;
  @override
  final bool shouldSupplyMetadataQueries;

  const _ClusteredOptions({
    required this.scheme,
    required this.cluster,
    required this.key,
    this.shouldSupplyMetadataQueries = true,
    this.host = kDefaultPusherChannelsHost,
    this.metadata = const PusherChannelsOptionsMetadata.byDefault(),
    this.port,
  });

  @override
  Uri get uri => Uri(
        scheme: scheme,
        port: port,
        host: _host,
        path: _path,
        queryParameters: queryParameters,
      );

  String get _host => 'ws-$cluster.$host';

  String get _path => '/app/$key';
}
