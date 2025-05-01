import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vidhar_final/Splash_screen.dart';
import 'package:vidhar_final/create_class_screen.dart';
import 'package:vidhar_final/student_dashboard.dart';
import 'package:vidhar_final/student_signup_screen.dart';
import 'package:vidhar_final/teacher_dashboard.dart';
import 'package:vidhar_final/teacher_signup_screen.dart';
import 'package:vidhar_final/view_classes_screen.dart';
import 'package:vidhar_final/view_joined_classes_screen.dart';


import 'login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugShowCheckedModeBanner: false;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Role-Based App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash' : (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/teacherSignup': (context) => TeacherSignupScreen(),
        '/studentSignup': (context) => StudentSignupScreen(),
        '/studentDashboard': (context) => StudentDashboard(),
        '/teacherDashboard': (context) => TeacherDashboard(),
        '/createClass': (context) => CreateClassScreen(),
        '/viewClasses': (context) => ViewClassesScreen(),

      },
    );
  }
}

