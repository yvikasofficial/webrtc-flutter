import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/UserProvider.dart';

class PickupPage extends StatefulWidget {
  final String name;
  final String deviceID;
  final Function function;
  final String channelName;

  PickupPage({this.name, this.deviceID, this.function, this.channelName});
  @override
  _DialPageState createState() => _DialPageState();
}

class _DialPageState extends State<PickupPage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final String serverToken =
      'AAAAbbuWh8c:APA91bGgNLx6SBtpR32P8QFrZxEfHFjJPlGv7rKXBUVlKaGP2v2PVRMnHrHpa0Q3XBKS87FlGHsLhgF0pwTb9tP2Rvg_1qTdM_d1ZsC4Kl3g6vAL1LHeQtcVqPa-TiQydU4_8zhe8Gbg';

  handleEndcall(to) async {
    await firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );

    final res = await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Tap to pick the call',
            'title': 'Someone dialing you'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'type': 'hasEnded',
            'status': 'done',
            'username': "Stonnis",
          },
          'to': to,
        },
      ),
    );
  }

  handlePickCall(to) async {
    var provider = Provider.of<UserProvider>(context, listen: false);
    await firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );

    final res = await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'Tap to pick the call',
            'title': 'Someone dialing you'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'type': 'hasPicked',
            'status': 'done',
            'username': "Stonnis",
            'code': provider.uid,
          },
          'to': to,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "images/bg.jpeg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(200),
                    child: Image.asset(
                      "images/girll.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  widget.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  "Video call",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            Container(),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await handlePickCall(widget.deviceID);
                    },
                    child: Container(
                      margin: EdgeInsets.all(30),
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => handleEndcall(widget.deviceID),
                    child: Container(
                      margin: EdgeInsets.all(30),
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
