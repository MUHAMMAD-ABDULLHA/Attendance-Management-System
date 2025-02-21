import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AttendanceLeaveScreen extends StatefulWidget {
  @override
  _AttendanceLeaveScreenState createState() => _AttendanceLeaveScreenState();
}

class _AttendanceLeaveScreenState extends State<AttendanceLeaveScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> leaves = [];
  List<Map<String, dynamic>> attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
    _fetchAttendance();
  }

  // ✅ Fetch Leave Requests
  void _fetchLeaves() {
    _database.child('leaves').onValue.listen((event) {
      if (event.snapshot.exists) {
        List<Map<String, dynamic>> tempLeaves = [];
        Map<dynamic, dynamic> leaveData = event.snapshot.value as Map<dynamic, dynamic>;

        leaveData.forEach((key, value) {
          tempLeaves.add({'id': key, ...value});
        });

        setState(() {
          leaves = tempLeaves;
        });
      }
    });
  }

  // ✅ Fetch Attendance
  void _fetchAttendance() {
    _database.child('attendance').onValue.listen((event) {
      if (event.snapshot.exists) {
        List<Map<String, dynamic>> tempAttendance = [];
        Map<dynamic, dynamic> attendanceData = event.snapshot.value as Map<dynamic, dynamic>;

        attendanceData.forEach((key, value) {
          tempAttendance.add({'id': key, ...value});
        });

        setState(() {
          attendanceRecords = tempAttendance;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance & Leave Requests")),
      body: Column(
        children: [
          Text("Leave Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: leaves.length,
              itemBuilder: (context, index) {
                var leave = leaves[index];
                return ListTile(
                  title: Text(leave['name'] ?? 'Unknown'),
                  subtitle: Text("Reason: ${leave['reason']}"),
                );
              },
            ),
          ),
          Text("Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                var record = attendanceRecords[index];
                return ListTile(
                  title: Text(record['name'] ?? 'Unknown'),
                  subtitle: Text("Status: ${record['status']}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
