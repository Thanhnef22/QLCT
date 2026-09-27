import 'package:flutter/material.dart';

Color financeColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return value == null ? const Color(0xFF84939A) : Color(0xFF000000 | value);
}

IconData financeIcon(String name) => switch (name) {
  'restaurant' => Icons.restaurant_rounded,
  'shopping_bag' => Icons.shopping_bag_rounded,
  'directions_car' => Icons.directions_car_rounded,
  'movie' => Icons.movie_rounded,
  'receipt_long' => Icons.receipt_long_rounded,
  'medical_services' => Icons.medical_services_rounded,
  'school' => Icons.school_rounded,
  'payments' => Icons.payments_rounded,
  'redeem' => Icons.redeem_rounded,
  'trending_up' => Icons.trending_up_rounded,
  'storefront' => Icons.storefront_rounded,
  'local_cafe' => Icons.local_cafe_rounded,
  'more_horiz' => Icons.more_horiz_rounded,
  _ => Icons.category_rounded,
};
