import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:nft/Constants.dart';
import 'package:nft/Providers/UserProvider.dart';
import 'package:nft/pages/Home/PickUpScreen.dart';
import 'package:nft/pages/Home/ShowUserList.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';

import 'signaling.dart';

class CallScreen extends StatelessWidget {
  final String ip;
  final String uid;

  const CallScreen({Key key, this.ip, this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CallProvider(),
      child: CallBody(
        ip: ip,
        uid: uid,
      ),
    );
  }
}

class CallBody extends StatefulWidget {
  static String tag = 'call_sample';

  final String ip;
  final String uid;

  CallBody({Key key, @required this.ip, this.uid}) : super(key: key);

  @override
  _CallBodyState createState() => _CallBodyState(serverIP: ip);
}

class _CallBodyState extends State<CallBody> {
  Signaling _signaling;
  var _selfId;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  final String serverIP;
  final TextEditingController textEditingController = TextEditingController();

  _CallBodyState({Key key, @required this.serverIP});

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
    FirebaseMessaging().configure(
      onMessage: (message) async {
        print(message);
        print("**********");
        if (message['data']['type'] == 'hasDialed') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickupPage(
                name: message['data']['username'],
                deviceID: message['data']['deviceId'],
                channelName: message['data']['callId'],
                function: handleStartDail,
              ),
            ),
          );
        } else if (message['data']['type'] == 'hasEnded') {
          Navigator.pop(context);
          Toast.show("Call ended!", context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
        } else if (message['data']['type'] == 'hasPicked') {
          Navigator.pop(context);
          _invitePeer(context, message['data']['code'], false);
        }
      },
      onLaunch: (message) async {},
      onResume: (message) async {},
    );
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  handleStartDail(String channelName) {
    _invitePeer(context, channelName, false);
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null) _signaling.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    if (_signaling == null) {
      _signaling = Signaling()..connect();

      _signaling.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew:
            this.setState(() {
              _inCalling = true;
            });
            break;
          case SignalingState.CallStateBye:
            this.setState(() {
              _localRenderer.srcObject = null;
              _remoteRenderer.srcObject = null;
              _inCalling = false;
            });
            break;
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
            break;
        }
      };

      _signaling.onEventUpdate = ((event) {
        var provider = Provider.of<UserProvider>(context, listen: false);

        final clientId = event['clientId'];
        provider.uid = event['clientId'];
        context.read<CallProvider>().updateClientIp(clientId);
      });

      _signaling.onPeersUpdate = ((event) {
        this.setState(() {
          _selfId = event['self'];
        });
      });

      _signaling.onLocalStream = ((stream) {
        _localRenderer.srcObject = stream;
      });

      _signaling.onAddRemoteStream = ((stream) {
        _remoteRenderer.srcObject = stream;
      });

      _signaling.onRemoveRemoteStream = ((stream) {
        _remoteRenderer.srcObject = null;
      });
    }
  }

  _invitePeer(context, peerId, useScreen) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling.invite(peerId, 'video', useScreen);
    }
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling.bye();
    }
  }

  _switchCamera() {
    _signaling.switchCamera();
  }

  _muteMic() {}

  @override
  Widget build(BuildContext context) {
    print("$_selfId ***************");
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text("Dial User"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.black38,
            ),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _inCalling
          ? SizedBox(
              width: 200.0,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FloatingActionButton(
                      child: const Icon(Icons.switch_camera),
                      onPressed: _switchCamera,
                    ),
                    FloatingActionButton(
                      onPressed: _hangUp,
                      tooltip: 'Hangup',
                      child: Icon(Icons.call_end),
                      backgroundColor: Colors.pink,
                    ),
                    FloatingActionButton(
                      child: const Icon(Icons.mic_off),
                      onPressed: _muteMic,
                    )
                  ]))
          : null,
      body: _inCalling
          ? OrientationBuilder(builder: (context, orientation) {
              return Container(
                child: Stack(children: <Widget>[
                  Positioned(
                      left: 0.0,
                      right: 0.0,
                      top: 0.0,
                      bottom: 0.0,
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: RTCVideoView(_remoteRenderer),
                        decoration: BoxDecoration(color: Colors.black54),
                      )),
                  Positioned(
                    left: 20.0,
                    top: 20.0,
                    child: Container(
                      width: orientation == Orientation.portrait ? 90.0 : 120.0,
                      height:
                          orientation == Orientation.portrait ? 120.0 : 90.0,
                      child: RTCVideoView(_localRenderer),
                      decoration: BoxDecoration(color: Colors.black54),
                    ),
                  ),
                ]),
              );
            })
          : ShowUserList(
              uid: widget.uid,
              clientId: _selfId,
            ),
    );
  }
}

class CallProvider with ChangeNotifier {
  String clientId = "";

  void updateClientIp(String newClientId) {
    clientId = newClientId;
    notifyListeners();
  }
}
