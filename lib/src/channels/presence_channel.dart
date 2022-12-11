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

  const PresenceChannelState({
    required this.status,
  });
}

class PresenceChannel extends EndpointAuthorizableChannel<PresenceChannelState,
        PresenceChannelAuthorizationData>
    with
        ChannelHandledSubscriptionMixin<PresenceChannelState>,
        TriggerableChannelMixin<PresenceChannelState> {
  @override
  final ChannelsManagerConnectionDelegate connectionDelegate;
  @override
  final ChannelStateChangedCallback<PresenceChannelState>?
      whenChannelStateChanged;
  @override
  final EndpointAuthorizableChannelAuthorizationDelegate<
      PresenceChannelAuthorizationData> authorizationDelegate;

  @override
  final EndpointAuthorizationErrorCallback? onAuthFailed;

  @override
  final String name;

  @internal
  PresenceChannel.internal({
    required this.connectionDelegate,
    required this.name,
    required this.whenChannelStateChanged,
    required this.authorizationDelegate,
    required this.onAuthFailed,
  });

  @override
  void subscribe() async {
    ensureStatusIdleBeforeSubscribe();
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
    setUnsubscribedStatus();
  }

  @override
  PresenceChannelState getStateWithNewStatus(ChannelStatus status) =>
      PresenceChannelState(
        status: status,
      );

  @override
  void handleEvent(PusherChannelsReadEvent event) {
    detectIfSubscriptionSucceeded(event);
  }
}
