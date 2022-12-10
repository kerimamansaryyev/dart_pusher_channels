import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/events/event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

typedef ChannelsManagerSendEventDelegate = void Function(
  PusherChannelsSentEventMixin event,
);

typedef ChannelsManagerEventStreamGetter = Stream<PusherChannelsEvent>
    Function();

typedef _ChannelConstructorDelegate<T extends Channel> = T Function();

class ChannelsManagerConnectionDelegate {
  @protected
  final ChannelsManagerEventStreamGetter eventStreamGetter;
  @protected
  final ChannelsManagerSendEventDelegate sendEventDelegate;

  const ChannelsManagerConnectionDelegate({
    required this.sendEventDelegate,
    required this.eventStreamGetter,
  });

  Stream<PusherChannelsEvent> get eventStream => eventStreamGetter();

  void sendEvent(PusherChannelsSentEventMixin event) =>
      sendEventDelegate(event);
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
