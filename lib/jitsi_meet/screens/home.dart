// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
// import 'package:node_fcm_test/screens/incomingcall.dart';

// import 'package:node_fcm_test/state/callProvider.dart';
// import 'package:node_fcm_test/utils.dart';
// import 'package:provider/provider.dart';

// class Home extends StatefulWidget {
//   String? name;
//   String? myToken;

//   Home({super.key, this.name, this.myToken});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   FirebaseMessaging? messaging;
//   NotificationSettings? settings;
//   String? selectedUserName;
//   String? payload;
//   String name1 = "";
//   String email = "";
//   String token = "";
//   bool selfcall = false;
//   String userWhoCalledToken = "";

//   @override
//   void initState() {
//     messaging = FirebaseMessaging.instance;
//     permisisonHandler();
//     // Replace 'your_collection' with your collection name
//     name1 = widget.name ?? "";
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: appBar(),
//       body: Stack(
//         children: [
//           StreamBuilder<Object>(
//               stream:
//                   FirebaseFirestore.instance.collection('users').snapshots(),
//               builder: (context, AsyncSnapshot snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const CircularProgressIndicator();
//                 } else if (snapshot.hasData) {
//                   return ListView.builder(
//                       itemCount: snapshot.data!.docs.length,
//                       primary: false,
//                       shrinkWrap: true,
//                       itemBuilder: (context, index) {
//                         return GestureDetector(
//                           onTap: () {
//                             name1 = snapshot.data.docs[index]["name"];
//                             email = snapshot.data.docs[index]["email"];
//                             token = snapshot.data.docs[index]["token"];
//                             selfcall = true;
//                             Provider.of<CallProvider>(context, listen: false)
//                                 .setcallwindow(true);
//                             addcallEvent();
//                             sendNotification(
//                                 snapshot.data.docs[index]["token"] ?? "",
//                                 widget.myToken ?? "",
//                                 "${widget.name}${snapshot.data.docs[index]["name"]}",
//                                 widget.name ?? "",
//                                 "calling");
//                           },
//                           child: Container(
//                             padding: EdgeInsets.all(15),
//                             decoration: BoxDecoration(
//                               color: Colors
//                                   .grey[200], // Light grey background color
//                               borderRadius: BorderRadius.circular(
//                                   10), // Optional: Rounded corners
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black
//                                       .withOpacity(0.2), // Shadow color
//                                   spreadRadius: 5, // Spread radius
//                                   blurRadius: 7, // Blur radius
//                                   offset: Offset(0, 3), // Offset
//                                 ),
//                               ],
//                             ),
//                             child: Column(children: [
//                               Text(snapshot.data.docs[index]["name"] ?? ""),
//                               Text(snapshot.data.docs[index]["email"] ?? "")
//                             ]),
//                           ),
//                         );
//                       });
//                 }
//                 return Center(
//                   child: CircularProgressIndicator(),
//                 );
//               }),
//           Provider.of<CallProvider>(context).callValue
//               ? IncomingCallScreen(
//                   payload: payload,
//                   email: email,
//                   name: name1,
//                   selfCall: selfcall,
//                   token: selfcall ? token : userWhoCalledToken)
//               : const SizedBox()
//         ],
//       ),
//     );
//   }

//   appBar() {
//     return AppBar(
//       leading: Text(payload ?? "name afsdkf"),
//     );
//   }

//   addcallEvent() {
//     String result = compareStrings(name1, widget.name ?? "");
//     FirebaseFirestore.instance
//         .collection(
//             'calls') // Replace 'your_collection' with your collection name
//         .add({
//       'link': result,
//       'status': "calling",
//     });
//   }

//   String compareStrings(String string1, String string2) {
//     int result = string1.compareTo(string2);
//     if (result < 0) {
//       return 'Ascending order: $string1, $string2';
//     } else if (result > 0) {
//       return 'Descending order: $string2, $string1';
//     } else {
//       return 'The strings are equal: $string1, $string2';
//     }
//   }

//   permisisonHandler() async {
//     FirebaseMessaging.onMessage.listen((event) {
//       payload = event.data["payload"];
//       userWhoCalledToken = event.data["myToken"];
//       selfcall = false;
//       name1 = event.notification?.title.toString() ?? "";

//       Provider.of<CallProvider>(context, listen: false).setcallwindow(true);
//       if (event.notification!.body != "calling") {
//         Provider.of<CallProvider>(context, listen: false).setcallwindow(false);
//       }
//       setState(() {});
//     });
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

/// new code

class Home extends StatefulWidget {
  final String currentUserId;

  const Home({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _callStream;
  // Get the current user ID
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

// Get the current user's name from Firestore
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    initDate();
  }

  initDate() async {
    // Listen to changes in the 'calls' collection
    _callStream = FirebaseFirestore.instance
        .collection('calls')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
    getCurrentUserData();
    await requestNotificationPermission();
  }

  void getCurrentUserData() {
    // Check if the current user is authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      // Retrieve the current user's document from Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get()
          .then((doc) {
        if (doc.exists) {
          // Get the current user's name from the document
          currentUserName = doc['name'];
        } else {
          // Handle the case where the document doesn't exist
          currentUserName = 'Unknown'; // Default value
        }
      }).catchError((error) {
        // Handle any errors that occur while retrieving the data
        print('Error getting user data: $error');
        currentUserName = 'Unknown'; // Default value
      });
    }
  }

  Future<void> requestNotificationPermission() async {
    await FlutterCallkitIncoming.requestNotificationPermission({
      "rationaleMessagePermission":
          "Notification permission is required, to show notification.",
      "postNotificationMessageRequired":
          "Notification permission is required, Please allow notification permission from setting."
    });
  }

  // Function to initiate a call
  void initiateCall(String receiverId, String receiverName) {
    // Create a new document in the 'calls' collection
    FirebaseFirestore.instance.collection('calls').add({
      'caller_id': widget.currentUserId,
      'receiver_id': receiverId,
      'call_status': 'initiated',
      'caller_name': currentUserName,
      'receiver_name': receiverName,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      // Call document created successfully
      print('Call initiated successfully');
      // Get the document reference
      DocumentReference documentRef = value;

      // Retrieve the document using the reference
      documentRef.get().then((documentSnapshot) {
        // Check if the document exists and contains data
        if (documentSnapshot.exists) {
          // Access the data fields
          String callerId = documentSnapshot['caller_id'];
          String callStatus = documentSnapshot['call_status'];

          startOutGoingCall(currentUserId: callerId);

          // Use the retrieved data
          print('Caller ID: $callerId');
          print('Call Status: $callStatus');

          // Now you can pass these values to your method or perform any other operations
        } else {
          print('Document does not exist');
        }
      });
    }).catchError((error) {
      // Error creating call document
      print('Error initiating call: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _callStream,
        builder: (context, snapshot) {
          // Check if there is an incoming call
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            // Retrieve the latest call document
            QueryDocumentSnapshot<Map<String, dynamic>> latestCall =
                snapshot.data!.docs.first;

            // Display incoming call notification or screen
            // You can navigate to a separate call screen or show a dialog
            // with options to accept or decline the call
            // Example:
            // showDialog(
            //   context: context,
            //   builder: (context) => IncomingCallDialog(),
            // );

            // Access the fields from the latest call document
            String receiverId = latestCall['receiver_id'];
            String calledName = latestCall['caller_name'];
            String callStatus = latestCall['call_status'];

            // Pass the fields to the incomingCall() method
            incomingCall(currentUserId: receiverId, receiverName: calledName);
          }

          // If no incoming call, display list of users
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // Filter out the current user from the list
                List<QueryDocumentSnapshot<Map<String, dynamic>>> users =
                    snapshot.data!.docs
                        .where((doc) => doc.id != widget.currentUserId)
                        .toList();
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    // Display each user as a list tile
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(users[index]['name']),
                        tileColor: Colors.amberAccent.shade100,
                        onTap: () {
                          // Initiate call when user is tapped
                          initiateCall(
                            users[index].id,
                            users[index]['name'],
                          );
                        },
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }

  /// Outgoing call
  Future<void> startOutGoingCall({
    String currentUserId = '0',
  }) async {
    // _currentUuid = _uuid.v4();
    final params = CallKitParams(
      id: currentUserId,
      nameCaller: 'Hien Nguyen',
      handle: '0123456789',
      type: 1,
      extra: {'userId': '1a2b3c4d'},
      ios: const IOSParams(handleType: 'number'),
    );
    await FlutterCallkitIncoming.startCall(params);
  }

  /// Incoming Call
  Future<void> incomingCall({
    String currentUserId = '',
    String receiverName = '',
  }) async {
    // _currentUuid = _uuid.v4();

    final params = CallKitParams(
      id: currentUserId,
      nameCaller: 'Hien Nguyen',
      appName: 'Callkit',
      avatar: 'https://i.pravatar.cc/100',
      handle: '0123456789',
      type: 0,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{'userId': '1a2b3c4d'},
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }
}
