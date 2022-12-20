import 'dart:async';

import 'package:dart_pusher_channels/src/client/client.dart';

typedef PusherChannelsConnectionOnErrorCallback = void Function(
  dynamic error,
  StackTrace trace,
);

typedef PusherChannelsConnectionOnEventCallback = void Function(String event);

typedef PusherChannelsConnectionOnDoneCallback = void Function();

/// An interface that delegates connection of an instance of [PusherChannelsClient] with a server.
///
/// Implement this interface to inject it into [PusherChannelsClient.custom].
///
abstract class PusherChannelsConnection {
  /// Sends a message to a server.
  void sendEvent(String eventEncoded);

  /// "Pinges" a server to ensure that connection is alive.
  void ping();

  /// Tries to establish connection.
  ///
  /// - [onDoneCallback] must be called when connection is closed.
  /// - [onErrorCallback] must be called when a connection error is thrown.
  /// - [onEventCallback] must be called when an event is received.
  void connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  });

  /// Closes the connection.
  FutureOr<void> close();
}
