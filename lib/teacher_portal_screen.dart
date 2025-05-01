import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vidhar_final/wifi_service.dart';

class TeacherPortalScreen extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const TeacherPortalScreen({Key? key, required this.teacherUid, required this.classId}) : super(key: key);

  @override
  State<TeacherPortalScreen> createState() => _TeacherPortalScreenState();
}

class _TeacherPortalScreenState extends State<TeacherPortalScreen> {
  String _wifiName = "Fetching...";
  String? _currentSessionId;

  final backgroundColor = const Color(0xFFD4EDF4);
  final cardColor = const Color(0xFF2A2E30);
  final accentColor = const Color(0xFFFF9E7A);
  final textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    fetchWifi();
  }

  Future<void> fetchWifi() async {
    String name = await WifiService.getWifiSSID();
    setState(() {
      _wifiName = name;
    });
  }

  Future<void> openSession() async {
    try {
      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
      await ref.child('attendance/$currentDate/$sessionId/initialized').set(true);
      await ref.update({
        'portalOpen': true,
        'teacherWifi': _wifiName,
        'currentSessionId': sessionId,
      });

      setState(() => _currentSessionId = sessionId);
      Fluttertoast.showToast(msg: 'Session $sessionId opened for $currentDate');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> closeSession() async {
    try {
      if (_currentSessionId == null) {
        Fluttertoast.showToast(msg: 'No session is active');
        return;
      }

      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
      final attendanceSnap = await ref.child('attendance/$currentDate/$_currentSessionId').get();
      final studentSnap = await ref.child('joinedStudents').get();

      if (!attendanceSnap.exists || !studentSnap.exists) {
        Fluttertoast.showToast(msg: 'Missing attendance or student data');
        return;
      }

      final recorded = Map<String, dynamic>.from(attendanceSnap.value as Map).keys.toSet();
      final studentData = Map<String, dynamic>.from(studentSnap.value as Map);

      for (final uid in studentData.keys) {
        if (!recorded.contains(uid)) {
          await ref.child('attendance/$currentDate/$_currentSessionId/$uid').set('Absent');
        }
      }

      await ref.update({'portalOpen': false});
      Fluttertoast.showToast(msg: 'Session $_currentSessionId closed. Absentees marked.');
      setState(() => _currentSessionId = null);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Text("Teacher Portal", style: GoogleFonts.poppins(color: textColor)),
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Class ID: ${widget.classId}", style: GoogleFonts.poppins(color: textColor, fontSize: 16)),
                    Text("Teacher ID: ${widget.teacherUid}", style: GoogleFonts.poppins(color: textColor, fontSize: 16)),
                    Text("Wi-Fi SSID: $_wifiName", style: GoogleFonts.poppins(color: textColor, fontSize: 16)),
                    Text("Session ID: ${_currentSessionId ?? 'None'}", style: GoogleFonts.poppins(color: textColor, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text("Start New Session", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: openSession,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              icon: const Icon(Icons.stop),
              label: Text("End Current Session", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: closeSession,
            ),
          ],
        ),
      ),
    );
  }
}
