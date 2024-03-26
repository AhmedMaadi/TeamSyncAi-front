import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pim/modulesList.dart';
import 'package:flutter_pim/tasksPage.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> fetchProjects() async {
    final response =
        await http.get(Uri.parse('http://192.168.231.1:3000/projectss'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load projects');
    }
  }

  Future<Map<String, dynamic>> fetchModules(String projectId) async {
    final response = await http
        .get(Uri.parse('http://192.168.231.1:3000/modules/project/$projectId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load modules');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Projects'),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: fetchProjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              Map<String, dynamic> data = snapshot.data!;
              List<dynamic> projects = data['projects'];
              return ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  var project = projects[index];
                  return FutureBuilder<Map<String, dynamic>>(
                    future: fetchModules(project['_id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        Map<String, dynamic> data = snapshot.data!;
                        List<dynamic> modules = data['modules'];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Project Name: ${project['name']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                           ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modules.length,
                              itemBuilder: (context, index) {
                                var module = modules[index];
                                return ListTileModule(
                                  projectTitle: project['name'],
                                  moduleTitle: module['module_name'],
                                  profileImagePaths: const [
                                    'images/reclamation.jpg'
                                  ],
                                  percentage:
                                      50, // You can modify this to get the percentage from the project data
                                  imagePath: 'images/pp.png',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                       builder: (context) => TasksPage(
                                          moduleId: module['_id'],
                                        
                                      ),
                                    ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
