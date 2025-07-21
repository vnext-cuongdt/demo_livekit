import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_components/livekit_components.dart';

class MyHomePage extends StatefulWidget {

  const MyHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String _url = 'ws://192.84.100.204:7880';
  final String _token =
      'eyJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoidXNlcjMyMSIsInZpZGVvIjp7InJvb21Kb2luIjp0cnVlLCJyb29tIjoiZW5nbGlzaC1yb29tIiwiY2FuUHVibGlzaCI6dHJ1ZSwiY2FuU3Vic2NyaWJlIjp0cnVlfSwicm9vbUNvbmZpZyI6eyJuYW1lIjoiIiwiZW1wdHlUaW1lb3V0IjowLCJkZXBhcnR1cmVUaW1lb3V0IjowLCJtYXhQYXJ0aWNpcGFudHMiOjAsIm1pblBsYXlvdXREZWxheSI6MCwibWF4UGxheW91dERlbGF5IjowLCJzeW5jU3RyZWFtcyI6ZmFsc2UsImFnZW50cyI6W3siYWdlbnROYW1lIjoibm92YS1hZ2VudCIsIm1ldGFkYXRhIjoie1widXNlcl9pZFwiOiBcIjEyMzQ1XCJ9In1dfSwiaXNzIjoiZGV2a2V5IiwiZXhwIjoxNzUzMDg3NDQ3LCJuYmYiOjAsInN1YiI6InVzZXIzMjEifQ.YOlsHrv_1cEAUblPXE35plcbwH7cZWbtDnVrOZnheak';

  /// handle join button pressed, fetch connection details and connect to room.
  // ignore: unused_element
  void _onJoinPressed(RoomContext roomCtx, String url, String token) async {
    if (kDebugMode) {
      print('Joining room: url=$url, token=$token');
    }
    try {
      await roomCtx.connect(url: url, token: token);
    }  on LiveKitException catch (e) {
      print('🔴 LiveKitException: ${e.message}');
    } on SocketException catch (e) {
      print('🔴 SocketException: $e');
    } catch (e) {
      print('🔴 Other error: $e');
    }

  }



  @override
  Widget build(BuildContext context) {
    return LivekitRoom(
      roomContext: RoomContext(
        roomOptions: RoomOptions(
          defaultAudioCaptureOptions: AudioCaptureOptions(),
          defaultAudioOutputOptions: AudioOutputOptions(),
          defaultAudioPublishOptions: const AudioPublishOptions(),
        ),
        enableAudioVisulizer: true,
        onConnected: () {
          if (kDebugMode) {
            print('Connected to room');
          }
        },
        onDisconnected: () {
          if (kDebugMode) {
            print('Disconnected from room');
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Error: $error');
          }
        },
      ),
      builder: (context, roomCtx) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'LiveKit Components',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              /// show clear pin button
              if (roomCtx.connected) const ClearPinButton(),
            ],
          ),
          body: Stack(
            children: [
              !roomCtx.connected && !roomCtx.connecting
                  /// show prejoin screen if not connected
                  ? Prejoin(
                    token: _token,
                    url: _url,
                    onJoinPressed: _onJoinPressed,
                  )
                  :
                  /// show room screen if connected
                  Row(
                    children: [
                      /// show chat widget on mobile
                      (roomCtx.isChatEnabled)
                          ? Expanded(
                            child: ChatBuilder(
                              builder: (context, enabled, chatCtx, messages) {
                                return ChatWidget(
                                  messages: messages,
                                  onSend:
                                      (message) => chatCtx.sendMessage(message),
                                  onClose: () {
                                    chatCtx.toggleChat(false);
                                  },
                                );
                              },
                            ),
                          )
                          : Expanded(
                            flex: 6,
                            child: Stack(
                              children: <Widget>[
                                /// show participant loop
                                ParticipantLoop(
                                  showAudioTracks: true,
                                  showVideoTracks: true,
                                  showParticipantPlaceholder: true,

                                  /// layout builder
                                  layoutBuilder:
                                      roomCtx.pinnedTracks.isNotEmpty
                                          ? const CarouselLayoutBuilder()
                                          : const GridLayoutBuilder(),

                                  /// participant builder
                                  participantTrackBuilder: (
                                    context,
                                    identifier,
                                  ) {
                                    // build participant widget for each Track
                                    return Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Stack(
                                        children: [
                                          /// video track widget in the background
                                          identifier.isAudio &&
                                                  roomCtx.enableAudioVisulizer
                                              ? const AudioVisualizerWidget(
                                                backgroundColor:
                                                    LKColors.lkDarkBlue,
                                              )
                                              : IsSpeakingIndicator(
                                                builder: (context, isSpeaking) {
                                                  return isSpeaking != null
                                                      ? IsSpeakingIndicatorWidget(
                                                        isSpeaking: isSpeaking,
                                                        child:
                                                            const VideoTrackWidget(),
                                                      )
                                                      : const VideoTrackWidget();
                                                },
                                              ),

                                          /// focus toggle button at the top right
                                          const Positioned(
                                            top: 0,
                                            right: 0,
                                            child: FocusToggle(),
                                          ),

                                          /// track stats at the top left
                                          const Positioned(
                                            top: 8,
                                            left: 0,
                                            child: TrackStatsWidget(),
                                          ),

                                          /// status bar at the bottom
                                          const Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: ParticipantStatusBar(),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                /// show control bar at the bottom
                                const Positioned(
                                  bottom: 30,
                                  left: 0,
                                  right: 0,
                                  child: ControlBar(),
                                ),
                              ],
                            ),
                          ),

                      /// show chat widget on desktop
                      (roomCtx.isChatEnabled)
                          ? Expanded(
                            flex: 2,
                            child: SizedBox(
                              width: 400,
                              child: ChatBuilder(
                                builder: (context, enabled, chatCtx, messages) {
                                  return ChatWidget(
                                    messages: messages,
                                    onSend:
                                        (message) =>
                                            chatCtx.sendMessage(message),
                                    onClose: () {
                                      chatCtx.toggleChat(false);
                                    },
                                  );
                                },
                              ),
                            ),
                          )
                          : const SizedBox(width: 0, height: 0),
                    ],
                  ),

              /// show toast widget
              const Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: ToastWidget(),
              ),
            ],
          ),
        );
      },
    );
  }
}
