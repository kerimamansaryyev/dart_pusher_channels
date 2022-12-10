import 'package:dart_pusher_channels/src/client/controller_interaction_interface.dart';

abstract class PusherChannelsClientLifeCycleObserver {
  abstract final PusherChannelsClientLifeCycleInteractionInterface
      interactionInterface;
}
