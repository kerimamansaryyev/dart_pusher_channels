import 'dart:typed_data';

import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
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
class PrivateEncryptedChannelAuthorizationData
    implements EndpointAuthorizationData {
  final String authKey;
  final Uint8List sharedSecret;

  const PrivateEncryptedChannelAuthorizationData({
    required this.authKey,
    required this.sharedSecret,
  });
}

/// A data class representing a state
/// of [PrivateEncryptedChannel]'s instances.
@immutable
class PrivateEncryptedChannelState implements ChannelState {
  @override
  final ChannelStatus status;
  @override
  final int? subscriptionCount;

  const PrivateEncryptedChannelState._({
    required this.status,
    required this.subscriptionCount,
  });

  const PrivateEncryptedChannelState.initial()
      : this._(
          status: ChannelStatus.idle,
          subscriptionCount: null,
        );

  PrivateEncryptedChannelState copyWith({
    ChannelStatus? status,
    int? subscriptionCount,
  }) =>
      PrivateEncryptedChannelState._(
        status: status ?? this.status,
        subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      );
}

class PrivateEncryptedChannel extends EndpointAuthorizableChannel<
    PrivateEncryptedChannelState, PrivateEncryptedChannelAuthorizationData> {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;

  @override
  final EndpointAuthorizableChannelAuthorizationDelegate<
      PrivateEncryptedChannelAuthorizationData> authorizationDelegate;

  @override
  final ChannelPublicEventEmitter publicEventEmitter;

  @override
  final String name;

  @override
  final ChannelsManagerStreamGetter publicStreamGetter;

  @internal
  PrivateEncryptedChannel.internal({
    required this.publicStreamGetter,
    required this.publicEventEmitter,
    required this.connectionDelegate,
    required this.name,
    required this.authorizationDelegate,
  });

  /// Unlike the public channels, this channel:
  /// 1. Grabs the authorization data of type [PrivateEncryptedChannelAuthorizationData].
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
      ChannelSubscribeEvent.forPrivateEncryptedChannel(
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
  PrivateEncryptedChannelState getStateWithNewStatus(ChannelStatus status) =>
      _stateIfNull().copyWith(
        status: status,
      );

  @override
  PrivateEncryptedChannelState getStateWithNewSubscriptionCount(
    int? subscriptionCount,
  ) =>
      _stateIfNull().copyWith(
        subscriptionCount: subscriptionCount,
      );

  PrivateEncryptedChannelState _stateIfNull() =>
      state ?? PrivateEncryptedChannelState.initial();
}
