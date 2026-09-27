typedef DefaultCategory = ({
  String id,
  String name,
  String icon,
  String color,
  String type,
});

abstract final class DefaultCategories {
  static const all = <DefaultCategory>[
    (
      id: 'expense-food',
      name: 'Ăn uống',
      icon: 'restaurant',
      color: '#FF796B',
      type: 'expense',
    ),
    (
      id: 'expense-shopping',
      name: 'Mua sắm',
      icon: 'shopping_bag',
      color: '#8B7CFF',
      type: 'expense',
    ),
    (
      id: 'expense-transport',
      name: 'Di chuyển',
      icon: 'directions_car',
      color: '#F5B84B',
      type: 'expense',
    ),
    (
      id: 'expense-entertainment',
      name: 'Giải trí',
      icon: 'movie',
      color: '#659BE8',
      type: 'expense',
    ),
    (
      id: 'expense-bills',
      name: 'Hóa đơn',
      icon: 'receipt_long',
      color: '#48BFA6',
      type: 'expense',
    ),
    (
      id: 'expense-health',
      name: 'Sức khỏe',
      icon: 'medical_services',
      color: '#F28BAC',
      type: 'expense',
    ),
    (
      id: 'expense-education',
      name: 'Giáo dục',
      icon: 'school',
      color: '#6EAADE',
      type: 'expense',
    ),
    (
      id: 'expense-other',
      name: 'Khác',
      icon: 'more_horiz',
      color: '#84939A',
      type: 'expense',
    ),
    (
      id: 'income-salary',
      name: 'Lương',
      icon: 'payments',
      color: '#18B892',
      type: 'income',
    ),
    (
      id: 'income-bonus',
      name: 'Thưởng',
      icon: 'redeem',
      color: '#E6AE49',
      type: 'income',
    ),
    (
      id: 'income-investment',
      name: 'Đầu tư',
      icon: 'trending_up',
      color: '#5FA8D3',
      type: 'income',
    ),
    (
      id: 'income-business',
      name: 'Kinh doanh',
      icon: 'storefront',
      color: '#8C9AE8',
      type: 'income',
    ),
    (
      id: 'income-other',
      name: 'Khác',
      icon: 'more_horiz',
      color: '#84939A',
      type: 'income',
    ),
  ];
}
