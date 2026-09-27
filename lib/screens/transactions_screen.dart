import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_routes.dart';
import '../finance/finance_format.dart';
import '../finance/finance_models.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_rules.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/state_panel.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({this.repository, super.key});
  final FinanceRepository? repository;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final FinanceRepository _repository =
      widget.repository ?? FinanceRepository();
  late Stream<List<FinanceTransaction>> _transactions = _repository
      .watchTransactions();
  late final Stream<List<FinanceCategory>> _categories = _repository
      .watchCategories();
  final _search = TextEditingController();
  String? _type;
  String? _categoryId;
  DateTimeRange? _range;
  int? _minAmount;
  int? _maxAmount;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    const routes = [
      AppRoutes.home,
      AppRoutes.transactions,
      AppRoutes.reports,
      AppRoutes.settings,
    ];
    if (index != 1) Navigator.pushReplacementNamed(context, routes[index]);
  }

  void _retry() => setState(() {
    _transactions = _repository.watchTransactions();
  });

  Future<void> _addTransaction() async {
    final saved = await Navigator.pushNamed(
      context,
      AppRoutes.addTransaction,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu giao dịch.')));
    }
  }

  Future<void> _openTransaction(String id) async {
    final deleted = await Navigator.pushNamed(
      context,
      AppRoutes.transactionDetail,
      arguments: id,
    );
    if (deleted == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch.')));
    }
  }

  Future<void> _showFilters() async {
    var categoryId = _categoryId;
    var range = _range;
    final min = TextEditingController(text: _minAmount?.toString() ?? '');
    final max = TextEditingController(text: _maxAmount?.toString() ?? '');
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, update) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Lọc giao dịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                StreamBuilder<List<FinanceCategory>>(
                  stream: _categories,
                  builder: (context, snapshot) =>
                      DropdownButtonFormField<String>(
                        initialValue:
                            snapshot.data?.any(
                                  (item) => item.id == categoryId,
                                ) ==
                                true
                            ? categoryId
                            : '',
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tất cả danh mục'),
                          ),
                          ...?snapshot.data?.map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => update(
                          () => categoryId = value == '' ? null : value,
                        ),
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: sheetContext,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: range,
                    );
                    if (picked != null) update(() => range = picked);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    range == null
                        ? 'Chọn khoảng thời gian'
                        : '${formatDate(range!.start)} – ${formatDate(range!.end)}',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: min,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: 'Từ (₫)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: max,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(labelText: 'Đến (₫)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _categoryId = null;
                            _range = null;
                            _minAmount = null;
                            _maxAmount = null;
                            _type = null;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final low = int.tryParse(min.text);
                          final high = int.tryParse(max.text);
                          if (low != null && high != null && low > high) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Số tiền từ phải nhỏ hơn hoặc bằng số tiền đến.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _categoryId = categoryId;
                            _range = range;
                            _minAmount = low;
                            _maxAmount = high;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      min.dispose();
      max.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Giao dịch')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm giao dịch',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Bộ lọc',
                onPressed: _showFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final choice in [
                (null, 'Tất cả'),
                ('expense', 'Chi tiêu'),
                ('income', 'Thu nhập'),
              ]) ...[
                ChoiceChip(
                  label: Text(choice.$2),
                  selected: _type == choice.$1,
                  onSelected: (_) => setState(() => _type = choice.$1),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<FinanceTransaction>>(
            stream: _transactions,
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
              final items = filterTransactions(
                snapshot.data!,
                TransactionFilter(
                  search: _search.text,
                  type: _type,
                  categoryId: _categoryId,
                  from: _range?.start,
                  to: _range?.end,
                  minAmount: _minAmount,
                  maxAmount: _maxAmount,
                ),
              );
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 52),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.data!.isEmpty
                              ? 'Chưa có giao dịch'
                              : 'Không tìm thấy giao dịch',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.data!.isEmpty
                              ? 'Hãy thêm giao dịch đầu tiên để bắt đầu quản lý chi tiêu.'
                              : 'Thử tìm kiếm hoặc thay đổi bộ lọc.',
                          textAlign: TextAlign.center,
                        ),
                        if (snapshot.data!.isEmpty) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _addTransaction,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm giao dịch'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 90),
                itemCount: items.length,
                itemBuilder: (context, index) => TransactionTile(
                  transaction: items[index],
                  onTap: () => _openTransaction(items[index].id),
                ),
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addTransaction,
      child: const Icon(Icons.add_rounded),
    ),
    bottomNavigationBar: AppBottomNav(currentIndex: 1, onSelected: _goToTab),
  );
}
