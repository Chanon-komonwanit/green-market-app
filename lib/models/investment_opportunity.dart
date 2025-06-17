import 'package:flutter/material.dart';

class InvestmentOpportunity {
  final String id;
  final String name;
  final String description;
  final String type; // e.g., Stocks, Bonds, Funds, Real Estate
  final String expectedReturn;
  final String riskLevel; // e.g., Low, Medium, High
  final IconData icon;

  InvestmentOpportunity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.expectedReturn,
    required this.riskLevel,
    required this.icon,
  });
}
