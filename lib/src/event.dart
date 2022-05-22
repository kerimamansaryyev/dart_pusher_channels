import 'package:meta/meta.dart';

typedef RecieveEventPredicate = void Function(
    String name, String? channelName, Map data);

/// Class to describe events of Pusher Channels
/// For more information: [https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#subscription-events)
@immutable
abstract class Event {
  /// Name of a channel
  String? get channelName;

  /// Name of an event
  String get name;

  /// Payload of event
  Map get data;

  const Event();
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

  PusherReadEvent(
      {required this.data, required this.name, required this.channelName});
}

/// Events sent to a server
class SendEvent extends Event {
  @override
  final Map data;

  @override
  final String name;

  const SendEvent(
      {required this.data, required this.name, required this.channelName});

  @override
  final String? channelName;
}

/// Special type of [ReadEvent] that accepts [RecieveEventPredicate]
/// Then accepted [onEventRecieved] can be called with [callHandler]
class RecieveEvent extends Event implements ReadEvent {
  @override
  final Map data;

  @override
  final String name;

  @override
  final String? channelName;

  @protected
  final RecieveEventPredicate onEventRecieved;

  /// Calling [onEventRecieved]
  void callHandler() {
    onEventRecieved(name, channelName, data);
  }

  const RecieveEvent(
      {required this.data,
      required this.name,
      required this.onEventRecieved,
      required this.channelName});
}
