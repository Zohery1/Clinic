// نموذج التقرير المالي (اليومي أو الشهري) القادم من الـ SQL View
class FinancialReportModel {
  final String clinicId;
  final DateTime reportDate;
  final DateTime reportMonth;
  final double totalRevenue;

  FinancialReportModel({
    required this.clinicId,
    required this.reportDate,
    required this.reportMonth,
    required this.totalRevenue,
  });

  factory FinancialReportModel.fromJson(Map<String, dynamic> json) {
    return FinancialReportModel(
      clinicId: json['clinic_id'] as String,
      reportDate: DateTime.parse(json['report_date'] as String),
      reportMonth: DateTime.parse(json['report_month'] as String),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
    );
  }
}
