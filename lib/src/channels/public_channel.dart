import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';

@immutable
class PublicChannelState implements ChannelState {
  @override
  final ChannelStatus status;

  const PublicChannelState({
    required this.status,
  });
}

class PublicChannel extends Channel<PublicChannelState>
    with ChannelHandledSubscriptionMixin {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;
  @override
  final ChannelStateChangedCallback<PublicChannelState>?
      whenChannelStateChanged;

  @override
  final String name;

  PublicChannel.internal({
    required this.connectionDelegate,
    required this.name,
    required this.whenChannelStateChanged,
  });

  @override
  void subscribe() {
    ensureStatusIdleBeforeSubscribe();
    connectionDelegate.sendEvent(
      ChannelSubscribeEvent(
        channelName: name,
      ),
    );
  }

  @override
  void unsubscribe() {
    connectionDelegate.sendEvent(
      ChannelUnsubscribeEvent(
        channelName: name,
      ),
    );
    setUnsubscribedStatus();
  }

  @override
  PublicChannelState getStateWithNewStatus(ChannelStatus status) =>
      PublicChannelState(
        status: status,
      );

  @override
  void handleEvent(PusherChannelsReadEvent event) {
    detectIfSubscriptionSucceeded(event);
  }
}
