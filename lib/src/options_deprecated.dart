import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:meta/meta.dart';

/// Options provided to [ConnectionDelegate].
/// See:
/// - [PusherChannelOptions.new]
/// - [PusherChannelOptions.ws]
/// - [PusherChannelOptions.wss]
@Deprecated('The class was renamed to [PusherChannelsOptions].')
@immutable
class PusherChannelOptions {
  /// Scheme depending on the security context. For web socket connections they are: `ws` or `wss`.
  final String scheme;

  /// Cluster of your app. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  /// otherwise - the host will be used as it was originally provided.
  final String? cluster;

  /// Port of a server.
  final int? port;

  /// Api key used per application that you may get after registering and creating a project on Pusher.
  /// `Note`: leave it as `null` if you do not have key and provide your custom `path`.
  final String? key;

  /// The package was tested on the versions of Pusher protocol starting from `7`.
  /// It is recommended to keep the version of the protocol on your server up-to-data
  final int protocol;

  /// Version of this library (it influences only on metadata sent to a server). [kDartPusherChannelsLibraryVersion] will be used by default if [version] is not provided.
  final String version;

  /// Host of a server. `Note:` If you provide a cluster, then the [host] will return 'ws-$[cluster].$[_host]',
  final String _host;

  /// Custom path to the Pusher Channels endpoint, used if [key] provided as `null`.
  final String? _path;

  /// Parameters:
  ///
  /// `scheme` - Scheme depending on the security context. For web socket connections they are: `ws` or `wss`.
  ///
  /// `host` - Host of a server. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  ///
  /// `path` - Custom path to the Pusher Channels endpoint, used if `key` provided as `null`.
  /// `Note:`
  /// - If both `key` and `path` are provided as `null` - [path] getter will return `/` (slash).
  /// - It's recommended to provide a path other than the root (`/`) on a server because query parameters will be added to the generated uri.
  /// - Do not set a route that ends with `/` on a server because query parameters will be added to the generated uri.
  ///
  /// `port` - Port of a server.
  ///
  /// `protocol` - The package was tested on the versions of Pusher protocol starting from `7`.
  /// It is recommended to keep the version of the protocol on your server up-to-date.
  ///
  /// `key` - Api key used per application that you may get after registering and creating a project on Pusher.
  /// `Note`: leave it as `null` if you do not have key and provide your custom `path`.
  ///
  /// `version` - Version of this library (it influences only on metadata sent to a server). Default value is [kDartPusherChannelsLibraryVersion].
  ///
  /// `cluster` - Cluster of your app. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  /// otherwise - the host will be used as it was originally provided.
  const PusherChannelOptions(
      {required this.scheme,
      required String host,
      String? path,
      this.cluster,
      required this.port,
      required this.key,
      required this.protocol,
      this.version = kDartPusherChannelsLibraryVersion})
      : _host = host,
        _path = path;

  /// Constructor for  using `ws` scheme
  ///
  /// Parameters:
  ///
  /// `host` - Host of a server. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  ///
  /// `path` - Custom path to the Pusher Channels endpoint, used if [key] provided as `null`.
  /// `Note:`
  /// - If both `key` and `path` are provided as `null` - [path] getter will return `/` (slash).
  /// - It's recommended to provide a path other than the root (`/`) on a server because query parameters will be added to the generated uri.
  /// - Do not set a route that ends with `/` on a server because query parameters will be added to the generated uri.
  ///
  /// `port` - Port of a server.
  ///
  /// `protocol` - The package was tested on the versions of Pusher protocol starting from `7`.
  /// It is recommended to keep the version of the protocol on your server up-to-date.
  ///
  /// `key` - Api key used per application that you may get after registering and creating a project on Pusher.
  /// `Note`: leave it as `null` if you do not have key and provide your custom `path`.
  ///
  /// `version` - Version of this library (it influences only on metadata sent to a server). Default value is [kDartPusherChannelsLibraryVersion].
  ///
  /// `cluster` - Cluster of your app. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  /// otherwise - the host will be used as it was originally provided.
  const PusherChannelOptions.ws({
    String? cluster,
    required int? port,
    required String? key,
    required int protocol,
    String version = kDartPusherChannelsLibraryVersion,
    required String host,
    String? path,
  }) : this(
            scheme: 'ws',
            cluster: cluster,
            host: host,
            port: port,
            key: key,
            protocol: protocol,
            path: path,
            version: version);

  /// Constructor for  using `wss` scheme
  ///
  /// Parameters:
  ///
  /// `host` - Host of a server. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  ///
  /// `path` - Custom path to the Pusher Channels endpoint, used if [key] provided as `null`.
  /// `Note:`
  /// - If both `key` and `path` are provided as `null` - [path] getter will return `/` (slash).
  /// - It's recommended to provide a path other than the root (`/`) on a server because query parameters will be added to the generated uri.
  /// - Do not set a route that ends with `/` on a server because query parameters will be added to the generated uri.
  ///
  /// `port` - Port of a server.
  ///
  /// `protocol` - The package was tested on the versions of Pusher protocol starting from `7`.
  /// It is recommended to keep the version of the protocol on your server up-to-date.
  ///
  /// `key` - Api key used per application that you may get after registering and creating a project on Pusher.
  /// `Note`: leave it as `null` if you do not have key and provide your custom `path`.
  ///
  /// `version` - Version of this library (it influences only on metadata sent to a server). Default value is [kDartPusherChannelsLibraryVersion].
  ///
  /// `cluster` - Cluster of your app. `Note:` If you provide a cluster, then the [host] getter will return 'ws-$[cluster].$[_host]',
  /// otherwise - the host will be used as it was originally provided.
  const PusherChannelOptions.wss({
    String? cluster,
    required int? port,
    required String? key,
    required int protocol,
    String version = kDartPusherChannelsLibraryVersion,
    required String host,
    String? path,
  }) : this(
            scheme: 'wss',
            cluster: cluster,
            host: host,
            port: port,
            key: key,
            path: path,
            protocol: protocol,
            version: version);

  /// If [cluster] is provided - then the given host will be pasted into following domain 'ws-$[cluster].$[_host]', otherwise will be set as it is.
  String get host => cluster == null ? _host : 'ws-$cluster.$_host';

  /// If `path` parameter was provided in any of the constructors - it will be set, otherwise the path will look like '/app/[key]'
  String get path {
    if (key != null) return '/app/$key';
    return _path ?? '/';
  }

  /// Generated uri.
  Uri get uri =>
      Uri(scheme: scheme, host: host, port: port, path: path, queryParameters: {
        'client': _kClient,
        'version': version.toString(),
        'protocol': protocol.toString()
      });
}

const _kClient = 'dart';
