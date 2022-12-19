import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:meta/meta.dart';

/// A data class implementing [ChannelState] and representing
/// a state of an instance of [PublicChannel].
@immutable
class PublicChannelState implements ChannelState {
  @override
  final ChannelStatus status;
  @override
  final int? subscriptionCount;

  const PublicChannelState({
    required this.status,
    required this.subscriptionCount,
  });

  PublicChannelState copyWith({
    ChannelStatus? status,
    int? subscriptionCount,
  }) =>
      PublicChannelState(
        status: status ?? this.status,
        subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      );
}

/// Public channels should be used for publicly accessible data as they do not require any form of authorization in order to be subscribed to.
///
/// You can subscribe and unsubscribe from channels at any time. There’s no need to wait for the Channels to finish connecting first.
///
/// See for more details: [Public Channels docs](https://pusher.com/docs/channels/using_channels/public-channels/).
class PublicChannel extends Channel<PublicChannelState> {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;

  @override
  final String name;
  @override
  final ChannelPublicEventEmitter publicEventEmitter;

  @override
  final ChannelsManagerStreamGetter publicStreamGetter;

  @internal
  PublicChannel.internal({
    required this.publicStreamGetter,
    required this.connectionDelegate,
    required this.name,
    required this.publicEventEmitter,
  });

  /// Sends the subscription event through the [connectionDelegate].
  @override
  void subscribe() {
    super.subscribe();
    connectionDelegate.sendEvent(
      ChannelSubscribeEvent.forPublicChannel(
        channelName: name,
      ),
    );
  }

  /// Sends the unsubscription event through the [connectionDelegate].
  @override
  void unsubscribe() {
    connectionDelegate.sendEvent(
      ChannelUnsubscribeEvent(
        channelName: name,
      ),
    );
    super.unsubscribe();
  }

  @override
  PublicChannelState getStateWithNewStatus(ChannelStatus status) =>
      state?.copyWith(
        status: status,
      ) ??
      PublicChannelState(
        status: status,
        subscriptionCount: null,
      );

  @override
  PublicChannelState getStateWithNewSubscriptionCount(
    int? subscriptionCount,
  ) =>
      state?.copyWith(
        subscriptionCount: subscriptionCount,
      ) ??
      PublicChannelState(
        status: ChannelStatus.idle,
        subscriptionCount: subscriptionCount,
      );
}
