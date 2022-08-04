import 'package:meta/meta.dart';

typedef ReceiveEventPredicate = void Function(
  String name,
  String? channelName,
  Map data,
);

/// Class to describe events of Pusher Channels
/// For more information: [https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events)
@immutable
abstract class Event {
  const Event();

  /// Name of a channel
  String? get channelName;

  /// Name of an event
  String get name;

  /// Payload of event
  Map get data;
}

/// Instances of [ReadEvent] can only be used to read.
abstract class ReadEvent extends Event {}

/// Read events from pusher
class PusherReadEvent extends ReadEvent {
  @override
  final Map data;

  @override
  final String name;

  @override
  final String? channelName;

  PusherReadEvent({
    required this.data,
    required this.name,
    required this.channelName,
  });
}

/// Events sent to a server
class SendEvent extends Event {
  @override
  final Map data;

  @override
  final String name;

  @override
  final String? channelName;

  const SendEvent({
    required this.data,
    required this.name,
    required this.channelName,
  });
}

/// Special type of [ReadEvent] that accepts [ReceiveEventPredicate]
/// Then accepted [onEventReceived] can be called with [callHandler]
class ReceiveEvent extends Event implements ReadEvent {
  @protected
  final ReceiveEventPredicate onEventReceived;

  @override
  final Map data;

  @override
  final String name;

  @override
  final String? channelName;

  const ReceiveEvent({
    required this.data,
    required this.name,
    required this.onEventReceived,
    required this.channelName,
  });

  /// Calling [onEventReceived]
  void callHandler() {
    onEventReceived(name, channelName, data);
  }
}
