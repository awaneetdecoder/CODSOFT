// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

// ================================================================= //
// --- 1. DATA MODELS & ENUMS ---
// ================================================================= //

enum TaskPriority { low, medium, high }

var _uuid = const Uuid();

class Task {
  final String id;
  String title;
  String description;
  DateTime dueDate;
  TaskPriority priority;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
  }) : id = _uuid.v4();
  
  Task._fromMap(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        description = map['description'],
        dueDate = DateTime.parse(map['dueDate']),
        priority = TaskPriority.values[map['priority']],
        isCompleted = map['isCompleted'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.index,
      'isCompleted': isCompleted,
    };
  }
}

// ================================================================= //
// --- 2. LOGIC & STATE MANAGEMENT ---
// ================================================================= //

class TaskViewModel extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;
  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  static const _tasksKey = 'tasks_data';
  static const _onboardingKey = 'onboarding_seen';

  TaskViewModel() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final taskData = prefs.getString(_tasksKey);
    if (taskData != null) {
      final List<dynamic> taskList = json.decode(taskData);
      _tasks = taskList.map((item) => Task._fromMap(item)).toList();
    }

    _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> taskList = _tasks.map((task) => task.toMap()).toList();
    await prefs.setString(_tasksKey, json.encode(taskList));
    await prefs.setBool(_onboardingKey, _hasSeenOnboarding);
  }

  void addTask(Task task) {
    _tasks.add(task);
    _saveAndNotify();
  }

  void updateTask(Task task) {
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveAndNotify();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveAndNotify();
  }

  void toggleCompletion(String id) {
    int index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _saveAndNotify();
    }
  }

  void completeOnboarding() {
    _hasSeenOnboarding = true;
    _saveAndNotify();
  }

  void _saveAndNotify() {
    _saveData();
    notifyListeners();
  }
}

// ================================================================= //
// --- 3. THEME & STYLES ---
// ================================================================= //

class AppStyles {
  static final ThemeData theme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    primarySwatch: Colors.blue,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}

// ================================================================= //
// --- 4. MAIN APPLICATION & ROUTING ---
// ================================================================= //

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TaskViewModel(),
      child: const TaskMasterApp(),
    ),
  );
}

class TaskMasterApp extends StatelessWidget {
  const TaskMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMaster',
      theme: AppStyles.theme,
      debugShowCheckedModeBanner: false,
      home: Consumer<TaskViewModel>(
        builder: (context, viewModel, child) {
          return viewModel.hasSeenOnboarding ? const HomeScreen() : const OnboardingScreen();
        },
      ),
    );
  }
}

// ================================================================= //
// --- 5. SCREENS ---
// ================================================================= //

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.string(
                '''<svg viewBox="0 0 300 300"><circle cx="150" cy="150" r="140" fill="#E3F2FD"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-family="Arial" font-size="40" fill="#1E88E5">TaskMaster</text></svg>''',
                width: 250,
                height: 250,
              ),
              Column(
                children: [
                  Text(
                    'Manage Your Everyday Tasks',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Organize, prioritize, and complete your tasks with a clean and simple interface.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Provider.of<TaskViewModel>(context, listen: false).completeOnboarding();
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TaskViewModel>(context);
    // *** THIS IS THE CORRECTED LOGIC ***
    // We separate the tasks into two lists instead of filtering them out.
    final pendingTasks = viewModel.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = viewModel.tasks.where((t) => t.isCompleted).toList();
    
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text("Hello There!"),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, color: Colors.black54),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'You have ${pendingTasks.length} tasks pending.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: "Pending Tasks"),
          const SizedBox(height: 16),
          if (pendingTasks.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No pending tasks. Great job!")))
          else
            ...pendingTasks.map((task) => TaskCard(task: task)).toList(),
          
          // We add a new section for completed tasks.
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionHeader(title: "Completed"),
            const SizedBox(height: 16),
            ...completedTasks.map((task) => TaskCard(task: task)).toList(),
          ]
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskEditorScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add New Task'),
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class TaskEditorScreen extends StatefulWidget {
  final Task? task;
  const TaskEditorScreen({super.key, this.task});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _dueDate;
  late TaskPriority _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate ?? DateTime.now();
    _priority = widget.task?.priority ?? TaskPriority.medium;
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<TaskViewModel>(context, listen: false);
      final task = Task(
        title: _titleController.text,
        description: _descController.text,
        dueDate: _dueDate,
        priority: _priority,
      );

      if (widget.task != null) {
        final updatedTask = Task._fromMap({
          ...task.toMap(),
          'id': widget.task!.id,
          'isCompleted': widget.task!.isCompleted,
        });
        viewModel.updateTask(updatedTask);
      } else {
        viewModel.addTask(task);
      }
      Navigator.pop(context);
    }
  }
  
  Future<void> _selectDate() async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2101));
      if (picked != null && picked != _dueDate) {
        setState(() {
          _dueDate = picked;
        });
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat.yMMMd().format(_dueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name.substring(0, 1).toUpperCase() + priority.name.substring(1)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _priority = value!),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.task == null ? 'Add Task' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================= //
// --- 6. CUSTOM WIDGETS ---
// ================================================================= //

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text('See All', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return Colors.red.shade300;
      case TaskPriority.medium: return Colors.orange.shade300;
      case TaskPriority.low: return Colors.blue.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<TaskViewModel>(context, listen: false);
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (val) => viewModel.toggleCompletion(task.id),
              activeColor: Colors.deepPurpleAccent,
            ),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(color: _getPriorityColor(task.priority), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.grey.shade400),
              onPressed: () => viewModel.deleteTask(task.id),
            ),
          ],
        ),
      ),
    );
  }
}
