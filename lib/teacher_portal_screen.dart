import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vidhar_final/wifi_service.dart';  // Assuming this is where your WifiService is defined

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

  // Open a new attendance session
  Future<void> openSession() async {
    try {
      final currentDate = DateTime.now().toIso8601String().split('T').first;
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString(); // Unique per session
      final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');

      await ref.child('attendance/$currentDate/$sessionId/initialized').set(true);

      await ref.update({
        'portalOpen': true,
        'teacherWifi': _wifiName,
        'currentSessionId': sessionId, // Store ongoing session
      });

      setState(() {
        _currentSessionId = sessionId;
      });

      Fluttertoast.showToast(msg: 'Session $sessionId opened for $currentDate');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  // Close the current session & mark absentees
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

      final attendanceData = Map<String, dynamic>.from(attendanceSnap.value as Map);
      final studentData = Map<String, dynamic>.from(studentSnap.value as Map);

      final recorded = attendanceData.keys.toSet();

      for (final uid in studentData.keys) {
        if (!recorded.contains(uid)) {
          await ref.child('attendance/$currentDate/$_currentSessionId/$uid').set('Absent');
        }
      }

      await ref.update({'portalOpen': false});

      Fluttertoast.showToast(msg: 'Session $_currentSessionId closed. Absentees marked.');

      setState(() {
        _currentSessionId = null; // Reset session ID after closing
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Portal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              child: ListTile(
                title: Text("Class ID: ${widget.classId}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Teacher ID: ${widget.teacherUid}"),
                    Text("Wi-Fi SSID: $_wifiName"),
                    Text("Current Session ID: ${_currentSessionId ?? 'None'}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.wifi),
              label: const Text('Start New Session'),
              onPressed: openSession,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock),
              label: const Text('End Current Session'),
              onPressed: closeSession,
            ),
          ],
        ),
      ),
    );
  }
}
