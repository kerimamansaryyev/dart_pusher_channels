import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';
import 'package:meta/meta.dart';

typedef ChannelsManagerSendEventDelegate = void Function(
  PusherChannelsSentEventMixin event,
);

typedef ChannelsManagerTriggerEventDelegate = void Function(
  PusherChannelsTriggerEvent event,
);

typedef ChannelsManagerEventStreamGetter = Stream<PusherChannelsEvent>
    Function();
typedef ChannelsManagerSocketIdGetter = String? Function();

typedef _ChannelConstructorDelegate<T extends Channel> = T Function();

class ChannelsManagerConnectionDelegate {
  @protected
  final ChannelsManagerEventStreamGetter eventStreamGetter;
  @protected
  final ChannelsManagerSendEventDelegate sendEventDelegate;
  @protected
  final ChannelsManagerSocketIdGetter socketIdGetter;
  @protected
  final ChannelsManagerTriggerEventDelegate triggerEventDelegate;

  const ChannelsManagerConnectionDelegate({
    required this.sendEventDelegate,
    required this.eventStreamGetter,
    required this.socketIdGetter,
    required this.triggerEventDelegate,
  });

  Stream<PusherChannelsEvent> get eventStream => eventStreamGetter();

  String? get socketId => socketIdGetter();

  void sendEvent(PusherChannelsSentEventMixin event) =>
      sendEventDelegate(event);

  void triggerEvent(PusherChannelsTriggerEvent event) =>
      triggerEventDelegate(event);
}

class ChannelsManager {
  final Map<String, Channel> _channelsMap = {};
  @protected
  final ChannelsManagerConnectionDelegate channelsConnectionDelegate;

  ChannelsManager({
    required this.channelsConnectionDelegate,
  });

  void handleEvent(PusherChannelsEvent event) {
    if (event is! PusherChannelsReadEvent) {
      return;
    }
    final channelName = event.channelName;
    if (channelName == null) {
      return;
    }
    final foundChannel = _channelsMap[channelName];
    if (foundChannel != null) {
      foundChannel.handleEvent(event);
    }
  }

  void _tryRestoreChannelSubscription(Channel channel, ChannelStatus? status) {
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
    required ChannelStateChangedCallback<PublicChannelState>?
        whenChannelStateChanged,
  }) =>
      _createChannelSafely<PublicChannel>(
        channelName: channelName,
        constructorDelegate: () => PublicChannel.internal(
          connectionDelegate: channelsConnectionDelegate,
          name: channelName,
          whenChannelStateChanged: whenChannelStateChanged,
        ),
      );

  PrivateChannel privateChannel(
    String channelName, {
    required ChannelStateChangedCallback<PrivateChannelState>?
        whenChannelStateChanged,
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData>
        authorizationDelegate,
    required EndpointAuthorizationErrorCallback? onAuthFailed,
  }) =>
      _createChannelSafely<PrivateChannel>(
        channelName: channelName,
        constructorDelegate: () => PrivateChannel.internal(
          authorizationDelegate: authorizationDelegate,
          connectionDelegate: channelsConnectionDelegate,
          name: channelName,
          whenChannelStateChanged: whenChannelStateChanged,
          onAuthFailed: onAuthFailed,
        ),
      );

  PresenceChannel presenceChannel(
    String channelName, {
    required ChannelStateChangedCallback<PresenceChannelState>?
        whenChannelStateChanged,
    required EndpointAuthorizableChannelAuthorizationDelegate<
            PresenceChannelAuthorizationData>
        authorizationDelegate,
    required EndpointAuthorizationErrorCallback? onAuthFailed,
  }) =>
      _createChannelSafely<PresenceChannel>(
        channelName: channelName,
        constructorDelegate: () => PresenceChannel.internal(
          authorizationDelegate: authorizationDelegate,
          connectionDelegate: channelsConnectionDelegate,
          name: channelName,
          whenChannelStateChanged: whenChannelStateChanged,
          onAuthFailed: onAuthFailed,
        ),
      );

  T _createChannelSafely<T extends Channel>({
    required String channelName,
    required _ChannelConstructorDelegate<T> constructorDelegate,
  }) {
    final foundChannel = _channelsMap[channelName];
    if (foundChannel == null) {
      return _channelsMap[channelName] = constructorDelegate();
    }
    if (foundChannel.runtimeType != T) {
      final previousStatus = foundChannel.state?.status;
      _tryRestoreChannelSubscription(
        _channelsMap[channelName] = constructorDelegate(),
        previousStatus,
      );
    }
    return (_channelsMap[channelName] ??= constructorDelegate()) as T;
  }

  void dispose() {
    for (final channel in _channelsMap.values) {
      channel.unsubscribe();
    }
    _channelsMap.clear();
  }
}
