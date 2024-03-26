import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_pim/tasksDetails.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Task {
  final String id;
  final String taskDescription;
  final DateTime date;
  final List<Member> members;
  bool completed;

  Task({
    required this.id,
    required this.taskDescription,
    required this.date,
    required this.members,
    this.completed = false,
  });
}

class Member {
  final String name;
  final String email;
  final List<String> profileImagePath;

  Member({
    required this.name,
    required this.email,
    required this.profileImagePath,
  });
}

class TasksPage extends StatefulWidget {
  final String moduleId;

  const TasksPage({
    Key? key,
    required this.moduleId,
  }) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<List<Task>> _todayTasks;
  late Future<List<Task>> _upcomingTasks;
  late List<Task> _completedTasks;
  late bool _showTodayTasks;
  late bool _showCompletedTasks;

  @override
  void initState() {
    super.initState();
    _showTodayTasks = true;
    _showCompletedTasks = false;
    _completedTasks = [];
    _todayTasks = fetchTodayTasks(widget.moduleId);
    _upcomingTasks = fetchUpcomingTasks();

    fetchAndCategorizeTasks().then((_) {
      _toggleShowCompletedTasks(false);
      _toggleShowTodayTasks(true);
    });
  }

  Future<void> fetchAndCategorizeTasks() async {
    try {
      final List<Task> tasks = await fetchAllTasks(widget.moduleId);
      setState(() {
        _completedTasks = tasks.where((task) => task.completed).toList();
        _showCompletedTasks = _completedTasks.isNotEmpty;
      });
    } catch (e) {
      print('Error fetching and categorizing tasks: $e');
    }
  }

  Future<List<Task>> fetchAllTasks(String moduleId) async {
    final response = await http.get(
      Uri.parse('http://192.168.231.1:3000/tasks/modul/$moduleId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['tasks'];

      final List<Task> allTasks = data.map<Task>((taskData) {
        return Task(
          id: taskData['_id'],
          taskDescription: taskData['task_description'],
          date: DateTime.parse(taskData['date']),
          members: [],
          completed: taskData['completed'] ?? false,
        );
      }).toList();

      return allTasks;
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<List<Task>> fetchTodayTasks(String moduleId) async {
    final response = await http
        .get(Uri.parse('http://192.168.231.1:3000/tasks/modul/$moduleId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['tasks'];
      final today = DateTime.now();
      final List<Task> todayTasks = [];

      for (var taskData in data) {
        final taskDate = DateTime.parse(taskData['date']);

        if (taskDate.year == today.year &&
            taskDate.month == today.month &&
            taskDate.day == today.day &&
            !(taskData['completed'] ?? false)) {
          final task = Task(
            id: taskData['_id'],
            taskDescription: taskData['task_description'],
            date: taskDate,
            members: [],
          );
          todayTasks.add(task);
        }
      }

      return todayTasks;
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<List<Task>> fetchUpcomingTasks() async {
    final response = await http.get(
        Uri.parse('http://192.168.231.1:3000/tasks/modul/${widget.moduleId}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)['tasks'];

      // Get today's date
      final today = DateTime.now();

      // Filter tasks for upcoming based on the date
      final List<Task> upcomingTasks = [];

      for (var taskData in data) {
        final taskDate = DateTime.parse(taskData['date']);
        final Task task = Task(
          id: taskData['_id'],
          taskDescription: taskData['task_description'],
          date: taskDate,
          members: [],
        );

        if (taskDate.isAfter(today) &&
            (taskDate.year != today.year ||
                taskDate.month != today.month ||
                taskDate.day != today.day)) {
          upcomingTasks.add(task);
        }
      }

      return upcomingTasks;
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  void _toggleShowTodayTasks(bool showToday) {
    setState(() {
      _showTodayTasks = showToday;
      _showCompletedTasks = false;
    });
  }

  void _toggleShowCompletedTasks(bool showCompleted) {
    setState(() {
      _showCompletedTasks = showCompleted;
      _showTodayTasks = false;
    });
  }

  void _markAsCompleted(Task task) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.231.1:3000/tasks/${task.id}/completed'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _todayTasks = _todayTasks.then((tasks) {
            tasks.removeWhere((t) => t.id == task.id);
            return Future.value(tasks);
          });

          _completedTasks.add(task);

          _toggleShowCompletedTasks(true);
        });
      } else {
        throw Exception('Failed to mark task as completed');
      }
    } catch (e) {
      print('Error marking task as completed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks for Module ${widget.moduleId}'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _toggleShowTodayTasks(true),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      _showTodayTasks ? Colors.blue : Colors.transparent,
                ),
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: _showTodayTasks ? Colors.white : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 35),
              TextButton(
                onPressed: () => _toggleShowTodayTasks(false),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: !_showTodayTasks && !_showCompletedTasks
                      ? Colors.blue
                      : Colors.transparent,
                ),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    color: !_showTodayTasks && !_showCompletedTasks
                        ? Colors.white
                        : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 35),
              TextButton(
                onPressed: () => _toggleShowCompletedTasks(true),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      _showCompletedTasks ? Colors.blue : Colors.transparent,
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: _showCompletedTasks ? Colors.white : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _showCompletedTasks
                ? ListView.builder(
                    itemCount: _completedTasks.length,
                    itemBuilder: (context, index) {
                      final Task task = _completedTasks[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            task.taskDescription,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Completed: ${DateFormat('EEEE, h:mm a').format(task.date)}',
                                ),
                              ),
                              VerticalDivider(),
                              Text(
                                'Done',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 20, 3),
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : FutureBuilder<List<Task>>(
                    future: _showTodayTasks ? _todayTasks : _upcomingTasks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else {
                        final List<Task> tasks = snapshot.data!;
                        return ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final Task task = tasks[index];
                            return Card(
                              child: ListTile(
                                title: Text(task.taskDescription),
                                subtitle: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Due: ${DateFormat('EEEE, h:mm a').format(task.date)}',
                                      ),
                                    ),
                                    VerticalDivider(),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TaskDetailsPage(
                                              task: task,
                                              markAsCompleted: _markAsCompleted,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                            255,
                                            5,
                                            223,
                                            252), // Set the button color to cyan
                                      ),
                                      child: Text(
                                        'In Progress',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailsPage(
                                        task: task,
                                        markAsCompleted: _markAsCompleted,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
