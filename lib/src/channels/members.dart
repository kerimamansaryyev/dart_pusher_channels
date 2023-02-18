import 'package:dart_pusher_channels/src/channels/channel.dart';
import 'package:dart_pusher_channels/src/channels/presence_channel.dart';
import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

/// A data class with the info about members of an instance of [Channel]
class MemberInfo {
  final String id;
  final Map<String, dynamic> info;

  MemberInfo({
    required this.id,
    required this.info,
  });
}

/// Delagetes the members changes in an instance of [Channel].
///
/// Usually, used by [PresenceChannel].
class ChannelMembers {
  static const _presenceKey = 'presence';
  static const _hashKey = 'hash';
  static const userIdKey = 'user_id';

  @protected
  Map<String, MemberInfo?> membersMap;
  @protected
  String? myId;

  ChannelMembers({
    required this.membersMap,
    required this.myId,
  });

  /// Returns the instace containing data of the local user (client) only.
  factory ChannelMembers.onlyMe({
    required String myId,
    required Map<String, dynamic> myData,
  }) =>
      ChannelMembers(
        membersMap: {
          myId: MemberInfo(
            id: myId,
            info: {
              ...myData,
            },
          ),
        },
        myId: myId,
      );

  /// Gives a length of [membersMap].
  int get membersCount => membersMap.length;

  static ChannelMembers? tryParseFromMap({
    required Map<String, dynamic> data,
  }) {
    final hash = safeMessageToMapDeserializer(
      data[_presenceKey]?[_hashKey],
    );

    if (hash == null) {
      return null;
    }

    return ChannelMembers(
      membersMap: hash.map<String, MemberInfo?>(
        (key, _) => MapEntry(
          key,
          null,
        ),
      ),
      myId: null,
    );
  }

  /// Gives an id of the local user (client).
  String? getMyId() => myId;

  /// Gives this members as `Map`.
  Map<String, MemberInfo?> getAsMap() => {...membersMap};

  /// Gives an instance of [MemberInfo] if any is in the [membersMap].
  MemberInfo? getMemberInfo(String id) => membersMap[id];

  /// Gives an instance of [MemberInfo] if any is in the [membersMap] for the local user (client).
  MemberInfo? getMyMemberInfo() => myId == null ? null : getMemberInfo(myId!);

  @internal
  void updateMember({
    required String id,
    required MemberInfo? info,
  }) {
    membersMap[id] = info;
  }

  @internal
  void removeMember({
    required String userId,
  }) =>
      membersMap.remove(
        userId,
      );

  @internal
  void updateMe({
    required String id,
    required MemberInfo? memberInfo,
  }) {
    myId = id;
    membersMap[myId!] = memberInfo;
  }

  /// Merges the old [membersMap] with the new one ([otherMap]).
  @internal
  void merge(Map<String, MemberInfo?> otherMap) {
    membersMap = {
      ...membersMap,
      ...otherMap,
    };
  }
}
