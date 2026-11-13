import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskCreateScreen extends StatefulWidget {
  final String token;

  const TaskCreateScreen({
    super.key,
    required this.token,
  });


  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String priority = 'Trung bình';
  String status = 'Chưa thực hiện';

  DateTime? startDate;
  DateTime? dueDate;

  List<Map<String, dynamic>> users = [];
  List<String> selectedAssigneeIds = [];

  Map<String, String> selectedSharedUsers = {};

  bool isLoadingUsers = false;

  String? primaryAssigneeId;


  Future<void> loadUsers() async {
    setState(() {
      isLoadingUsers = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/auth/users'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('DANH SACH USERS: ${response.body}');

        setState(() {
          users = List<Map<String, dynamic>>.from(data['users']);
        });
      }
    } catch (e) {
      debugPrint('Load users error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingUsers = false;
        });
      }
    }
  }


  Future<void> selectDate(bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (startDate != null &&
        dueDate != null &&
        dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hạn hoàn thành không được trước ngày bắt đầu'),
        ),
      );
      return;
    }

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
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/tasks'),
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
          'assigneeIds': selectedAssigneeIds,
          'primaryAssigneeId': primaryAssigneeId,
          'sharedWith': selectedSharedUsers.entries.map((entry) {
            return {
              'userId': entry.key,
              'role': entry.value,
            };
          }).toList(),
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context, data['task']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Tạo công việc thất bại'),
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
    }
  }


  @override
  void initState() {
    super.initState();
    loadUsers();
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
          title: const Text('Tạo công việc'),
          actions: [
            TextButton(
              onPressed: saveTask,
              child: const Text(
                'LƯU',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ]
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Thông tin công việc',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên công việc',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task_alt),
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
              maxLines: 4, decoration: const InputDecoration(
              labelText: 'Mô tả công việc',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
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

            const Text(
              'Người được giao',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (isLoadingUsers)
              const Center(child: CircularProgressIndicator())
            else if (users.isEmpty)
              const Text('Chưa có tài khoản nào')
            else
              ...users.map((user) {
                final userId = user['_id'].toString();

                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(user['fullName'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  value: selectedAssigneeIds.contains(userId),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedAssigneeIds.add(userId);
                      } else {
                        selectedAssigneeIds.remove(userId);
                      }
                    });
                  },
                );
              }),

            const Text(
              'Người phụ trách chính',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: primaryAssigneeId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Chọn người phụ trách chính',
              ),
              items: users
                  .where((user) => selectedAssigneeIds.contains(user['_id'].toString()))
                  .map((user) {
                return DropdownMenuItem<String>(
                  value: user['_id'].toString(),
                  child: Text(user['fullName'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  primaryAssigneeId = value;
                });
              },
            ),


            const Divider(height: 32),

            const Text(
              'Chia sẻ công việc',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Chọn người được chia sẻ và quyền truy cập',
            ),

            ...users
                .where((user) =>
            !selectedAssigneeIds.contains(
              user['_id'].toString(),
            ))
                .map((user) {
              final userId = user['_id'].toString();
              final isSelected =
              selectedSharedUsers.containsKey(userId);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(user['fullName'] ?? ''),
                    subtitle: Text(user['email'] ?? ''),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedSharedUsers[userId] = 'viewer';
                        } else {
                          selectedSharedUsers.remove(userId);
                        }
                      });
                    },
                  ),

                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedSharedUsers[userId],
                        decoration: const InputDecoration(
                          labelText: 'Quyền truy cập',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Viewer - Chỉ xem'),
                          ),
                          DropdownMenuItem(
                            value: 'editor',
                            child: Text('Editor - Được chỉnh sửa'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSharedUsers[userId] = value;
                            });
                          }
                        },
                      ),
                    ),
                ],
              );
            }),


            const SizedBox(height: 20),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(
                startDate == null
                    ? 'Chưa chọn ngày'
                    : '${startDate!.day}/${startDate!.month}/${startDate!
                    .year}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => selectDate(true),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Hạn hoàn thành'),
              subtitle: Text(
                dueDate == null
                    ? 'Chưa chọn ngày'
                    : '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
              ),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () => selectDate(false),
            ),

            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }
}