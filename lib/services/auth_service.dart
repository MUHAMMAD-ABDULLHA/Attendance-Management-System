import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Realtime Database

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref(); // Realtime Database reference

  // Stream of authentication state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Register with email, password, username, and gender
  Future<void> register(String email, String password, String username, String gender) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data (username and gender) to Realtime Database
      await _database.child('users').child(userCredential.user!.uid).set({
        'email': email,
        'username': username,
        'gender': gender,
        'createdAt': DateTime.now().toIso8601String(), // Optional: Add a timestamp
      });

      notifyListeners(); // Notify listeners after registration
    } on FirebaseAuthException catch (e) {
      print("Registration Error: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected Error: $e");
      throw e;
    }
  }

  // Login with email and password
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners(); // Notify listeners after login
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("Unexpected Error: $e");
      throw e;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners(); // Notify listeners after logout
  }
}