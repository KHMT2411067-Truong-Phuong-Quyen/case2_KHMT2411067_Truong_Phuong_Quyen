import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_detail_screen.dart';



class TaskListScreen extends StatefulWidget {
  final String userId;
  final String fullName;
  final String email;
  final String token;

  const TaskListScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.token,
  });


  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String? selectedStatus;
  String? selectedPriority;
  String sortBy = 'createdAt';
  String selectedTaskType = 'all';


  List<Map<String, dynamic>> users = [];
  String? selectedAssigneeId;
  bool isLoadingUsers = false;


  List<Map<String, dynamic>> get filteredTasks {
    final roleFilteredTasks = tasks.where((task) {
      final createdBy = task['createdBy'];
      final createdById = createdBy is Map
          ? createdBy['_id']?.toString()
          : createdBy?.toString();

      final assignees = task['assigneeIds'] as List? ?? [];

      final isCreator = createdById == widget.userId;

      final isAssignee = assignees.any((assignee) {
        final assigneeId = assignee is Map
            ? assignee['_id']?.toString()
            : assignee.toString();

        return assigneeId == widget.userId;
      });

      switch (selectedTaskType) {
        case 'received':
          return isAssignee && !isCreator;
        case 'assigned':
          return isCreator && assignees.isNotEmpty;
        default:
          return true;
      }
    }).toList();



    final result = roleFilteredTasks.where((task) {
      final title = (task['title'] ?? '').toString().toLowerCase();

      final matchSearch =
      title.contains(searchText.toLowerCase());

      final matchStatus = selectedStatus == null ||
          task['status'] == selectedStatus;

      final matchPriority = selectedPriority == null ||
          task['priority'] == selectedPriority;


      final assigneeIds = (task['assigneeIds'] as List? ?? [])
          .map((assignee) {
        if (assignee is Map) {
          return assignee['_id'].toString();
        }
        return assignee.toString();
      }).toList();

      final matchAssignee = selectedAssigneeId == null ||
          assigneeIds.contains(selectedAssigneeId);


      return matchSearch &&
          matchStatus &&
          matchPriority &&
          matchAssignee;
    }).toList();

    result.sort((a, b) {
      switch (sortBy) {
        case 'dueDate':
          final dateA = DateTime.tryParse(
            a['dueDate']?.toString() ?? '',
          );
          final dateB = DateTime.tryParse(
            b['dueDate']?.toString() ?? '',
          );

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateA.compareTo(dateB);

        case 'priority':
          const priorityOrder = {
            'high': 1,
            'medium': 2,
            'low': 3,
          };

          return (priorityOrder[a['priority']] ?? 4)
              .compareTo(priorityOrder[b['priority']] ?? 4);

        default:
          final dateA = DateTime.tryParse(
            a['createdAt']?.toString() ?? '',
          );
          final dateB = DateTime.tryParse(
            b['createdAt']?.toString() ?? '',
          );

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
      }
    });

    return result;
  }


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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

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


  Future<void> loadTasks() async {
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

        setState(() {
          tasks.clear();
          tasks.addAll(
            List<Map<String, dynamic>>.from(data['tasks']),
          );
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải công việc: $e');
    }
  }

  Future<void> openCreateTask() async {
    final newTask = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCreateScreen(
          token: widget.token,
        ),
      ),
    );

    if (newTask != null) {
      loadTasks();
    }
  }


  @override
  void initState() {
    super.initState();
    loadTasks();
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: widget.userId,
                    fullName: widget.fullName,
                    email: widget.email,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedTaskType,
              decoration: const InputDecoration(
                labelText: 'Loại công việc',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Tất cả công việc'),
                ),
                DropdownMenuItem(
                  value: 'received',
                  child: Text('Công việc được giao cho tôi'),
                ),
                DropdownMenuItem(
                  value: 'assigned',
                  child: Text('Công việc tôi đã giao'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedTaskType = value;
                  });
                }
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm công việc...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả')),
                      DropdownMenuItem(value: 'todo', child: Text('Chưa thực hiện')),
                      DropdownMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
                      DropdownMenuItem(value: 'completed', child: Text('Đã hoàn thành')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedStatus = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Ưu tiên',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tất cả')),
                      DropdownMenuItem(value: 'low', child: Text('Thấp')),
                      DropdownMenuItem(value: 'medium', child: Text('Trung bình')),
                      DropdownMenuItem(value: 'high', child: Text('Cao')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedPriority = value);
                    },
                  ),
                ),
              ],
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: sortBy,
              decoration: const InputDecoration(
                labelText: 'Sắp xếp theo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'createdAt',
                  child: Text('Thời gian tạo mới nhất'),
                ),
                DropdownMenuItem(
                  value: 'dueDate',
                  child: Text('Hạn hoàn thành gần nhất'),
                ),
                DropdownMenuItem(
                  value: 'priority',
                  child: Text('Mức độ ưu tiên cao nhất'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sortBy = value;
                  });
                }
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedAssigneeId,
              decoration: const InputDecoration(
                labelText: 'Người được giao',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tất cả'),
                ),
                ...users.map((user) {
                  return DropdownMenuItem<String>(
                    value: user['_id'].toString(),
                    child: Text(user['fullName'] ?? ''),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedAssigneeId = value;
                });
              },
            ),
          ),


          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
              child: Text('Không tìm thấy công việc nào'),
            )
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.task_alt),
                    title: Text(task['title'] ?? ''),
                    subtitle: Text(
                      '${task['status']} • Ưu tiên: ${task['priority']}',
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(
                            task: task,
                            token: widget.token,
                          ),
                        ),
                      );

                      if (result == true) {
                        loadTasks();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openCreateTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}