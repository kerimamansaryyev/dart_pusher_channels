library channels;

import 'dart:async';
import 'package:meta/meta.dart';
import '../connection.dart';
import '../event.dart';
import '../event_names.dart';

part 'authorization_delegate.dart';
part 'event.dart';

abstract class Channel {
  final String name;

  void subscribe();

  void unsubscribe();

  @protected
  final ConnectionDelegate connectionDelegate;

  Stream<ChannelReadEvent> bind(String eventName) => connectionDelegate.onEvent
      .where((event) => event.channelName == name && eventName == event.name)
      .map<ChannelReadEvent>((event) =>
          ChannelReadEvent(name: event.name, data: event.data, channel: this));

  Channel({required this.name, required this.connectionDelegate});
}

class PrivateChannel extends Channel {
  PrivateChannel(
      {required String name,
      required ConnectionDelegate connectionDelegate,
      required this.authorizationDelegate})
      : super(name: name, connectionDelegate: connectionDelegate);

  final AuthorizationDelegate authorizationDelegate;

  @override
  void subscribe() {}

  @override
  void unsubscribe() {}
}

class PublicChannel extends Channel {
  PublicChannel(
      {required String name, required ConnectionDelegate connectionDelegate})
      : super(name: name, connectionDelegate: connectionDelegate);

  @override
  void subscribe() {
    connectionDelegate.send(SendEvent(
        data: {'channel': name},
        name: PusherEventNames.subscribe,
        channelName: null));
  }

  @override
  void unsubscribe() {
    connectionDelegate.send(SendEvent(
        data: {'channel': name},
        name: PusherEventNames.unsubscribe,
        channelName: null));
  }
}
