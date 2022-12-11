import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:meta/meta.dart';

@immutable
class PrivateChannelAuthorizationData implements EndpointAuthorizationData {
  final String authKey;

  const PrivateChannelAuthorizationData({
    required this.authKey,
  });
}

@immutable
class PrivateChannelState implements ChannelState {
  @override
  final ChannelStatus status;
  @override
  final int? subscriptionCount;

  const PrivateChannelState({
    required this.status,
    required this.subscriptionCount,
  });

  PrivateChannelState copyWith({
    ChannelStatus? status,
    int? subscriptionCount,
  }) =>
      PrivateChannelState(
        status: status ?? this.status,
        subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      );
}

class PrivateChannel extends EndpointAuthorizableChannel<PrivateChannelState,
        PrivateChannelAuthorizationData>
    with TriggerableChannelMixin<PrivateChannelState> {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;

  @override
  final EndpointAuthorizableChannelAuthorizationDelegate<
      PrivateChannelAuthorizationData> authorizationDelegate;

  @override
  final ChannelPublicEventEmitter publicEventEmitter;

  @override
  final String name;

  @override
  final ChannelsManagerStreamGetter publicStreamGetter;

  @internal
  PrivateChannel.internal({
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
    if (fixatedLifeCycleCount < authRequestCycle ||
        currentAuthKey == null ||
        state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    connectionDelegate.sendEvent(
      ChannelSubscribeEvent.forPrivateChannel(
        channelName: name,
        authKey: currentAuthKey,
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
  PrivateChannelState getStateWithNewStatus(ChannelStatus status) =>
      state?.copyWith(
        status: status,
      ) ??
      PrivateChannelState(
        status: status,
        subscriptionCount: null,
      );

  @override
  PrivateChannelState getStateWithNewSubscriptionCount(
    int? subscriptionCount,
  ) =>
      state?.copyWith(
        subscriptionCount: subscriptionCount,
      ) ??
      PrivateChannelState(
        status: ChannelStatus.idle,
        subscriptionCount: subscriptionCount,
      );
}
