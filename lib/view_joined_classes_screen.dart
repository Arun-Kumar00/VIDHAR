import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'attendance_screen.dart';

class ViewJoinedClassesScreen extends StatefulWidget {
  @override
  _ViewJoinedClassesScreenState createState() => _ViewJoinedClassesScreenState();
}

class _ViewJoinedClassesScreenState extends State<ViewJoinedClassesScreen> {
  List<Map<String, String>> _joinedClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJoinedClasses();
  }

  Future<void> _fetchJoinedClasses() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final studentUid = user.uid;
      final joinedClassesRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses');

      final joinedClassesSnapshot = await joinedClassesRef.get();

      if (joinedClassesSnapshot.exists) {
        List<Map<String, String>> joinedClassesList = [];

        for (var classEntry in joinedClassesSnapshot.children) {
          final combinedKey = classEntry.key;

          if (combinedKey == null || !combinedKey.contains(' ')) continue;

          final parts = combinedKey.split(' ');
          final teacherUid = parts[0];
          final classId = parts[1];

          // Fetch class details
          final classRef = FirebaseDatabase.instance
              .ref()
              .child('classes')
              .child(teacherUid)
              .child(classId);

          final classSnapshot = await classRef.get();

          if (classSnapshot.exists) {
            final classData = classSnapshot.value as Map<dynamic, dynamic>;

            joinedClassesList.add({
              'classId': classId,
              'teacherUid': teacherUid,
              'teacherName': classData['teacherName'] ?? 'Unknown',
              'subjectName': classData['subjectName'] ?? 'Unknown',
            });
          }
        }

        setState(() {
          _joinedClasses = joinedClassesList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _joinedClasses = [];
          _isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching joined classes: $error");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveClass(String teacherUid, String classId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final studentUid = user.uid;
      final combinedKey = '$teacherUid $classId';

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses')
          .child(combinedKey)
          .remove();

      setState(() {
        _joinedClasses.removeWhere((element) =>
        element['teacherUid'] == teacherUid && element['classId'] == classId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have successfully left the class $classId.")),
      );
    } catch (error) {
      print("Error leaving class: $error");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Failed to leave the class. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _showLeaveConfirmation(String teacherUid, String classId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Leave"),
        content: Text("Are you sure you want to leave the class $classId?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveClass(teacherUid, classId);
            },
            child: Text("Leave"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Joined Classes")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _joinedClasses.isEmpty
          ? Center(child: Text("You have not joined any classes."))
          : ListView.builder(
        itemCount: _joinedClasses.length,
        itemBuilder: (context, index) {
          final classData = _joinedClasses[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text("Class ID: ${classData['classId']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Teacher: ${classData['teacherName']}"),
                  Text("Subject: ${classData['subjectName']}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.info, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceScreen(
                            teacherUid: classData['teacherUid']!,
                            classId: classData['classId']!,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.exit_to_app, color: Colors.red),
                    onPressed: () => _showLeaveConfirmation(
                      classData['teacherUid']!,
                      classData['classId']!,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
