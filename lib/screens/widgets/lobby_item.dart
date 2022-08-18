import 'package:agora_voice_test/models/agora_user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/agora_controller.dart';
import '../main_screen.dart';

class LobbyItem extends StatefulWidget {
  final AgoraUserModel model;
  final bool fromDirectorScreen;
  const LobbyItem(
      {Key? key, required this.model, required this.fromDirectorScreen})
      : super(key: key);

  @override
  State<LobbyItem> createState() => _LobbyItemState();
}

class _LobbyItemState extends State<LobbyItem> {
  late bool muted;
  @override
  void initState() {
    muted = widget.model.muted;
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black12,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.fromDirectorScreen)
                GestureDetector(
                  onTap: () {
                    Provider.of<AgoraEngineController>(context, listen: false)
                        .promoteToStageUser(widget.model.uid, true);
                  },
                  child: const Icon(
                    Icons.arrow_upward,
                  ),
                ),
              const SizedBox(
                height: 10,
              ),
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 15,
                ),
                width: 55,
                child: Text(
                  widget.model.uid.toString(),
                  // maxLines: 1,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.model.uid == uid) {
                        Provider.of<AgoraEngineController>(context,
                                listen: false)
                            .leaveCall(context);
                      } else {
                        Provider.of<AgoraEngineController>(context,
                                listen: false)
                            .removeAUser(uid: widget.model.uid);
                      }
                    },
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        muted = !muted;
                      });
                      Provider.of<AgoraEngineController>(context, listen: false)
                          .toggleLocalAudioMute(muted);
                    },
                    child: Icon(
                      widget.model.muted ? Icons.mic_off : Icons.mic,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
