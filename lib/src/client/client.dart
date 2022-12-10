import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/connection/websocket_connection.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class PusherChannelsClient {
  @protected
  final PusherChannelsClientLifeCycleController controller;
  @protected
  final ChannelsManager channelsManager;

  PusherChannelsClient._({
    required this.controller,
    required this.channelsManager,
  });

  factory PusherChannelsClient._baseWithConnection({
    required Duration? activityDurationOverride,
    required Duration defaultActivityDuration,
    required Duration waitForPongDuration,
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    required Duration minimReconnectDelayDuration,
  }) {
    late final PusherChannelsClient client;

    final controller = PusherChannelsClientLifeCycleController(
      minimumReconnectDuration: minimReconnectDelayDuration,
      externalEventHandler: (event) => client._handleEvent(event),
      activityDurationOverride: activityDurationOverride,
      waitForPongDuration: waitForPongDuration,
      defaultActivityDuration: defaultActivityDuration,
      connectionDelegate: connectionDelegate,
      connectionErrorHandler: connectionErrorHandler,
    );

    final channelsManager = ChannelsManager(
      channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
        sendEventDelegate: (event) => client.sendEvent(event),
        eventStreamGetter: () => client.eventStream,
      ),
    );

    return client = PusherChannelsClient._(
      controller: controller,
      channelsManager: channelsManager,
    );
  }

  factory PusherChannelsClient.custom({
    required PusherChannelsConnectionDelegate connectionDelegate,
    required PusherChannelsClientLifeCycleConnectionErrorHandler
        connectionErrorHandler,
    Duration minimReconnectDelayDuration = const Duration(seconds: 1),
    Duration defaultActivityDuration = kPusherChannelsDefaultActivityDuration,
    Duration? activityDurationOverride,
    Duration waitForPongDuration = kPusherChannelsDefaultWaitForPongDuration,
  }) =>
      PusherChannelsClient._baseWithConnection(
        minimReconnectDelayDuration: minimReconnectDelayDuration,
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
    Duration minimReconnectDelayDuration = const Duration(seconds: 1),
    Duration defaultActivityDuration = kPusherChannelsDefaultActivityDuration,
    Duration? activityDurationOverride,
    Duration waitForPongDuration = kPusherChannelsDefaultWaitForPongDuration,
  }) =>
      PusherChannelsClient._baseWithConnection(
        minimReconnectDelayDuration: minimReconnectDelayDuration,
        waitForPongDuration: waitForPongDuration,
        activityDurationOverride: activityDurationOverride,
        defaultActivityDuration: defaultActivityDuration,
        connectionDelegate: () => PusherChannelsWebSocketConnection(
          uri: options.uri,
        ),
        connectionErrorHandler: connectionErrorHandler,
      );

  PublicChannel publicChannel(
    String channelName, {
    ChannelStateChangedCallback<PublicChannelState>? whenChannelStateChanged,
  }) =>
      channelsManager.publicChannel(
        channelName,
        whenChannelStateChanged: whenChannelStateChanged,
      );

  Stream<PusherChannelsEvent> get eventStream => controller.eventStream;

  Stream<PusherChannelsErrorEvent> get pusherErrorEventStream =>
      eventStream.whereType<PusherChannelsErrorEvent>();

  Stream<PusherChannelsClientLifeCycleState> get lifecycleStream =>
      controller.lifecycleStream;

  Stream<void> get onConnectionEstablished => lifecycleStream
      .where(
        (event) =>
            event == PusherChannelsClientLifeCycleState.establishedConnection,
      )
      .map(voidStreamMapper);

  Future<void> connect() => controller.connectSafely();

  Future<void> disconnect() => controller.disconnectSafely();

  void trigger(PusherChannelsTriggerEvent event) => controller.triggerEvent(
        event,
      );

  void sendEvent(PusherChannelsSentEventMixin event) =>
      controller.sendEvent(event);

  void reconnect() => controller.reconnectSafely();

  void dispose() {
    controller.dispose();
    channelsManager.dispose();
  }

  void _handleEvent(PusherChannelsEvent event) {
    channelsManager.handleEvent(event);
  }
}
