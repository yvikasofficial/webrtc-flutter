import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:nft/Constants.dart';
import 'package:nft/pages/Home/PickUpScreen.dart';
import 'package:nft/pages/Home/ShowUserList.dart';
import 'package:nft/pages/webrtc/signaling.dart';
import 'package:toast/toast.dart';

class HomeScreen extends StatefulWidget {
  final String uid;

  HomeScreen({this.uid});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging().configure(
      onMessage: (message) async {
        print(message);
        if (message['data']['type'] == 'hasDialed') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PickupPage(
                name: "myname",
                deviceID: message['data']['deviceId'],
              ),
            ),
          );
        } else if (message['data']['type'] == 'hasEnded') {
          Navigator.pop(context);
          Toast.show("Call ended!", context,
              duration: Toast.LENGTH_SHORT, gravity: Toast.BOTTOM);
        }
      },
      onLaunch: (message) async {},
      onResume: (message) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: ShowUserList(
        uid: widget.uid,
      ),
    );
  }
}
