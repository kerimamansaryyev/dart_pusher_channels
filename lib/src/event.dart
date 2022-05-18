import 'package:meta/meta.dart';

typedef RecieveEventPredicate = void Function(
    String name, String? channelName, Map data);

@immutable
abstract class Event {
  String? get channelName;
  String get name;
  Map get data;

  const Event();
}

abstract class ReadEvent extends Event {}

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

class RecieveEvent extends Event implements ReadEvent {
  @override
  final Map data;

  @override
  final String name;

  @override
  final String? channelName;

  final RecieveEventPredicate onEventRecieved;

  void callHandler() {
    onEventRecieved(name, channelName, data);
  }

  const RecieveEvent(
      {required this.data,
      required this.name,
      required this.onEventRecieved,
      required this.channelName});
}
