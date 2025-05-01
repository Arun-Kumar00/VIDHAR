import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherSignupScreen extends StatefulWidget {
  @override
  _TeacherSignupScreenState createState() => _TeacherSignupScreenState();
}

class _TeacherSignupScreenState extends State<TeacherSignupScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );

    _controller.forward();
  }

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
        'role': 'teacher',
        'uid': userCredential.user!.uid,
      });

      Navigator.pushReplacementNamed(context, '/login');
    } catch (error) {
      _showErrorDialog(error.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Error", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text("Okay")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74EBD5), Color(0xFFACB6E5)], // Same gradient as login screen
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: size.width * 0.85,
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        'Create Teacher Account',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      SizedBox(height: 25),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline),
                          labelText: 'Full Name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          labelText: 'Email Address',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          labelText: 'Confirm Password',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A90E2),
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 8,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: Text(
                          "Already have an account? Login",
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
