import 'package:dart_pusher_channels/src/channels/triggerable_channel.dart';
import 'package:dart_pusher_channels/src/events/trigger_event.dart';

class ChannelTriggerEvent extends PusherChannelsTriggerEvent {
  ChannelTriggerEvent({
    required TriggerableChannelMixin channel,
    required super.name,
    required super.data,
  }) : super(
          channelName: channel.name,
        );
}
