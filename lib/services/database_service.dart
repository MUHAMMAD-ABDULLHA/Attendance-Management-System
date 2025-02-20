import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  Future<void> markAttendance(String userId, String date) async {
    await _databaseRef.child('attendance/$userId/$date').set({
      'date': date,
      'status': 'present',
    });
  }

  Future<void> sendLeaveRequest(String userId, String date, String reason) async {
    await _databaseRef.child('leave_requests').push().set({
      'userId': userId,
      'date': date,
      'reason': reason,
      'status': 'pending',
    });
  }
}