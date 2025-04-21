import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class ExtraInfoPage extends StatefulWidget {
  final String teacherUid;
  final String classId;

  const ExtraInfoPage({super.key, required this.teacherUid, required this.classId});

  @override
  State<ExtraInfoPage> createState() => _ExtraInfoPageState();
}

class _ExtraInfoPageState extends State<ExtraInfoPage> {
  List<Map<String, dynamic>> _students = [];
  List<String> _attendanceDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  Future<void> _fetchAttendanceRecords() async {
    setState(() => _isLoading = true);

    final classRef = FirebaseDatabase.instance.ref('classes/${widget.teacherUid}/${widget.classId}');
    final attendanceSnapshot = await classRef.child('attendance').get();
    final joinedStudentsSnapshot = await classRef.child('joinedStudents').get();
    final usersRef = FirebaseDatabase.instance.ref('users');

    if (!joinedStudentsSnapshot.exists) {
      setState(() => _isLoading = false);
      return;
    }

    List<Map<String, dynamic>> students = [];
    Set<String> attendanceDates = {};

    // Extract attendance dates
    if (attendanceSnapshot.exists) {
      for (var dateSnap in attendanceSnapshot.children) {
        attendanceDates.add(dateSnap.key!);
      }
    }

    // Process each student
    for (var studentSnap in joinedStudentsSnapshot.children) {
      final userId = studentSnap.key!;
      final userSnap = await usersRef.child(userId).get();
      if (!userSnap.exists) continue;

      final name = userSnap.child('name').value?.toString() ?? 'Unknown';
      final roll = userSnap.child('rollNumber').value?.toString() ?? 'N/A';

      int totalSessions = 0, present = 0;
      Map<String, String> dailyAttendance = {};

      for (String date in attendanceDates) {
        final dateSessionSnap = attendanceSnapshot.child(date);
        int dailyTotal = 0;
        int dailyPresent = 0;
        String statusString = "";

        for (var session in dateSessionSnap.children) {
          if (session.key == "initialized") continue;
          final sessionMap = session.value as Map?;
          if (sessionMap == null) continue;

          if (sessionMap.containsKey(userId)) {
            dailyTotal++;
            if (sessionMap[userId] == "Present") {
              statusString += "P ";
              dailyPresent++;
            } else {
              statusString += "A ";
            }
          }
        }

        totalSessions += dailyTotal;
        present += dailyPresent;

        dailyAttendance[date] = statusString.trim().isEmpty ? "-" : statusString.trim();
      }

      students.add({
        "roll": roll,
        "name": name,
        "dailyAttendance": dailyAttendance,
        "totalClasses": totalSessions,
        "classesAttended": present,
      });
    }

    students.sort((a, b) => a["roll"].compareTo(b["roll"]));

    setState(() {
      _students = students;
      _attendanceDates = attendanceDates.toList()..sort();
      _isLoading = false;
    });
  }



  Future<void> _exportToExcel() async {
    if (Platform.isAndroid) {
      var permission = await Permission.manageExternalStorage.request();
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }
    }

    final excel = Excel.createExcel();
    final Sheet sheet = excel['Attendance Register'];

    sheet.appendRow(["Roll No", "Name", ..._attendanceDates, "Total Classes", "Classes Attended"]);

    for (var student in _students) {
      List<String> row = [student['roll'], student['name']];
      for (String date in _attendanceDates) {
        row.add(student['dailyAttendance'][date] ?? "-");
      }
      row.add(student['totalClasses'].toString());
      row.add(student['classesAttended'].toString());
      sheet.appendRow(row);
    }

    Directory downloadsDir = Directory('/storage/emulated/0/Download');
    final path = "${downloadsDir.path}/Attendance_${widget.classId}.xlsx";

    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Excel file saved to Downloads: Attendance_${widget.classId}.xlsx"),
        action: SnackBarAction(
          label: "Open",
          onPressed: () => OpenFilex.open(path),
        ),
      ),
    );

    // Optional: Show a dialog to share
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Export Successful"),
        content: const Text("Do you want to share the Excel file?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(path)], text: "Attendance Sheet");
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Register"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export to Excel",
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text("Roll No")),
            const DataColumn(label: Text("Name")),
            ..._attendanceDates.map((date) => DataColumn(label: Text(date))),
            const DataColumn(label: Text("Total Classes")),
            const DataColumn(label: Text("Attended")),
          ],
          rows: _students.map((student) {
            return DataRow(cells: [
              DataCell(Text(student["roll"])),
              DataCell(Text(student["name"])),
              ..._attendanceDates.map((date) =>
                  DataCell(Text(student["dailyAttendance"][date] ?? "-"))),
              DataCell(Text(student["totalClasses"].toString())),
              DataCell(Text(student["classesAttended"].toString())),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
