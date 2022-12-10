import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/connection/websocket_connection.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/options/options.dart';

import 'package:meta/meta.dart';

class PusherChannelsClient {
  @protected
  final PusherChannelsClientLifeCycleController controller;

  PusherChannelsClient._({
    required this.controller,
  });

  factory PusherChannelsClient._baseWithConnection({
    required Duration? activityDurationOverride,
    required Duration defaultActivityDuration,
    required Duration waitForPongDuration,
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
  }) {
    late PusherChannelsClientLifeCycleController controller;

    controller = PusherChannelsClientLifeCycleController(
      activityDurationOverride: activityDurationOverride,
      waitForPongDuration: waitForPongDuration,
      defaultActivityDuration: defaultActivityDuration,
      connectionDelegate: connectionDelegate,
      connectionErrorHandler: connectionErrorHandler,
    );

    return PusherChannelsClient._(
      controller: controller,
    );
  }

  factory PusherChannelsClient.custom({
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    Duration defaultActivityDuration = kPusherChannelsDefaultActivityDuration,
    Duration? activityDurationOverride,
    Duration waitForPongDuration = kPusherChannelsDefaultWaitForPongDuration,
  }) =>
      PusherChannelsClient._baseWithConnection(
        waitForPongDuration: waitForPongDuration,
        activityDurationOverride: activityDurationOverride,
        defaultActivityDuration: defaultActivityDuration,
        connectionDelegate: connectionDelegate,
        connectionErrorHandler: connectionErrorHandler,
      );

  factory PusherChannelsClient.websocket({
    required PusherChannelsOptions options,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    Duration defaultActivityDuration = kPusherChannelsDefaultActivityDuration,
    Duration? activityDurationOverride,
    Duration waitForPongDuration = kPusherChannelsDefaultWaitForPongDuration,
  }) =>
      PusherChannelsClient._baseWithConnection(
        waitForPongDuration: waitForPongDuration,
        activityDurationOverride: activityDurationOverride,
        defaultActivityDuration: defaultActivityDuration,
        connectionDelegate: () => PusherChannelsWebSocketConnection(
          uri: options.uri,
        ),
        connectionErrorHandler: connectionErrorHandler,
      );

  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      controller.lifecycleStream;

  Future<void> connect() => controller.connectSafely();

  Future<void> disconnect() => controller.disconnectSafely();

  void trigger(PusherChannelsTriggerEvent event) => controller.triggerEvent(
        event,
      );

  void reconnect() => controller.reconnectSafely();

  void dispose() {
    controller.dispose();
  }
}
