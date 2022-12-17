import 'package:dart_pusher_channels/src/utils/helpers.dart';
import 'package:meta/meta.dart';

class MemberInfo {
  final String id;
  final Map<String, dynamic> info;

  MemberInfo({
    required this.id,
    required this.info,
  });
}

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

  int get membersCount => membersMap.length;

  String? getMyId() => myId;

  Map<String, MemberInfo?> getMap() => {...membersMap};

  MemberInfo? getMemberInfo(String id) => membersMap[id];

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

  @internal
  void merge(Map<String, MemberInfo?> otherMap) {
    membersMap = {
      ...membersMap,
      ...otherMap,
    };
  }
}
