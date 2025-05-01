import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vidhar_final/wifi_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String classId;
  final String teacherUid;

  const AttendanceScreen({required this.classId, required this.teacherUid, Key? key}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _wifiName = "Fetching Wi-Fi...";
  String? _currentSessionId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchWifi();
    await fetchCurrentSessionId();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchWifi() async {
    String name = await WifiService.getWifiSSID();
    setState(() {
      _wifiName = name;
    });
  }

  Future<void> fetchCurrentSessionId() async {
    final ref = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
    final snapshot = await ref.child('currentSessionId').get();
    if (snapshot.exists) {
      _currentSessionId = snapshot.value.toString();
    }
  }

  Future<void> markAttendance() async {
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
      setState(() {}); // Refresh the page after marking attendance
    } catch (e) {
      Fluttertoast.showToast(msg: "Error marking attendance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Attendance")),
        body: const Center(child: Text("User not logged in.")),
      );
    }

    final studentUid = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance"),
        backgroundColor: const Color(0xFF2A2E30),
          foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('users/$studentUid').get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("Failed to load user data"));
          }

          final userData = Map<String, dynamic>.from(userSnapshot.data!.value as Map);
          final rollNumber = userData['rollNumber'] ?? "N/A";

          return FutureBuilder<DataSnapshot>(
            future: FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}/attendance').get(),
            builder: (context, attendanceSnapshot) {
              if (!attendanceSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

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

              return RefreshIndicator(
                onRefresh: _initializeData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 5,
                        color: const Color(0xFFD4EDF4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.class_, size: 40, color: Color(0xFF2A2E30)),
                          title: Text(
                            "Class ID: ${widget.classId}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("Roll No: $rollNumber", style: const TextStyle(color: Colors.black87)),
                              Text("Wi-Fi SSID: $_wifiName", style: const TextStyle(color: Colors.black87)),
                              Text("Session ID: ${_currentSessionId ?? 'None'}", style: const TextStyle(color: Colors.black87)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: CircularPercentIndicator(
                          radius: 100,
                          lineWidth: 13,
                          animation: true,
                          percent: percent,
                          center: Text(
                            "${(percent * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          footer: const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Attendance Percentage",
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ),
                          progressColor: const Color(0xFFFF9E7A),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: markAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A2E30),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            "Mark Attendance",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Divider(thickness: 1),
                      const Text(
                        "Attendance Records",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const SizedBox(height: 10),
                      ...attendanceData.entries.map((entry) {
                        final date = entry.key;
                        final sessions = Map<String, dynamic>.from(entry.value);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text("📅 $date", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            ...sessions.entries.where((e) => e.key != 'initialized').map((session) {
                              final sessionId = session.key;
                              final studentMap = Map<String, dynamic>.from(session.value);
                              final status = studentMap[studentUid] ?? "N/A";

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("• Session: $sessionId", style: const TextStyle(color: Colors.black87)),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: status == "Present" ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
