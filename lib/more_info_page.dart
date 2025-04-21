import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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

        double attendancePercentage =
        total > 0 ? (present / total) * 100 : 0;

        students.add({
          "name": name,
          "percent": "${attendancePercentage.toStringAsFixed(1)}%",
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
      appBar: AppBar(title: const Text("Class Info")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            title: Text(student['name'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Attendance: ${student['percent']}"),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherPortalScreen(
                    teacherUid: widget.teacherUid,
                    classId: widget.classId,
                  ),
                ),
              ),
              child: const Text("Take Attendance"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExtraInfoPage(
                    teacherUid: widget.teacherUid,
                    classId: widget.classId,
                  ),
                ),
              ),
              child: const Text("Extra Info"),
            ),
          ],
        ),
      ),
    );
  }
}
