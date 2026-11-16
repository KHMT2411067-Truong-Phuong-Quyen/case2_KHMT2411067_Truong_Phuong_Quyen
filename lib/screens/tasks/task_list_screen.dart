import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'task_detail_screen.dart';
import '../ notifications/notification_screen.dart';
import '../../services/notification_service.dart';
import '../../services/statistics_service.dart';



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
  int unreadCount = 0;


  Map<String, dynamic>? statistics;
  Map<String, dynamic>? deadlineTasks;

  bool isLoadingStatistics = false;
  String? statisticsError;
  bool isStatisticsExpanded = false;


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

      final primary = task['primaryAssigneeId'];
      final primaryId = primary is Map
          ? primary['_id']?.toString()
          : primary?.toString();

      final isPrimaryAssignee = primaryId == widget.userId;

      final sharedUsers = task['sharedWith'] as List? ?? [];

      final isSharedUser = sharedUsers.any((item) {
        final user = item['userId'];
        final userId = user is Map
            ? user['_id']?.toString()
            : user?.toString();

        return userId == widget.userId;
      });

      switch (selectedTaskType) {
        case 'created':
          return isCreator;
        case 'primary':
          return isPrimaryAssignee;
        case 'shared':
          return isSharedUser;
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách công việc'),
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


  Future<void> loadStatistics() async {
    setState(() {
      isLoadingStatistics = true;
      statisticsError = null;
    });

    try {
      final results = await Future.wait([
        StatisticsService.getStatistics(widget.token),
        StatisticsService.getDeadlineTasks(widget.token),
      ]);

      if (!mounted) return;

      setState(() {
        statistics = results[0] as Map<String, dynamic>;
        deadlineTasks = results[1] as Map<String, dynamic>;
        isLoadingStatistics = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        statisticsError = e.toString();
        isLoadingStatistics = false;
      });
    }
  }


  Future<void> loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        unreadCount = count;
      });
    } catch (e) {
      debugPrint('Lỗi tải số thông báo: $e');
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
    loadUnreadCount();
    loadStatistics();
  }


Widget _buildStatisticsContent() {
  if (isLoadingStatistics) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  if (statisticsError != null) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            statisticsError!,
            style: const TextStyle(color: Colors.red),
          ),
          TextButton(
            onPressed: loadStatistics,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  if (statistics == null) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Chưa có dữ liệu thống kê'),
    );
  }

  final byStatus =
      statistics!['byStatus'] as Map<String, dynamic>? ?? {};

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                'Đã tạo',
                statistics!['totalCreated'],
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatisticItem(
                'Được giao',
                statistics!['totalAssigned'],
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildStatisticItem(
                'Được chia sẻ',
                statistics!['totalShared'],
                Colors.purple,
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                'Chưa làm',
                byStatus['todo'],
                Colors.grey,
              ),
            ),
            Expanded(
              child: _buildStatisticItem(
                'Đang làm',
                byStatus['inProgress'],
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildStatisticItem(
                'Hoàn thành',
                byStatus['completed'],
                Colors.green,
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                'Quá hạn',
                statistics!['overdue'],
                Colors.red,
              ),
            ),
            Expanded(
              child: _buildStatisticItem(
                'Sắp đến hạn',
                statistics!['upcoming'],
                Colors.deepOrange,
              ),
            ),
          ],
        ),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: loadStatistics,
            icon: const Icon(Icons.refresh), label: const Text('Làm mới'),
          ),
        ),


        const SizedBox(height: 12),

        _buildDeadlineSection(
          'Công việc quá hạn',
          deadlineTasks?['overdueTasks'] ?? [],
          Colors.red,
        ),

        const SizedBox(height: 12),

        _buildDeadlineSection(
          'Công việc sắp đến hạn',
          deadlineTasks?['upcomingTasks'] ?? [],
          Colors.deepOrange,
        ),
      ],
    ),
  );
}


  String formatDeadline(dynamic value) {
    if (value == null) return 'Chưa thiết lập';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Không xác định';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }


  Widget _buildDeadlineSection(
      String title,
      List<dynamic> taskList,
      Color color,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: color),
            const SizedBox(width: 8),
            Text(
              '$title (${taskList.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (taskList.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Không có công việc'),
          )
        else
          ...taskList.map((task) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.task_alt, color: color),
              title: Text(task['title'] ?? 'Không có tiêu đề'),
              subtitle: Text(
                'Hạn hoàn thành: ${formatDeadline(task['dueDate'])}',
              ),
            );
          }),
      ],
    );
  }


  Widget _buildStatisticItem(
      String label,
      dynamic value,
      Color color,
      ) {
    return Column(
      children: [
        Text(
          '${value ?? 0}',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }


  void openTaskActivities() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskActivitiesScreen(
          token: widget.token,
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),




        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(
                      token: widget.token,
                  ),
                ),
              );

              loadUnreadCount();
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 28),

                if (unreadCount > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),


          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử hoạt động',
            onPressed: openTaskActivities,
          ),



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
                    token: widget.token,
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
                  value: 'created',
                  child: Text('Công việc do tôi tạo'),
                ),
                DropdownMenuItem(
                  value: 'primary',
                  child: Text('Công việc tôi phụ trách chính'),
                ),
                DropdownMenuItem(
                  value: 'shared',
                  child: Text('Công việc được chia sẻ với tôi'),
                ),
                DropdownMenuItem(
                  value: 'received',
                  child: Text('Tất cả công việc được giao cho tôi'),
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


class TaskActivitiesScreen extends StatefulWidget {
  final String token;

  const TaskActivitiesScreen({
    super.key,
    required this.token,
  });

  @override
  State<TaskActivitiesScreen> createState() =>
      _TaskActivitiesScreenState();
}

class _TaskActivitiesScreenState
    extends State<TaskActivitiesScreen> {
  List<dynamic> activities = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }


  Future<void> loadActivities() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/statistics/activities'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          activities = data['activities'] ?? [];
        });
      } else {
        setState(() {
          error = 'Không thể tải lịch sử hoạt động';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Không thể kết nối đến máy chủ';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            TextButton(
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
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];

            final user = activity['userId'];
            final userName = user is Map
                ? user['fullName'] ?? 'Người dùng'
                : 'Người dùng';

            final date = DateTime.tryParse(
              activity['createdAt']?.toString() ?? '',
            )?.toLocal();

            final formattedDate = date == null
                ? ''
                : '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/'
                '${date.year} '
                '${date.hour.toString().padLeft(2, '0')}:'
                '${date.minute.toString().padLeft(2, '0')}';

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(
                    Icons.history,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                title: Text(
                  activity['description'] ?? '',
                ),
                subtitle: Text(
                  '$userName • $formattedDate',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}