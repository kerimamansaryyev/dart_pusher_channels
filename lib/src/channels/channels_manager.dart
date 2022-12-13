import 'dart:async';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/exceptions/exception.dart';
import 'package:meta/meta.dart';

class ChannelsManagerHasBeenDisposedException
    implements PusherChannelsException {
  @override
  final String message = 'ChannelsManager has been disposed';

  const ChannelsManagerHasBeenDisposedException();
}

typedef ChannelPublicEventEmitter = void Function(
  ChannelReadEvent event,
);

typedef ChannelsManagerSendEventDelegate = void Function(
  PusherChannelsSentEventMixin event,
);

typedef ChannelsManagerTriggerEventDelegate = void Function(
  PusherChannelsTriggerEvent event,
);

typedef ChannelsManagerSocketIdGetter = String? Function();

typedef _ChannelConstructorDelegate<T extends Channel> = T Function();

class ChannelsManagerConnectionDelegate {
  @protected
  final ChannelsManagerSendEventDelegate sendEventDelegate;
  @protected
  final ChannelsManagerSocketIdGetter socketIdGetter;
  @protected
  final ChannelsManagerTriggerEventDelegate triggerEventDelegate;

  const ChannelsManagerConnectionDelegate({
    required this.sendEventDelegate,
    required this.socketIdGetter,
    required this.triggerEventDelegate,
  });

  String? get socketId => socketIdGetter();

  void sendEvent(PusherChannelsSentEventMixin event) =>
      sendEventDelegate(event);

  void triggerEvent(PusherChannelsTriggerEvent event) =>
      triggerEventDelegate(event);
}

class ChannelsManager {
  bool _isDisposed = false;
  final StreamController<ChannelReadEvent> _publicStreamController =
      StreamController.broadcast();
  final Map<String, Channel> _channelsMap = {};
  @protected
  final ChannelsManagerConnectionDelegate channelsConnectionDelegate;

  ChannelsManager({
    required this.channelsConnectionDelegate,
  });

  void handleEvent(PusherChannelsEvent event) {
    if (_isDisposed) {
      return;
    }
    if (event is! PusherChannelsReadEvent) {
      return;
    }
    final channelName = event.channelName;
    if (channelName == null) {
      return;
    }
    final foundChannel = _channelsMap[channelName];
    if (foundChannel != null) {
      foundChannel.handleEvent(
        ChannelReadEvent.fromPusherChannelsReadEvent(foundChannel, event),
      );
    }
  }

  void _tryRestoreChannelSubscription(Channel channel, ChannelStatus? status) {
    if (_isDisposed) {
      return;
    }
    switch (status) {
      case ChannelStatus.subscribed:
        channel.subscribe();
        break;
      case ChannelStatus.unsubscribed:
      case ChannelStatus.idle:
      default:
        return;
    }
  }

  PublicChannel publicChannel(
    String channelName, {
    required bool forceCreateNewInstance,
  }) =>
      _createChannelSafely<PublicChannel>(
        channelName: channelName,
        forceCreateNewInstance: forceCreateNewInstance,
        constructorDelegate: () => PublicChannel.internal(
          connectionDelegate: channelsConnectionDelegate,
          publicStreamGetter: () => _publicStreamController.stream,
          name: channelName,
          publicEventEmitter: _exposedPublicEventsStreamEmit,
        ),
      );

  PrivateChannel privateChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData>
        authorizationDelegate,
    required bool forceCreateNewInstance,
  }) =>
      _createChannelSafely<PrivateChannel>(
        channelName: channelName,
        forceCreateNewInstance: forceCreateNewInstance,
        constructorDelegate: () => PrivateChannel.internal(
          authorizationDelegate: authorizationDelegate,
          connectionDelegate: channelsConnectionDelegate,
          publicStreamGetter: () => _publicStreamController.stream,
          name: channelName,
          publicEventEmitter: _exposedPublicEventsStreamEmit,
        ),
      );

  PresenceChannel presenceChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PresenceChannelAuthorizationData>
        authorizationDelegate,
    required bool forceCreateNewInstance,
  }) =>
      _createChannelSafely<PresenceChannel>(
        channelName: channelName,
        forceCreateNewInstance: forceCreateNewInstance,
        constructorDelegate: () => PresenceChannel.internal(
          authorizationDelegate: authorizationDelegate,
          connectionDelegate: channelsConnectionDelegate,
          publicStreamGetter: () => _publicStreamController.stream,
          name: channelName,
          publicEventEmitter: _exposedPublicEventsStreamEmit,
        ),
      );

  T _createChannelSafely<T extends Channel>({
    required String channelName,
    required _ChannelConstructorDelegate<T> constructorDelegate,
    required bool forceCreateNewInstance,
  }) {
    if (_isDisposed) {
      throw const ChannelsManagerHasBeenDisposedException();
    }
    final foundChannel = _channelsMap[channelName];
    if (foundChannel == null) {
      return _channelsMap[channelName] = constructorDelegate();
    }
    if (foundChannel.runtimeType != T || forceCreateNewInstance) {
      final previousStatus = foundChannel.state?.status;
      _tryRestoreChannelSubscription(
        _channelsMap[channelName] = constructorDelegate(),
        previousStatus,
      );
    }
    return (_channelsMap[channelName] ??= constructorDelegate()) as T;
  }

  void dispose() {
    if (_isDisposed) {
      throw const ChannelsManagerHasBeenDisposedException();
    }
    _isDisposed = true;
    for (final channel in _channelsMap.values) {
      channel.unsubscribe();
    }
    _channelsMap.clear();
    _publicStreamController.close();
  }

  void _exposedPublicEventsStreamEmit(ChannelReadEvent event) {
    if (_isDisposed) {
      return;
    }

    _publicStreamController.add(event);
  }
}
