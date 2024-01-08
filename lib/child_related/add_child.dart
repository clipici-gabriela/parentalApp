// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:parental_app/widgets/user_image_picker.dart';

class AddChild extends StatefulWidget {
  const AddChild({super.key});

  @override
  State<AddChild> createState() {
    return _AddChildState();
  }
}

class _AddChildState extends State<AddChild> {
  final _formKey = GlobalKey<FormState>();

  String _enteredEmail = '';
  String _enteredPassword = '';
  String _enteredName = '';
  String _enteredAge = '';
  File? _selectedImage;

  Future<String?> createChildAccount(String email, String password) async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('createChildAccount');
    try {
      final result = await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
      });
      return result.data['uid'];
    } on FirebaseFunctionsException catch (e) {
      print('Error: ${e.code} - ${e.message}');
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  void _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      //...
      return;
    }
    var parentUser = FirebaseAuth.instance.currentUser;

    _formKey.currentState!.save();

    try {
      String? childUid =
          await createChildAccount(_enteredEmail, _enteredPassword);

      if (childUid != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('$childUid.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageURL = await storageRef.getDownloadURL();

        FirebaseFirestore.instance
            .collection('ParentsUsers')
            .doc(parentUser!.uid)
            .collection('Children')
            .doc(childUid)
            .set({
          'name': _enteredName,
          'email': _enteredEmail,
          'image': imageURL,
          'age': _enteredAge,
          'parentID': parentUser.uid,
          'typeUser': 'child',
        });

        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
        ),
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
                UserImagePicker(
                  onPickedImage: (pickedImage) {
                    _selectedImage = pickedImage;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Please enter the child name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredName = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || !value.contains(RegExp(r'[1-18]'))) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredAge = value!;
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text('The age should not be older than 18 years'),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email adress!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredEmail = value!;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null ||
                        value.trim().length < 8 ||
                        !value.contains(RegExp(r'[A-Z]')) ||
                        !value.contains(RegExp(r'[1-9]'))) {
                      return 'Password must be at least 8 characters long and includes a combination of numbers and uppercase letters!';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredPassword = value!;
                  },
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
