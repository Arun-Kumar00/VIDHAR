import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vidhar_final/wifi_service.dart';  // Same as TeacherPortalScreen

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String teacherUid;

  const AttendanceScreen({required this.classId, required this.teacherUid, Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _wifiName = "Fetching...";
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    fetchWifi();
    fetchCurrentSessionId();
  }

  Future<void> fetchWifi() async {
    String name = await WifiService.getWifiSSID();
    setState(() {
      _wifiName = name;
    });
  }

  // Get current active session ID
  Future<void> fetchCurrentSessionId() async {
    final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
    final snapshot = await ref.child('currentSessionId').get();
    if (snapshot.exists) {
      setState(() {
        _currentSessionId = snapshot.value.toString();
      });
    }
  }

  void markAttendance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: "User not logged in.");
      return;
    }

    if (_currentSessionId == null) {
      Fluttertoast.showToast(msg: "No active session.");
      return;
    }

    final studentUid = user.uid;
    final classRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
    final snapshot = await classRef.get();

    if (!snapshot.exists) {
      Fluttertoast.showToast(msg: "Class not found.");
      return;
    }

    final classData = Map<String, dynamic>.from(snapshot.value as Map);
    final portalOpen = classData['portalOpen'] ?? false;
    final teacherWifi = classData['teacherWifi'] ?? '';

    if (!portalOpen) {
      Fluttertoast.showToast(msg: "Attendance portal is closed.");
      return;
    }

    final currentDate = DateTime.now().toIso8601String().split('T').first;
    final attendanceRef = classRef.child('attendance/$currentDate/$_currentSessionId');

    final studentAttendanceSnap = await attendanceRef.child(studentUid).get();
    if (studentAttendanceSnap.exists) {
      Fluttertoast.showToast(msg: "Attendance already marked.");
      return;
    }

    String status = (_wifiName == teacherWifi) ? "Present" : "Absent";

    try {
      await attendanceRef.child(studentUid).set(status);
      Fluttertoast.showToast(msg: "Marked as $status");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error marking attendance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
          appBar: AppBar(title: Text("Attendance")),
          body: Center(child: Text("User not logged in.")));
    }

    final studentUid = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance")),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('users/$studentUid').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Failed to load user data"));
          }

          final userData = Map<String, dynamic>.from(snapshot.data!.value as Map);
          final rollNumber = userData['rollNumber'] ?? "N/A";

          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance').get(),
            builder: (context, attendanceSnapshot) {
              if (!attendanceSnapshot.hasData) return Center(child: CircularProgressIndicator());

              final attendanceData = Map<String, dynamic>.from(attendanceSnapshot.data?.value as Map? ?? {});
              int total = 0, present = 0;

              attendanceData.forEach((date, sessions) {
                if (sessions is Map) {
                  sessions.forEach((sessionId, studentMap) {
                    if (sessionId == "initialized") return;

                    if (studentMap is Map && studentMap.containsKey(studentUid)) {
                      total++;
                      if (studentMap[studentUid] == "Present") present++;
                    }
                  });
                }
              });

              double percent = total > 0 ? present / total : 0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      child: ListTile(
                        title: Text("Class ID: ${widget.classId}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Roll No: $rollNumber"),
                            Text("Wi-Fi SSID: $_wifiName"),
                            Text("Current Session ID: ${_currentSessionId ?? 'None'}"),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    CircularPercentIndicator(
                      radius: 100,
                      lineWidth: 13,
                      percent: percent,
                      center: Text("${(percent * 100).toStringAsFixed(1)}%"),
                      footer: Text("Attendance Percentage"),
                      progressColor: Colors.green,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: markAttendance,
                      child: const Text("Mark Attendance"),
                    ),
                    SizedBox(height: 30),
                    const Text("Attendance Records", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...attendanceData.entries.map((entry) {
                      final date = entry.key;
                      final sessions = Map<String, dynamic>.from(entry.value);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date: $date", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...sessions.entries.where((e) => e.key != 'initialized').map((e) {
                            final sessionId = e.key;
                            final studentMap = Map<String, dynamic>.from(e.value);
                            final status = studentMap[studentUid] ?? "N/A";

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("• $sessionId"),
                                Text(status, style: TextStyle(color: status == "Present" ? Colors.green : Colors.red)),
                              ],
                            );
                          }).toList(),
                          Divider(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
