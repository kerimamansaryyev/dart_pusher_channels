## 1.2.3
- Updated dependency: `pinenacl: ^0.6.0`

## 1.2.2+1
- Fixed the licence url in README

## 1.2.2
- Added parameter `overrideContentTypeHeader` into the factory constructors of `EndpointAuthorizableChannelTokenAuthorizationDelegate` to opt
overriding the content type header. It's `true` by default.

## 1.2.1

- Minimum Dart SDK version: `^3.0.0`
- Upgraded http package to version `^1.0.0`
- Converted abstract classes that are used as mixins to abstract mixin classes

## 1.1.1

- Encapsulated the helper extension methods
- Added `publish.yml` workflow to automatically publish releases

## 1.1.0

`NEW FEATURES`:
- Support for Private Encrypted Channels

Expressing the deepest gratitude to [Sameh Doush](https://github.com/samehdoush) for developing and providing a test environment that boosted a release of the feature.

## 1.0.0+6

- Fixed the detected typos in README.

## 1.0.0+5

- Added the **Milestones** section in README.

## 1.0.0+4

- Fixed mistakes in the docs.

## 1.0.0+3

- Updated the platforms metadata.

## 1.0.0+2

- Updated the metadata of this package.

## 1.0.0+1

- Fixed linking in the README.

## 1.0.0

Whole the project has been rethinked and redesigned in this update. The structure is more convenient and canonical according to the [official documentation](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol/#recommendations-for-client-libraries)

`NEW FEATURES`:
- Support for Presence Channels
- Triggering events
- Tested on all the platforms

`BREAKING CHANGES`:

Refactored:
- Renamed and reorganized a hierarchy of the event classes
- Reorganized a hierarchy of the channel classes
- Divided the whole lifecycle of the client in separate layers:
	- Connection layer
	- Channels layer
	- Client's layer

Removed:
- `ConnectionDelegate`
- `WebSocketChannelConnectionDelegate` 
- `TokenAuthorizationDelegate`
- `Event`
- `ReadEvent`
- `SendEvent`

Added:
- Unit tests
- `PusherChannelsConnection` - interface for a connection layer
- `PusherChannelsWebSocketConnection` - implementation of `PusherChannelsConnection`
- `PusherChannelsClientLifeCycleController` - internal controller of a client's lifecycle
- `ChannelsManager` - internal delegate of channels
- `ChannelMembers`
- `ChannelExtension`
- `TriggerableChannelMixin`
- `EndpointAuthorizableChannel`
- `EndpointAuthorizableChannelAuthorizationDelegate`
- `PresenceChannel`

## 0.3.1+1

Updated `kDartPusherChannelsLibraryVersion` constant metadata to `0.3.1`

## 0.3.1

Added `shouldSupplyQueryMetaData` to `PusherChannelsOptions`. It will regulate whether to include or omit the metadata such as `client`, `version`, `protocol`.

## 0.3.0

`BREAKING CHANGE`: `PusherChannelOptions` was deprecated and renamed to `PusherChannelsOptions` for conveniency.

## 0.2.9

Returning '`/`' in `path` getter of `PusherChannelOptions` if both `key` and `path` parameters are provided as `null`.

## 0.2.8+1

Updated `README.md`

## 0.2.8

Minimal changes:

- `key` parameter of `PusherChannelOptions` is nullable now.

- Added a feature to set custom endpoint path to `PusherChannelOptions` with `path` parameter.

- Made `version` parameter of `PusherChannelOptions` equals to `kDartPusherChannelsLibraryVersion`.

- Updated the inline documentation.

- Updated `README.md`.

- Update the example file.

## 0.2.7

Bug fixes:

- Fixed bug when connection status was set to `ConnectionStatus.connceted` each time the pusher error event occured.

(Even if connection status was set to `ConnectionStatus.established` before).

- Fixed bug on double connections triggered by concurrent attempts to reconnect.

  

Internal changes:

- Using `disconnectSafely` instead of `disconnect` on disposing the delegate.

## 0.2.6+1

- Fixed markdown of `README`

## 0.2.6

  

- Updated inline documentation of the package

- Change: `connect` and `disconnect` methods of `ConnectionDelegate` are `@protected`. Use `connectSafely` and `disconnectSafely` respectively from the outside.

## 0.2.5

Merging pull requests [#6](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/6),

[#8](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/8), [#10](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/10), [#12](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/12). Thanks to [Nicolas Britos](https://github.com/nicobritos) for contributions.

- Added an additional member `pingWaitPongDuration` to the `ConnectionDelegate` and the parameter with the same name

to the constructor `PusherChannelsClient.websocket`. It will regulate timeout of `ping` waiting for `pong` (checking if connection is alive).

- Fixed multiple connections occuring after `disconnect` commited by multiple `reconnect` calls.

- Distincting manual disconnections of `ConnectionDelegate` (`disconnectSafely`) from automated ones.

- Fixed: multiple socket connections while calling `connect` multiple times are prevented.

- Change: now `reconnect`'s type is `Future<void>`. (Previously was `void`).

## 0.2.3+1

  

Featuring contributors in README

## 0.2.3

  

Merging pull request [#5](https://github.com/kerimamansaryyev/dart_pusher_channels/pull/5), many thanks to [Nicolas Britos](https://github.com/nicobritos)

- Add custom logger handler to use a custom Logger instead of printing to console.

- Hide PusherChannelsPackageLogger from public API.

- Fix logger tests not capturing what was being printed to console.

- Remove logTest method as it is not needed anymore.

## 0.2.2

  

Added `PusherChannelsPackageConfigs` which enables and disables log prints.

## 0.2.1

  

Added following additional controls to `PusherChannelsClient`

- Method `disconnect()`

- Method `reconnect()`

## 0.2.0+1

  

- Updated README.md

- Improved annotations

## 0.2.0

  

- Tested on Windows succesfully and updated meta data

## 0.1.1

  

- Fixed reconnection tries on disposal

## 0.1.0+1

  

- Updated the description of pubspec.yaml

## 0.1.0

  

- Fixed issue of non-cancallable timer. Added logging with `print` by default. Will be optional in next minor version.

## 0.0.9+1

  

- Making `refresh` callback of `onConnectionErrorHandler` constructor of `PusherChannelsClient.websocket` non-nullable

## 0.0.9

  

- Implemented `unsubscribe` method for private channels.

## 0.0.8

  

- Updated README.

## 0.0.7

  

- Using more canonical names of classes and interfaces.

## 0.0.6

  

- Updated README and example.

## 0.0.5

  

- Updated documentation.

## 0.0.3

  

- Initial version.