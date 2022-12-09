library pusher_channels_options;

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:meta/meta.dart';

part 'clustered_options.dart';

mixin _QuerySupplyMixin on PusherChannelsOptions {
  String get client => 'dart';
  int get protocol;
  String get version;
  bool get shouldSupplyMetadataQueries;

  @protected
  Map<String, String>? get queryParamters {
    if (!shouldSupplyMetadataQueries) {
      return null;
    }
    return {
      'client': client,
      'version': version,
      'protocol': protocol.toString(),
    };
  }
}

abstract class PusherChannelsOptions {
  Uri get uri;

  const factory PusherChannelsOptions.fromCluster({
    required String scheme,
    required String cluster,
    required String key,
    bool shouldSupplyMetadataQueries,
    String host,
    String version,
    int protocol,
    int? port,
  }) = _ClusteredOptions;
}
