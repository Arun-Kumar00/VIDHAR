import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', role);

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
        backgroundColor: Colors.white,
        title: Text("Error", style: TextStyle(color: Colors.red)),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74EBD5), Color(0xFFACB6E5)],
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
                        'Welcome to VIDHAR',
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      SizedBox(height: 25),
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
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _login,
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
                          'Login',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Who are you?",
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.person_outline, color: Colors.white),
                                        label: Text(
                                          "I am a Teacher",
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF4A90E2),
                                          foregroundColor: Colors.white,
                                          minimumSize: Size(double.infinity, 48),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(context, '/teacherSignup');
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.school_outlined, color: Colors.white),
                                        label: Text(
                                          "I am a Student",
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF56C596),
                                          foregroundColor: Colors.white,
                                          minimumSize: Size(double.infinity, 48),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(context, '/studentSignup');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text(
                          "New here? Create an account",
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
