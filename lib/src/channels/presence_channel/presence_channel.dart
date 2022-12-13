import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:meta/meta.dart';

@immutable
class PresenceChannelAuthorizationData implements EndpointAuthorizationData {
  final String authKey;
  final String channelDataEncoded;

  const PresenceChannelAuthorizationData({
    required this.authKey,
    required this.channelDataEncoded,
  });
}

@immutable
class PresenceChannelState implements ChannelState {
  @override
  final ChannelStatus status;

  @override
  final int? subscriptionCount;

  const PresenceChannelState({
    required this.status,
    required this.subscriptionCount,
  });

  PresenceChannelState copyWith({
    ChannelStatus? status,
    int? subscriptionCount,
  }) =>
      PresenceChannelState(
        status: status ?? this.status,
        subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      );
}

class PresenceChannel extends EndpointAuthorizableChannel<PresenceChannelState,
        PresenceChannelAuthorizationData>
    with TriggerableChannelMixin<PresenceChannelState> {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;

  @override
  final EndpointAuthorizableChannelAuthorizationDelegate<
      PresenceChannelAuthorizationData> authorizationDelegate;

  @override
  final String name;

  @override
  final ChannelPublicEventEmitter publicEventEmitter;

  @override
  final ChannelsManagerStreamGetter publicStreamGetter;

  @internal
  PresenceChannel.internal({
    required this.publicStreamGetter,
    required this.publicEventEmitter,
    required this.connectionDelegate,
    required this.name,
    required this.authorizationDelegate,
  });

  @override
  void subscribe() async {
    super.subscribe();
    final fixatedLifeCycleCount = startNewAuthRequestCycle();
    await setAuthKeyFromDelegate();
    final currentAuthKey = authData?.authKey;
    final currentChannelDataEncoded = authData?.channelDataEncoded;
    if (fixatedLifeCycleCount < authRequestCycle ||
        currentAuthKey == null ||
        state?.status == ChannelStatus.unsubscribed ||
        currentChannelDataEncoded == null) {
      return;
    }
    connectionDelegate.sendEvent(
      ChannelSubscribeEvent.forPresenceChannel(
        channelName: name,
        authKey: currentAuthKey,
        channelDataEncoded: currentChannelDataEncoded,
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
    super.unsubscribe();
  }

  @override
  PresenceChannelState getStateWithNewStatus(ChannelStatus status) =>
      state?.copyWith(
        status: status,
      ) ??
      PresenceChannelState(
        status: status,
        subscriptionCount: null,
      );

  @override
  PresenceChannelState getStateWithNewSubscriptionCount(
    int? subscriptionCount,
  ) =>
      state?.copyWith(
        subscriptionCount: subscriptionCount,
      ) ??
      PresenceChannelState(
        status: ChannelStatus.idle,
        subscriptionCount: subscriptionCount,
      );

  @override
  void handleEvent(ChannelReadEvent event) {
    super.handleEvent(event);
    if (!canHandleEvent(event)) {
      return;
    }
    //TODO: hadnle presence there
  }
}
