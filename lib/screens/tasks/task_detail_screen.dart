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
bool isUpdatingShare = false;


String get currentUserId {
  // Lấy ID người dùng từ JWT
  final parts = widget.token.split('.');
  final payload = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  );

  return (payload['userId'] ?? payload['id'] ?? payload['_id']).toString();
}

bool get isCreator {
  final creator = currentTask['createdBy'];

  final creatorId = creator is Map
      ? creator['_id'].toString()
      : creator.toString();

  return creatorId == currentUserId;
}

bool get canEdit {
  if (isCreator) return true;

  final sharedUsers =
      currentTask['sharedWith'] as List? ?? [];

  return sharedUsers.any((item) {
    final user = item['userId'];
    final userId =
    user is Map ? user['_id'].toString() : user.toString();

    return userId == currentUserId && item['role'] == 'editor';
  });
}


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


  Future<void> openTaskHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskHistoryPage(
          taskId: currentTask['_id'].toString(),
          taskTitle: currentTask['title'] ?? '',
          token: widget.token,
        ),
      ),
    );
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
      setState(() {
        isDeleting = false;
      });
    }
  }
}


  Widget _buildStatusSelector() {
    final statuses = {
      'todo': 'Chưa thực hiện',
      'in_progress': 'Đang thực hiện',
      'completed': 'Đã hoàn thành',
    };

    final currentStatus = currentTask['status']?.toString() ?? 'todo';

    // Người tạo hoặc người được giao mới được đổi trạng thái
    final isAssignee = (currentTask['assigneeIds'] as List? ?? [])
        .any((user) {
      final id = user is Map ? user['_id']?.toString() : user.toString();
      return id == currentUserId;
    });

    if (!isCreator && !isAssignee) {
      return _buildInfo('Trạng thái', statuses[currentStatus] ?? currentStatus);
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Trạng thái'),
      subtitle: DropdownButton<String>(
        isExpanded: true,
        value: statuses.containsKey(currentStatus) ? currentStatus : 'todo',
        items: statuses.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (newStatus) {
          if (newStatus != null) {
            updateTaskStatus(newStatus);
          }
        },
      ),
    );
  }

  Future<void> updateTaskStatus(String status) async {
    try {
      final response = await http.put(
        Uri.parse(
          'http://10.0.2.2:3000/api/tasks/${currentTask['_id']}/status',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          currentTask = Map<String, dynamic>.from(data['task']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Cập nhật trạng thái thất bại'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),


        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Chỉnh sửa',
              onPressed: editTask,
            ),

          if (isCreator)
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
          _buildStatusSelector(),
          _buildInfo('Mức độ ưu tiên', currentTask['priority']),
          _buildInfo('Ngày bắt đầu', currentTask['startDate']),
          _buildInfo('Hạn hoàn thành', currentTask['dueDate']),


          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.history,
                color: Colors.blue,
              ),
              title: const Text(
                'Lịch sử hoạt động',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Xem quá trình thay đổi của công việc',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: openTaskHistory,
            ),
          ),

          const Divider(height: 30),


          const Divider(height: 30),

          const Text(
            'Người tạo công việc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          _buildUserTile(currentTask['createdBy'], 'Người tạo'),

          const Divider(height: 30),

          const Text(
            'Danh sách người được giao',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          ...((currentTask['assigneeIds'] as List?) ?? []).map(
                (user) {
              final userId = user is Map
                  ? user['_id']?.toString()
                  : user.toString();

              final primary = currentTask['primaryAssigneeId'];
              final primaryId = primary is Map
                  ? primary['_id']?.toString()
                  : primary?.toString();

              return _buildUserTile(
                user,
                userId == primaryId
                    ? 'Người phụ trách chính'
                    : 'Người được giao',
              );
            },
          ),

          const Divider(height: 30),

          const Text(
            'Danh sách người được chia sẻ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),


          ...((currentTask['sharedWith'] as List?) ?? []).map(
                (item) {
              final user = item['userId'];
              final userId = user is Map
                  ? user['_id'].toString()
                  : user.toString();

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  user is Map
                      ? user['fullName'] ?? 'Không rõ tên'
                      : 'Tài khoản',
                ),
                subtitle: Text(
                  user is Map ? user['email'] ?? '' : '',
                ),
                trailing: isCreator
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'viewer' || value == 'editor') {
                      updateSharePermission(userId, value);
                    } else if (value == 'revoke') {
                      revokeShareAccess(userId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'viewer',
                      child: Text('Chỉ xem (Viewer)'),
                    ),
                    const PopupMenuItem(
                      value: 'editor',
                      child: Text('Chỉnh sửa (Editor)'),
                    ),
                    const PopupMenuItem(
                      value: 'revoke',
                      child: Text('Thu hồi quyền'),
                    ),
                  ],
                )
                    : Text(
                  item['role'] == 'editor' ? 'Editor' : 'Viewer',
                ),
              );
            },
          ),
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

  Widget _buildUserTile(dynamic user, String role) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    final name = user is Map
        ? user['fullName'] ?? 'Không rõ tên'
        : 'Tài khoản';

    final email = user is Map
        ? user['email'] ?? ''
        : '';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(name.toString()),
      subtitle: Text(email.toString()),
      trailing: Text(
        role,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> updateSharePermission(
      String userId, String role) async {
    try {
      final response = await http.put(
        Uri.parse(
          'http://10.0.2.2:3000/api/tasks/${currentTask['_id']}/share',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'userId': userId,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          currentTask = Map<String, dynamic>.from(data['task']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật quyền thành công'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Cập nhật quyền thất bại'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật quyền chia sẻ'),
        ),
      );
    }
  }


  Future<void> revokeShareAccess(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'http://10.0.2.2:3000/api/tasks/${currentTask['_id']}/share',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          currentTask = Map<String, dynamic>.from(data['task']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thu hồi quyền chia sẻ'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Thu hồi quyền thất bại'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thu hồi quyền chia sẻ'),
        ),
      );
    }
  }
}


class TaskHistoryPage extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String token;

  const TaskHistoryPage({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.token,
  });

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:3000/api/statistics/tasks/${widget
              .taskId}/activities',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          activities = List<Map<String, dynamic>>.from(
            data['activities'] ?? [],
          );
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data['message'] ??
              'Không thể tải lịch sử hoạt động';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Không thể kết nối đến máy chủ';
        isLoading = false;
      });
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return 'Không rõ thời gian';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Không rõ thời gian';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadActivities,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : activities.isEmpty
          ? const Center(
        child: Text('Chưa có lịch sử hoạt động'),
      )
          : RefreshIndicator(
        onRefresh: loadActivities,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            final user = activity['userId'];

            final userName = user is Map
                ? user['fullName'] ?? 'Người dùng'
                : 'Người dùng';

            return Card(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.history),
                ),
                title: Text(
                  activity['description'] ??
                      'Hoạt động công việc',
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Người thực hiện: $userName\n'
                        'Thời gian: ${formatDate(activity['createdAt'])}',
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}