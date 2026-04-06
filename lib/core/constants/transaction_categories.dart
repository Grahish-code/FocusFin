import 'package:flutter/material.dart';

class TransactionCategory {
  final String label;
  final IconData icon;
  final Color color;

  const TransactionCategory({
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<TransactionCategory> kTransactionCategories = [
  TransactionCategory(label: 'Food',          icon: Icons.restaurant_rounded,       color: Color(0xFFFF6B6B)),
  TransactionCategory(label: 'Travel',        icon: Icons.flight_rounded,            color: Color(0xFF4ECDC4)),
  TransactionCategory(label: 'Petrol',        icon: Icons.local_gas_station_rounded, color: Color(0xFFFF922B)),
  TransactionCategory(label: 'Shopping',      icon: Icons.shopping_bag_rounded,      color: Color(0xFFFFBE0B)),
  TransactionCategory(label: 'Education',     icon: Icons.school_rounded,            color: Color(0xFF74C0FC)),
  TransactionCategory(label: 'Entertainment', icon: Icons.movie_rounded,             color: Color(0xFFCC5DE8)),
  TransactionCategory(label: 'Bills',         icon: Icons.receipt_long_rounded,      color: Color(0xFF845EF7)),
  TransactionCategory(label: 'Individual',    icon: Icons.person_rounded,            color: Color(0xFF69DB7C)),
  TransactionCategory(label: 'Events',        icon: Icons.celebration_rounded,       color: Color(0xFFF783AC)),
  TransactionCategory(label: 'Groceries',     icon: Icons.local_grocery_store_rounded, color: Color(0xFF63E6BE)),
  TransactionCategory(label: 'Others',        icon: Icons.more_horiz_rounded,        color: Color(0xFFADB5BD)),
];