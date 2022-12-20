part of pusher_channels_options;

@immutable
class _HostOptions with PusherChannelsOptions, _QuerySupplyMixin {
  final String scheme;

  final String host;

  final String key;

  final int? port;

  @override
  final PusherChannelsOptionsMetadata metadata;

  @override
  final bool shouldSupplyMetadataQueries;

  const _HostOptions({
    required this.scheme,
    required this.host,
    required this.key,
    this.port,
    this.shouldSupplyMetadataQueries = true,
    this.metadata = const PusherChannelsOptionsMetadata.byDefault(),
  });

  @override
  Uri get uri => Uri(
        scheme: scheme,
        port: port,
        host: host,
        path: _path,
        queryParameters: queryParameters,
      );

  String get _path => '/app/$key';
}
