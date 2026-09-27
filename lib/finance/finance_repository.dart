import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'finance_models.dart';

class FinanceFailure implements Exception {
  const FinanceFailure(this.message);
  final String message;
}

String financeErrorMessage(Object error) {
  if (error is FinanceFailure) return error.message;
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Bạn không có quyền truy cập dữ liệu này.';
  }
  if (error is FirebaseException && error.code == 'unavailable') {
    return 'Không có kết nối mạng. Vui lòng thử lại.';
  }
  return 'Không thể tải hoặc lưu dữ liệu. Vui lòng thử lại.';
}

class FinanceTransactionSnapshot {
  const FinanceTransactionSnapshot({
    required this.items,
    required this.isFromCache,
  });

  final List<FinanceTransaction> items;
  final bool isFromCache;
}

class FinanceRepository {
  FinanceRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const FinanceFailure('Vui lòng đăng nhập lại.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _firestore.collection('users/$_uid/$name');

  Stream<List<FinanceCategory>> watchCategories() =>
      _collection('categories').snapshots().map((snapshot) {
        final items = snapshot.docs.map(FinanceCategory.fromDoc).toList();
        items.sort((a, b) => a.name.compareTo(b.name));
        return items;
      });

  Stream<List<FinanceTransaction>> watchTransactions() =>
      watchTransactionsWithSource().map((snapshot) => snapshot.items);

  Stream<FinanceTransactionSnapshot> watchTransactionsWithSource() =>
      _collection('transactions')
          .orderBy('date', descending: true)
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
            final items = snapshot.docs
                .map(FinanceTransaction.fromDoc)
                .toList();
            items.sort((a, b) {
              final byDate = b.date.compareTo(a.date);
              if (byDate != 0) return byDate;
              return (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              );
            });
            return FinanceTransactionSnapshot(
              items: items,
              isFromCache: snapshot.metadata.isFromCache,
            );
          });

  Stream<FinanceTransaction?> watchTransaction(String id) =>
      _collection('transactions')
          .doc(id)
          .snapshots()
          .map((doc) => doc.exists ? FinanceTransaction.fromDoc(doc) : null);

  Stream<List<FinanceBudget>> watchBudgets() => _collection('budgets')
      .snapshots()
      .map((snapshot) {
        final items = snapshot.docs.map(FinanceBudget.fromDoc).toList();
        items.sort((a, b) {
          final byMonth = b.month.compareTo(a.month);
          return byMonth != 0
              ? byMonth
              : a.categoryName.compareTo(b.categoryName);
        });
        return items;
      });

  Future<String> saveCategory({
    String? id,
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const FinanceFailure('Vui lòng nhập tên danh mục.');
    }
    if (type != 'expense' && type != 'income') {
      throw const FinanceFailure('Vui lòng chọn loại danh mục.');
    }
    final collection = _collection('categories');
    final ref = id == null ? collection.doc() : collection.doc(id);
    final old = id == null ? null : await ref.get();
    if (id != null && !old!.exists) {
      throw const FinanceFailure('Không tìm thấy danh mục.');
    }
    if (old != null && old.data()?['type'] != type) await _ensureUnused(id!);
    final payload = <String, dynamic>{
      'name': cleanName,
      'type': type,
      'icon': icon ?? old?.data()?['icon'] ?? 'category',
      'color': color ?? old?.data()?['color'] ?? '#84939A',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(payload);
    } else {
      await ref.update(payload);
    }
    return ref.id;
  }

  Future<void> deleteCategory(String id) async {
    await _ensureUnused(id);
    await _collection('categories').doc(id).delete();
  }

  Future<void> _ensureUnused(String categoryId) async {
    final transactions = await _collection('transactions')
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();
    final budgets = await _collection('budgets')
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();
    if (transactions.docs.isNotEmpty || budgets.docs.isNotEmpty) {
      throw const FinanceFailure(
        'Danh mục đang được dùng trong giao dịch hoặc ngân sách.',
      );
    }
  }

  Future<String> saveTransaction({
    String? id,
    required int amount,
    required String categoryId,
    required DateTime date,
    String note = '',
  }) async {
    if (amount <= 0) throw const FinanceFailure('Số tiền phải lớn hơn 0.');
    final categoryDoc = await _collection('categories').doc(categoryId).get();
    if (!categoryDoc.exists) {
      throw const FinanceFailure('Vui lòng chọn danh mục hợp lệ.');
    }
    final category = FinanceCategory.fromDoc(categoryDoc);
    final payload = <String, dynamic>{
      'amount': amount,
      'categoryId': category.id,
      'categoryName': category.name,
      'categoryIcon': category.icon,
      'categoryColor': category.color,
      'type': category.type,
      'note': note.trim(),
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final collection = _collection('transactions');
    final ref = id == null ? collection.doc() : collection.doc(id);
    if (id == null) {
      payload['receiptImageUrl'] = null;
      payload['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(payload);
    } else {
      await ref.update(payload);
    }
    return ref.id;
  }

  Future<void> deleteTransaction(String id) =>
      _collection('transactions').doc(id).delete();

  Future<String> saveBudget({
    String? id,
    required String categoryId,
    required String month,
    required int limitAmount,
  }) async {
    if (limitAmount <= 0) {
      throw const FinanceFailure('Hạn mức phải lớn hơn 0.');
    }
    if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month)) {
      throw const FinanceFailure('Vui lòng chọn tháng hợp lệ.');
    }
    final categoryDoc = await _collection('categories').doc(categoryId).get();
    if (!categoryDoc.exists || categoryDoc.data()?['type'] != 'expense') {
      throw const FinanceFailure('Vui lòng chọn danh mục chi tiêu hợp lệ.');
    }
    final category = FinanceCategory.fromDoc(categoryDoc);
    final budgetId = '$month-$categoryId';
    if (id != null && id != budgetId) {
      throw const FinanceFailure(
        'Không thể đổi tháng hoặc danh mục ngân sách.',
      );
    }
    final ref = _collection('budgets').doc(budgetId);
    final payload = <String, dynamic>{
      'categoryId': categoryId,
      'categoryName': category.name,
      'limitAmount': limitAmount,
      'month': month,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      final created = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        if ((await transaction.get(ref)).exists) {
          return false;
        }
        transaction.set(ref, {
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (!created) {
        throw const FinanceFailure('Danh mục đã có ngân sách trong tháng này.');
      }
    } else {
      await ref.update(payload);
    }
    return budgetId;
  }

  Future<void> deleteBudget(String id) =>
      _collection('budgets').doc(id).delete();
}
