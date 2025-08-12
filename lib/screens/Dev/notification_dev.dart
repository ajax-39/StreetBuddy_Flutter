// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:street_buddy/services/push_notification_service.dart';

class NotificationDev extends StatefulWidget {
  const NotificationDev({super.key});

  @override
  State<NotificationDev> createState() => _NotificationDevState();
}

class _NotificationDevState extends State<NotificationDev> {
  List<String> Users = [];
  List<bool> Success = [];
  String title = '';
  String body = '';
  String route = '';
  late Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  void getStream() {
    setState(() {
      stream = FirebaseFirestore.instance.collection('users').snapshots();
    });
  }

  @override
  void initState() {
    super.initState();
    getStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Manager'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                  width: 2,
                )),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                          width: 2,
                        )),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'POST',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange.shade900,
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Container(
                                width: 2,
                                height: 25,
                                color: Colors.black,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: Text(
                                  'https://fcm.googleapis.com/v1/projects/streetbuddy-bd84d/messages:send',
                                  maxLines: 2,
                                  style: GoogleFonts.shareTechMono(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    StreamBuilder(
                        stream: stream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }

                          Users = snapshot.data!.docs
                              .map(
                                (e) => e.id,
                              )
                              .toList();

                          return Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text.rich(
                                    style: GoogleFonts.robotoMono(),
                                    TextSpan(
                                      text:
                                          '{ \n  "message": { \n    "token": ',
                                      children: [
                                        TextSpan(
                                          text: 'Users<id>/token.every',
                                          style: GoogleFonts.shareTechMono(
                                            color: Colors.white,
                                            fontStyle: FontStyle.italic,
                                            backgroundColor:
                                                Colors.deepOrange.shade900,
                                          ),
                                        ),
                                        TextSpan(
                                            text: ',\n    "notification": {'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  onChanged: (value) => title = value,
                                  style: GoogleFonts.robotoMono(),
                                  decoration:
                                      InputDecoration(hintText: 'title:'),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  onChanged: (value) => body = value,
                                  style: GoogleFonts.robotoMono(),
                                  decoration:
                                      InputDecoration(hintText: 'body:'),
                                ),
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    style: GoogleFonts.robotoMono(),
                                    '    },\n    "data": {',
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  style: GoogleFonts.robotoMono(),
                                  decoration:
                                      InputDecoration(hintText: 'route: (opt)'),
                                ),
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    style: GoogleFonts.robotoMono(),
                                    '    "type": "misc"\n    }\n  }\n}',
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'OAuth',
                          style: GoogleFonts.robotoMono(),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 18,
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(),
                              side: BorderSide(
                                color: Colors.deepOrange.shade900,
                                width: 2,
                              )),
                          onPressed: () async {
                            for (var i in Users) {
                              try {
                                if (title.isNotEmpty && body.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('users/$i/pref')
                                      .doc('token')
                                      .get()
                                      .then(
                                    (value) async {
                                      if (value.exists) {
                                        await PushNotificationService
                                            .sendPushNotification(
                                                value
                                                    .data()!['token']
                                                    .toString(),
                                                title,
                                                body,
                                                route.isNotEmpty ? route : '/',
                                                'alert');
                                        setState(() {
                                          Success.add(true);
                                        });
                                      } else {
                                        setState(() {
                                          Success.add(false);
                                        });
                                      }
                                    },
                                  );
                                } else {}
                              } catch (e) {
                                print(e.toString());
                              }
                            }
                          },
                          label: Text(
                            'SEND',
                            style: GoogleFonts.robotoMono(
                                color: Colors.deepOrange.shade900,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 4,
                    ),
                  ],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: Success.length,
              itemBuilder: (context, index) => Row(
                children: [
                  Text(Users[index]),
                  Icon(Success[index] ? Icons.done : Icons.cancel_outlined),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}
