import 'dart:async';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_encrypted_channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:dart_pusher_channels/src/exception/exception.dart';
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

/// Appears to be a delegate between an instance
/// of [PusherChannelsClient] and [ChannelsManager].
class ChannelsManagerConnectionDelegate {
  /// Called by an instance of [TriggerableChannelMixin] to send an event.
  @protected
  final ChannelsManagerSendEventDelegate sendEventDelegate;

  /// Called by an instance of [Channel] to send the subscription event.
  @protected
  final ChannelsManagerSocketIdGetter socketIdGetter;

  /// Called by an instance of [TriggerableChannelMixin] to trigger an event.
  @protected
  final ChannelsManagerTriggerEventDelegate triggerEventDelegate;

  const ChannelsManagerConnectionDelegate({
    required this.sendEventDelegate,
    required this.socketIdGetter,
    required this.triggerEventDelegate,
  });

  /// Calling [socketIdGetter]
  String? get socketId => socketIdGetter();

  /// Calling [sendEventDelegate]
  void sendEvent(PusherChannelsSentEventMixin event) =>
      sendEventDelegate(event);

  /// Calling [triggerEventDelegate]
  void triggerEvent(PusherChannelsTriggerEvent event) =>
      triggerEventDelegate(event);
}

/// Delegates creation of instances of [Channel].
///
/// Takes events from [PusherChannelsClientLifeCycleController] through an instance
/// of [PusherChannelsClient] and handles the events by respective channels.
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

  /// Creates and saves public channel under the key respective to [channelName].
  ///
  /// Returns an existing instance if any.
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

  /// Creates and saves private channel under the key respective to [channelName].
  ///
  /// Returns an existing instance if any.
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

  /// Creates and saves private encrypted channel under the key respective to [channelName].
  ///
  /// Returns an existing instance if any.
  PrivateEncryptedChannel privateEncryptedChannel(
    String channelName, {
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateEncryptedChannelAuthorizationData>
        authorizationDelegate,
    required bool forceCreateNewInstance,
    required PrivateEncryptedChannelEventDataEncodeDelegate
        eventDataEncodeDelegate,
  }) =>
      _createChannelSafely<PrivateEncryptedChannel>(
        channelName: channelName,
        forceCreateNewInstance: forceCreateNewInstance,
        constructorDelegate: () => PrivateEncryptedChannel.internal(
          eventDataEncodeDelegate: eventDataEncodeDelegate,
          authorizationDelegate: authorizationDelegate,
          connectionDelegate: channelsConnectionDelegate,
          publicStreamGetter: () => _publicStreamController.stream,
          name: channelName,
          publicEventEmitter: _exposedPublicEventsStreamEmit,
        ),
      );

  /// Creates and saves presence channel under the key respective to [channelName].
  ///
  /// Returns an existing instance if any.
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

  /// Creates a channel of type [T] using [constructorDelegate].
  ///
  /// If the last recorded channel with [channelName] still matches [T
  /// type bounds - then it will be returned.
  ///
  /// If requested [T] is different from the last recorded channel in
  /// [_channelsMap] or [forceCreateNewInstance] is `true`
  /// - then a new instance of [T] will be created.
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
      _channelsMap[channelName] = constructorDelegate();
    }
    return (_channelsMap[channelName] ??= constructorDelegate()) as T;
  }

  /// Destroys this instance, clears [_channelsMap] and closes [_publicStreamController]
  /// making this instance
  /// unusable.
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
