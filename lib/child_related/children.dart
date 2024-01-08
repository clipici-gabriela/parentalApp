import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:parental_app/child_related/add_child.dart';
import 'package:parental_app/child_related/child_detaild.dart';
//import 'package:parental_app/parent_screens/child_detaild.dart';

class ChildrenList extends StatefulWidget {
  const ChildrenList({super.key});

  @override
  State<ChildrenList> createState() {
    return _ChildrenListState();
  }
}

class _ChildrenListState extends State<ChildrenList> {
  Future<List<DocumentSnapshot>>? childrenDocumentsFuture;

  @override
  void initState() {
    super.initState();
    //Initialize the future in initState so  it's only created once
    childrenDocumentsFuture =
        getChildrenDocuments(FirebaseAuth.instance.currentUser!.uid);
  }

  // Update the future to force the FutureBuilder to rerun it
  void refreshChildren() {
    childrenDocumentsFuture =
        getChildrenDocuments(FirebaseAuth.instance.currentUser!.uid);
  }

  //Open the dialog to add a new child/device
  void _openAddChildOverlay() async {
    final result = await showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => const AddChild(),
    );

    if (result == true) {
      setState(() {
        refreshChildren();
      });
    }
  }

//   void startTrackingChild(String childUid) {
//   FlutterBackgroundService().invoke('startTracking', {'childUid': childUid});
// }


  Future<List<DocumentSnapshot>> getChildrenDocuments(
      String parentUserId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('ParentsUsers')
        .doc(parentUserId)
        .collection('Children')
        .get();

    // Returning the list of document snapshots
    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: childrenDocumentsFuture,
      builder: (BuildContext context,
          AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: _openAddChildOverlay,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.add_to_home_screen_outlined),
            ),
            appBar: AppBar(
              title: const Text(
                'SafeSteps',
              ),
              backgroundColor: const Color.fromARGB(255, 117, 213, 243),
            ),
            body: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: snapshot.data!.length, //Number of children
              itemBuilder: (context, index) {
                var childData =
                    snapshot.data![index].data() as Map<String, dynamic>;

                String name = childData['name'];
                String imageURL =
                    childData['image']; // Placeholder for asset names
                String childID = snapshot.data![index].id;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChildDetailScreen(childId: childID),
                           // MapScreen(childId: childID),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(imageURL),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(name),
                    ],
                  ),
                );
              },
            ),
          );
        }
        return const Center(
          child: Text('No device found'),
        );
      },
    );
  }
}
