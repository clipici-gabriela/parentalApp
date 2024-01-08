import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:parental_app/child_screens/tasks.dart';
import 'package:parental_app/location/location_service.dart';
import 'package:parental_app/parent_screens/parent_account.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    startLocationTracking();
  }

  LocationService _locationService = LocationService();

  void startLocationTracking() async {
    LocationData? locationData = await _locationService.getCurrentLocation();

    String childUserId = FirebaseAuth.instance.currentUser!.uid;

    // Send the location data to Firestore
    FirebaseFirestore.instance.collection('Locations').doc(childUserId).set({
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
      'timestamp':
          FieldValue.serverTimestamp(), // To get the time of the update
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account')
        ],
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
      body: <Widget>[
        const TasksList(),
        const ParentAccountScreen(),
      ][currentPageIndex],
    );
  }
}
