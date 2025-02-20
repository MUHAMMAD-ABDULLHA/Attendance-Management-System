import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.ref('attendance');
  final DatabaseReference _leaveRef = FirebaseDatabase.instance.ref('leave_requests');

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await authService.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Students'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Attendance'),
              Tab(icon: Icon(Icons.beach_access), text: 'Leave Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentsList(),
            _buildAttendanceManagement(),
            _buildLeaveRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder(
      stream: _usersRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Attendance')),
              DataColumn(label: Text('Leaves')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.entries.map((entry) {
              final user = entry.value as Map<dynamic, dynamic>? ?? {};
              return DataRow(cells: [
                DataCell(Text(user['name']?.toString() ?? 'N/A')),
                DataCell(Text(user['email']?.toString() ?? 'N/A')),
                DataCell(Text(user['attendanceCount']?.toString() ?? '0')),
                DataCell(Text(user['leaveCount']?.toString() ?? '0')),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditUserDialog(entry.key, user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(entry.key),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceManagement() {
    return StreamBuilder(
      stream: _attendanceRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No attendance records found.'));
        }

        final attendanceRecords = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};

        return ListView.builder(
          itemCount: attendanceRecords.length,
          itemBuilder: (context, index) {
            final key = attendanceRecords.keys.elementAt(index);
            final record = attendanceRecords[key] as Map<dynamic, dynamic>? ?? {};
            if (record['userId'] == null || record['userId'].isEmpty) {
              return const ListTile(
                title: Text('Invalid user ID.'),
              );
            }

            return FutureBuilder(
              future: _usersRef.child(record['userId']).once(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }
                if (userSnapshot.hasError) {
                  return ListTile(
                    title: Text('Error: ${userSnapshot.error}'),
                  );
                }
                if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                  return const ListTile(
                    title: Text('User not found.'),
                  );
                }

                final user = userSnapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
                return ListTile(
                  title: Text(user['name']?.toString() ?? 'N/A'),
                  subtitle: Text(record['date']?.toString() ?? 'N/A'),
                  trailing: DropdownButton<String>(
                    value: record['status']?.toString() ?? 'Absent',
                    items: ['Present', 'Absent']
                        .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                    onChanged: (value) => _updateAttendanceStatus(key, value!),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeaveRequests() {
    return StreamBuilder(
      stream: _leaveRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No leave requests found.'));
        }

        final requests = snapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final key = requests.keys.elementAt(index);
            final request = requests[key] as Map<dynamic, dynamic>? ?? {};
            if (request['userId'] == null || request['userId'].isEmpty) {
              return const Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Invalid user ID.'),
                ),
              );
            }

            return FutureBuilder(
              future: _usersRef.child(request['userId']).once(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Loading...'),
                    ),
                  );
                }
                if (userSnapshot.hasError) {
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Error: ${userSnapshot.error}'),
                    ),
                  );
                }
                if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                  return const Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('User not found.'),
                    ),
                  );
                }

                final user = userSnapshot.data!.snapshot.value as Map<dynamic, dynamic>? ?? {};
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(user['name']?.toString() ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${request['date']?.toString() ?? 'N/A'}'),
                        Text('Reason: ${request['reason']?.toString() ?? 'N/A'}'),
                      ],
                    ),
                    trailing: request['status']?.toString() == 'pending'
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _updateLeaveStatus(key, 'approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _updateLeaveStatus(key, 'rejected'),
                        ),
                      ],
                    )
                        : Text(
                      request['status']?.toString() ?? 'N/A',
                      style: TextStyle(
                        color: request['status']?.toString() == 'approved'
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateAttendanceStatus(String key, String status) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _attendanceRef.child(key).update({'status': status});
      });
    });
  }

  void _updateLeaveStatus(String key, String status) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _leaveRef.child(key).update({'status': status});
      });
    });
  }

  void _deleteUser(String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _usersRef.child(userId).remove();
        _attendanceRef.orderByChild('userId').equalTo(userId).get().then((snapshot) {
          if (snapshot.value != null) {
            (snapshot.value as Map).keys.forEach((key) {
              _attendanceRef.child(key).remove();
            });
          }
        });
      });
    });
  }

  void _showEditUserDialog(String userId, Map<dynamic, dynamic> user) {
    final nameController = TextEditingController(text: user['name']?.toString() ?? '');
    final emailController = TextEditingController(text: user['email']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _usersRef.child(userId).update({
                  'name': nameController.text,
                  'email': emailController.text,
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}