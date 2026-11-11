import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String token;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.token,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
late Map<String, dynamic> currentTask;
bool isDeleting = false;

@override
void initState() {
super.initState();
currentTask = Map<String, dynamic>.from(widget.task);
}

// Chỉnh sửa công việc
Future<void> editTask() async {
final updatedTask = await Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
TaskEditScreen(
    task: currentTask,
    token: widget.token,
),
),
);

if (updatedTask != null) {
setState(() {
currentTask = updatedTask;
});
}
}

// Xác nhận xóa công việc
Future<void> confirmDelete() async {
final confirm = await showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
title: const Text('Xóa công việc'),
content: const Text(
'Bạn có chắc chắn muốn xóa công việc này không?',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Hủy'),
),
TextButton(
onPressed: () => Navigator.pop(context, true),
child: const Text(
'Xóa',
style: TextStyle(color: Colors.red),
),
),
],
),
);

if (confirm == true) {
await deleteTask();
}
}

// Gọi API xóa công việc
Future<void> deleteTask() async {
setState(() {
isDeleting = true;
});

try {
final response = await http.delete(
Uri.parse(
'http://10.0.2.2:3000/api/tasks/${currentTask['_id']}',
),
headers: {
'Authorization': 'Bearer ${widget.token}',
},
);

final data = jsonDecode(response.body);

if (!mounted) return;

if (response.statusCode == 200) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Xóa công việc thành công'),
),
);

Navigator.pop(context, true);
} else {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(data['message'] ?? 'Không thể xóa công việc'),
),
);
}
} catch (error) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Không thể kết nối đến máy chủ'),
),
);
} finally {
if (mounted) {
setState(() {isDeleting = false;
});
}
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa',
            onPressed: editTask,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Xóa công việc',
            onPressed: isDeleting ? null : confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            currentTask['title'] ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mô tả công việc',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(currentTask['description'] ?? 'Không có mô tả'),
          const Divider(height: 30),
          _buildInfo('Trạng thái', currentTask['status']),
          _buildInfo('Mức độ ưu tiên', currentTask['priority']),
          _buildInfo('Ngày bắt đầu', currentTask['startDate']),
          _buildInfo('Hạn hoàn thành', currentTask['dueDate']),
        ],
      ),
    );
  }

  Widget _buildInfo(String label, dynamic value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value?.toString() ?? 'Chưa thiết lập'),
    );
  }
}