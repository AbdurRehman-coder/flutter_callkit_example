import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  TextEditingController? email = TextEditingController();

  TextEditingController? name = TextEditingController();

  String? token;

  FirebaseMessaging? messaging;
  NotificationSettings? settings;

  @override
  void initState() {
    // TODO: implement initState
    messaging = FirebaseMessaging.instance;
    fetchperm();
    super.initState();
  }

  fetchperm() async {
    settings = await messaging?.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextField(
          controller: name,
          decoration: InputDecoration(label: Text("name")),
        ),
        TextField(
            controller: email,
            decoration: InputDecoration(label: Text("email"))),
        ElevatedButton(
            onPressed: () {
              messaging?.getAPNSToken().then((value) {
                print('APNs token: $value');
              });
              messaging?.getToken().then((value) {
                // token = value;

                FirebaseFirestore.instance
                    .collection(
                        'users') // Replace 'your_collection' with your collection name
                    .add({
                  'email': email?.text,
                  'name': name?.text,
                  'token': value
                }).then((valuedata) {
                  // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => Home(
                  //               name: name?.text,
                  //               myToken: value,
                  //             )));
                });
              });
              // setState(() {});
            },
            child: const Text("Register"))
      ]),
    );
  }
}
