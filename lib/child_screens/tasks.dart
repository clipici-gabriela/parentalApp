import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parental_app/models/task.dart';

class TasksList extends StatefulWidget {
  const TasksList({super.key});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    //Initialize the future in initState so  it's only created once
    _fetchTasks();
  }

// Add a parameter to _fetchTasks to accept the child's name or ID
  Future<void> _fetchTasks() async {
    String childUser = FirebaseAuth.instance.currentUser!.uid;
    String parentId = '';
    String name = '';

    QuerySnapshot parentUsersSnapshot =
        await FirebaseFirestore.instance.collection('ParentsUsers').get();

    for (var parentDoc in parentUsersSnapshot.docs) {
      DocumentSnapshot childUserDoc = await FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(parentDoc.id)
          .collection('Children')
          .doc(childUser)
          .get();

      if (childUserDoc.exists) {
        parentId = childUserDoc['parentID'];
        name = childUserDoc['name'];
        break; // Stop the loop if we find the user
      }
    }

    QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
        .collection('ParentsUsers')
        .doc(parentId)
        .collection('Tasks')
        .where('assignedTo',
            isEqualTo: name) // Use Firestore query to filter by assignedTo
        .get();

    List<Task> fetchedTasks = tasksSnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Task.fromFirestore(doc.id, data);
    }).toList();

    setState(() {
      _tasks = fetchedTasks;
    });
  }

  void _toggleTaskCompletion(Task task) async {

    try {
      // Assuming task.id contains the document ID from Firestore
      await FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(task.parentId) // Make sure this is stored in the Task object
          .collection('Tasks')
          .doc(task.id)
          .update({'completed': !task.completed});

      setState(() {
        // Find the task in the list and update its completed status
        final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
        if (taskIndex != -1) {
          _tasks[taskIndex] = Task(
            id: _tasks[taskIndex].id,
            parentId: _tasks[taskIndex].parentId,
            description: _tasks[taskIndex].description,
            assignedTo: _tasks[taskIndex].assignedTo,
            deadline: _tasks[taskIndex].deadline,
            completed: !_tasks[taskIndex].completed,
          );
        }
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SafeSteps',
        ),
        backgroundColor: const Color.fromARGB(255, 117, 213, 243),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task.description),
            trailing: Text(task.deadline.format(context)),
            leading: IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {
                _toggleTaskCompletion(task);
              },
              color: task.completed ? Colors.green : Colors.grey,
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: _tasks.length,
      ),
    );
  }
}
