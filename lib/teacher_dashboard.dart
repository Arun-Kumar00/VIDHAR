import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:vidhar_final/view_classes_screen.dart';
import 'create_class_screen.dart';

class TeacherDashboard extends StatelessWidget {
  final backgroundColor = const Color(0xFFD4EDF4);
  final cardColor = const Color(0xFF2A2E30);
  final accentColor = const Color(0xFFFF9E7A);
  final textColor = Colors.white;

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: cardColor, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Logout",
              style: GoogleFonts.poppins(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? teacherUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Text('Teacher Dashboard', style: GoogleFonts.poppins(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: accentColor),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // 🔐 UID Display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'UID: ${teacherUid ?? "Not Available"}',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: cardColor),
                    onPressed: () {
                      if (teacherUid != null) {
                        Clipboard.setData(ClipboardData(text: teacherUid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("UID copied to clipboard", style: GoogleFonts.poppins()),
                            backgroundColor: cardColor,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _DashboardCard(
              title: 'Create Class',
              icon: Icons.add_box,
              color: accentColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateClassScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            _DashboardCard(
              title: 'View Existing Classes',
              icon: Icons.class_,
              color: accentColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewClassesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
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
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnim = Tween<double>(begin: 1, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF2A2E30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
            child: Column(
              children: [
                Icon(widget.icon, size: 40, color: widget.color),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
