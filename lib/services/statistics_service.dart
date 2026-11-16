import 'dart:convert';
import 'package:http/http.dart' as http;

class StatisticsService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/statistics';

  // Lấy thống kê công việc
  static Future<Map<String, dynamic>> getStatistics(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['statistics']);
    }

    throw Exception(
      data['message'] ?? 'Không thể tải thống kê công việc',
    );
  }

  // Lấy danh sách công việc sắp đến hạn và quá hạn
  static Future<Map<String, dynamic>> getDeadlineTasks(
      String token,
      ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/deadlines'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'overdueTasks': data['overdueTasks'] ?? [],
        'upcomingTasks': data['upcomingTasks'] ?? [],
      };
    }

    throw Exception(
      data['message'] ?? 'Không thể tải danh sách công việc theo hạn',
    );
  }
}