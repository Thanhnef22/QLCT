import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Bắt đầu hành trình mới',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Chỉ mất một phút để xây dựng thói quen tài chính tốt hơn.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.mutedInk)),
            const SizedBox(height: 28),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nguyễn Minh Anh',
                    prefixIcon: Icon(Icons.person_outline_rounded))),
            const SizedBox(height: 16),
            const TextField(
                decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded))),
            const SizedBox(height: 16),
            const TextField(
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Tối thiểu 8 ký tự',
                    prefixIcon: Icon(Icons.lock_outline_rounded))),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: const Text('Tạo tài khoản')),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Đã có tài khoản? ',
                  style: Theme.of(context).textTheme.bodyMedium),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đăng nhập'))
            ]),
          ]),
        ),
      ),
    );
  }
}
