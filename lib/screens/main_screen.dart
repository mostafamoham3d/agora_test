import 'package:agora_voice_test/screens/director_screen.dart';
import 'package:agora_voice_test/screens/participant_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

late int uid;

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController channelController = TextEditingController();
  @override
  void initState() {
    getUserUid();
    super.initState();
  }

  Future<void> getUserUid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? storedUid = preferences.getInt('uid');
    if (storedUid != null) {
      uid = storedUid;
    } else {
      int time = DateTime.now().microsecondsSinceEpoch;
      uid = int.parse(time.toString().substring(1, time.toString().length - 6));
      preferences.setInt('uid', uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 30,
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Name',
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextField(
                controller: channelController,
                decoration: const InputDecoration(
                  hintText: 'Channel',
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DirectorScreen(
                        name: nameController.text,
                        channelName: channelController.text,
                        uid: uid,
                      ),
                    ),
                  );
                },
                child: const Text('Director'),
              ),
              const SizedBox(
                height: 15,
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ParticipantScreen(
                        name: nameController.text,
                        channelName: channelController.text,
                        uid: uid,
                      ),
                    ),
                  );
                },
                child: const Text('Participant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
