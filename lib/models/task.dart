import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Task {
  final String id;
  final String parentId;
  final String description;
  final String assignedTo;
  final TimeOfDay deadline;
  final bool completed;

  Task(
      {required this.id,
      required this.parentId,
      required this.description,
      required this.assignedTo,
      required this.deadline,
      required this.completed});

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
          final deadlineTimestamp = data['deadline'] as Timestamp?;
    final deadlineDateTime = deadlineTimestamp?.toDate();
    final deadlineTimeOfDay = deadlineDateTime != null
        ? TimeOfDay(hour: deadlineDateTime.hour, minute: deadlineDateTime.minute)
        : null;

    return Task(
      id: id,
      parentId : data['parentID'],
      description: data['description'] as String? ??
          'No description', // Provide a default value
      assignedTo: data['assignedTo'] as String? ??
          'Unassigned', // Provide a default value
      deadline: deadlineTimeOfDay!, // Handle potential nulls
      completed: data['completed'] as bool? ?? false, // Provide a default value
    );
  }
}
