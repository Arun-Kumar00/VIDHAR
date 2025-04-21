import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

  Future<void> _createClass() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final teacherUid = user.uid;
        final teacherRef = FirebaseDatabase.instance.ref().child('users').child(teacherUid);
        final snapshot = await teacherRef.get();

        if (snapshot.exists) {
          final teacherName = snapshot.child('name').value.toString();
          final classId = _classIdController.text.trim();

          if (classId.isEmpty || _passwordController.text.trim().isEmpty || _subjectNameController.text.trim().isEmpty) {
            throw Exception("Please fill all fields.");
          }

          // Save the class under teacher UID and then class ID
          await FirebaseDatabase.instance
              .ref()
              .child('classes')
              .child(teacherUid)
              .child(classId)
              .set({
            'password': _passwordController.text.trim(),
            'department': _selectedDepartment,
            'createdBy': teacherUid,
            'teacherName': teacherName,
            'subjectName': _subjectNameController.text.trim(),
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Class Created"),
              content: Text("Your class has been successfully created!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _classIdController.clear();
                    _passwordController.clear();
                    _subjectNameController.clear();
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        } else {
          throw Exception("Teacher details not found.");
        }
      } else {
        throw Exception("User not authenticated.");
      }
    } catch (error) {
      print("Error creating class: $error");
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
      appBar: AppBar(title: Text('Create Class')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _classIdController,
                decoration: InputDecoration(
                  labelText: 'Class ID',
                  hintText: 'Enter a unique Class ID',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Class Password',
                  hintText: 'Enter a Class Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _subjectNameController,
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'Enter the Subject Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                items: ['CSE', 'ECE', 'EE', 'ME', 'AE', 'AIDS']
                    .map((department) => DropdownMenuItem(
                    value: department, child: Text(department)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _createClass,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Create Class'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
