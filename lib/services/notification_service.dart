import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/notifications';

  // Lấy token đăng nhập
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Lấy danh sách thông báo
  static Future<List<dynamic>> getNotifications() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    }

    throw Exception('Không thể tải thông báo');
  }

  // Đếm thông báo chưa đọc
  static Future<int> getUnreadCount() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/unread-count'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unreadCount'] ?? 0;
    }

    throw Exception('Không thể đếm thông báo');
  }

  // Đánh dấu một thông báo đã đọc
  static Future<bool> markAsRead(String id) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$id/read'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // Đánh dấu tất cả thông báo đã đọc
  static Future<bool> markAllAsRead() async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}