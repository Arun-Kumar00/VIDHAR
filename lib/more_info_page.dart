import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'teacher_portal_screen.dart';
import 'extra_info_page.dart';

class MoreInfoPage extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const MoreInfoPage({
    super.key,
    required this.teacherUid,
    required this.classId,
  });

  @override
  State<MoreInfoPage> createState() => _MoreInfoPageState();
}

class _MoreInfoPageState extends State<MoreInfoPage> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  final backgroundColor = const Color(0xFFD4EDF4);
  final cardColor = const Color(0xFF2A2E30);
  final accentColor = const Color(0xFFFF9E7A);
  final textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);

    final usersSnapshot = await FirebaseDatabase.instance.ref('users').get();
    final attendanceRef = FirebaseDatabase.instance
        .ref('classes/${widget.teacherUid}/${widget.classId}/attendance');
    final attendanceSnapshot = await attendanceRef.get();

    List<Map<String, dynamic>> students = [];

    for (var userSnap in usersSnapshot.children) {
      final userData = userSnap.value as Map;
      final classKey = '${widget.teacherUid} ${widget.classId}';

      if (userData['role'] == 'student' &&
          (userData['joinedClasses'] ?? {}).containsKey(classKey)) {
        final userId = userSnap.key!;
        final name = userData['name'] ?? '';

        int present = 0, total = 0;

        for (var dateSnap in attendanceSnapshot.children) {
          for (var session in dateSnap.children) {
            if (session.key == "initialized") continue;
            Map sessionData = (session.value as Map?) ?? {};
            if (sessionData.containsKey(userId)) {
              total++;
              if (sessionData[userId] == "Present") present++;
            }
          }
        }

        double attendancePercentage = total > 0 ? (present / total) * 100 : 0;

        students.add({
          "name": name,
          "percent": attendancePercentage,
        });
      }
    }

    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Text("Class Info", style: GoogleFonts.poppins(color: textColor)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
          ? Center(
          child: Text("No students joined this class.",
              style: GoogleFonts.poppins(color: Colors.black87)))
          : ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            color: cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 5,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: accentColor,
                child: Text(
                  student['name'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                student['name'],
                style: GoogleFonts.poppins(
                    color: textColor, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: LinearProgressIndicator(
                  value: (student['percent'] / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.greenAccent,
                  minHeight: 6,
                ),
              ),
              trailing: Text(
                "${student['percent'].toStringAsFixed(1)}%",
                style: GoogleFonts.poppins(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherPortalScreen(
                      teacherUid: widget.teacherUid,
                      classId: widget.classId,
                    ),
                  ),
                ),
                label: Text("Take Attendance",
                    style: GoogleFonts.poppins(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExtraInfoPage(
                      teacherUid: widget.teacherUid,
                      classId: widget.classId,
                    ),
                  ),
                ),
                label: Text("Extra Info",
                    style: GoogleFonts.poppins(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
