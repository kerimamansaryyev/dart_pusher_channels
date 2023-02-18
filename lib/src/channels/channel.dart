import 'dart:async';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/channels/private_channel.dart';
import 'package:dart_pusher_channels/src/channels/public_channel.dart';
import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/client/controller.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:meta/meta.dart';

typedef ChannelsManagerStreamGetter = Stream<ChannelReadEvent> Function();

/// Represents a status of an instance of [Channel]
enum ChannelStatus {
  /// Indicates that an instance of [Channel] can receive events.
  subscribed,

  /// Indicates that an instance of [Channel] cam not receive events.
  unsubscribed,

  /// Indicates that an instance of [Channel] is waiting to be subscribed.
  pendingSubscription,

  /// Indicates that an instance of [Channel] has not made any attempt to subscribe/unsubscribe.
  idle,
}

/// A base representation of a state [Channel]'s instances
@immutable
abstract class ChannelState {
  /// See [ChannelStatus] for more details.
  abstract final ChannelStatus status;

  /// Subscriptions count of an instance of [Channel]
  abstract final int? subscriptionCount;
}

/// Receives and handles respective events delegated by [ChannelsManager].
///
/// Each application can have one channel or many, and each client can choose which channels it subscribes to.

/// Channels provide:

/// - A way of filtering data For example, in a chat application there may be a channel for people who want to discuss ‘dogs’
/// - A way of controlling access to different streams of information. For example, a project management application would want to authorize people to get updates about ‘secret-projectX’
///
/// Supported channels:
/// - [PublicChannel]
/// - [PrivateChannel]
/// - [PresenceChannel]
///
/// See for more details: [Channels docs](https://pusher.com/docs/channels/using_channels/channels/)
abstract class Channel<T extends ChannelState> {
  @protected
  static const internalSubscriptionSucceededEventName =
      'pusher_internal:subscription_succeeded';
  @protected
  static const internalSubscriptionsCountEventName =
      'pusher_internal:subscription_count';
  @protected
  static const internalMemberAddedEventName = 'pusher_internal:member_added';
  @protected
  static const internalMemberRemovedEventName =
      'pusher_internal:member_removed';
  @protected
  static const pusherInternalPrefix = 'pusher_internal:';

  static const subscriptionsCountKey = 'subscription_count';
  static const memberAddedEventName = 'pusher:member_added';
  static const memberRemovedEventName = 'pusher:member_removed';
  static const subscriptionsCountEventName = 'pusher:subscription_count';
  static const subscriptionSucceededEventName = 'pusher:subscription_succeeded';
  static const subscriptionErrorEventName = 'pusher:subscription_error';
  static const authErrorTypeString = 'AuthError';
  static const decryptionErrorTypeString = 'DecryptionError';

  /// Gives the current status of the [state].
  @protected
  ChannelStatus? get currentStatus => state?.status;

  /// A current state of this channel
  T? get state => _currentState;

  /// Name of this channel
  String get name;

  /// A delegate that is passed by [ChannelsManager].
  /// Exposes necessary API of [PusherChannelsClientLifeCycleController].
  ///
  /// See for more details:
  /// - [ChannelsManager]
  /// - [ChannelsManagerConnectionDelegate]
  @protected
  ChannelsManagerConnectionDelegate get connectionDelegate;

  /// Delegates a sink of the [ChannelsManager]'s StreamController.
  @protected
  ChannelPublicEventEmitter get publicEventEmitter;

  /// A atream injection applied by an instance of [ChannelsManager]
  @protected
  ChannelsManagerStreamGetter get publicStreamGetter;

  @visibleForTesting
  static String getInternalSubscriptionSucceededEventNameTest() =>
      internalSubscriptionSucceededEventName;

  @visibleForTesting
  static String getInternalSubscriptionsCountEventName() =>
      internalSubscriptionsCountEventName;

  T? _currentState;

  @protected
  T getStateWithNewStatus(ChannelStatus status);

  @protected
  T getStateWithNewSubscriptionCount(int? subscriptionCount);

  @protected
  bool canHandleEvent(ChannelReadEvent event) =>
      event.channelName == name && currentStatus != ChannelStatus.unsubscribed;

  @mustCallSuper
  @protected
  void updateState(T newState) {
    _currentState = newState;
  }

  /// Presets this current state with new status - [ChannelStatus.pendingSubscription]
  @mustCallSuper
  void subscribe() {
    _ensureStatusPendingBeforeSubscribe();
  }

  /// Presets this current state with new status - [ChannelStatus.unsubscribed]
  @mustCallSuper
  void unsubscribe() {
    _setUnsubscribedStatus();
  }

  /// Handles events received from an instance of [ChannelsManager]
  @internal
  @mustCallSuper
  void handleEvent(ChannelReadEvent event) {
    if (!canHandleEvent(event)) {
      return;
    }
    switch (event.name) {
      case internalSubscriptionSucceededEventName:
        _handleSubscription(event);
        break;
      case internalSubscriptionsCountEventName:
        _handleSubscriptionCount(event);
        break;
      default:
        handleOtherExternalEvents(event);
        break;
    }
  }

  /// Performs subscription if this channel was not unsubscibed
  /// intentionally. Recommended to use while listening for
  /// [PusherChannelsClient.onConnectionEstablished]
  void subscribeIfNotUnsubscribed() {
    if (state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    subscribe();
  }

  @visibleForTesting
  T? getStateTest() => state;

  /// Returns a stream with all the events captured
  /// by this channel.
  Stream<ChannelReadEvent> bindToAll() => publicStreamGetter()
      .where(
        (event) => event.channelName == name,
      )
      .transform<ChannelReadEvent>(
        StreamTransformer.fromHandlers(
          handleData: _bindStreamSinkFilter,
        ),
      );

  /// Return a stream capturing events with respective [eventName].
  Stream<ChannelReadEvent> bind(String eventName) => publicStreamGetter()
      .where(
        (event) => _bindStreamFilterPredicate(
          targetEventName: eventName,
          event: event,
        ),
      )
      .transform<ChannelReadEvent>(
        StreamTransformer.fromHandlers(
          handleData: _bindStreamSinkFilter,
        ),
      );

  /// Passes all other events to [ChannelsManager]'s instances' sink i.e. - [publicEventEmitter]
  @protected
  @internal
  void handleOtherExternalEvents(ChannelReadEvent readEvent) {
    if (readEvent.name.contains(pusherInternalPrefix)) {
      return;
    }
    publicEventEmitter(
      readEvent,
    );
  }

  bool _bindStreamFilterPredicate({
    required String targetEventName,
    required ChannelReadEvent event,
  }) {
    return targetEventName == event.name && event.channelName == name;
  }

  /// Does not allow the events to be added to the [sink]
  /// if this channel is unsubscribed.
  void _bindStreamSinkFilter(
    ChannelReadEvent event,
    EventSink<ChannelReadEvent> sink,
  ) {
    if (currentStatus == ChannelStatus.unsubscribed) {
      return;
    }
    sink.add(
      event,
    );
  }

  void _ensureStatusPendingBeforeSubscribe() {
    if (currentStatus != ChannelStatus.pendingSubscription) {
      updateState(
        getStateWithNewStatus(
          ChannelStatus.pendingSubscription,
        ),
      );
    }
  }

  void _setUnsubscribedStatus() {
    updateState(
      getStateWithNewStatus(
        ChannelStatus.unsubscribed,
      ),
    );
  }

  /// Handles events with name pusher_internal:subscription_succeeded and swaps
  /// its name to pusher:subscription_succeeded.
  void _handleSubscription(ChannelReadEvent readEvent) {
    updateState(
      getStateWithNewStatus(
        ChannelStatus.subscribed,
      ),
    );
    publicEventEmitter(
      readEvent.copyWithName(
        subscriptionSucceededEventName,
      ),
    );
  }

  /// Handles events with name pusher_internal:subscription_count and swaps
  /// its name to pusher:subscription_count.
  void _handleSubscriptionCount(ChannelReadEvent readEvent) {
    final count = int.tryParse(
      '${readEvent.tryGetDataAsMap()?[subscriptionsCountKey]}',
    );
    updateState(
      getStateWithNewSubscriptionCount(
        count,
      ),
    );
    publicEventEmitter(
      readEvent.copyWithName(
        subscriptionsCountEventName,
      ),
    );
  }
}
