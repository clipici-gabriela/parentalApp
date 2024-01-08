import 'package:flutter/material.dart';

class ChildDetailScreen extends StatelessWidget {
  final String childId;

  const ChildDetailScreen({Key? key, required this.childId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the childId to fetch data and display details
    return Scaffold(
      appBar: AppBar(
        title: Text('Child Details'),
      ),
      body: Center(
        // Display the child's details here
        child: Text('Details for child ID: $childId'),
      ),
    );
  }
}
