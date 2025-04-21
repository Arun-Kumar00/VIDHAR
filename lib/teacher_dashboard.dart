import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class TeacherDashboard extends StatefulWidget {
  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String teacherUid = ""; // To store the UID
  String teacherName = ""; // To store the teacher's name

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch details from Firebase
        final snapshot =
        await FirebaseDatabase.instance.ref().child('users').child(user.uid).get();

        if (snapshot.exists) {
          setState(() {
            teacherUid = snapshot.child('uid').value.toString();
            teacherName = snapshot.child('name').value.toString();
          });
        } else {
          print("Teacher details not found in database.");
        }
      }
    } catch (error) {
      print("Error fetching teacher details: $error");
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: teacherUid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Teacher UID copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Teacher Name
            Text(
              "Welcome, $teacherName",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Display Teacher UID with Copy Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Teacher UID: $teacherUid",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Create Class Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/createClass');
              },
              child: Text('Create Class'),
            ),
            SizedBox(height: 16),

            // View Existing Classes Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/viewClasses');
              },
              child: Text('View Existing Classes'),
            ),
          ],
        ),
      ),
    );
  }
}
