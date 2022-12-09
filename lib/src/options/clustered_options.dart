part of pusher_channels_options;

class _ClusteredOptions with PusherChannelsOptions, _QuerySupplyMixin {
  final String scheme;
  final String host;
  final String cluster;
  final int? port;
  final String key;
  @override
  final int protocol;
  @override
  final String version;
  @override
  final bool shouldSupplyMetadataQueries;

  const _ClusteredOptions({
    required this.scheme,
    required this.cluster,
    required this.key,
    this.shouldSupplyMetadataQueries = true,
    this.host = kDefaultPusherChannelsHost,
    this.version = kDartPusherChannelsLibraryVersion,
    this.protocol = kLatestAvailablePusherProtocol,
    this.port,
  });

  @override
  Uri get uri => Uri(
        scheme: scheme,
        port: port,
        host: _host,
        path: _path,
        queryParameters: queryParamters,
      );

  String get _host => 'ws-$cluster.$host';

  String get _path => '/app/$key';
}
