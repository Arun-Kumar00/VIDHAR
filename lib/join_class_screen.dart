import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinClassScreen extends StatefulWidget {
  @override
  _JoinClassScreenState createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _teacherUidController = TextEditingController();
  final _classIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final Color backgroundColor = Color(0xFFD4EDF4);
  final Color cardColor = Color(0xFFFFFFFF); // Replaced opacity with a solid white color
  final Color accentColor = Color(0xFFFF9E7A);
  final Color titleColor = Color(0xFF2A2E30);

  Future<void> _joinClass() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User is not logged in.");
      final studentUid = user.uid;

      final studentSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .get();

      if (!studentSnapshot.exists) throw Exception("Student details not found.");

      final studentData = studentSnapshot.value as Map<dynamic, dynamic>;
      final studentName = studentData['name'];
      final studentEmail = studentData['email'];

      final teacherUid = _teacherUidController.text.trim();
      final classId = _classIdController.text.trim();
      if (teacherUid.isEmpty || classId.isEmpty) {
        throw Exception("Please enter both Teacher UID and Class ID.");
      }

      final classRef = FirebaseDatabase.instance
          .ref()
          .child('classes')
          .child(teacherUid)
          .child(classId);
      final classSnapshot = await classRef.get();
      if (!classSnapshot.exists) throw Exception("Class not found.");

      final classData = classSnapshot.value as Map<dynamic, dynamic>;
      final classPassword = classData['password'];
      if (_passwordController.text.trim() != classPassword) {
        throw Exception("Incorrect password.");
      }

      // Join operations
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(studentUid)
          .child('joinedClasses')
          .child('$teacherUid $classId')
          .set(true);

      await FirebaseDatabase.instance
          .ref()
          .child('classes')
          .child(teacherUid)
          .child(classId)
          .child('joinedStudents')
          .child(studentUid)
          .set({'name': studentName, 'email': studentEmail});

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Class Joined", style: GoogleFonts.poppins()),
          content: Text("You have successfully joined the class!", style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Pop the current screen (JoinClassScreen)
                Navigator.pushReplacementNamed(context, '/student_dashboard'); // Navigate to the Student Dashboard
              },
              child: Text("OK", style: GoogleFonts.poppins(color: accentColor)),
            ),
          ],
        ),
      );
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error", style: GoogleFonts.poppins()),
          content: Text(error.toString(), style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: GoogleFonts.poppins(color: accentColor)),
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: titleColor,
        title: Text('Join Class', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildInputField("Teacher UID", _teacherUidController),
                SizedBox(height: 16),
                _buildInputField("Class ID", _classIdController),
                SizedBox(height: 16),
                _buildInputField("Class Password", _passwordController, isPassword: true),
                SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isLoading ? null : _joinClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: titleColor,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text('Join Class', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        hintText: "Enter $label",
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
