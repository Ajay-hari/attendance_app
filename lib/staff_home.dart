import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class StaffHome extends StatefulWidget {
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  List students = [];
  Map<int, String> markedStatus = {};

  Future<void> loadStudents() async {
    final res = await http.get(Uri.parse("$BASE_URL/students"));

    if (res.statusCode == 200) {
      setState(() {
        students = jsonDecode(res.body);
      });
    }
  }

  Future<void> markAttendance(int id, String status) async {
    final date = DateTime.now().toIso8601String().substring(0, 10);

    await http.post(
      Uri.parse("$BASE_URL/attendance/set"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": id,
        "date": date,
        "status": status,
      }),
    );

    setState(() {
      markedStatus[id] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Marked $status")),
    );
  }

  // ------------------------------------------------------------
  //  ADD NEW STUDENT FUNCTION
  // ------------------------------------------------------------
  Future<void> addStudent(String name, String email) async {
    final res = await http.post(
      Uri.parse("$BASE_URL/students/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": "12345"  // Default password
      }),
    );

    if (res.statusCode == 200) {
      Navigator.pop(context); // close dialog
      loadStudents(); // refresh list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student Added Successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to Add Student")),
      );
    }
  }

  // ------------------------------------------------------------
  // POPUP FORM TO ADD STUDENT
  // ------------------------------------------------------------
  void showAddStudentDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add New Student", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: "Student Name"),
            ),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: "Student Email"),
            ),
            SizedBox(height: 10),
            Text(
              "Default Password: 12345",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                addStudent(nameCtrl.text, emailCtrl.text);
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Staff Panel",
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
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade100,

        child: students.isEmpty
            ? const Center(
          child: CircularProgressIndicator(color: Colors.blue),
        )
            : ListView.builder(
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];
            final currentStatus = markedStatus[s["id"]];

            return Container(
              height: 90,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s["name"],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          s["email"],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            markAttendance(s["id"], "Present"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentStatus == "Present"
                              ? Colors.green.shade500
                              : Colors.green.shade100,
                          minimumSize: Size(70, 32),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "P",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: currentStatus == "Present"
                                ? Colors.white
                                : Colors.green.shade900,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () =>
                            markAttendance(s["id"], "Absent"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentStatus == "Absent"
                              ? Colors.red.shade500
                              : Colors.red.shade100,
                          minimumSize: Size(70, 32),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "A",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: currentStatus == "Absent"
                                ? Colors.white
                                : Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),

      // ------------------------------------------------------------
      // FLOATING BUTTON TO ADD STUDENT
      // ------------------------------------------------------------
      floatingActionButton: FloatingActionButton(
        onPressed: showAddStudentDialog,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}
