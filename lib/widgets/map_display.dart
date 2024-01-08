import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDisplay extends StatefulWidget{
  const MapDisplay({super.key, required this.childId});

  final String childId; 

  @override
  State<MapDisplay> createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Locations')
            .doc(widget.childId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.hasData && snapshot.data!.data() != null) {
            var locationData = snapshot.data!.data() as Map<String, dynamic>;
            var latitude = locationData['latitude'];
            var longitude = locationData['longitude'];

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('Name'),
                  position: LatLng(latitude, longitude),
                )
              },
            );
          }
          return const Text('No location data available.');
        },
      );
  }
}