import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class TeacherSignupScreen extends StatefulWidget {
  @override
  _TeacherSignupScreenState createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> {
  final _nameController = TextEditingController();
  final _genderController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final databaseRef = FirebaseDatabase.instance.ref();
  bool _isLoading = false;

  Future<void> _signUp() async {
    try {
      setState(() => _isLoading = true);
      if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
        throw Exception("Passwords do not match!");
      }

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'teacher',
        'uid': userCredential.user!.uid, // Save the Firebase UID
        'gender': _genderController.text.trim(),
      });


      Navigator.pushReplacementNamed(context, '/login'); // Redirect to Login screen
    } catch (error) {
      print("Sign-Up failed: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teacher Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _genderController,
              decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
            ),
            if (_isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
