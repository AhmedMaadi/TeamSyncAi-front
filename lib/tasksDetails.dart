import 'package:flutter/material.dart';
import 'package:flutter_pim/tasksPage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskDetailsPage extends StatefulWidget {
  final Task task;
  final Function(Task) markAsCompleted;

  const TaskDetailsPage({
    Key? key,
    required this.task,
    required this.markAsCompleted,
  }) : super(key: key);

  @override
  _TaskDetailsPageState createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late List<String> steps;

  @override
  void initState() {
    super.initState();
    steps = [];
    generateSteps();
  }

  Future<void> generateSteps() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.231.1:3000/task/${widget.task.id}'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final dynamic stepsData = responseData['steps'];

        if (stepsData is List<dynamic>) {
          setState(() {
            steps = stepsData.cast<String>().toList();
          });
        } else if (stepsData is String) {
          setState(() {
            steps = [stepsData];
          });
        } else {
          print('Invalid steps data format');
        }
      } else {
        print('Failed to load steps: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching steps: $e');
    }
  }

  void _showCompletionMessage(BuildContext context) {
    final snackBar = SnackBar(
      content: Text('You completed a task!'),
      backgroundColor: Colors.orange,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: const Color(0xFFE89F16),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task.taskDescription,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 20,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Due:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        DateFormat('EEEE, h:mm a').format(widget.task.date),
                        style: const TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 233, 142, 5),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Team Members:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: widget.task.members.length,
                itemBuilder: (context, index) {
                  final member = widget.task.members[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  AssetImage(member.profileImagePath[0]),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(member.email),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Steps:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                for (final step in steps)
                  Text(
                    step,
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Mark task as completed
                    widget.markAsCompleted(widget.task);
                    // Show completion message
                    _showCompletionMessage(context);
                    // Navigate back
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      fixedSize: const Size(300.0, 50.0)),
                  child: const Text(
                    'Mark as Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
