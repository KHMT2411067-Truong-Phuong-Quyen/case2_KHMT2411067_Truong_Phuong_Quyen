import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String userId;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.fullName,
    required this.email,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void editProfile() {
    final nameController = TextEditingController(
      text: widget.fullName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Họ và tên',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();

                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập họ và tên')),
                  );
                  return;
                }

                try {
                  final response = await http.put(
                    Uri.parse('http://10.0.2.2:3000/api/auth/profile'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'userId': widget.userId,
                      'fullName': newName,
                    }),
                  );

                  final data = jsonDecode(response.body);

                  if (response.statusCode == 200) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? 'Cập nhật thành công')),
                    );

                    setState(() {
                      // Cập nhật tên hiển thị ở bước tiếp theo
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? 'Cập nhật thất bại')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể kết nối đến máy chủ')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }


void changePassword() {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword =
                  currentPasswordController.text;
              final newPassword = newPasswordController.text;
              final confirmPassword =
                  confirmPasswordController.text;

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ thông tin'),
                  ),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mật khẩu mới phải có ít nhất 6 ký tự',
                    ),
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mật khẩu xác nhận không khớp'),
                  ),
                );
                return;
              }

              try {
                final response = await http.put(
                  Uri.parse('http://10.0.2.2:3000/api/auth/change-password',
                  ),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'userId': widget.userId,
                    'currentPassword': currentPassword,
                    'newPassword': newPassword,
                  }),
                );

                final data = jsonDecode(response.body);

                if (response.statusCode == 200) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        data['message'] ?? 'Đổi mật khẩu thành công',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        data['message'] ?? 'Đổi mật khẩu thất bại',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể kết nối đến máy chủ'),
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF4F46E5),
              child: Icon(Icons.person, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hồ sơ cá nhân',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Họ và tên'),
              subtitle: Text(widget.fullName),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(widget.email),
            ),

            ElevatedButton.icon(
              onPressed: editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa hồ sơ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: changePassword,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Đổi mật khẩu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}