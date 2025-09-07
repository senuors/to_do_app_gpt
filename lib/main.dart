// main.dart
import 'dart:convert'; // تحويل JSON

import 'package:flutter/material.dart'; // ويدجت (Widget) ومواد التصميم
import 'package:shared_preferences/shared_preferences.dart'; // التخزين المحلي (SharedPreferences)

// موديل المهمة (Task)
class Task {
  final int id; // معرف فريد (timestamp)
  String title;
  bool done;

  Task({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory Task.fromJson(Map<String, dynamic> json) =>
      Task(id: json['id'], title: json['title'], done: json['done']);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple To-Do',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  List<Task> _tasks = [];

  // INIT: تحميل المهام عند بدء الويدجت (initState)
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // تحميل من SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('tasks');
    if (stored != null) {
      setState(() {
        _tasks = stored
            .map((s) => Task.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
      });
    }
  }

  // حفظ القائمة في SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> asString = _tasks
        .map((t) => jsonEncode(t.toJson()))
        .toList();
    await prefs.setStringList('tasks', asString);
  }

  // إضافة مهمة جديدة
  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final task = Task(id: DateTime.now().millisecondsSinceEpoch, title: text);
    setState(() {
      _tasks.insert(0, task); // إدراج في البداية
      _controller.clear();
    });
    _saveTasks();
  }

  // تبديل حالة الانجاز (done)
  void _toggleDone(int index) {
    setState(() {
      _tasks[index].done = !_tasks[index].done;
    });
    _saveTasks();
  }

  // حذف مهمة
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do Simple'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // إدخال مهمة جديدة
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب مهمة واضغط +',
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addTask, child: const Text('+')),
              ],
            ),
            const SizedBox(height: 12),
            // قائمة المهام
            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('لا توجد مهام'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Dismissible(
                          key: Key(task.id.toString()),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteTask(index),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.done,
                              onChanged: (_) => _toggleDone(index),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_forever),
                              onPressed: () => _deleteTask(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
