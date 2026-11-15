import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String token;

  const NotificationScreen({
    super.key,
    required this.token,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final result =
      await NotificationService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải thông báo'),
        ),
      );
    }
  }

  Future<void> markAsRead(int index) async {
    final notification = notifications[index];
    final id = notification['_id']?.toString();

    if (id == null || notification['isRead'] == true) {
      return;
    }

    try {
      final success =
      await NotificationService.markAsRead(id);

      if (success && mounted) {
        setState(() {
          notifications[index]['isRead'] = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật thông báo'),
        ),
      );
    }
  }


  Future<void> openRelatedTask(int index) async {
    final item = notifications[index];
    final taskData = item['taskId'];

    if (taskData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông báo không có công việc liên quan'),
        ),
      );
      return;
    }

    final taskId = taskData is Map
        ? taskData['_id']?.toString()
        : taskData.toString();

    if (taskId == null || taskId.isEmpty) return;

    await markAsRead(index);

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/tasks'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final tasks = List<Map<String, dynamic>>.from(
          data['tasks'] ?? [],
        );

        final task = tasks.firstWhere(
              (task) => task['_id'].toString() == taskId,
          orElse: () => {},
        );

        if (task.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy công việc'),
            ),
          );
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              token: widget.token,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải công việc'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Open task error: $e');
    }
  }


  Future<void> markAllAsRead() async {
    try {
      final success =
      await NotificationService.markAllAsRead();

      if (success && mounted) {
        setState(() {
          for (final item in notifications) {
            item['isRead'] = true;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật thông báo'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF25255A),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: notifications.isEmpty
                ? null
                : markAllAsRead,
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : notifications.isEmpty
          ? const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có thông báo nào',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: loadNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final item = notifications[index];
            final isRead = item['isRead'] == true;

            return Card(
              color: isRead
                  ? Colors.white
                  : const Color(0xFFEEF0FF),
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.all(14),
                leading: CircleAvatar(
                  backgroundColor:
                  const Color(0xFF4F46E5)
                      .withOpacity(0.12),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                title: Text(
                  item['title'] ?? 'Thông báo',
                  style: TextStyle(
                    fontWeight: isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding:
                  const EdgeInsets.only(top: 6),
                  child: Text(
                    item['message'] ?? '',
                  ),
                ),
                trailing: isRead
                    ? const Icon(
                  Icons.check,
                  color: Colors.grey,
                )

                    : const Icon(
                  Icons.circle,
                  size: 10,
                  color: Color(0xFF4F46E5),
                ),
                onTap: () => openRelatedTask(index),
              ),
            );
          },
        ),
      ),
    );
  }
}