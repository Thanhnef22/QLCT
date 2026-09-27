import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../finance/finance_models.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_visuals.dart';
import '../widgets/state_panel.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({this.repository, super.key});
  final FinanceRepository? repository;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final FinanceRepository _repository =
      widget.repository ?? FinanceRepository();
  late Stream<List<FinanceCategory>> _categories = _repository
      .watchCategories();
  String _type = 'expense';

  void _retry() => setState(() {
    _categories = _repository.watchCategories();
  });

  Future<void> _showForm([FinanceCategory? category]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryDialog(
        repository: _repository,
        category: category,
        type: _type,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu danh mục.')));
    }
  }

  Future<void> _delete(FinanceCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa danh mục?'),
        content: Text(
          'Xóa “${category.name}”? Danh mục đang dùng trong giao dịch hoặc ngân sách sẽ không thể xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã xóa danh mục.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(financeErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Danh mục')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Chi tiêu')),
                ButtonSegment(value: 'income', label: Text('Thu nhập')),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FinanceCategory>>(
            stream: _categories,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: StatePanel(
                    type: StatePanelType.error,
                    onAction: _retry,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data!
                  .where((item) => item.type == _type)
                  .toList();
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 52,
                        color: AppColors.mutedInk,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có danh mục',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Thêm danh mục để phân loại giao dịch.'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _showForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm danh mục'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final color = financeColor(item.color);
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: color.withAlpha(28),
                        child: Icon(financeIcon(item.icon), color: color),
                      ),
                      title: Text(item.name),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Tùy chọn danh mục',
                        onSelected: (value) =>
                            value == 'edit' ? _showForm(item) : _delete(item),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Chỉnh sửa'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Xóa')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showForm,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Thêm danh mục'),
    ),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.repository,
    required this.category,
    required this.type,
  });
  final FinanceRepository repository;
  final FinanceCategory? category;
  final String type;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  static const _icons = [
    'category',
    'restaurant',
    'shopping_bag',
    'directions_car',
    'movie',
    'medical_services',
    'school',
    'payments',
    'redeem',
    'trending_up',
  ];
  static const _colors = [
    '#84939A',
    '#FF796B',
    '#18B892',
    '#F5B84B',
    '#6584D8',
    '#9D73C5',
  ];
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late String _icon = widget.category?.icon ?? 'category';
  late String _color = widget.category?.color ?? '#84939A';
  late String _type = widget.category?.type ?? widget.type;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.saveCategory(
        id: widget.category?.id,
        name: _name.text,
        type: _type,
        icon: _icon,
        color: _color,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(financeErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
    content: SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 40,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tên danh mục.'
                    : null,
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Chi tiêu')),
                  ButtonSegment(value: 'income', label: Text('Thu nhập')),
                ],
                selected: {_type},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _type = value.first),
              ),
              const SizedBox(height: 10),
              Text('Biểu tượng', style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 4,
                children: _icons
                    .map(
                      (icon) => IconButton.filledTonal(
                        tooltip: icon,
                        style: IconButton.styleFrom(
                          backgroundColor: icon == _icon
                              ? AppColors.mintSoft
                              : null,
                        ),
                        onPressed: () => setState(() => _icon = icon),
                        icon: Icon(financeIcon(icon)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text('Màu sắc', style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 8,
                children: _colors
                    .map(
                      (color) => IconButton(
                        tooltip: color,
                        onPressed: () => setState(() => _color = color),
                        icon: Icon(
                          color == _color ? Icons.check_circle : Icons.circle,
                          color: financeColor(color),
                          size: 30,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Đang lưu...' : 'Lưu'),
      ),
    ],
  );
}
