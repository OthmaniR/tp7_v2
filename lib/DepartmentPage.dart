import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'student_management.dart'; // Import your StudentManagementScreen file

class DepartmentPage extends StatefulWidget {
  @override
  _DepartmentPageState createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  List<Map<String, dynamic>> classes = [];
  List<String> departments = ['INFO', 'GC']; // Your list of departments
  String selectedDepartment = 'INFO'; // Default selected department

  @override
  void initState() {
    super.initState();
    fetchClassesFromBackend(selectedDepartment);
  }

  Future<void> fetchClassesFromBackend(String department) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8082/classes/depart/$department'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            classes = List<Map<String, dynamic>>.from(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Departments'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: selectedDepartment,
              onChanged: (String? newValue) async {
                setState(() {
                  selectedDepartment = newValue!;
                });

                // Fetch classes for the selected department
                await fetchClassesFromBackend(selectedDepartment);
              },
              items: departments.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),

            SizedBox(height: 20),
            Text(
              'Classes for $selectedDepartment department:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(classes[index]['nomClass'] ?? 'N/A'),
                    subtitle: Text('ID: ${classes[index]['codClass'] ?? 'N/A'}'),
                    onTap: () {
                      // Navigate to StudentManagementScreen with selected class details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentManagementScreen(
                            classId: classes[index]['codClass'].toString(),
                            className: classes[index]['nomClass'] ?? 'N/A',
                          ),
                        ),
                      );

                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateClassPopup(context);
        },
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }

  void _showCreateClassPopup(BuildContext context) {
    TextEditingController classNameController = TextEditingController();
    TextEditingController departmentController = TextEditingController();
    TextEditingController numberOfStudentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: AlertDialog(
              title: Text('Create New Class'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: departmentController,
                    decoration: InputDecoration(labelText: 'Department'),
                  ),
                  TextField(
                    controller: classNameController,
                    decoration: InputDecoration(labelText: 'Class Name'),
                  ),
                  TextField(
                    controller: numberOfStudentsController,
                    decoration: InputDecoration(labelText: 'Number of Students'),
                    keyboardType: TextInputType.number,
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
                    _createNewClass(
                      departmentController.text,
                      classNameController.text,
                      numberOfStudentsController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Create'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createNewClass(
      String department,
      String className,
      String numberOfStudents,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/classes/put'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'depart': department,
          'nomClass': className,
          'nbreEtud': numberOfStudents,
        }),
      );

      if (response.statusCode == 201) {
        // Class created successfully, refresh the class list
        fetchClassesFromBackend(selectedDepartment);
      } else {
        throw Exception('Failed to create a new class');
      }
    } catch (error) {
      print('Error creating a new class: $error');
    }
  }
}
