import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nft/Constants.dart';
import 'package:nft/Providers/UserProvider.dart';
import 'package:nft/Widget/UserCardWidget.dart';
import 'package:nft/pages/Home/DialScreen.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ShowUserList extends StatefulWidget {
  final String uid;
  final String clientId;
  final Function function;

  ShowUserList({this.uid, this.clientId, this.function});
  @override
  _ShowUserListState createState() => _ShowUserListState();
}

class _ShowUserListState extends State<ShowUserList> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final String serverToken =
      'AAAAbbuWh8c:APA91bGgNLx6SBtpR32P8QFrZxEfHFjJPlGv7rKXBUVlKaGP2v2PVRMnHrHpa0Q3XBKS87FlGHsLhgF0pwTb9tP2Rvg_1qTdM_d1ZsC4Kl3g6vAL1LHeQtcVqPa-TiQydU4_8zhe8Gbg';

  sendAndRetrieveMessage(to, name) async {
    var provider = Provider.of<UserProvider>(context, listen: false);
    await firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DialPage(
          name: name,
          deviceId: to,
        ),
      ),
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
            'type': 'hasDialed',
            'status': 'done',
            'callId': provider.uid,
            'deviceId': await firebaseMessaging.getToken(),
            'username': "Stonnis",
          },
          'to': to,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder(
        future: Firestore.instance.collection('users').getDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SpinKitDoubleBounce(color: kPrimaryColor);
          }

          return ListView.builder(
            itemCount: snapshot.data.documents.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return SizedBox(height: 40);
              }
              if (widget.uid == snapshot.data.documents[index - 1]['uid']) {
                return Container();
              }
              return GestureDetector(
                  onTap: () => sendAndRetrieveMessage(
                        snapshot.data.documents[index - 1]['token'],
                        snapshot.data.documents[index - 1]['username'],
                      ),
                  child:
                      UserCardWidget(json: snapshot.data.documents[index - 1]));
            },
          );
        },
      ),
    );
  }
}
