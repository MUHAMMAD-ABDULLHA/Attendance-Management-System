// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
//
// class StorageService {
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   Future<String> uploadProfilePicture(String userId, File image) async {
//     final storageRef = _storage.ref().child('profile_pictures/$userId.jpg');
//     await storageRef.putFile(image);
//     return await storageRef.getDownloadURL();
//   }
// }