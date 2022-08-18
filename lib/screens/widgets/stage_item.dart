import 'package:agora_voice_test/controllers/agora_controller.dart';
import 'package:agora_voice_test/models/agora_user_model.dart';
import 'package:agora_voice_test/screens/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StageItem extends StatefulWidget {
  final AgoraUserModel model;
  final bool fromDirectorScreen;
  const StageItem(
      {Key? key, required this.model, required this.fromDirectorScreen})
      : super(key: key);

  @override
  State<StageItem> createState() => _StageItemState();
}

class _StageItemState extends State<StageItem> {
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
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.black12,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (uid != widget.model.uid && widget.fromDirectorScreen)
                GestureDetector(
                  onTap: () {
                    Provider.of<AgoraEngineController>(context, listen: false)
                        .demoteToLobbyUser(widget.model.uid, true);
                  },
                  child: const Icon(
                    Icons.arrow_downward,
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
                  widget.model.name,
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
                      if (widget.model.uid == uid) {
                        setState(() {
                          muted = !muted;
                          print(muted);
                        });
                        Provider.of<AgoraEngineController>(context,
                                listen: false)
                            .toggleLocalAudioMute(muted);
                      } else {
                        Provider.of<AgoraEngineController>(context,
                                listen: false)
                            .toggleUserAudio(
                                uid: widget.model.uid, muted: muted);
                      }
                    },
                    child: widget.model.uid == uid
                        ? Icon(
                            muted ? Icons.mic_off : Icons.mic,
                            color: Colors.blue,
                          )
                        : Icon(
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
