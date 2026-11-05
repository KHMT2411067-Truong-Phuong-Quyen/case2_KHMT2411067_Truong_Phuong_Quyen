import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
final fullNameController = TextEditingController();
final emailController = TextEditingController();
final passwordController = TextEditingController();
final confirmPasswordController = TextEditingController();

bool hidePassword = true;
bool hideConfirmPassword = true;

@override
void dispose() {
fullNameController.dispose();
emailController.dispose();
passwordController.dispose();
confirmPasswordController.dispose();
super.dispose();
}

Future<void> register() async {
  final fullName = fullNameController.text.trim();
  final email = emailController.text.trim();
  final password = passwordController.text;
  final confirmPassword = confirmPasswordController.text;

  if (fullName.isEmpty || email.isEmpty ||
      password.isEmpty || confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
    );
    return;
  }

  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['message'] ?? 'Đăng ký thất bại'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không thể kết nối đến máy chủ')),
    );
  }
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF5F6FA),
appBar: AppBar(
backgroundColor: const Color(0xFFF5F6FA),
title: const Text('Đăng ký'),
),
body: SafeArea(
child: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.person_add_alt_1,
size: 72,
color: Color(0xFF4F46E5),
),
const SizedBox(height: 20),
const Text(
'Tạo tài khoản',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 26,
fontWeight: FontWeight.bold,
color: Color(0xFF25255A),
),
),
const SizedBox(height: 28),
TextField(
controller: fullNameController,
decoration: InputDecoration(
labelText: 'Họ và tên',
prefixIcon: const Icon(Icons.person_outline),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.white,
),
),
const SizedBox(height: 16),
TextField(
controller: emailController,
keyboardType: TextInputType.emailAddress,
decoration: InputDecoration(
labelText: 'Email',
prefixIcon: const Icon(Icons.email_outlined),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.white,
),
),
const SizedBox(height: 16),
TextField(
controller: passwordController,
obscureText: hidePassword,
decoration: InputDecoration(
labelText: 'Mật khẩu',
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
onPressed: () {
setState(() {
hidePassword = !hidePassword;
});
},
icon: Icon(
hidePassword
? Icons.visibility_outlined
: Icons.visibility_off_outlined,
),
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.white,
),
),
const SizedBox(height: 16),
TextField(
controller: confirmPasswordController,
obscureText: hideConfirmPassword,
decoration: InputDecoration(
labelText: 'Xác nhận mật khẩu',
prefixIcon: const Icon(Icons.lock_outline),
suffixIcon: IconButton(
onPressed: () {
setState(() {
hideConfirmPassword = !hideConfirmPassword;
});
},
icon: Icon(
hideConfirmPassword
? Icons.visibility_outlined
: Icons.visibility_off_outlined,
),
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.white,
),
),
  const SizedBox(height: 24),
  SizedBox(
    height: 52,
    child: ElevatedButton(
      onPressed: register,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'ĐĂNG KÝ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
  const SizedBox(height: 12),
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Đã có tài khoản? Đăng nhập'),
  ),
],
),
),
),
),
);
}
}