import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/connection/websocket_connection.dart';
import 'package:dart_pusher_channels/src/events/error_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/exceptions/exception.dart';
import 'package:dart_pusher_channels/src/options/options.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class PusherChannelsClientDisposedException implements PusherChannelsException {
  @override
  String get message =>
      'The instance of PusherChannelsClient is disposed and can\'t be reused. Please, try to create a new instance.';

  const PusherChannelsClientDisposedException();
}

class PusherChannelsClient {
  bool _isDisposed = false;
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
        triggerEventDelegate: (event) => client.trigger(event),
        socketIdGetter: () => client.controller.socketId,
        sendEventDelegate: (event) => client.sendEvent(event),
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
    bool forceCreateNewInstance = false,
  }) {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return channelsManager.publicChannel(
      channelName,
      forceCreateNewInstance: forceCreateNewInstance,
    );
  }

  PrivateChannel privateChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData>
        authorizationDelegate,
    bool forceCreateNewInstance = false,
  }) {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return channelsManager.privateChannel(
      channelName,
      authorizationDelegate: authorizationDelegate,
      forceCreateNewInstance: forceCreateNewInstance,
    );
  }

  PresenceChannel presenceChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PresenceChannelAuthorizationData>
        authorizationDelegate,
    bool forceCreateNewInstance = false,
  }) {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return channelsManager.presenceChannel(
      channelName,
      authorizationDelegate: authorizationDelegate,
      forceCreateNewInstance: forceCreateNewInstance,
    );
  }

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

  Future<void> connect() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return controller.connectSafely();
  }

  Future<void> disconnect() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    return controller.disconnectSafely();
  }

  @internal
  void trigger(PusherChannelsTriggerEvent event) {
    if (_isDisposed) {
      return;
    }
    controller.triggerEvent(
      event,
    );
  }

  @internal
  void sendEvent(PusherChannelsSentEventMixin event) {
    if (_isDisposed) {
      return;
    }
    controller.sendEvent(event);
  }

  void reconnect() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    controller.reconnectSafely();
  }

  void dispose() {
    if (_isDisposed) {
      throw const PusherChannelsClientDisposedException();
    }
    _isDisposed = true;
    controller.dispose();
    channelsManager.dispose();
  }

  void _handleEvent(PusherChannelsEvent event) {
    if (_isDisposed) {
      return;
    }
    channelsManager.handleEvent(event);
  }
}
