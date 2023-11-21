import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StudentManagementScreen extends StatefulWidget {
  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Map<String, dynamic>> classes = [];
  Map<String, dynamic>? selectedClass;
  List<Map<String, dynamic>> students = [];
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLastNameController = TextEditingController();
  String? selectedClassId;

  @override
  void initState() {
    super.initState();
    fetchClassesFromBackend();
  }

  Future<void> fetchClassesFromBackend() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8082/classes'));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('_embedded') && data['_embedded'] != null) {
          List<dynamic> classesData = data['_embedded']['classes'];
          setState(() {
            classes = List<Map<String, dynamic>>.from(classesData);
          });
        } else {
          throw Exception('No classes found');
        }
      } else {
        throw Exception('Failed to load classes');
      }
    } catch (error) {
      print('Error fetching classes: $error');
    }
  }

  Future<void> fetchStudentsByClass(int classCode) async {
    final String apiUrl = 'http://10.0.2.2:8082/classes/$classCode/etudiants';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('_embedded') &&
            responseData['_embedded'] != null &&
            responseData['_embedded'].containsKey('etudiants')) {
          List<dynamic> studentsData = responseData['_embedded']['etudiants'];
          List<Map<String, dynamic>> fetchedStudents =
          List<Map<String, dynamic>>.from(studentsData);
          setState(() {
            students = fetchedStudents;
          });
        } else {
          throw Exception('No students found for class with ID: $classCode');
        }
      } else {
        throw Exception('Failed to load students for class with ID: $classCode');
      }
    } catch (error) {
      throw Exception('Error fetching students: $error');
    }
  }

  Future<void> _handleRefresh() async {
    if (selectedClass != null) {
      await fetchStudentsByClass(selectedClass!['codClass']);
    }
  }


  void _showAddStudentPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: studentNameController,
                decoration: InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: studentLastNameController,
                decoration: InputDecoration(labelText: 'Student Last Name'),
              ),
              DropdownButton<Map<String, dynamic>>(
                value: selectedClass,
                hint: Text('Select a class'),
                items: classes.map<DropdownMenuItem<Map<String, dynamic>>>(
                      (classData) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: classData,
                      child: Text(classData['nomClass'].toString()),
                    );
                  },
                ).toList(),
                onChanged: (Map<String, dynamic>? classData) {
                  setState(() {
                    selectedClass = classData;
                  });
                  if (classData != null) {
                    fetchStudentsByClass(classData['codClass']);
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addNewStudent(studentNameController.text,studentLastNameController.text);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
  void _deleteStudent(int studentId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8082/classes/etudiants/deleteStudent/$studentId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // After successfully deleting a student, fetch the updated list of students
        fetchStudentsByClass(selectedClass!['codClass']);
      } else if (response.statusCode == 404) {
        // Handle the case where the student was not found
        print('Student not found');
      } else {
        throw Exception('Failed to delete the student');
      }
    } catch (error) {
      print('Error deleting the student: $error');
    }
  }

// Add this method to call _deleteStudent when you want to delete a student
  void _confirmDeleteStudent(BuildContext context, int studentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this student?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteStudent(studentId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateStudentPopup(BuildContext context, Map<String, dynamic> student) {
    studentNameController.text = student['nom'];
    studentLastNameController.text = student['prenom'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Student'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: studentNameController,
                decoration: InputDecoration(labelText: 'Student Name'),
              ),
              TextField(
                controller: studentLastNameController,
                decoration: InputDecoration(labelText: 'Student Last Name'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateStudent(student);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
  void _updateStudent(Map<String, dynamic> student) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/classes/etudiants/updateStudent/${student['id']}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nom': studentNameController.text,
          'classe': {
            'codClass': selectedClass!['codClass'],
          },
          'prenom': studentLastNameController.text,
          'dateNais': '2023-11-21', // Example date; adjust accordingly
        }),
      );

      if (response.statusCode == 200) {
        // After successfully updating a student, fetch the updated list of students
        fetchStudentsByClass(selectedClass!['codClass']);
        _handleRefresh();
      } else {
        throw Exception('Failed to update the student');
      }
    } catch (error) {
      print('Error updating the student: $error');
    }
  }



  void _addNewStudent(String studentName, String lastName) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/classes/etudiants/addStudent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nom': studentName,
          'classe': {
            'codClass': selectedClass!['codClass'],
          },
          'prenom': lastName, // Add other attributes if needed
          'dateNais': '2023-11-21', // Example date; adjust accordingly
        }),
      );



      if (response.statusCode == 201) {
        // After successfully adding a new student, fetch the updated list of students
        fetchStudentsByClass(selectedClass!['codClass']);
        _handleRefresh();

      } else {
        throw Exception('Failed to add a new student');
      }
    } catch (error) {
      print('Error adding a new student: $error');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<Map<String, dynamic>>(
              value: selectedClass,
              hint: Text('Select a class'),
              items: classes.map<DropdownMenuItem<Map<String, dynamic>>>(
                    (classData) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: classData,
                    child: Text(classData['nomClass'].toString()),
                  );
                },
              ).toList(),
              onChanged: (Map<String, dynamic>? classData) {
                setState(() {
                  selectedClass = classData;
                });
                if (classData != null) {
                  fetchStudentsByClass(classData['codClass']);
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    subtitle: Text('ID: ${students[index]['id']}'),
                    title: Text(students[index]['nom']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Handle update logic here
                            _showUpdateStudentPopup(context, students[index]);
                          },
                          child: Text('Update'),
                        ),
                        SizedBox(width: 8), // Add some spacing between buttons
                        ElevatedButton(
                          onPressed: () {
                            // Handle delete logic here
                            _confirmDeleteStudent(context, students[index]['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red, // Use red color for delete button
                          ),
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );

                },

              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddStudentPopup(context);
        },
        tooltip: 'Add Student',
        child: Icon(Icons.add),
      ),
    );
  }
}
