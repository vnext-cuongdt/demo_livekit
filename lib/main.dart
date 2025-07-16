import 'dart:convert';
import 'package:demo_livekit/pages/connect.dart';
import 'package:flutter/material.dart';

const String livekitHost = 'http://192.84.5.83:7880/'; // địa chỉ máy chủ LiveKit
const String roomName = 'demo-room';
final String identity = 'user-${DateTime.now().millisecondsSinceEpoch}';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveKit Flutter Demo',
      home: ConnectPage(),
    );
  }
}
