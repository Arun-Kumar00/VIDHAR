import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

import 'teacher_dashboard.dart'; // Make sure this is the correct path

class CreateClassScreen extends StatefulWidget {
  @override
  _CreateClassScreenState createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _classIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _subjectNameController = TextEditingController();
  String _selectedDepartment = 'CSE';
  bool _isLoading = false;

  final Color backgroundColor = Color(0xFFD4EDF4);
  final Color cardColor = Colors.white.withOpacity(0.9);
  final Color accentColor = Color(0xFFFF9E7A);
  final Color titleColor = Color(0xFF2A2E30);

  Future<void> _createClass() async {
    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) throw Exception("User not authenticated.");
      final teacherUid = user.uid;

      final teacherRef = FirebaseDatabase.instance.ref().child('users').child(teacherUid);
      final snapshot = await teacherRef.get();

      if (!snapshot.exists) throw Exception("Teacher details not found.");

      final teacherName = snapshot.child('name').value.toString();
      final classId = _classIdController.text.trim();
      final password = _passwordController.text.trim();
      final subjectName = _subjectNameController.text.trim();

      if (classId.isEmpty || password.isEmpty || subjectName.isEmpty) {
        throw Exception("Please fill all fields.");
      }

      await FirebaseDatabase.instance
          .ref()
          .child('classes')
          .child(teacherUid)
          .child(classId)
          .set({
        'password': password,
        'department': _selectedDepartment,
        'createdBy': teacherUid,
        'teacherName': teacherName,
        'subjectName': subjectName,
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Class Created", style: GoogleFonts.poppins()),
          content: Text("Your class has been successfully created!", style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                      (route) => false,
                );
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
        title: Text('Create Class', style: GoogleFonts.poppins(color: Colors.white)),
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
                _buildInputField("Class ID", _classIdController),
                SizedBox(height: 16),
                _buildInputField("Class Password", _passwordController, isPassword: true),
                SizedBox(height: 16),
                _buildInputField("Subject Name", _subjectNameController),
                SizedBox(height: 16),
                _buildDropdownField(),
                SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createClass,
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
                      : Text('Create Class', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
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

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: 'Department',
        labelStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: ['CSE1', 'CSE2', 'ME', 'AE', 'ECE', 'EE', 'AIDS', 'CE', 'VLSI']
          .map((department) => DropdownMenuItem(
        value: department,
        child: Text(department, style: GoogleFonts.poppins()),
      ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedDepartment = value!);
      },
    );
  }
}
