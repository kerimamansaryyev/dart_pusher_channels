## 0.2.6+1
- Fixed markdown of `README`
## 0.2.6

- Updated inline documentation of the package
- Change: `connect` and `disconnect` methods of `ConnectionDelegate` are `@protected`. Use `connectSafely` and `disconnectSafely` respectively from the outside.
## 0.2.5
Merging pull requests [#6](https://github.com/mcfugger/dart_pusher_channels/pull/6),
[#8](https://github.com/mcfugger/dart_pusher_channels/pull/8), [#10](https://github.com/mcfugger/dart_pusher_channels/pull/10), [#12](https://github.com/mcfugger/dart_pusher_channels/pull/12). Thanks to [Nicolas Britos](https://github.com/nicobritos) for contributions.
- Added an additional member `pingWaitPongDuration` to the `ConnectionDelegate` and the parameter with the same name
to the constructor `PusherChannelsClient.websocket`. It will regulate timeout of `ping` waiting for `pong` (checking if connection is alive).
- Fixed multiple connections occuring after `disconnect` commited by multiple `reconnect` calls.
- Distincting manual disconnections of `ConnectionDelegate` (`disconnectSafely`) from automated ones.
- Fixed: multiple socket connections while calling `connect` multiple times are prevented.
- Change: now `reconnect`'s type is `Future<void>`. (Previously was `void`).
## 0.2.3+1

Featuring contributors in README
## 0.2.3

Merging pull request [#5](https://github.com/mcfugger/dart_pusher_channels/pull/5), many thanks to [Nicolas Britos](https://github.com/nicobritos)
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
