import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:meta/meta.dart';

/// Authorization data that is expected to subscribe to the private channels.
///
/// See also:
/// - [EndpointAuthorizableChannelAuthorizationDelegate]
/// - [EndpointAuthorizationData]
/// - [EndpointAuthorizableChannel]
@immutable
class PrivateChannelAuthorizationData implements EndpointAuthorizationData {
  final String authKey;

  const PrivateChannelAuthorizationData({
    required this.authKey,
  });
}

/// A data class representing a state
/// of [PrivateChannel]'s instances.
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

/// Private channels require users to authorized to subscribe it.
/// So that's why it extends [EndpointAuthorizableChannel] with
/// [PrivateChannelAuthorizationData] and requires [authorizationDelegate].
///
/// Private channels should be used when access to the channel needs to be restricted in some way. In order for a user to subscribe to a private channel permission must be authorized.
/// The authorization occurs via a HTTP Request to a configurable authorization url when the subscribe method is called with a private- channel name.
///
/// It also allows users to trigger the client events using [trigger] method.
///
/// See also:
/// - [EndpointAuthorizableChannel]
/// - [EndpointAuthorizableChannelAuthorizationDelegate]
/// - [Private Channel docs](https://pusher.com/docs/channels/using_channels/private-channels/)
///
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

  /// Unlike the public channels, this channel:
  /// 1. Grabs the authorization data of type [PrivateChannelAuthorizationData].
  /// 2. Sends the subscription event with the derived data.
  ///
  /// See also:
  /// - [EndpointAuthorizableChannelAuthorizationDelegate]
  /// - [EndpointAuthorizableChannel]
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
