import 'dart:async';
import 'dart:math' as math;

import 'package:demo_livekit/pages/room.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class JoinArgs {
  JoinArgs({
    required this.url,
    required this.token,
    this.e2ee = false,
    this.simulcast = true,
    this.adaptiveStream = true,
    this.dynacast = true,
    this.preferredCodec = 'VP8',
    this.enableBackupVideoCodec = true,
  });

  final String url;
  final String token;
  final bool e2ee;
  final bool simulcast;
  final bool adaptiveStream;
  final bool dynacast;
  final String preferredCodec;
  final bool enableBackupVideoCodec;
}

class PreJoinPage extends StatefulWidget {
  const PreJoinPage({required this.args, super.key});

  final JoinArgs args;

  @override
  State<StatefulWidget> createState() => _PreJoinPageState();
}

class _PreJoinPageState extends State<PreJoinPage> {
  List<MediaDevice> _audioInputs = [];
  List<MediaDevice> _videoInputs = [];
  StreamSubscription? _subscription;

  bool _busy = false;
  bool _enableVideo = true;
  bool _enableAudio = true;
  LocalAudioTrack? _audioTrack;
  LocalVideoTrack? _videoTrack;

  MediaDevice? _selectedVideoDevice;
  MediaDevice? _selectedAudioDevice;
  VideoParameters _selectedVideoParameters = VideoParametersPresets.h720_169;

  @override
  void initState() {
    super.initState();
    _subscription = Hardware.instance.onDeviceChange.stream.listen(
      _loadDevices,
    );
    Hardware.instance.enumerateDevices().then(_loadDevices);
  }

  @override
  void deactivate() {
    _subscription?.cancel();
    super.deactivate();
  }

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    if (_audioInputs.isNotEmpty) {
      if (_selectedAudioDevice == null) {
        _selectedAudioDevice = _audioInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await _changeLocalAudioTrack();
          setState(() {});
        });
      }
    }

    if (_videoInputs.isNotEmpty) {
      if (_selectedVideoDevice == null) {
        _selectedVideoDevice = _videoInputs.first;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await _changeLocalVideoTrack();
          setState(() {});
        });
      }
    }
    setState(() {});
  }

  // Future<void> _setEnableVideo(value) async {
  //   _enableVideo = value;
  //   if (!_enableVideo) {
  //     await _videoTrack?.stop();
  //     _videoTrack = null;
  //   } else {
  //     await _changeLocalVideoTrack();
  //   }
  //   setState(() {});
  // }

  Future<void> _setEnableAudio(value) async {
    _enableAudio = value;
    if (!_enableAudio) {
      await _audioTrack?.stop();
      _audioTrack = null;
    } else {
      await _changeLocalAudioTrack();
    }
    setState(() {});
  }

  Future<void> _changeLocalAudioTrack() async {
    if (_audioTrack != null) {
      await _audioTrack!.stop();
      _audioTrack = null;
    }

    if (_selectedAudioDevice != null) {
      _audioTrack = await LocalAudioTrack.create(
        AudioCaptureOptions(deviceId: _selectedAudioDevice!.deviceId),
      );
      await _audioTrack!.start();
    }
  }

  Future<void> _changeLocalVideoTrack() async {
    if (_videoTrack != null) {
      await _videoTrack!.stop();
      _videoTrack = null;
    }

    if (_selectedVideoDevice != null) {
      _videoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          deviceId: _selectedVideoDevice!.deviceId,
          params: _selectedVideoParameters,
        ),
      );
      await _videoTrack!.start();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  _join(BuildContext context) async {
    _busy = true;

    setState(() {});

    var args = widget.args;

    try {
      //create new room
      var cameraEncoding = const VideoEncoding(
        maxBitrate: 5 * 1000 * 1000,
        maxFramerate: 30,
      );

      var screenEncoding = const VideoEncoding(
        maxBitrate: 3 * 1000 * 1000,
        maxFramerate: 15,
      );



      final room = Room(
        roomOptions: RoomOptions(
          adaptiveStream: args.adaptiveStream,
          dynacast: args.dynacast,
          defaultAudioCaptureOptions: AudioCaptureOptions(),
          defaultAudioOutputOptions: AudioOutputOptions(),
          defaultAudioPublishOptions: const AudioPublishOptions(),
          // defaultCameraCaptureOptions: const CameraCaptureOptions(
          //   maxFrameRate: 30,
          //   params: VideoParameters(dimensions: VideoDimensions(1280, 720)),
          // ),
          // defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
          //   useiOSBroadcastExtension: true,
          //   params: VideoParameters(
          //     dimensions: VideoDimensionsPresets.h1080_169,
          //   ),
          // ),
          // defaultVideoPublishOptions: VideoPublishOptions(
          //   simulcast: args.simulcast,
          //   videoCodec: args.preferredCodec,
          //   backupVideoCodec: BackupVideoCodec(
          //     enabled: args.enableBackupVideoCodec,
          //   ),
          //   videoEncoding: cameraEncoding,
          //   screenShareEncoding: screenEncoding,
          // ),
        ),
      );
      // Create a Listener before connecting
      final listener = room.createListener();

      await room.prepareConnection(args.url, args.token);
      print('args.url ${args.url}');


      // Try to connect to the room
      // This will throw an Exception if it fails for any reason.
      await room.connect(
        args.url,
        args.token,

        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(enabled: true, track: _audioTrack),
          // camera: TrackOption(track: _videoTrack, enabled: true),
        ),
      );


      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => RoomPage(room, listener)),
      );
    } catch (error) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Error'),
            content: Text('Could not connect $error'),
          )
      );
      print('Could not connect $error');
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _actionBack(BuildContext context) async {
    // await _setEnableVideo(false);
    await _setEnableAudio(false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Devices',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _actionBack(context),
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Padding(
                //   padding: const EdgeInsets.only(bottom: 10),
                //   child: SizedBox(
                //     width: 320,
                //     height: 240,
                //     child: Container(
                //       alignment: Alignment.center,
                //       color: Colors.black54,
                //       child:
                //           _videoTrack != null
                //               ? VideoTrackRenderer(
                //                 renderMode: VideoRenderMode.auto,
                //                 _videoTrack!,
                //               )
                //               : Container(
                //                 alignment: Alignment.center,
                //                 child: LayoutBuilder(
                //                   builder:
                //                       (ctx, constraints) => Icon(
                //                         Icons.videocam_off,
                //                         color: Colors.blue,
                //                         size:
                //                             math.min(
                //                               constraints.maxHeight,
                //                               constraints.maxWidth,
                //                             ) *
                //                             0.3,
                //                       ),
                //                 ),
                //               ),
                //     ),
                //   ),
                // ),

                ElevatedButton(
                  onPressed: _busy ? null : () => _join(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      const Text('JOIN'),
                    ],
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
