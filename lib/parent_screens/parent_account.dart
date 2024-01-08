import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParentAccountScreen extends StatefulWidget {
  const ParentAccountScreen({super.key});

  @override
  State<ParentAccountScreen> createState() => _ParentAccountScreenState();
}

class _ParentAccountScreenState extends State<ParentAccountScreen> {
  bool _isParent = true;

  Future<DocumentSnapshot<Object>?> getUserDocument() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot<Object> parentUserDoc = await FirebaseFirestore.instance
          .collection('ParentsUsers')
          .doc(user.uid)
          .get();
      if (parentUserDoc.exists) {
        return parentUserDoc;
      }
    }
    DocumentSnapshot<Object> childUserDoc = await FirebaseFirestore.instance
        .collection('Children')
        .doc(user!.uid)
        .get();
    if (childUserDoc.exists) {
      setState(() {
        _isParent = false;
      });
      return childUserDoc;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Object>?>(
      future: getUserDocument(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Object>?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            Map<String, dynamic> userData =
                snapshot.data!.data() as Map<String, dynamic>;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Account'),
                backgroundColor: const Color.fromARGB(255, 117, 213, 243),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    children: [
                      if (_isParent)
                        Row(
                          children: [
                            Card(
                              child: Text('${userData['firstName']}'),
                            ),
                            Card(
                              child: Text('${userData['lastName']}'),
                            )
                          ],
                        ),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Account'),
            backgroundColor: const Color.fromARGB(255, 117, 213, 243),
          ),
          body: ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer),
            child: const Text('Logout'),
          ),
        );
      },
    );
  }
}
