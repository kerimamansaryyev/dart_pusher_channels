import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/client/pong_observer.dart';
import 'package:dart_pusher_channels/src/connection/websocket_connection.dart';
import 'package:dart_pusher_channels/src/options/options.dart';

import 'package:meta/meta.dart';

class PusherChannelsClient {
  @protected
  final PusherChannelsClientLifeCycleController controller;

  PusherChannelsClient._({
    required this.controller,
  });

  factory PusherChannelsClient._baseWithConnection({
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
  }) {
    late PusherChannelsClientLifeCycleController controller;

    controller = PusherChannelsClientLifeCycleController(
      connectionDelegate: connectionDelegate,
      connectionErrorHandler: connectionErrorHandler,
      observersDelegate: (interactionInterface) => [
        PusherChannelsClientPongLifeCycleObserver(
          interactionInterface: interactionInterface,
        )
      ],
    );

    return PusherChannelsClient._(
      controller: controller,
    );
  }

  factory PusherChannelsClient.custom({
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
  }) =>
      PusherChannelsClient._baseWithConnection(
        connectionDelegate: connectionDelegate,
        connectionErrorHandler: connectionErrorHandler,
      );

  factory PusherChannelsClient.websocket({
    required PusherChannelsOptions options,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
  }) =>
      PusherChannelsClient._baseWithConnection(
        connectionDelegate: () => PusherChannelsWebSocketConnection(
          uri: options.uri,
        ),
        connectionErrorHandler: connectionErrorHandler,
      );

  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      controller.lifecycleStream;

  Future<void> connect() => controller.connectSafely();

  Future<void> disconnect() => controller.disconnectSafely();

  void reconnect() => controller.reconnectSafely();

  void dispose() {
    controller.dispose();
  }
}
