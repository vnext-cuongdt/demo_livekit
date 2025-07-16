import 'package:demo_livekit/pages/prejoin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/text_field.dart';

class ConnectPage extends StatefulWidget {
  //
  const ConnectPage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  //
  static const _storeKeyUri = 'uri';
  static const _storeKeyToken = 'token';
  static const _storeKeySimulcast = 'simulcast';
  static const _storeKeyAdaptiveStream = 'adaptive-stream';
  static const _storeKeyDynacast = 'dynacast';
  static const _storeKeyE2EE = 'e2ee';
  static const _storeKeySharedKey = 'shared-key';
  static const _storeKeyMultiCodec = 'multi-codec';

  final _uriCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _simulcast = true;
  bool _adaptiveStream = true;
  bool _dynacast = true;
  bool _busy = false;
  bool _e2ee = false;
  bool _multiCodec = false;
  String _preferredCodec = 'VP8';

  @override
  void initState() {
    super.initState();
    if (lkPlatformIs(PlatformType.android)) {
      _checkPermissions();
    }
    _uriCtrl.text = 'ws://192.84.100.204:7880';
    _tokenCtrl.text = 'eyJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoidXNlcjMyMSIsInZpZGVvIjp7InJvb21Kb2luIjp0cnVlLCJyb29tIjoiZW5nbGlzaC1yb29tIiwiY2FuUHVibGlzaCI6dHJ1ZX0sImlzcyI6ImRldmtleSIsImV4cCI6MTc1MjY5MzE4MywibmJmIjowLCJzdWIiOiJ1c2VyMzIxIn0.zuZeWotvi2FANGn9LdgpvIYxqeeuDYNskwNUt_Ig4Pk';
  }

  @override
  void dispose() {
    _uriCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.bluetooth.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Permission disabled');
    }

    status = await Permission.bluetoothConnect.request();
    if (status.isPermanentlyDenied) {
      print('Bluetooth Connect Permission disabled');
    }

    status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      print('Camera Permission disabled');
    }

    status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      print('Microphone Permission disabled');
    }
  }





  Future<void> _connect(BuildContext ctx) async {
    //
    try {
      setState(() {
        _busy = true;
      });

      // Save URL and Token for convenience

      print('Connecting with url: ${_uriCtrl.text}, '
          'token: ${_tokenCtrl.text}...');

      var url = _uriCtrl.text;
      var token = _tokenCtrl.text;

      await Navigator.push<void>(
        ctx,
        MaterialPageRoute(
            builder: (_) => PreJoinPage(
              args: JoinArgs(
                url: url,
                token: token,
                e2ee: _e2ee,
                simulcast: _simulcast,
                adaptiveStream: _adaptiveStream,
                dynacast: _dynacast,
                preferredCodec: _preferredCodec,
                enableBackupVideoCodec:
                ['VP9', 'AV1'].contains(_preferredCodec),
              ),
            )),
      );
    } catch (error) {
      print('Could not connect $error');
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }








  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: SvgPicture.asset(
                  'images/logo-dark.svg',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: LKTextField(
                  label: 'Server URL',
                  ctrl: _uriCtrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: LKTextField(
                  label: 'Token',
                  ctrl: _tokenCtrl,
                ),
              ),

              ElevatedButton(
                onPressed: _busy ? null : () => _connect(context),
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
                    const Text('CONNECT'),
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