import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:users/controller/flutter_functions.dart';
import 'package:users/controller/user_intraction_manager.dart';
import 'package:users/providers/userprofiledatanotifier.dart';

import '../models/profiledata.dart';

class SaveProfile extends ConsumerStatefulWidget {
  const SaveProfile({super.key});

  @override
  ConsumerState<SaveProfile> createState() => _SaveProfileState();
}

class _SaveProfileState extends ConsumerState<SaveProfile> {
  bool init = true;

  bool automaticallyImplyLeading = true;
  String initialDateOfBirth = '';
  final _usernameController = TextEditingController();

  final _dateOfBirthController = TextEditingController();
  final _PlaceOfBirthController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (init) {
      // Update the value of automaticallyImplyLeading based on the arguments
      final arguments = ModalRoute.of(context)?.settings.arguments as Map?;
      if (arguments != null &&
          arguments.containsKey('automaticallyImplyLeading')) {
        automaticallyImplyLeading =
            arguments['automaticallyImplyLeading'] as bool;
      }
      init = false;
      // Don't set the value of the controllers here
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _dateOfBirthController.dispose();

    _PlaceOfBirthController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileData = ref.watch(userProfileDataProvider);

    final userInteractionManager = ref.watch(userInteractionManagerProvider);
    if (userProfileData.data != null) {
      if (userProfileData.data![0].dateofbirth != null &&
          userInteractionManager.dateAndTimeOfBirth == null &&
          userInteractionManager.selectedTimeOfBirth == null) {
        initialDateOfBirth = userProfileData.data![0].dateofbirth!;
      } else if (userProfileData.data![0].dateofbirth != null &&
          userInteractionManager.dateAndTimeOfBirth != null &&
          userInteractionManager.selectedTimeOfBirth != null) {
        initialDateOfBirth =
            '${userInteractionManager.dateOfBirth} ${userInteractionManager.selectedTimeOfBirth!.hour.toString().padLeft(2, '0')}:${userInteractionManager.selectedTimeOfBirth!.minute.toString().padLeft(2, '0')}';
      }
      _dateOfBirthController.text = initialDateOfBirth;

      if (userProfileData.data![0].username != null) {
        _usernameController.text = userProfileData.data![0].username!;
      }
      if (userProfileData.data![0].placeofbirth != null) {
        _PlaceOfBirthController.text = userProfileData.data![0].placeofbirth!;
      }
    }
    File? currentImageFile;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        title: const Text('Save profile'),
      ),
      body: Form(
        key: formKey,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: 200.0,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take a photo'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final pickedFile =
                                      await userInteractionManager
                                          .onImageButtonPress(
                                              ImageSource.camera);
                                  if (pickedFile != null) {
                                    ref
                                        .read(userProfileDataProvider.notifier)
                                        .setImageFile(pickedFile);
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Choose from gallery'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  final pickedFile =
                                      await userInteractionManager
                                          .onImageButtonPress(
                                              ImageSource.gallery);
                                  if (pickedFile != null) {
                                    ref
                                        .read(userProfileDataProvider.notifier)
                                        .setImageFile(pickedFile);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: FutureBuilder<File?>(
                    future: ref
                        .read(userProfileDataProvider.notifier)
                        .getImageFile(context),
                    builder:
                        (BuildContext context, AsyncSnapshot<File?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final file = snapshot.data!;
                          currentImageFile = file;
                          return CircleAvatar(
                            radius: 50.0,
                            backgroundImage: FileImage(file),
                          );
                        } else {
                          return const CircleAvatar(
                            radius: 50.0,
                            child: Icon(Icons.person, size: 50.0),
                          );
                        }
                      } else {
                        return const CircleAvatar(
                          radius: 50.0,
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                    validator: (validator) {
                      if (validator == null || validator.isEmpty) {
                        return "please enter display name";
                      }
                      return null;
                    },
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                    onChanged: (value) => {}),
                Consumer(
                  builder: (context, ref, child) {
                    final userInteractionManager =
                        ref.watch(userInteractionManagerProvider);

                    // Check if date and time of birth are set
                    if (userInteractionManager.dateAndTimeOfBirth != null &&
                        userInteractionManager.selectedTimeOfBirth != null) {
                      String formattedTime =
                          '${userInteractionManager.selectedTimeOfBirth!.hour.toString().padLeft(2, '0')}:${userInteractionManager.selectedTimeOfBirth!.minute.toString().padLeft(2, '0')}';
                      _dateOfBirthController.text =
                          '${userInteractionManager.dateOfBirth} $formattedTime';
                    }

                    // Add the condition to check if the date of birth is not null
                    return TextFormField(
                      validator: (validator) {
                        if (validator == null || validator.isEmpty) {
                          return "please select date and time";
                        }
                        return null;
                      },
                      controller: _dateOfBirthController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                      ),
                      readOnly: true,
                      onTap: () {
                        Future.delayed(Duration.zero)
                            .then((value) =>
                                userInteractionManager.dateofbirth(context))
                            .then((value) => userInteractionManager
                                .selectTimeOfBirth(context));
                      },
                    );
                  },
                ),
                TextFormField(
                    validator: (validator) {
                      if (validator == null || validator.isEmpty) {
                        return "please enter place of birth";
                      }
                      return null;
                    },
                    controller: _PlaceOfBirthController,
                    decoration: const InputDecoration(
                      labelText: 'Place of Birth',
                    ),
                    onChanged: (value) => {}),
                const SizedBox(height: 16.0),
                Consumer(
                  builder: (context, ref, child) {
                    var userData = ref.read(userProfileDataProvider);
                    return ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          UserProfileData updatedUser = UserProfileData(
                            id: userProfileData.data![0].id,
                            username: _usernameController.text,
                            dateofbirth: _dateOfBirthController.text,
                            placeofbirth: _PlaceOfBirthController.text,
                          );
                          final userInteractionManager =
                              ref.read(userInteractionManagerProvider);
                          XFile? pickedFile = await userInteractionManager
                              .onImageButtonPress(ImageSource.gallery);
                          if (pickedFile != null) {
                            ref
                                .read(userProfileDataProvider.notifier)
                                .setImageFile(pickedFile);
                          }
                          await ref
                              .read(userProfileDataProvider.notifier)
                              .updateUserModel(
                                  userData.data![0].id!.toString(), updatedUser)
                              .then((value) => Future.delayed(Duration.zero)
                                  .then((value) => showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Success'),
                                            content: const Text(
                                                'Profile updated successfully'),
                                            actions: [
                                              ElevatedButton(
                                                child: const Text('OK'),
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pushNamedAndRemoveUntil(
                                                          'wellcome',
                                                          (Route<dynamic>
                                                                  route) =>
                                                              false);
                                                  //Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      )));

                          await ref
                              .read(userProfileDataProvider.notifier)
                              .updateUser(
                                  _usernameController.text,
                                  _PlaceOfBirthController.text,
                                  _dateOfBirthController.text,
                                  context);
                        }
                      },
                      child: const Text('Save Profile'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
