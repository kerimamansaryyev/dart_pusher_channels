import 'dart:async';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:meta/meta.dart';

typedef ChannelsManagerStreamGetter = Stream<ChannelReadEvent> Function();

enum ChannelStatus {
  subscribed,
  unsubscribed,
  pendingSubscription,
  idle,
}

@immutable
abstract class ChannelState {
  abstract final ChannelStatus status;
  abstract final int? subscriptionCount;
}

abstract class Channel<T extends ChannelState> {
  @visibleForTesting
  static String getInternalSubscriptionSucceededEventNameTest() =>
      internalSubscriptionSucceededEventName;

  @visibleForTesting
  static String getInternalSubscriptionsCountEventName() =>
      internalSubscriptionsCountEventName;

  @protected
  static const internalSubscriptionSucceededEventName =
      'pusher_internal:subscription_succeeded';
  @protected
  static const internalSubscriptionsCountEventName =
      'pusher_internal:subscription_count';
  static const subscriptionsCountKey = 'subscription_count';
  static const subscriptionsCountEventName = 'pusher:subscription_count';
  static const subscriptionSucceededEventName = 'pusher:subscription_succeeded';
  static const pusherInternalPrefix = 'pusher_internal:';
  static const authErrorType = 'AuthError';
  static const subscriptionErrorEventName = 'pusher:subscription_error';

  T? _currentState;
  abstract final String name;
  @protected
  abstract final ChannelsManagerConnectionDelegate connectionDelegate;
  @protected
  abstract final ChannelPublicEventEmitter publicEventEmitter;
  @protected
  abstract final ChannelsManagerStreamGetter publicStreamGetter;

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

  @mustCallSuper
  void subscribe() {
    _ensureStatusPendingBeforeSubscribe();
  }

  @mustCallSuper
  void unsubscribe() {
    _setUnsubscribedStatus();
  }

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
        _handleOtherExternalEvents(event);
        break;
    }
  }

  void subscribeIfNotUnsubscribed() {
    if (state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    subscribe();
  }

  T? get state => _currentState;

  @visibleForTesting
  T? getStateTest() => state;

  @protected
  ChannelStatus? get currentStatus => state?.status;

  Stream<ChannelReadEvent> bindToAll() => publicStreamGetter()
      .where(
        (event) => event.channelName == name,
      )
      .transform<ChannelReadEvent>(
        StreamTransformer.fromHandlers(
          handleData: _bindStreamSinkFilter,
        ),
      );

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

  bool _bindStreamFilterPredicate({
    required String targetEventName,
    required ChannelReadEvent event,
  }) {
    return targetEventName == event.name && event.channelName == name;
  }

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

  void _handleOtherExternalEvents(ChannelReadEvent readEvent) {
    if (readEvent.name.contains(pusherInternalPrefix)) {
      return;
    }
    publicEventEmitter(
      readEvent,
    );
  }
}
