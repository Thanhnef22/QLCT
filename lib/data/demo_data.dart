import 'package:flutter/material.dart';

class DemoTransaction {
  const DemoTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  final String title;
  final String category;
  final String amount;
  final String date;
  final IconData icon;
  final Color color;
  final bool isIncome;
}

const demoTransactions = <DemoTransaction>[
  DemoTransaction(
    title: 'Ăn uống',
    category: 'Bữa trưa tại văn phòng',
    amount: '- 85.000 ₫',
    date: 'Hôm nay, 12:30',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFFE9DE),
  ),
  DemoTransaction(
    title: 'Mua sắm',
    category: 'Siêu thị WinMart',
    amount: '- 420.000 ₫',
    date: 'Hôm qua, 18:42',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFE9E4FF),
  ),
  DemoTransaction(
    title: 'Lương tháng 9',
    category: 'Thu nhập',
    amount: '+ 18.500.000 ₫',
    date: '01/09/2026',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFE2F8F1),
    isIncome: true,
  ),
  DemoTransaction(
    title: 'Di chuyển',
    category: 'Grab',
    amount: '- 64.000 ₫',
    date: '31/08/2026',
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFFFFF2D6),
  ),
];

const budgetItems = <Map<String, Object>>[
  {
    'name': 'Ăn uống',
    'spent': '1.850.000 ₫',
    'limit': '3.000.000 ₫',
    'progress': 0.62,
    'color': 0xFFFF796B
  },
  {
    'name': 'Mua sắm',
    'spent': '2.400.000 ₫',
    'limit': '4.000.000 ₫',
    'progress': 0.60,
    'color': 0xFF8B7CFF
  },
  {
    'name': 'Di chuyển',
    'spent': '780.000 ₫',
    'limit': '1.500.000 ₫',
    'progress': 0.52,
    'color': 0xFFF5B84B
  },
];
