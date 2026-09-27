import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../finance/finance_format.dart';
import '../finance/finance_models.dart';
import '../finance/finance_repository.dart';
import '../finance/finance_visuals.dart';
import '../widgets/state_panel.dart';

class AddTransactionScreen extends StatefulWidget {
  // TODO: Add receipt picking and Firebase Storage upload when image_picker
  // is introduced; this screen has no existing receipt control or package.
  const AddTransactionScreen({this.transactionId, this.repository, super.key});

  final String? transactionId;
  final FinanceRepository? repository;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late final FinanceRepository _repository =
      widget.repository ?? FinanceRepository();
  late Stream<List<FinanceCategory>> _categories = _repository
      .watchCategories();
  Stream<FinanceTransaction?>? _transaction;
  String _type = 'expense';
  String? _categoryId;
  DateTime? _date;
  bool _loaded = false;
  bool _busy = false;
  bool _dateError = false;

  void _retryCategories() => setState(() {
    _categories = _repository.watchCategories();
  });

  void _retryTransaction() => setState(() {
    _transaction = _repository.watchTransaction(widget.transactionId!);
  });

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _transaction = _repository.watchTransaction(widget.transactionId!);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _fill(FinanceTransaction item) {
    if (_loaded) return;
    _loaded = true;
    _amount.text = item.amount.toString();
    _note.text = item.note;
    _type = item.type;
    _categoryId = item.categoryId;
    _date = item.date;
  }

  Future<void> _chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() {
        _date = date;
        _dateError = false;
      });
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    final valid = _formKey.currentState!.validate();
    setState(() => _dateError = _date == null);
    if (!valid || _date == null || _categoryId == null) return;
    setState(() => _busy = true);
    try {
      await _repository.saveTransaction(
        id: widget.transactionId,
        amount: parseVnd(_amount.text)!,
        categoryId: _categoryId!,
        date: _date!,
        note: _note.text,
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
  Widget build(BuildContext context) {
    if (_transaction == null) return _buildScaffold();
    return StreamBuilder<FinanceTransaction?>(
      stream: _transaction,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: StatePanel(
                type: StatePanelType.error,
                onAction: _retryTransaction,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final item = snapshot.data;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sửa giao dịch')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Giao dịch không còn tồn tại.'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            ),
          );
        }
        _fill(item);
        return _buildScaffold();
      },
    );
  }

  Widget _buildScaffold() => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.transactionId == null ? 'Thêm giao dịch' : 'Sửa giao dịch',
      ),
    ),
    body: StreamBuilder<List<FinanceCategory>>(
      stream: _categories,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: StatePanel(
              type: StatePanelType.error,
              onAction: _retryCategories,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshot.data!
            .where((item) => item.type == _type)
            .toList();
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Chi tiêu'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text('Thu nhập'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _type = value.first;
                        _categoryId = null;
                      }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền.';
                  }
                  if (parseVnd(value) == null) return 'Số tiền phải lớn hơn 0.';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: '₫',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: categories.any((item) => item.id == _categoryId)
                    ? _categoryId
                    : null,
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Row(
                          children: [
                            Icon(
                              financeIcon(item.icon),
                              color: financeColor(item.color),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(item.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _categoryId = value),
                validator: (value) =>
                    value == null ? 'Vui lòng chọn danh mục.' : null,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              if (categories.isEmpty) ...[
                const SizedBox(height: 8),
                const Text('Chưa có danh mục cho loại giao dịch này.'),
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: _busy ? null : _chooseDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày giao dịch',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    errorText: _dateError
                        ? 'Vui lòng chọn ngày giao dịch.'
                        : null,
                  ),
                  child: Text(_date == null ? 'Chọn ngày' : formatDate(_date!)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Thêm ghi chú nếu cần',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Đang lưu...' : 'Lưu giao dịch'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
