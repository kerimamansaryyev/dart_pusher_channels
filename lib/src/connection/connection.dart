import 'dart:async';

typedef PusherChannelsConnectionOnErrorCallback = void Function(
  dynamic error,
  StackTrace trace,
);

typedef PusherChannelsConnectionOnEventCallback = void Function(String event);

typedef PusherChannelsConnectionOnDoneCallback = void Function();

abstract class PusherChannelsConnection {
  void sendEvent(String eventEncoded);
  FutureOr<void> connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  });
  FutureOr<void> close();
}
