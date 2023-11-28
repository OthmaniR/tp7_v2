import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentManagementScreen extends StatefulWidget {
  final String classId;
  final String className;

  // Define the classId parameter in the constructor
  StudentManagementScreen({required this.classId, required this.className});

  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    fetchStudentsForClass(widget.classId);
  }

  Future<void> fetchStudentsForClass(String classId) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8082/classes/etudiants'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            students = List<Map<String, dynamic>>.from(data);
          });
        } else {
          throw Exception('No students found for class');
        }
      } else {
        throw Exception('Failed to load students');
      }
    } catch (error) {
      print('Error fetching students: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Students for ${widget.className}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display students here using the 'students' list

            // Example: Display student names in a ListView
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(students[index]['nom'] ?? 'N/A'),
                    subtitle: Text('ID: ${students[index]['id'] ?? 'N/A'}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Additional UI or features can be added here
    );
  }
}
