import 'package:agora_voice_test/screens/widgets/lobby_item.dart';
import 'package:agora_voice_test/screens/widgets/stage_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/agora_controller.dart';
import 'main_screen.dart';

class DirectorScreen extends StatefulWidget {
  final String name;
  final String channelName;
  final int uid;
  const DirectorScreen({
    Key? key,
    required this.name,
    required this.channelName,
    required this.uid,
  }) : super(key: key);

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      Provider.of<AgoraEngineController>(context, listen: false)
          .joinStageAsADirector(widget.channelName, uid, widget.name);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgoraEngineController>(
      builder: (context, provider, child) => Scaffold(
        bottomSheet: const Padding(
          padding: EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Enter a message',
            ),
          ),
        ),
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Provider.of<AgoraEngineController>(context, listen: false)
                  .leaveCall(context, widget.uid);
              Navigator.of(context).pop();
            },
            icon: const Icon(
              Icons.arrow_back_outlined,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
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
                              fromDirectorScreen: true,
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
                    height: 100,
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
                                model:
                                    provider.lobbyUsers.values.toList()[index],
                                fromDirectorScreen: true,
                              );
                            },
                          )
                        : const Center(
                            child: Text('No users'),
                          ),
                  ),
                  SizedBox(
                    height: 200,
                    child: provider.messages.isNotEmpty
                        ? ListView.builder(
                            itemCount: provider.messages.length,
                            itemBuilder: (context, index) {
                              return Row(
                                children: [
                                  Text(provider.messages[index].name),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(provider.messages[index].msg),
                                ],
                              );
                            })
                        : Center(
                            child: Text('No messages'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
