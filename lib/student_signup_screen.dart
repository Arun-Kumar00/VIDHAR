import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StudentSignupScreen extends StatefulWidget {
  @override
  _StudentSignupScreenState createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _genderController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedDepartment = 'CSE';
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

      await FirebaseDatabase.instance.ref().child('users').child(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'student',
        'rollNumber': _rollNumberController.text.trim(),
        'gender': _genderController.text.trim(),
        'department': _selectedDepartment,
        'uid': userCredential.user!.uid,
      });

      Navigator.pushReplacementNamed(context, '/login');
    } catch (error) {
      print("Sign-Up failed: $error");
      _showErrorDialog("Sign-Up failed: ${error.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _rollNumberController,
                decoration: InputDecoration(labelText: 'Roll Number', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _genderController,
                decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                items: ['CSE', 'ECE', 'EE', 'ME', 'AE', 'AIDS']
                    .map((dep) => DropdownMenuItem(value: dep, child: Text(dep)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedDepartment = value!),
                decoration: InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
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
              if (_isLoading) SizedBox(height: 20),
              if (_isLoading) CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
