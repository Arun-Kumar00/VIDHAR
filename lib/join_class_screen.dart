import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class JoinClassScreen extends StatefulWidget {
  @override
  _JoinClassScreenState createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _teacherUidController = TextEditingController();
  final _classIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinClass() async {
    try {
      setState(() => _isLoading = true);

      // Current user (student)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User is not logged in.");

      final studentUid = user.uid;

      // Fetch student details
      final studentSnapshot = await FirebaseDatabase.instance.ref().child('users').child(studentUid).get();
      if (!studentSnapshot.exists) throw Exception("Student details not found.");

      final studentData = studentSnapshot.value as Map<dynamic, dynamic>;
      final studentName = studentData['name'];
      final studentEmail = studentData['email'];

      // Get teacherUid and classId from input
      final teacherUid = _teacherUidController.text.trim();
      final classId = _classIdController.text.trim();

      if (teacherUid.isEmpty || classId.isEmpty) {
        throw Exception("Please enter both Teacher UID and Class ID.");
      }

      // Fetch class data
      final classRef = FirebaseDatabase.instance.ref().child('classes').child(teacherUid).child(classId);
      final classSnapshot = await classRef.get();
      if (!classSnapshot.exists) throw Exception("Class not found.");

      final classData = classSnapshot.value as Map<dynamic, dynamic>;
      final classPassword = classData['password'];

      // Validate password
      if (_passwordController.text.trim() != classPassword) throw Exception("Incorrect password.");

      // Add class to student's joinedClasses
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses')
          .child('$teacherUid $classId') // storing as "teacherUid classId"
          .set(true);

      // Add student to class's joinedStudents
      await FirebaseDatabase.instance
          .ref()
          .child('classes')
          .child(teacherUid)
          .child(classId)
          .child('joinedStudents')
          .child(studentUid)
          .set({
        'name': studentName,
        'email': studentEmail,
      });

      // Success Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Class Joined"),
          content: Text("You have successfully joined the class!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } catch (error) {
      // Error Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Class')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _teacherUidController,
              decoration: InputDecoration(
                labelText: 'Teacher UID',
                hintText: 'Enter Teacher UID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _classIdController,
              decoration: InputDecoration(
                labelText: 'Class ID',
                hintText: 'Enter Class ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Class Password',
                hintText: 'Enter Class Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _joinClass,
              child: Text('Join Class'),
            ),
            if (_isLoading) SizedBox(height: 16),
            if (_isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
