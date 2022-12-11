import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
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

  const PrivateChannelState({
    required this.status,
  });
}

class PrivateChannel extends EndpointAuthorizableChannel<PrivateChannelState,
        PrivateChannelAuthorizationData>
    with
        ChannelHandledSubscriptionMixin<PrivateChannelState>,
        TriggerableChannelMixin<PrivateChannelState> {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;
  @override
  final ChannelStateChangedCallback<PrivateChannelState>?
      whenChannelStateChanged;
  @override
  final EndpointAuthorizableChannelAuthorizationDelegate<
      PrivateChannelAuthorizationData> authorizationDelegate;

  @override
  final EndpointAuthorizationErrorCallback? onAuthFailed;

  @override
  final String name;

  @internal
  PrivateChannel.internal({
    required this.connectionDelegate,
    required this.name,
    required this.whenChannelStateChanged,
    required this.authorizationDelegate,
    required this.onAuthFailed,
  });

  @override
  void subscribe() async {
    ensureStatusPendingBeforeSubscribe();
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
    setUnsubscribedStatus();
  }

  @override
  PrivateChannelState getStateWithNewStatus(ChannelStatus status) =>
      PrivateChannelState(
        status: status,
      );

  @override
  void handleEvent(PusherChannelsReadEvent event) {
    detectIfSubscriptionSucceeded(event);
  }
}
