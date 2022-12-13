import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorizable_channel.dart';
import 'package:dart_pusher_channels/src/channels/endpoint_authorizable_channel/endpoint_authorization_delegate.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel/members.dart';
import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscribe_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_unsubscribe_event.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
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

  final ChannelMembers? members;

  const PresenceChannelState({
    required this.status,
    required this.subscriptionCount,
    required this.members,
  });

  PresenceChannelState copyWith({
    ChannelStatus? status,
    int? subscriptionCount,
    ChannelMembers? members,
  }) =>
      PresenceChannelState(
        members: members ?? this.members,
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
    final currentAuthData = authData;
    if (fixatedLifeCycleCount < authRequestCycle ||
        currentAuthData == null ||
        state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    _handleAuthenticated(currentAuthData);
    connectionDelegate.sendEvent(
      ChannelSubscribeEvent.forPresenceChannel(
        channelName: name,
        authKey: currentAuthData.authKey,
        channelDataEncoded: currentAuthData.channelDataEncoded,
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
        members: null,
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
        members: null,
      );

  @override
  void handleEvent(ChannelReadEvent event) {
    super.handleEvent(event);
    if (!canHandleEvent(event)) {
      return;
    }
    switch (event.name) {
      case Channel.internalSubscriptionSucceededEventName:
        _handleSubscription(event);
        break;
      case Channel.internalMemberAddedEventName:
        _handleMemberAdded(event);
        break;
      case Channel.internalMemberRemovedEventName:
        _handleMemberRemoved(event);
        break;
    }
  }

  @protected
  PresenceChannelState getStateWithNewMembers(ChannelMembers? members) =>
      state?.copyWith(
        members: members,
      ) ??
      PresenceChannelState(
        status: ChannelStatus.idle,
        subscriptionCount: null,
        members: members,
      );

  void _handleAuthenticated(
    PresenceChannelAuthorizationData authorizationData,
  ) {
    final dataDecoded = safeMessageToMapDeserializer(
      authorizationData.channelDataEncoded,
    );
    final userId = dataDecoded?[ChannelMembers.userIdKey]?.toString();
    if (dataDecoded == null || userId == null) {
      return;
    }
    final myId = userId;
    final myData = dataDecoded;
    updateState(
      getStateWithNewMembers(
        (state?.members
              ?..updateMe(
                memberInfo: MemberInfo(
                  id: myId,
                  info: {
                    ...myData,
                  },
                ),
                id: myId,
              )) ??
            ChannelMembers.onlyMe(
              myData: myData,
              myId: myId,
            ),
      ),
    );
  }

  void _handleMemberRemoved(ChannelReadEvent event) {
    final data = event.tryGetDataAsMap();
    final userId = data?[ChannelMembers.userIdKey]?.toString();
    if (userId == null) {
      return;
    }
    final members = state?.members ??
        ChannelMembers(
          membersMap: {},
          myId: null,
        );
    updateState(
      getStateWithNewMembers(
        members
          ..removeMember(
            userId: userId,
          ),
      ),
    );
    publicEventEmitter(
      event.copyWithName(
        Channel.memberRemovedEventName,
      ),
    );
  }

  void _handleMemberAdded(ChannelReadEvent event) {
    final data = event.tryGetDataAsMap();
    final userId = data?[ChannelMembers.userIdKey]?.toString();
    final userInfo = data;
    if (userId == null || userInfo == null) {
      return;
    }
    final members = state?.members ??
        ChannelMembers(
          membersMap: {},
          myId: null,
        );
    updateState(
      getStateWithNewMembers(
        members
          ..updateMember(
            id: userId,
            info: MemberInfo(
              id: userId,
              info: userInfo,
            ),
          ),
      ),
    );
    publicEventEmitter(
      event.copyWithName(
        Channel.memberAddedEventName,
      ),
    );
  }

  void _handleSubscription(ChannelReadEvent readEvent) {
    final data = readEvent.tryGetDataAsMap();
    if (data == null) {
      return;
    }

    final newMembers = ChannelMembers.tryParseFromMap(
      data: data,
    );

    if (newMembers == null) {
      updateState(
        getStateWithNewMembers(
          null,
        ),
      );
    } else {
      final currentMembers = state?.members;
      final dataToMerge = {
        ...newMembers.getMap(),
      };
      final myId = currentMembers?.getMyId();
      if (myId != null) {
        dataToMerge.remove(myId);
      }

      updateState(
        getStateWithNewMembers(
          (currentMembers
                ?..merge(
                  dataToMerge,
                )) ??
              newMembers,
        ),
      );
    }
  }
}
