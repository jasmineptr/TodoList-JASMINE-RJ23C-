import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String category;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'category': category,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      deadline: (map['deadline'] as Timestamp).toDate(),
      category: map['category'],
      isCompleted: map['isCompleted'],
    );
  }
}

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Task> _tasks = [];
  StreamSubscription? _tasksSubscription;

  List<Task> get tasks => _tasks;

  List<Task> get lateTasks {
    final now = DateTime.now();
    return _tasks.where((task) => !task.isCompleted && task.deadline.isBefore(now)).toList();
  }

  TaskProvider() {
    _initTasks();
  }

  void _initTasks() {
    final user = _auth.currentUser;
    if (user != null) {
      _tasksSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .snapshots()
          .listen((snapshot) {
        _tasks = snapshot.docs
            .map((doc) => Task.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
        notifyListeners();
      });
    }
  }

  Future<void> addTask(Task task) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .add(task.toMap());
    }
  }

  Future<void> updateTask(Task task) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(task.id)
          .update(task.toMap());
    }
  }

  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': isCompleted});
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
} 