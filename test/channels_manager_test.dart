import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/channels_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Testing ChannelsManager', () {
    test(
      'Gives the same instance of channels if exists',
      () {
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            sendEventDelegate: (event) {},
            eventStreamGetter: Stream.empty,
          ),
        );
        final oldPublicChannel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        final newPublicChannel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        expect(oldPublicChannel == newPublicChannel, true);
      },
    );
    test(
      'Disposing the manager will unsubscrive the channel',
      () {
        final manager = ChannelsManager(
          channelsConnectionDelegate: ChannelsManagerConnectionDelegate(
            sendEventDelegate: (event) {},
            eventStreamGetter: Stream.empty,
          ),
        );
        final channel = manager.publicChannel(
          'hello',
          whenChannelStateChanged: null,
        );
        expect(channel.state?.status, null);
        manager.dispose();
        expect(channel.state?.status, ChannelStatus.unsubscribed);
      },
    );
  });
}
