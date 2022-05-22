part of channels;

/// Implementation of [ReadEvent] recieved from [Channel]
class ChannelReadEvent extends Event implements ReadEvent {
  @override
  final Map data;

  @override
  final String name;

  final Channel channel;

  const ChannelReadEvent(
      {required this.name, required this.data, required this.channel});

  @override
  String get channelName => channel.name;
}
