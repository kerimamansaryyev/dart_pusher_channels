import 'package:meta/meta.dart';

import 'connection.dart';

/// Options for [ConnectionDelegate]

@immutable
class PusherChannelOptions {
  /// Host of a server
  final String _host;

  /// Scheme. For example, when using Web socket connection: ws or wss
  final String scheme;
  final String? cluster;

  /// Port of a server
  final int? port;

  /// Paste your API key that you get after registering and creating a project on Pusher
  final String key;

  /// The package was tested on the newer versions of Pusher protocol
  /// It is recommended to keep the version of the protocol on your server up-to-data
  final int protocol;
  final String version;

  const PusherChannelOptions({
    required this.scheme,
    required this.port,
    required this.key,
    required this.protocol,
    required this.version,
    required String host,
    this.cluster,
  }) : _host = cluster == null ? host : 'ws-$cluster.$host';

  const PusherChannelOptions.ws({
    required int? port,
    required String key,
    required int protocol,
    required String version,
    required String host,
    String? cluster,
  }) : this(
          scheme: 'ws',
          cluster: cluster,
          host: host,
          port: port,
          key: key,
          protocol: protocol,
          version: version,
        );

  const PusherChannelOptions.wss({
    required int? port,
    required String key,
    required int protocol,
    required String version,
    required String host,
    String? cluster,
  }) : this(
          scheme: 'wss',
          cluster: cluster,
          host: host,
          port: port,
          key: key,
          protocol: protocol,
          version: version,
        );

  /// Generated uri.
  Uri get uri => Uri(
        scheme: scheme,
        host: _host,
        port: port,
        path: '/app/$key',
        queryParameters: {
          'client': _kClient,
          'version': version.toString(),
          'protocol': protocol.toString()
        },
      );
}

const _kClient = 'dart';
