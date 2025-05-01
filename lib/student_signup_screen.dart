import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentSignupScreen extends StatefulWidget {
  @override
  _StudentSignupScreenState createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedDepartment = 'CSE1';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _departments = [
    'CSE1', 'CSE2', 'ME', 'AE', 'ECE', 'EE', 'AIDS', 'CE', 'VLSI'
  ];

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
        'role': 'student',
        'uid': userCredential.user!.uid,
        'rollNumber': _rollNumberController.text.trim(),
        'department': _selectedDepartment,
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: isPassword ? Icon(Icons.lock_outline) : Icon(Icons.person_outline),
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        labelText: 'Department',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      style: TextStyle(color: Colors.black),
      items: _departments.map((dept) {
        return DropdownMenuItem(
          value: dept,
          child: Text(dept),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value!;
        });
      },
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
            colors: [Color(0xFF74EBD5), Color(0xFFACB6E5)], // Matching gradient as login screen
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
                        'Student Signup',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      SizedBox(height: 25),
                      _buildTextField("Full Name", _nameController),
                      SizedBox(height: 20),
                      _buildTextField("Roll Number", _rollNumberController),
                      SizedBox(height: 20),
                      _buildDropdown(),
                      SizedBox(height: 20),
                      _buildTextField("Email Address", _emailController),
                      SizedBox(height: 20),
                      _buildTextField("Password", _passwordController, isPassword: true),
                      SizedBox(height: 20),
                      _buildTextField("Confirm Password", _confirmPasswordController, isPassword: true),
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
