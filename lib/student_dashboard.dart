import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'join_class_screen.dart';
import 'view_joined_classes_screen.dart';

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  final double cardOpacity = 0.85;
  final cardColor = const Color(0xFF2A2E30);
  final accentColor = const Color(0xFFFF9E7A);
  final backgroundColor = const Color(0xFFD4EDF4);
  final iconAccent = const Color(0xFFFF9E7A);
  final titleColor = const Color(0xFF2A2E30);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _slideAnimation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  // Logout Function
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Confirm Logout",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: cardColor,
          ),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: cardColor, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Dismiss dialog
              await _logout(context);       // Then perform logout
            },
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryCardColor = Colors.white.withOpacity(cardOpacity);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: titleColor,
        title: Text('Student Dashboard', style: GoogleFonts.poppins(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: iconAccent),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: primaryCardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Welcome Student!",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 30),
                _DashboardCard(
                  title: 'Join Class',
                  icon: Icons.group_add,
                  color: iconAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => JoinClassScreen()),
                    );
                  },
                ),
                SizedBox(height: 20),
                _DashboardCard(
                  title: 'Joined Classes',
                  icon: Icons.class_,
                  color: iconAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ViewJoinedClassesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: Color(0xFF2A2E30),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
