import 'package:dart_pusher_channels/src/connection/websocket_connection.dart';
import 'package:dart_pusher_channels/src/controller.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:meta/meta.dart';

class PusherChannelsClient {
  final PusherChannelsOptions options;
  @protected
  final PusherChannelsClientConnectionLifeCycleController controller;

  PusherChannelsClient._({
    required this.options,
    required this.controller,
  });

  PusherChannelsClient.websocket({
    required PusherChannelsOptions options,
  }) : this._(
          options: options,
          controller: PusherChannelsClientConnectionLifeCycleController(
            connectionDelegate: () => PusherChannelsWebSocketConnection(
              uri: options.uri,
            ),
          ),
        );

  PusherChannelsClient.custom({
    required PusherChannelsOptions options,
    required PusherChannelsConnectionDelegate connectionDelegate,
  }) : this._(
          options: options,
          controller: PusherChannelsClientConnectionLifeCycleController(
            connectionDelegate: connectionDelegate,
          ),
        );
}
