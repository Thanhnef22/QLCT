import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AuthMark(),
              const SizedBox(height: 36),
              Text('Chào mừng trở lại',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Đăng nhập để tiếp tục quản lý tài chính của bạn.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.mutedInk)),
              const SizedBox(height: 32),
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
                      hintText: '••••••••',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      suffixIcon: Icon(Icons.visibility_outlined))),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () {}, child: const Text('Quên mật khẩu?')),
              ),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.home),
                  child: const Text('Đăng nhập')),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('hoặc',
                        style: Theme.of(context).textTheme.bodySmall)),
                const Expanded(child: Divider())
              ]),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.home),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Tiếp tục với Google')),
              const SizedBox(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Chưa có tài khoản? ',
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Đăng ký'))
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthMark extends StatelessWidget {
  const _AuthMark();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: AppColors.mint.withAlpha(45),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ]),
        child: const Icon(Icons.account_balance_wallet_rounded,
            color: Colors.white, size: 26),
      ),
    );
  }
}
