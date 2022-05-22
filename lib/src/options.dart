import 'package:meta/meta.dart';
import 'connection.dart';

/// Options for [ConnectionDelegate]

@immutable
class PusherChannelOptions {
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

  /// Host of a server
  final String _host;

  const PusherChannelOptions(
      {required this.scheme,
      required String host,
      this.cluster,
      required this.port,
      required this.key,
      required this.protocol,
      required this.version})
      : _host = cluster == null ? host : 'ws-$cluster.$host';

  const PusherChannelOptions.ws({
    String? cluster,
    required int? port,
    required String key,
    required int protocol,
    required String version,
    required String host,
  }) : this(
            scheme: 'ws',
            cluster: cluster,
            host: host,
            port: port,
            key: key,
            protocol: protocol,
            version: version);

  const PusherChannelOptions.wss({
    String? cluster,
    required int? port,
    required String key,
    required int protocol,
    required String version,
    required String host,
  }) : this(
            scheme: 'wss',
            cluster: cluster,
            host: host,
            port: port,
            key: key,
            protocol: protocol,
            version: version);

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
          });
}

const _kClient = 'dart';
