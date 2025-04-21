import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'more_info_page.dart';

class ViewClassesScreen extends StatefulWidget {
  @override
  _ViewClassesScreenState createState() => _ViewClassesScreenState();
}

class _ViewClassesScreenState extends State<ViewClassesScreen> {
  List<Map<String, String>> _classes = [];
  bool _isLoading = true;
  String? _teacherUid; // ✅ Add this variable to store teacher UID

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      _teacherUid = user.uid; // ✅ Store teacher UID

      final DatabaseReference userClassesRef = FirebaseDatabase.instance.ref('classes/${user.uid}');
      final snapshot = await userClassesRef.once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<String, String>> loadedClasses = [];

        data.forEach((classId, classData) {
          final classInfo = Map<String, dynamic>.from(classData);
          loadedClasses.add({
            'classId': classId,
            'department': classInfo['department'] ?? '',
            'password': classInfo['password'] ?? '',
            'subjectName': classInfo['subjectName'] ?? '',
            'teacherName': classInfo['teacherName'] ?? '',
          });
        });

        setState(() {
          _classes = loadedClasses;
          _isLoading = false;
        });
      } else {
        setState(() {
          _classes = [];
          _isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching classes: $error");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteClass(String classId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final DatabaseReference classRef = FirebaseDatabase.instance.ref('classes/${user.uid}/$classId');
      await classRef.remove();

      setState(() {
        _classes.removeWhere((cls) => cls['classId'] == classId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Class $classId deleted successfully!")),
      );
    } catch (error) {
      print("Error deleting class: $error");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Error"),
          content: Text("Failed to delete class. Please try again."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Classes')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _classes.isEmpty
          ? Center(child: Text("No classes found."))
          : ListView.builder(
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final classData = _classes[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Department: ${classData['department']}", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Class ID: ${classData['classId']}"),
                  Text("Password: ${classData['password']}"),
                  Text("Subject: ${classData['subjectName']}"),
                  Text("Teacher: ${classData['teacherName']}"),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoreInfoPage(
                                classId: classData['classId']!,
                                teacherUid: _teacherUid!, // ✅ Pass teacher UID
                              ),
                            ),
                          );
                        },
                        child: Text("More Info"),
                      ),
                      ElevatedButton(
                        onPressed: () => _deleteClass(classData['classId']!),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text("Delete"),
                      ),
                    ],
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
