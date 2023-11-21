import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupsManagementScreen extends StatefulWidget {
  @override
  _GroupsManagementScreenState createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends State<GroupsManagementScreen> {
  List<Map<String, dynamic>> classes = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classes'),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(classes[index]['nomClass'] ?? 'N/A'),
              subtitle: Text('ID: ${classes[index]['codClass'] ?? 'N/A'}'),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show the popup to create a new class
          _showCreateClassPopup(context);
        },
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
    );
  }

  // Function to show the popup for creating a new class
  void _showCreateClassPopup(BuildContext context) {
    TextEditingController classNameController = TextEditingController();

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
                  // Add form fields for class details (name, etc.)
                  TextField(
                    controller: classNameController,
                    decoration: InputDecoration(labelText: 'Class Name'),
                    // Handle onChanged or controller to capture user input
                  ),
                  // Add more fields as needed
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    // Close the popup
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Perform logic to create a new class
                    // Use the value entered in the text field
                    _createNewClass(classNameController.text);
                    // Close the popup
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
  void _createNewClass(String className) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/classes'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nomClass': className, // Use the entered class name
          // Add more fields as needed
        }),
      );

      if (response.statusCode == 201) {
        // Successfully created a new class, fetch the updated list
        fetchClassesFromBackend();
      } else {
        throw Exception('Failed to create a new class');
      }
    } catch (error) {
      print('Error creating a new class: $error');
    }
  }
}
