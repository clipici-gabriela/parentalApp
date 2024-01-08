import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//enum Names { ion, mihai, andrei, adelina }

class AddNewTask extends StatefulWidget {
  const AddNewTask({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddNewTaskState();
  }
}

class _AddNewTaskState extends State<AddNewTask> {
  final _formKey = GlobalKey<FormState>();

  String _enteredTask = '';
  String? _assignedChild;

  TimeOfDay? _pickedTime;

  List<String>? childrenList;

  @override
  void initState() {
    super.initState();
    String parentUserId = FirebaseAuth.instance.currentUser!.uid;

    getChildrenNames(parentUserId).then((namesList) {
      setState(() {
        childrenList = namesList;
      });
    });
  }

  Future<List<String>> getChildrenNames(String parentUserId) async {
    try {
      // Fetch the 'Children' collection from Firestore
      QuerySnapshot childrenSnapshot = await FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(parentUserId)
          .collection('Children')
          .get();

      // Map the documents to their 'name' field
      List<String> childrenNames = childrenSnapshot.docs
          .map((doc) => doc.data()
              as Map<String, dynamic>) // Cast the data to a non-nullable Map
          .map((data) => data['name']
              as String) // Extract the 'name' field as a String
          .toList();

      return childrenNames;
    } catch (e) {
      // If there is an error, return an empty list or handle the error as needed
      print('Error fetching children names: $e');
      return [];
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay initialTime = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null &&
        (pickedTime.hour > initialTime.hour ||
            (pickedTime.hour == initialTime.hour &&
                pickedTime.minute > initialTime.minute))) {
      setState(() {
        _pickedTime = pickedTime; // Save the picked time in the state
      });
    } else {
      // Show an error message if the picked time is in the past
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a future time for today.")),
      );
    }
  }

  void _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields and pick a time'),
        ),
      );
      return;
    }

    final parentUser = FirebaseAuth.instance.currentUser;

    _formKey.currentState!.save();

    final now = DateTime.now();
    final deadlineDateTime = DateTime(
        now.year, now.month, now.day, _pickedTime!.hour, _pickedTime!.minute);

    //Create the task data
    final taskData = {
      'parentID' : parentUser!.uid,
      'description': _enteredTask,
      'assignedTo': _assignedChild,
      'deadline': Timestamp.fromDate(deadlineDateTime),
      'completed': false,
    };

    try {
      FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(parentUser.uid)
          .collection('Tasks')
          .add(taskData);

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Failed to add task')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add task: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return SizedBox(
      height: double.infinity,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Task'),
                  autocorrect: false,
                  validator: (value) {
                    if (value == null) {
                      return 'Please enter the task';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredTask = value!;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    FutureBuilder<List<String>>(
                      future: getChildrenNames(
                          FirebaseAuth.instance.currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.hasData) {
                          var childrenNames = snapshot.data!;

                          if (_assignedChild == null ||
                              !childrenNames.contains(_assignedChild)) {
                            _assignedChild = childrenNames.isNotEmpty
                                ? childrenNames.first
                                : null;
                          }

                          return DropdownButton<String>(
                            value: _assignedChild,
                            items: childrenNames
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _assignedChild = value!;
                              });
                            },
                          );
                        } else {
                          return const Text('No children available');
                        }
                      },
                    ),
                    const SizedBox(
                      width: 24,
                    ),
                    IconButton(
                      onPressed: () => _selectTime(context),
                      icon: const Icon(Icons.timer_sharp),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 15,
                ),
                Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
