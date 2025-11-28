import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class StudentHome extends StatefulWidget {
  final int userId;
  const StudentHome({super.key, required this.userId});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List attendance = [];

  Future<void> fetchAttendance() async {
    final res = await http.get(
      Uri.parse("$BASE_URL/attendance/student/${widget.userId}"),
    );

    if (res.statusCode == 200) {
      setState(() {
        attendance = jsonDecode(res.body);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Attendance",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        elevation: 2,
      ),

      body: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade100,
        child: attendance.isEmpty
            ? const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        )
            : ListView.builder(
          itemCount: attendance.length,
          itemBuilder: (_, i) {
            final a = attendance[i];
            bool present = a["status"] == "Present";

            return Container(
              height: 85,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Date: ${a['date']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Status: ${a['status']}",
                        style: TextStyle(
                          fontSize: 16,
                          color: present
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: present
                          ? Colors.green.shade500
                          : Colors.red.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
