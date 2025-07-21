import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';


class LiveKitAudioPage extends StatefulWidget {
  const LiveKitAudioPage({super.key});
  @override
  State<LiveKitAudioPage> createState() => _LiveKitAudioPageState();
}

class _LiveKitAudioPageState extends State<LiveKitAudioPage> {
  Room? _room;
  bool _joined = false;

  final String url = 'ws://192.168.1.15:7880';
  final String token =
      'eyJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoidXNlcjMyMSIsInZpZGVvIjp7InJvb21Kb2luIjp0cnVlLCJyb29tIjoiZW5nbGlzaC1yb29tIiwiY2FuUHVibGlzaCI6dHJ1ZSwiYWdlbnQiOnRydWV9LCJyb29tQ29uZmlnIjp7Im5hbWUiOiIiLCJlbXB0eVRpbWVvdXQiOjAsImRlcGFydHVyZVRpbWVvdXQiOjAsIm1heFBhcnRpY2lwYW50cyI6MCwibWluUGxheW91dERlbGF5IjowLCJtYXhQbGF5b3V0RGVsYXkiOjAsInN5bmNTdHJlYW1zIjpmYWxzZSwiYWdlbnRzIjpbeyJhZ2VudE5hbWUiOiJub3ZhLWFnZW50IiwibWV0YWRhdGEiOiJ7XCJ1c2VyX2lkXCI6IFwiMTIzNDVcIn0ifV19LCJpc3MiOiJkZXZrZXkiLCJleHAiOjE3NTMwNDk5MTUsIm5iZiI6MCwic3ViIjoidXNlcjMyMSJ9.BfnfcIcnoEC9fixrHAdPyXt2NdgZ9ol4Ic3t6N2XpYw';

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  Future<void> _joinRoom() async {
    // Yêu cầu quyền micro
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      print("Microphone permission denied.");
      return;
    }

    // Kết nối tới room
    final room = Room();
    room.addListener(_onRoomChanged);
    await room.connect(url, token);

    // Publish microphone audio
    await room.localParticipant?.setMicrophoneEnabled(true);

    setState(() {
      _room = room;
      _joined = true;
    });
  }

  void _onRoomChanged() {
    // debug info nếu cần
    print("Room state: ${_room?.connectionState}");
  }

  @override
  void dispose() {
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LiveKit Audio Join")),
      body: Center(
        child: _joined
            ? const Text("🎧 Đã vào phòng và bật microphone")
            : const CircularProgressIndicator(),
      ),
    );
  }
}
