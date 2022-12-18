import 'package:dart_pusher_channels/src/client/client.dart';
import 'package:dart_pusher_channels/src/options/options.dart';

/// Used to be passed as the `version` metadata by instances of [PusherChannelsOptionsMetadata]
const kDartPusherChannelsLibraryVersion = '0.8.0';

/// Used to be passed as the `protocol` metadata by instances of [PusherChannelsOptionsMetadata]
const kLatestAvailablePusherProtocol = 7;

/// A default host that is used in [PusherChannelsOptions.fromCluster] factory constructor.
const kDefaultPusherChannelsHost = 'pusher.com';

/// A default activity duration that is used by instances of [PusherChannelsClient] in case if a server
/// does not give the one when establishing connection.
const kPusherChannelsDefaultActivityDuration = Duration(seconds: 120);

/// A default interval duration used when waiting for the `pong` message from a server.
const kPusherChannelsDefaultWaitForPongDuration = Duration(seconds: 30);
