import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TaskEditScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String token;

  const TaskEditScreen({
    super.key,
    required this.task,
    required this.token,
  });

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  late String priority;
  late String status;

  DateTime? startDate;
  DateTime? dueDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.task['title'] ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.task['description'] ?? '',
    );

    priority = {
      'low': 'Thấp',
      'medium': 'Trung bình',
      'high': 'Cao',
    }[widget.task['priority']] ?? 'Trung bình';

    status = {
      'todo': 'Chưa thực hiện',
      'in_progress': 'Đang thực hiện',
      'completed': 'Đã hoàn thành',
    }[widget.task['status']] ?? 'Chưa thực hiện';

    startDate = DateTime.tryParse(
      widget.task['startDate']?.toString() ?? '',
    );

    dueDate = DateTime.tryParse(
      widget.task['dueDate']?.toString() ?? '',
    );
  }

// Chọn ngày
  Future<void> selectDate(bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now())
          : (dueDate ?? startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          startDate = selectedDate;
        } else {
          dueDate = selectedDate;
        }
      });
    }
  }

// Định dạng ngày
  String formatDate(DateTime? date) {
    if (date == null) return 'Chưa chọn ngày';

    return '${date.day}/${date.month}/${date.year}';
  }

// Lưu thay đổi
  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate != null &&
        dueDate != null &&
        dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hạn hoàn thành không được trước ngày bắt đầu',
          ),
        ),
      );
      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    final priorityMap = {
      'Thấp': 'low',
      'Trung bình': 'medium',
      'Cao': 'high',
    };

    final statusMap = {
      'Chưa thực hiện': 'todo',
      'Đang thực hiện': 'in_progress',
      'Đã hoàn thành': 'completed',
    };

    try {
      final response = await http.put(
        Uri.parse(
          'http://10.0.2.2:3000/api/tasks/${widget.task['_id']}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'priority': priorityMap[priority],
          'status': statusMap[status],
          'startDate': startDate?.toIso8601String(),
          'dueDate': dueDate?.toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật công việc thành công'),
          ),
        );

        Navigator.pop(context, data['task']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Không thể cập nhật công việc',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối đến máy chủ'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isSaving ? null : saveChanges,
            tooltip: 'Lưu thay đổi',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên công việc',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return 'Vui lòng nhập tên công việc';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả công việc',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16), DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(
                labelText: 'Mức độ ưu tiên',
                border: OutlineInputBorder(),
              ),
              items: ['Thấp', 'Trung bình', 'Cao']
                  .map((value) =>
                  DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => priority = value);
                }
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
              ),
              items: [
                'Chưa thực hiện',
                'Đang thực hiện',
                'Đã hoàn thành',
              ]
                  .map((value) =>
                  DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => status = value);
                }
              },
            ),

            const SizedBox(height: 20),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(formatDate(startDate)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => selectDate(true),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Hạn hoàn thành'),
              subtitle: Text(formatDate(dueDate)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => selectDate(false),
            ),
          ],
        ),
      ),
    );
  }
}