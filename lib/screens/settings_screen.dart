import 'package:flutter/material.dart';
import '../app/app_routes.dart';
import '../app/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/finance_card.dart';
import '../widgets/state_panel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;

  void _goToTab(BuildContext context, int index) {
    final routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings
    ];
    if (index != 3) Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final child = Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            FinanceCard(
                child: Row(children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.mintSoft,
                  child: Text('MA',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.mintDark))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Minh Anh',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('minhanh@example.com',
                        style: Theme.of(context).textTheme.bodySmall)
                  ])),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.edit_outlined))
            ])),
            const SizedBox(height: 24),
            Text('Tuỳ chỉnh', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _SettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Chế độ tối',
                subtitle: 'Thử giao diện nền tối',
                trailing: Switch(
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value))),
            _SettingTile(
                icon: Icons.category_outlined,
                title: 'Danh mục',
                subtitle: 'Quản lý nhóm thu chi',
                trailing: const Icon(Icons.chevron_right_rounded)),
            _SettingTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Tài khoản & ví',
                subtitle: 'Tiền mặt, ngân hàng',
                trailing: const Icon(Icons.chevron_right_rounded)),
            const SizedBox(height: 24),
            Text('Trạng thái giao diện',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            FinanceCard(
                child: Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                  onPressed: () => _showState(context, StatePanelType.loading),
                  child: const Text('Loading')),
              OutlinedButton(
                  onPressed: () => _showState(context, StatePanelType.empty),
                  child: const Text('Empty')),
              OutlinedButton(
                  onPressed: () => _showState(context, StatePanelType.error),
                  child: const Text('Error'))
            ])),
            const SizedBox(height: 24),
            Center(
                child: TextButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, AppRoutes.onboarding),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Đăng xuất'))),
          ]),
      bottomNavigationBar: AppBottomNav(
          currentIndex: 3, onSelected: (index) => _goToTab(context, index)),
    );

    return _darkMode ? Theme(data: AppTheme.dark, child: child) : child;
  }

  void _showState(BuildContext context, StatePanelType type) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
            child: StatePanel(
                type: type, onAction: () => Navigator.pop(context))));
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.mintSoft,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.mintDark)),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: trailing);
  }
}
