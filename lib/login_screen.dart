import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    try {
      setState(() => _isLoading = true);

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;
      final userRef = FirebaseDatabase.instance.ref().child('users').child(userId);
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map;
        final role = userData['role'];

        if (role == 'student') {
          Navigator.pushReplacementNamed(context, '/studentDashboard');
        } else if (role == 'teacher') {
          Navigator.pushReplacementNamed(context, '/teacherDashboard');
        } else {
          _showErrorDialog("User role is undefined.");
        }
      } else {
        _showErrorDialog("User data not found.");
      }

    } catch (error) {
      print("Login failed: $error");
      _showErrorDialog("Failed to login. Please check your credentials.");
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
            child: Text("Okay"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.visibility),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Who are you?"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/teacherSignup');
                            },
                            child: Text("I am a Teacher"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/studentSignup');
                            },
                            child: Text("I am a Student"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Text("New here? Create an Account"),
            ),
            if (_isLoading) SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
