// lib/models/investment_summary.dart

class InvestmentSummary {
  final int totalProjects;
  final int activeProjects;
  final double totalAmountRaised;
  final int upcomingActivities;

  InvestmentSummary({
    required this.totalProjects,
    required this.activeProjects,
    required this.totalAmountRaised,
    required this.upcomingActivities,
  });

  factory InvestmentSummary.fromMap(Map<String, dynamic> map) {
    return InvestmentSummary(
      totalProjects: map['totalProjects'] as int? ?? 0,
      activeProjects: map['activeProjects'] as int? ?? 0,
      totalAmountRaised: (map['totalAmountRaised'] as num?)?.toDouble() ?? 0.0,
      upcomingActivities: map['upcomingActivities'] as int? ?? 0,
    );
  }
}
