import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parental_app/widgets/map_display.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends State<MapScreen> {
  String childId = '';

  Map<String, String>? childrenMap;

  @override
  void initState() {
    super.initState();
    String parentUserId = FirebaseAuth.instance.currentUser!.uid;

    getChildrenMap(parentUserId).then((namesList) {
      setState(() {
        childrenMap = namesList;
        childId = childrenMap!.entries.first.value;
      });
    });
  }

  Future<Map<String, String>> getChildrenMap(String parentUserId) async {
    Map<String, String> childrenMap = {};

    try {
      // Fetch the 'Children' collection from Firestore
      QuerySnapshot childrenSnapshot = await FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(parentUserId)
          .collection('Children')
          .get();

      // Build a map of names to UIDs
      for (var doc in childrenSnapshot.docs) {
        String name =
            doc['name']; // presupunem că 'name' este un câmp din document
        String uid = doc.id; // UID-ul este ID-ul documentului
        childrenMap[name] = uid;
      }
    } catch (e) {
      // If there is an error, return an empty map or handle the error as needed
      print('Error fetching children data: $e');
    }

    return childrenMap;
  }

  Future<String?> _selectChild(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select child\'s location'),
          content: SingleChildScrollView(
            child: ListBody(
              children: childrenMap!.entries.map((entry) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(entry.value),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool childrenAvailable = childrenMap != null && childrenMap!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        backgroundColor: const Color.fromARGB(255, 117, 213, 243),
        
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Aici trebuie să folosim await pentru a aștepta selecția utilizatorului
          final selectedChildId = await _selectChild(context);
          if (selectedChildId != null) {
            setState(() {
              childId = selectedChildId;
            });
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(Icons.location_on),
      ),
      body: childrenAvailable
          ? MapDisplay(childId: childId)
          : const Align(
              alignment: Alignment.center,
              child: Text('No children available for tracking'),
            ),
    );
  }
}
