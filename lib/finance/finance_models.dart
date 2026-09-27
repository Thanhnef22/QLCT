import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final String type;

  factory FinanceCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FinanceCategory(
      id: doc.id,
      name: data['name'] as String,
      icon: data['icon'] as String? ?? 'category',
      color: data['color'] as String? ?? '#84939A',
      type: data['type'] as String,
    );
  }
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.type,
    required this.note,
    required this.date,
    this.receiptImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int amount;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String type;
  final String note;
  final DateTime date;
  final String? receiptImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FinanceTransaction.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FinanceTransaction(
      id: doc.id,
      amount: (data['amount'] as num).toInt(),
      categoryId: data['categoryId'] as String,
      categoryName: data['categoryName'] as String,
      categoryIcon: data['categoryIcon'] as String? ?? 'category',
      categoryColor: data['categoryColor'] as String? ?? '#84939A',
      type: data['type'] as String,
      note: data['note'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate().toLocal(),
      receiptImageUrl: data['receiptImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate().toLocal(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate().toLocal(),
    );
  }
}

class FinanceBudget {
  const FinanceBudget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.month,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final int limitAmount;
  final String month;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FinanceBudget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FinanceBudget(
      id: doc.id,
      categoryId: data['categoryId'] as String,
      categoryName: data['categoryName'] as String,
      limitAmount: (data['limitAmount'] as num).toInt(),
      month: data['month'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate().toLocal(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate().toLocal(),
    );
  }
}
