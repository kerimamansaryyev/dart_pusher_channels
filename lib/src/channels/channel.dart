import 'dart:async';

import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_read_event.dart';
import 'package:dart_pusher_channels/src/events/channel_events/channel_subscription_succeeded_event.dart';
import 'package:dart_pusher_channels/src/events/read_event.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

typedef ChannelStateChangedCallback<T extends ChannelState> = void Function(
  T state,
);

enum ChannelStatus {
  subscribed,
  unsubscribed,
  idle,
}

mixin ChannelHandledSubscriptionMixin<T extends ChannelState> on Channel<T> {
  ChannelStatus _currentStatus = ChannelStatus.idle;

  @mustCallSuper
  @protected
  T getStateWithNewStatus(ChannelStatus status);

  @mustCallSuper
  void ensureStatusIdleBeforeSubscribe() {
    if (_currentStatus != ChannelStatus.idle) {
      _currentStatus = ChannelStatus.idle;
      updateState(
        getStateWithNewStatus(
          _currentStatus,
        ),
      );
    }
  }

  @mustCallSuper
  void setUnsubscribedStatus() {
    if (_currentStatus != ChannelStatus.unsubscribed) {
      _currentStatus = ChannelStatus.unsubscribed;
      updateState(
        getStateWithNewStatus(
          _currentStatus,
        ),
      );
    }
  }

  @mustCallSuper
  void detectIfSubscriptionSucceeded(PusherChannelsReadEvent event) {
    final succeededEvent =
        ChannelSubscriptionSuccededEvent.tryGetFromChannelReadEvent(
      ChannelReadEvent.fromPusherChannelsReadEvent(this, event),
    );
    if (succeededEvent != null &&
        _currentStatus != ChannelStatus.unsubscribed) {
      _currentStatus = ChannelStatus.subscribed;
      updateState(
        getStateWithNewStatus(
          _currentStatus,
        ),
      );
    }
  }
}

@immutable
abstract class ChannelState {
  abstract final ChannelStatus status;
}

abstract class Channel<T extends ChannelState> {
  T? _currentState;
  abstract final String name;
  @protected
  abstract final ChannelsManagerConnectionDelegate connectionDelegate;
  @protected
  abstract final ChannelStateChangedCallback<T>? whenChannelStateChanged;

  @mustCallSuper
  @protected
  void updateState(T newState) {
    _currentState = newState;
    whenChannelStateChanged?.call(newState);
  }

  @mustCallSuper
  void subscribe();

  @mustCallSuper
  void unsubscribe();

  @internal
  @mustCallSuper
  void handleEvent(PusherChannelsReadEvent event);

  void subscribeIfNotUnsubscribed() {
    if (state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    subscribe();
  }

  T? get state => _currentState;

  Stream<ChannelReadEvent> bind(String eventName) => connectionDelegate
      .eventStream
      .whereType<PusherChannelsReadEvent>()
      .where((event) => event.channelName == name && eventName == event.name)
      .map<ChannelReadEvent>(
        (event) => ChannelReadEvent(
          rootObject: {...event.rootObject},
          channel: this,
        ),
      )
      .transform<ChannelReadEvent>(
        StreamTransformer.fromHandlers(
          handleData: _decideIfAllowSinkOnBind,
        ),
      );

  void _decideIfAllowSinkOnBind(
    ChannelReadEvent data,
    EventSink<ChannelReadEvent> sink,
  ) {
    if (state?.status == ChannelStatus.unsubscribed) {
      return;
    }
    sink.add(data);
  }
}
