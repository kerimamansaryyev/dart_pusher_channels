part of channels;

/// Implementation of [ReadEvent] received from [Channel]
class ChannelReadEvent extends Event implements ReadEvent {
  final Channel channel;

  @override
  final Map data;

  @override
  final String name;

  const ChannelReadEvent({
    required this.name,
    required this.data,
    required this.channel,
  });

  @override
  String get channelName => channel.name;
}
