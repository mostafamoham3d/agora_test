import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_voice_test/models/agora_user_model.dart';
import 'package:agora_voice_test/models/message_model.dart';
import 'package:agora_voice_test/screens/main_screen.dart' as myUid;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

String appId = '2e5e4d7ee946410ea9dc68e980b4f66a';

class AgoraEngineController extends ChangeNotifier {
  late RtcEngineContext context;
  late RtcEngine engine;
  AgoraRtmChannel? channel;
  AgoraRtmClient? client;
  Map<String, AgoraUserModel> lobbyUsers = {};
  Map<String, AgoraUserModel> stageUsers = {};
  List<MessageModel> messages = [];
  int userId = 0;
  sendMessage(String text, int userId) async {
    var userAttrs = await client?.getUserAttributes(userId.toString());
    String name = userAttrs!['name'];
    channel?.sendMessage(AgoraRtmMessage.fromText('$name $text'));
  }

  Future leaveChannel() async {
    lobbyUsers = {};
    stageUsers = {};
    notifyListeners();
    await engine.leaveChannel();
  }

  Future<void> joinLobbyAsAParticipant(
      String channelName, int uid, BuildContext ctx, String userName) async {
    // Get microphone permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone].request();
    }

    // Create RTC client instance
    context = RtcEngineContext(appId);
    engine = await RtcEngine.createWithContext(context);
    client = await AgoraRtmClient.createInstance(appId);
    // Define event handling logic

    client?.onConnectionStateChanged = (int state, int reason) async {
      if (state == 5) {
        await engine.leaveChannel();
        engine.destroy();
        channel?.leave();
        client?.logout();
        client?.destroy();
        stageUsers = {};
        lobbyUsers = {};
        notifyListeners();
      }
    };
    await client?.login(null, uid.toString());
    channel = await client?.createChannel(channelName);
    await channel?.join();
    await engine.joinChannel(null, channelName, null, uid);
    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        Map<String, String> name = {'key': 'name', 'value': userName};
        Map<String, String> muted = {'key': 'muted', 'value': 'true'};
        Map<String, String> isOnStage = {'key': 'isOnStage', 'value': 'false'};
        client?.addOrUpdateLocalUserAttributes([name, muted, isOnStage]);
        print('joinChannelSuccess ${channel} ${uid}');
        lobbyUsers['$uid'] = AgoraUserModel(
            name: userName, muted: true, uid: uid, isOnStage: false);
        // sendMessage('joined', uid);
        notifyListeners();
      },
      userJoined: (int id, int elapsed) {
        print('userJoined ${uid}');
        if (id != myUid.uid) {
          addUserToLobby(id);
        }
        sendMessage('joined', uid);
      },
      leaveChannel: (RtcStats stats) {
        sendMessage('left', uid);
        client?.clearLocalUserAttributes();
      },
      userOffline: (int uid, UserOfflineReason reason) {
        print('==>>> userOffline ${uid}');
        removeUser(uid);
      },
      remoteAudioStateChanged: (int uid, state, reason, elapsed) {
        if (state == AudioRemoteState.Decoding) {
          updateUserAudio(uid: uid, muted: false);
          print('==============unmuted============');
        } else {
          updateUserAudio(uid: uid, muted: true);
          print('==============muted============');
        }
      },
    ));
    channel?.onMemberJoined = (AgoraRtmMember member) {
      sendMessage('joined', int.parse(member.userId));
      print('==============${member.userId}=========== joined');
    };
    channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      List<String> parsedMessage = message.text.split(' ');
      print(parsedMessage[1]);
      switch (parsedMessage[0]) {
        case 'mute':
          if (parsedMessage[1] == myUid.uid.toString()) {
            engine.muteLocalAudioStream(true);
            print('==================mute');
            updateUserAudio(uid: myUid.uid, muted: true);
          }
          break;
        case 'unmute':
          if (parsedMessage[1] == myUid.uid.toString()) {
            engine.muteLocalAudioStream(false);
            updateUserAudio(uid: myUid.uid, muted: false);
            print('==================unmute');
          }
          break;
        case 'promoted':
          promoteToStageUser(int.parse(parsedMessage[1]), false);
          break;
        case 'demoted':
          demoteToLobbyUser(int.parse(parsedMessage[1]), false);
          break;
        case 'remove':
          if (parsedMessage[1] == myUid.uid.toString()) {
            leaveCall(ctx, myUid.uid);
          }
          break;
        default:
          messages
              .add(MessageModel(name: parsedMessage[0], msg: parsedMessage[1]));
          notifyListeners();
          break;
      }
    };
    engine.muteLocalAudioStream(true);
  }

  toggleLocalAudioMute(bool mute) {
    engine.muteLocalAudioStream(mute);
    notifyListeners();
  }

  leaveCall(BuildContext context, int id) async {
    await sendMessage('left', id);
    lobbyUsers = {};
    stageUsers = {};
    await engine.leaveChannel();
    engine.destroy();
    channel?.leave();
    messages = [];
    notifyListeners();
    client?.clearLocalUserAttributes();
    client?.logout();
    client?.destroy();
    Navigator.of(context).pop();
  }

  Future<void> joinStageAsADirector(
      String channelName, int uid, String userName) async {
    // Get microphone permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone].request();
    }

    // Create RTC client instance
    context = RtcEngineContext(appId);
    engine = await RtcEngine.createWithContext(context);
    client = await AgoraRtmClient.createInstance(appId);
    // Define event handling logic

    client?.onConnectionStateChanged = (int state, int reason) async {
      if (state == 5) {
        await engine.leaveChannel();
        engine.destroy();
        channel?.leave();
        client?.logout();
        client?.destroy();
        stageUsers = {};
        lobbyUsers = {};
        notifyListeners();
      }
    };
    await client?.login(null, uid.toString());
    channel = await client?.createChannel(channelName);
    await channel?.join();
    await engine.joinChannel(null, channelName, null, uid);
    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        Map<String, String> name = {'key': 'name', 'value': userName};
        Map<String, String> muted = {'key': 'muted', 'value': 'false'};
        Map<String, String> isOnStage = {'key': 'isOnStage', 'value': 'true'};
        client?.addOrUpdateLocalUserAttributes([name, muted, isOnStage]);
        print('joinChannelSuccess ${channel} ${uid}');
        stageUsers['$uid'] = AgoraUserModel(
            name: userName, muted: false, uid: uid, isOnStage: true);
        notifyListeners();
        //sendMessage('joined', uid);
      },
      userJoined: (int id, int elapsed) {
        print('userJoined================== ${uid}');
        if (id != myUid.uid) {
          addUserToLobby(id);
        }
        sendMessage('joined', uid);
      },
      leaveChannel: (RtcStats stats) {
        print('====>>>> left');
        sendMessage('left', uid);
        client?.clearLocalUserAttributes();
      },
      userOffline: (int uid, UserOfflineReason reason) {
        print('==>>> userOffline ${uid}');
        removeUser(uid);
      },
      remoteAudioStateChanged: (int uid, state, reason, elapsed) {
        if (state == AudioRemoteState.Decoding) {
          updateUserAudio(uid: uid, muted: false);
        } else {
          updateUserAudio(uid: uid, muted: true);
        }
      },
    ));
    channel?.onMemberJoined = (AgoraRtmMember member) {
      sendMessage('joined', int.parse(member.userId));
      print('==============${member.userId}=========== joined rr');
    };
    channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      List<String> parsedMessage = message.text.split(' ');
      print(parsedMessage[1]);
      switch (parsedMessage[0]) {
        case 'mute':
          if (parsedMessage[1] == myUid.uid.toString()) {
            engine.muteLocalAudioStream(true);
            print('==================mute');
            updateUserAudio(uid: myUid.uid, muted: true);
          }
          break;
        case 'unmute':
          if (parsedMessage[1] == myUid.uid.toString()) {
            engine.muteLocalAudioStream(false);
            updateUserAudio(uid: myUid.uid, muted: false);
            print('==================unmute');
          }
          break;
        case 'promoted':
          promoteToStageUser(int.parse(parsedMessage[1]), false);
          break;
        case 'demoted':
          demoteToLobbyUser(int.parse(parsedMessage[1]), false);
          break;
        case 'remove':
          if (parsedMessage[1] == myUid.uid.toString()) {}
          break;
        default:
          messages
              .add(MessageModel(name: parsedMessage[0], msg: parsedMessage[1]));
          notifyListeners();
          break;
      }
    };
  }

  Future<void> addUserToLobby(int uid) async {
    Map<String, dynamic>? userAttrs =
        await client?.getUserAttributes(uid.toString());
    print('added user=============${userAttrs!['muted']}');
    // sendMessage('joined', uid);
    if (userAttrs['isOnStage'] == 'true') {
      stageUsers['$uid'] = AgoraUserModel(
        name: userAttrs['name'],
        muted: userAttrs['muted'] != 'false' ? false : true,
        uid: uid,
        isOnStage: true,
      );
      notifyListeners();
    } else {
      lobbyUsers['$uid'] = AgoraUserModel(
        name: userAttrs['name'],
        muted: true,
        uid: uid,
        isOnStage: false,
      );
    }
    notifyListeners();
  }

  Future<void> removeUser(int uid) async {
    if (lobbyUsers.containsKey('$uid')) {
      lobbyUsers.remove('$uid');
      notifyListeners();
    }
    if (stageUsers.containsKey('$uid')) {
      stageUsers.remove('$uid');
      notifyListeners();
    }
    // List<AgoraUserModel> tempLobby = lobbyUsers;
    // List<AgoraUserModel> tempStage = stageUsers;
    // for (int i = 0; i < tempLobby.length; i++) {
    //   if (tempLobby[i].uid == uid) {
    //     tempLobby.removeAt(i);
    //   }
    // }
    //
    // for (int i = 0; i < tempStage.length; i++) {
    //   if (tempStage[i].uid == uid) {
    //     tempStage.removeAt(i);
    //   }
    // }
    //
    // lobbyUsers = tempLobby;
    // stageUsers = tempStage;
    // notifyListeners();
  }

  Future<void> promoteToStageUser(int uid, bool fromDirector) async {
    Map<String, String> muted = {'key': 'muted', 'value': 'false'};
    Map<String, String> isOnStage = {'key': 'isOnStage', 'value': 'true'};
    client?.addOrUpdateLocalUserAttributes([muted, isOnStage]);
    AgoraUserModel tempUser = lobbyUsers['$uid']!;
    channel?.sendMessage(AgoraRtmMessage.fromText('unmute $uid'));
    await engine.muteRemoteAudioStream(uid, false);
    stageUsers['$uid'] = tempUser.copyWith(
      muted: false,
    );
    sendMessage('promoted to Stage', uid);
    lobbyUsers.remove('$uid');
    notifyListeners();
    if (fromDirector) {
      notifyWhenAUserIsPromotedOrDemoted(uid: uid, promoted: true);
    }
    // for (int i = 0; i < lobbyUsers.length; i++) {
    //   if (lobbyUsers[i].uid == uid) {
    //     print('======================$uid');
    //     // String tempName = lobbyUsers[i].name;
    //     lobbyUsers.removeAt(i);
    //     notifyListeners();
    //   }
    // }
    // stageUsers.add(
    //     AgoraUserModel(name: 'Name', muted: false, uid: uid, isOnStage: true));
    // notifyListeners();
  }

  Future<void> demoteToLobbyUser(int uid, bool fromDirector) async {
    Map<String, String> muted = {'key': 'muted', 'value': 'true'};
    Map<String, String> isOnStage = {'key': 'isOnStage', 'value': 'false'};
    client?.addOrUpdateLocalUserAttributes([muted, isOnStage]);
    AgoraUserModel tempUser = stageUsers['$uid']!;
    lobbyUsers['$uid'] = tempUser.copyWith(muted: true);
    engine.muteRemoteAudioStream(uid, true);
    sendMessage('demoted to lobby', uid);
    stageUsers.remove('$uid');
    notifyListeners();
    if (fromDirector) {
      notifyWhenAUserIsPromotedOrDemoted(uid: uid, promoted: false);
    }
    // List<AgoraUserModel> tempStage = stageUsers;
    // String? tempName;
    // for (int i = 0; i < tempStage.length; i++) {
    //   if (tempStage[i].uid == uid) {
    //     tempName = tempStage[i].name;
    //     tempStage.removeAt(i);
    //   }
    // }
    // lobbyUsers.add(AgoraUserModel(
    //     name: tempName!, muted: true, uid: uid, isOnStage: false));
    // stageUsers = tempStage;
    // notifyListeners();
  }

  Future<void> updateUserAudio({required int uid, required bool muted}) async {
    if (muted) {
      Map<String, String> muted = {'key': 'muted', 'value': 'true'};
      client?.addOrUpdateLocalUserAttributes([muted]);
    } else {
      Map<String, String> muted = {'key': 'muted', 'value': 'false'};
      client?.addOrUpdateLocalUserAttributes([muted]);
    }
    AgoraUserModel tempUser = stageUsers['$uid']!;
    stageUsers['$uid'] = tempUser.copyWith(muted: muted);
    print('${stageUsers['$uid']!.muted}');
    notifyListeners();
  }

  Future<void> toggleUserAudio({required int uid, required bool muted}) async {
    if (muted) {
      channel?.sendMessage(AgoraRtmMessage.fromText('unmute $uid'));
    } else {
      channel?.sendMessage(AgoraRtmMessage.fromText('mute $uid'));
    }
  }

  Future<void> notifyWhenAUserIsPromotedOrDemoted(
      {required int uid, required bool promoted}) async {
    if (promoted) {
      channel?.sendMessage(AgoraRtmMessage.fromText('promoted $uid'));
    } else {
      channel?.sendMessage(AgoraRtmMessage.fromText('demoted $uid'));
    }
  }

  Future<void> removeAUser({required int uid}) async {
    channel?.sendMessage(AgoraRtmMessage.fromText('remove $uid'));
  }
}
