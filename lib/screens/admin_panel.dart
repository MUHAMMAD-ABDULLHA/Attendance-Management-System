import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // ✅ Fetch Users from Firebase
  void _fetchUsers() {
    _database.child('users').onValue.listen((event) {
      if (event.snapshot.exists) {
        List<Map<String, dynamic>> tempUsers = [];
        Map<dynamic, dynamic> userData = event.snapshot.value as Map<dynamic, dynamic>;

        userData.forEach((key, value) {
          tempUsers.add({'id': key, ...value});
        });

        setState(() {
          users = tempUsers;
        });
      }
    });
  }

  // ✅ Edit User Dialog
  void _showEditUserDialog(Map<String, dynamic> user) {
    TextEditingController nameController = TextEditingController(text: user['name']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit User"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _updateUser(user['id'], nameController.text);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Update User
  void _updateUser(String userId, String newName) {
    _database.child('users').child(userId).update({'name': newName});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          return ListTile(
            title: Text(user['name'] ?? 'No Name'),
            subtitle: Text(user['email']),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditUserDialog(user),
            ),
          );
        },
      ),
    );
  }
}
