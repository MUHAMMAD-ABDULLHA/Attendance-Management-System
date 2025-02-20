import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class UserPanel extends StatefulWidget {
  final String userId;

  const UserPanel({Key? key, required this.userId}) : super(key: key);

  @override
  _UserPanelState createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  Future<void> _fetchProfileImage() async {
    try {
      final databaseRef = FirebaseDatabase.instance.ref('users/${widget.userId}/profilePicture');
      final snapshot = await databaseRef.get();

      if (snapshot.exists) {
        final base64Image = snapshot.value as String;
        setState(() => _imageBytes = base64Decode(base64Image));
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  Future<void> markAttendance() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseDatabase.instance.ref('attendance/${widget.userId}/$today').set({
        'userId': widget.userId, // Add userId to the record
        'date': today,
        'status': 'present',
      });
    } catch (e) {
      print('Error marking attendance: $e');
    }
  }

  Future<void> sendLeaveRequest(BuildContext context) async {
    final reasonController = TextEditingController();
    DateTime? selectedDate;

    bool isDateValid(DateTime date) {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      return !(date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) &&
          !date.isBefore(startOfToday);
    }

    Future<bool> isAttendanceMarked(String date) async {
      final snapshot = await FirebaseDatabase.instance
          .ref('attendance/${widget.userId}/$date')
          .get();
      return snapshot.exists;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Send Leave Request',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.deepPurple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null && isDateValid(pickedDate)) {
                  selectedDate = pickedDate;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid date. Please select a future weekday.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                selectedDate == null
                    ? 'Select Date'
                    : 'Selected: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a date.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
              if (await isAttendanceMarked(formattedDate)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attendance already marked for this date.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await FirebaseDatabase.instance.ref('leave_requests').push().set({
                  'userId': widget.userId,
                  'date': formattedDate,
                  'reason': reasonController.text,
                  'status': 'pending',
                });
                Navigator.pop(context);
              } catch (e) {
                print('Error sending leave request: $e');
              }
            },
            child: const Text(
              'Submit',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      Uint8List? pickedFile;
      if (kIsWeb) {
        pickedFile = await ImagePickerWeb.getImageAsBytes();
      } else {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        pickedFile = await image?.readAsBytes();
      }

      if (pickedFile != null) {
        setState(() => _imageBytes = pickedFile);
        await FirebaseDatabase.instance
            .ref('users/${widget.userId}/profilePicture')
            .set(base64Encode(pickedFile));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Panel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.deepPurple.shade50,
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
              child: _imageBytes == null
                  ? const Icon(Icons.person, size: 60, color: Colors.deepPurple)
                  : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upload Profile Picture',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: markAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mark Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => sendLeaveRequest(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Leave Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Colors.deepPurple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.deepPurple,
                      tabs: [
                        Tab(text: 'Attendance'),
                        Tab(text: 'Leave Requests'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildAttendanceList(),
                          _buildLeaveRequestsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('attendance/${widget.userId}').onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No attendance records found'));
        }

        final records = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final sortedDates = records.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final date = sortedDates[index];
            final status = records[date]['status'];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text('Date: $date'),
                subtitle: Text('Status: ${status.toString().toUpperCase()}'),
                trailing: Icon(
                  status == 'present'
                      ? Icons.check_circle
                      : Icons.leave_bags_at_home,
                  color: status == 'present' ? Colors.green : Colors.blue,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaveRequestsList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('leave_requests')
          .orderByChild('userId').equalTo(widget.userId).onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No leave requests found'));
        }

        final rawData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final requests = rawData.values.toList().reversed.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text('Date: ${request['date']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason: ${request['reason']}'),
                    Text(
                      'Status: ${request['status']}',
                      style: TextStyle(
                        color: _getStatusColor(request['status']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}