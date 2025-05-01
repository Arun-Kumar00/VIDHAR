import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'more_info_page.dart';

class ViewClassesScreen extends StatefulWidget {
  @override
  _ViewClassesScreenState createState() => _ViewClassesScreenState();
}

class _ViewClassesScreenState extends State<ViewClassesScreen> {
  List<Map<String, String>> _classes = [];
  bool _isLoading = true;
  String? _teacherUid;

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

      _teacherUid = user.uid;

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
      backgroundColor: Color(0xFFD4EDF4),
      appBar: AppBar(
        title: Text('Your Classes', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _classes.isEmpty
          ? Center(
        child: Text("No classes found.",
            style: GoogleFonts.poppins(fontSize: 16)),
      )
          : ListView.builder(
        itemCount: _classes.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final classData = _classes[index];
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            color: Colors.white,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Department: ${classData['department']}",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Class ID: ${classData['classId']}",
                      style: GoogleFonts.poppins()),
                  Text("Password: ${classData['password']}",
                      style: GoogleFonts.poppins()),
                  Text("Subject: ${classData['subjectName']}",
                      style: GoogleFonts.poppins()),
                  Text("Teacher: ${classData['teacherName']}",
                      style: GoogleFonts.poppins()),
                  SizedBox(height: 12),
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
                                teacherUid: _teacherUid!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF77C1E2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("More Info",
                            style: GoogleFonts.poppins()),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _deleteClass(classData['classId']!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Delete",
                            style: GoogleFonts.poppins()),
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
