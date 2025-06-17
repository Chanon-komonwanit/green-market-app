import 'package:flutter/material.dart';

class MyInvestment {
  final String id;
  final String name;
  final String assetType;
  final double quantity; // or units
  final double currentValue;
  final double totalReturn; // Can be positive or negative
  final double returnPercentage;
  final IconData icon;

  MyInvestment({
    required this.id,
    required this.name,
    required this.assetType,
    required this.quantity,
    required this.currentValue,
    required this.totalReturn,
    required this.returnPercentage,
    required this.icon,
  });
}
