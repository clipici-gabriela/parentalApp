import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:location/location.dart';
import 'package:parental_app/child_screens/home_screen.dart';
import 'package:parental_app/parent_screens/authentication.dart';
import 'package:parental_app/parent_screens/home.dart';
import 'package:parental_app/parent_screens/splsh.dart';
import 'firebase_options.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      // onBackground: onIosBackground,
    ),
  );
  service.startService();
}

void onStart(ServiceInstance service) async {
  Location location = Location();
  String? currentChildUid;

  service.on('startTracking').listen((event) {
    currentChildUid = event!['childUid'];
    // Now `currentChildUid` contains the UID of the child to track
  });

  // Ensure the service is running in the foreground with a persistent notification
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  bool serviceEnabled = await location.serviceEnabled();

  // Check if location service is enabled
  if (!serviceEnabled) {
    serviceEnabled = await location.requestService();
    if (!serviceEnabled) {
      return;
    }
  }

  // Check for location permissions
  PermissionStatus permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return;
    }
  }

  //Start listening for location changes
  location.onLocationChanged.listen((LocationData currentLocation) {
    //Location update, send the location to Firestore

    FirebaseFirestore.instance.collection('Locations').doc(currentChildUid).set({
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
    });

    service.invoke(
      'updateLocation',
      {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      },
    );
  });

  // Optionally, set a timer to perform the location fetch at intervals
  Timer.periodic(const Duration(minutes: 10), (timer) async {
    // Fetch the location periodically
    LocationData currentLocation = await location.getLocation();
    // Send to Firestore
    FirebaseFirestore.instance.collection('Locations').doc(currentChildUid).set({
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
    });
  });

}

void onIosBackground(ServiceInstance service) {
  // iOS-specific code for background service
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //await initializeBackgroundService();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  Future<String> getUserType(String uid) async {
    // Default to 'child' if user document or typeUser field is not found.
    String userType = 'child';
    try {
      // Try to get the user from the 'ParentsUsers' collection first
      DocumentSnapshot parentUserDoc = await FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(uid)
          .get();

      if (parentUserDoc.exists &&
          parentUserDoc.data() is Map<String, dynamic>) {
        // User is a parent
        userType = 'parent';
      } else {
        // If not found in 'ParentsUsers', check in the 'Children' subcollection of each parent
        QuerySnapshot parentUsersSnapshot =
            await FirebaseFirestore.instance.collection('ParentsUsers').get();

        for (var parentDoc in parentUsersSnapshot.docs) {
          DocumentSnapshot childUserDoc = await FirebaseFirestore.instance
              .collection('ParentsUsers')
              .doc(parentDoc.id)
              .collection('Children')
              .doc(uid)
              .get();

          if (childUserDoc.exists) {
            // User is a child
            userType = 'child';
            break; // Stop the loop if we find the user
          }
        }
      }
    } catch (e) {
      print('Failed to get user type: $e');
    }
    return userType;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        // ignore: deprecated_member_use
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 117, 213, 243)),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SpalshScreen();
          }
          if (snapshot.hasData) {
            return FutureBuilder<String>(
              future: getUserType(snapshot.data!.uid),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SpalshScreen(); // Show splash screen while loading user type
                }
                if (userTypeSnapshot.hasError) {
                  return const AuthenticationScreen(); // Fallback to authentication screen on error
                }
                if (userTypeSnapshot.data == 'parent') {
                  return const ParentHomeScreen(); // If user type is 'parent', go to ParentHomeScreen
                }
                return const ChildHomeScreen();
              },
            );
          }

          return const AuthenticationScreen();
        },
      ),
    );
  }
}
