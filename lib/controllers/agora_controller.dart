import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:agora_voice_test/models/agora_user_model.dart';
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
  int userId = 0;
  Future leaveChannel() async {
    lobbyUsers = {};
    stageUsers = {};
    notifyListeners();
    await engine.leaveChannel();
  }

  Future<void> joinLobbyAsAParticipant(
      String channelName, int uid, BuildContext ctx) async {
    // Get microphone permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone].request();
    }

    // Create RTC client instance
    context = RtcEngineContext(appId);
    engine = await RtcEngine.createWithContext(context);
    client = await AgoraRtmClient.createInstance(appId);
    // Define event handling logic
    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        print('joinChannelSuccess ${channel} ${uid}');
        lobbyUsers['$uid'] = AgoraUserModel(
            name: 'listener', muted: true, uid: uid, isOnStage: false);
        notifyListeners();
      },
      userJoined: (int uid, int elapsed) {
        print('userJoined ${uid}');
        addUserToLobby(uid);
      },
      leaveChannel: (RtcStats stats) {
        print('====>>>> left');
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
    channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      List<String> parsedMessage = message.text.split(' ');
      print(parsedMessage[1]);
      switch (parsedMessage[0]) {
        case 'mute':
          if (parsedMessage[1] == uid.toString()) {
            engine.muteLocalAudioStream(true);
          }
          break;
        case 'unmute':
          if (parsedMessage[1] == uid.toString()) {
            engine.muteLocalAudioStream(false);
          }
          break;
        case 'promoted':
          promoteToStageUser(int.parse(parsedMessage[1]), false);
          break;
        case 'demoted':
          demoteToLobbyUser(int.parse(parsedMessage[1]), false);
          break;
        case 'remove':
          if (parsedMessage[1] == uid.toString()) {
            leaveCall(ctx);
          }
          break;
      }
    };
    engine.muteLocalAudioStream(true);
  }

  toggleLocalAudioMute(bool mute) {
    engine.muteLocalAudioStream(mute);
    notifyListeners();
  }

  leaveCall(BuildContext context) async {
    lobbyUsers = {};
    stageUsers = {};
    await engine.leaveChannel();
    engine.destroy();
    channel?.leave();
    client?.clearLocalUserAttributes();
    client?.logout();
    client?.destroy();
    Navigator.of(context).pop();
  }

  Future<void> joinStageAsADirector(String channelName, int uid) async {
    // Get microphone permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone].request();
    }

    // Create RTC client instance
    context = RtcEngineContext(appId);
    engine = await RtcEngine.createWithContext(context);
    client = await AgoraRtmClient.createInstance(appId);
    // Define event handling logic
    engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        print('joinChannelSuccess ${channel} ${uid}');
        stageUsers['$uid'] = AgoraUserModel(
            name: 'admin', muted: false, uid: uid, isOnStage: true);
        notifyListeners();
      },
      userJoined: (int uid, int elapsed) {
        print('userJoined================== ${uid}');
        addUserToLobby(uid);
        notifyListeners();
      },
      leaveChannel: (RtcStats stats) {
        print('====>>>> left');
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
    client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print('${message.text}');
    };
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
  }

  Future<void> addUserToLobby(int uid) async {
    lobbyUsers['$uid'] = AgoraUserModel(
      name: 'todo',
      muted: true,
      uid: uid,
      isOnStage: false,
    );
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
    AgoraUserModel tempUser = lobbyUsers['$uid']!;
    stageUsers['$uid'] = tempUser.copyWith(
      muted: false,
    );
    engine.muteRemoteAudioStream(uid, false);
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
    AgoraUserModel tempUser = stageUsers['$uid']!;
    lobbyUsers['$uid'] = tempUser.copyWith(muted: true);
    engine.muteRemoteAudioStream(uid, true);
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
    AgoraUserModel tempUser = stageUsers['$uid']!;
    stageUsers['$uid'] = tempUser.copyWith(muted: muted);
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
