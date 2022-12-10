import 'package:dart_pusher_channels/src/client/controller_interaction_interface.dart';
import 'package:dart_pusher_channels/src/client/observer.dart';

class PusherChannelsClientPongLifeCycleObserver
    extends PusherChannelsClientLifeCycleObserver {
  @override
  final PusherChannelsClientLifeCycleInteractionInterface interactionInterface;

  PusherChannelsClientPongLifeCycleObserver({
    required this.interactionInterface,
  });
}
