import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../app/theme_controller.dart';
import '../auth/auth_error_mapper.dart';
import '../auth/auth_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/finance_card.dart';
import '../widgets/state_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _signingOut = false;
  late final AuthService _authService = widget.authService ?? AuthService();

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.start, (_) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AuthErrorMapper.message(error))));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _goToTab(BuildContext context, int index) {
    final routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings,
    ];
    if (index != 3) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final themeController = ThemeControllerScope.of(context);
    final fullName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Tài khoản';
    final initials = fullName.length >= 2
        ? fullName.substring(0, 2).toUpperCase()
        : fullName.toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          FinanceCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Text(
                    initials,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Tuỳ chỉnh', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',
            subtitle: 'Áp dụng cho toàn ứng dụng',
            trailing: Switch(
              value: themeController.isDark,
              onChanged: themeController.setDark,
            ),
          ),
          _SettingTile(
            icon: Icons.category_outlined,
            title: 'Danh mục',
            subtitle: 'Quản lý nhóm thu chi',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, AppRoutes.categories),
          ),
          _SettingTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Tài khoản & ví',
            subtitle: 'Tiền mặt, ngân hàng',
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 24),
          Text(
            'Trạng thái giao diện',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          FinanceCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _showState(context, StatePanelType.loading),
                  child: const Text('Đang tải'),
                ),
                OutlinedButton(
                  onPressed: () => _showState(context, StatePanelType.empty),
                  child: const Text('Trống'),
                ),
                OutlinedButton(
                  onPressed: () => _showState(context, StatePanelType.error),
                  child: const Text('Lỗi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: _signingOut ? null : _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onSelected: (index) => _goToTab(context, index),
      ),
    );
  }

  void _showState(BuildContext context, StatePanelType type) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
        child: StatePanel(type: type, onAction: () => Navigator.pop(context)),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
