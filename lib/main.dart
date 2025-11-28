import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_home.dart';
import 'staff_home.dart';

const BASE_URL = "http://10.145.53.199:8000";

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  // -----------------------------------------------------------
  //                       LOGIN FUNCTION
  // -----------------------------------------------------------
  Future<void> login() async {
    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("$BASE_URL/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailCtrl.text.trim(),
          "password": passCtrl.text.trim(),
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["role"] == "student") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentHome(userId: data["id"])),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StaffHome()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid login")),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server connection error")),
      );
    }
  }

  // -----------------------------------------------------------
  //              CHANGE PASSWORD (FIXED VERSION)
  //  1) Login with email + old password -> get user_id
  //  2) Call /change-password with user_id + old + new
  // -----------------------------------------------------------
  Future<void> changePassword(String oldPass, String newPass) async {
    // Email must be entered in login box
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email in login box")),
      );
      return;
    }

    try {
      // STEP 1: Verify old password by calling /login
      final loginRes = await http.post(
        Uri.parse("$BASE_URL/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": oldPass,
        }),
      );

      if (loginRes.statusCode != 200) {
        // Old password is wrong OR email mismatch
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Old password is incorrect")),
        );
        return;
      }

      final loginData = jsonDecode(loginRes.body);
      final int userId = loginData["id"];

      // STEP 2: Call /change-password with user_id + old + new
      final res = await http.post(
        Uri.parse("$BASE_URL/change-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,        // 🔴 IMPORTANT: use user_id, not email
          "old_password": oldPass,
          "new_password": newPass,
        }),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context); // close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to change password")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error while changing password")),
      );
    }
  }

  // -----------------------------------------------------------
  //    POPUP DIALOG — CHANGE PASSWORD (EMAIL NOT ASKED HERE)
  // -----------------------------------------------------------
  void openChangePasswordDialog() {
    TextEditingController oldCtrl = TextEditingController();
    TextEditingController newCtrl = TextEditingController();
    TextEditingController confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Center(
          child: Text(
            "Change Password",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // OLD PASSWORD
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: "Old Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // NEW PASSWORD
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_reset),
                labelText: "New Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // CONFIRM PASSWORD
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.verified_user),
                labelText: "Confirm Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New passwords do not match")),
                );
                return;
              }

              if (oldCtrl.text.isEmpty || newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All fields are required")),
                );
                return;
              }

              // Now call the fixed changePassword function
              changePassword(
                oldCtrl.text.trim(),
                newCtrl.text.trim(),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  //                        LOGIN UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // TITLE
                  const Text(
                    "ANNAMALAI UNIVERSITY",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  // Department box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Department of Computer and Information Science",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // LOGIN BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Student / Staff Attendance Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // EMAIL
                        TextField(
                          controller: emailCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email,
                                color: Colors.white),
                            labelText: "Email",
                            labelStyle:
                            const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // PASSWORD
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock,
                                color: Colors.white),
                            labelText: "Password",
                            labelStyle:
                            const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        loading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // CHANGE PASSWORD BUTTON
                        TextButton(
                          onPressed: openChangePasswordDialog,
                          child: const Text(
                            "Change Password?",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
