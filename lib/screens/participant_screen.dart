import 'package:agora_voice_test/controllers/agora_controller.dart';
import 'package:agora_voice_test/screens/main_screen.dart';
import 'package:agora_voice_test/screens/widgets/lobby_item.dart';
import 'package:agora_voice_test/screens/widgets/stage_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParticipantScreen extends StatefulWidget {
  final String name;
  final String channelName;
  final int uid;
  const ParticipantScreen({
    Key? key,
    required this.name,
    required this.channelName,
    required this.uid,
  }) : super(key: key);

  @override
  _ParticipantScreenState createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      Provider.of<AgoraEngineController>(context, listen: false)
          .joinLobbyAsAParticipant(widget.channelName, uid, context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgoraEngineController>(
      builder: (context, provider, child) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Provider.of<AgoraEngineController>(context, listen: false)
                  .leaveCall(context);
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back_outlined,
            ),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'Stage',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              crossAxisCount: 4),
                      itemBuilder: (context, index) {
                        if (index < provider.stageUsers.length) {
                          return StageItem(
                            model: provider.stageUsers.values.toList()[index],
                            fromDirectorScreen: false,
                          );
                        } else {
                          return const CircleAvatar(
                            radius: 25,
                            child: Text('Add user'),
                          );
                        }
                      }),
                ),
                const Divider(
                  thickness: 2,
                ),
                const Text(
                  'Lobby',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 200,
                  child: provider.lobbyUsers.isNotEmpty
                      ? GridView.builder(
                          itemCount: provider.lobbyUsers.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  crossAxisCount: 4),
                          itemBuilder: (context, index) {
                            return LobbyItem(
                              model: provider.lobbyUsers.values.toList()[index],
                              fromDirectorScreen: false,
                            );
                          },
                        )
                      : const Center(
                          child: Text('No users'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
