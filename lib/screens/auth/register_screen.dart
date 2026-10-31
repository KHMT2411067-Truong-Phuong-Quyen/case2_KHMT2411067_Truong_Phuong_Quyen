import 'package:flutter/material.dart';

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
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Giao diện đăng ký đã hoạt động. '
                  'Chức năng sẽ được kết nối với API sau.',
            ),
          ),
        );
      },
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