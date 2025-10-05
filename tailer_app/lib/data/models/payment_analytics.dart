/// Payment analytics model for aggregating payment data and generating reports
class PaymentAnalytics {
  final DateTime periodStart;
  final DateTime periodEnd;
  final AnalyticsPeriod period;
  final double totalRevenue;
  final double totalRefunds;
  final double netRevenue;
  final int totalTransactions;
  final int totalRefundTransactions;
  final Map<String, double> revenueByPaymentMethod;
  final Map<String, int> transactionsByPaymentMethod;
  final Map<String, double> revenueByDay;
  final double averageTransactionValue;
  final double outstandingAmount;
  final List<TopCustomer> topCustomers;
  final PaymentTrends trends;

  const PaymentAnalytics({
    required this.periodStart,
    required this.periodEnd,
    required this.period,
    required this.totalRevenue,
    required this.totalRefunds,
    required this.netRevenue,
    required this.totalTransactions,
    required this.totalRefundTransactions,
    required this.revenueByPaymentMethod,
    required this.transactionsByPaymentMethod,
    required this.revenueByDay,
    required this.averageTransactionValue,
    required this.outstandingAmount,
    required this.topCustomers,
    required this.trends,
  });

  /// Create empty analytics
  factory PaymentAnalytics.empty({
    required DateTime periodStart,
    required DateTime periodEnd,
    required AnalyticsPeriod period,
  }) {
    return PaymentAnalytics(
      periodStart: periodStart,
      periodEnd: periodEnd,
      period: period,
      totalRevenue: 0.0,
      totalRefunds: 0.0,
      netRevenue: 0.0,
      totalTransactions: 0,
      totalRefundTransactions: 0,
      revenueByPaymentMethod: {},
      transactionsByPaymentMethod: {},
      revenueByDay: {},
      averageTransactionValue: 0.0,
      outstandingAmount: 0.0,
      topCustomers: [],
      trends: PaymentTrends.neutral(),
    );
  }

  /// Calculate growth percentage compared to previous period
  double calculateGrowthPercentage(double previousValue, double currentValue) {
    if (previousValue == 0) return currentValue > 0 ? 100.0 : 0.0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  /// Get formatted total revenue
  String get formattedTotalRevenue => '₹${totalRevenue.toStringAsFixed(2)}';

  /// Get formatted net revenue
  String get formattedNetRevenue => '₹${netRevenue.toStringAsFixed(2)}';

  /// Get formatted average transaction value
  String get formattedAverageTransactionValue => '₹${averageTransactionValue.toStringAsFixed(2)}';

  /// Get formatted outstanding amount
  String get formattedOutstandingAmount => '₹${outstandingAmount.toStringAsFixed(2)}';

  /// Get refund percentage
  double get refundPercentage {
    if (totalRevenue == 0) return 0.0;
    return (totalRefunds / totalRevenue) * 100;
  }

  /// Get period display text
  String get periodDisplayText => period.displayName;

  /// Check if analytics has data
  bool get hasData => totalTransactions > 0;

  @override
  String toString() {
    return 'PaymentAnalytics(period: ${period.value}, revenue: $totalRevenue, transactions: $totalTransactions)';
  }
}

/// Top customer model for analytics
class TopCustomer {
  final String customerId;
  final String customerName;
  final double totalSpent;
  final int totalOrders;
  final DateTime lastOrderDate;

  const TopCustomer({
    required this.customerId,
    required this.customerName,
    required this.totalSpent,
    required this.totalOrders,
    required this.lastOrderDate,
  });

  /// Get formatted total spent
  String get formattedTotalSpent => '₹${totalSpent.toStringAsFixed(2)}';

  /// Get average order value
  double get averageOrderValue => totalOrders > 0 ? totalSpent / totalOrders : 0.0;

  /// Get formatted average order value
  String get formattedAverageOrderValue => '₹${averageOrderValue.toStringAsFixed(2)}';
}

/// Payment trends model
class PaymentTrends {
  final double revenueGrowth;
  final double transactionGrowth;
  final double averageValueGrowth;
  final TrendDirection revenueDirection;
  final TrendDirection transactionDirection;
  final TrendDirection averageValueDirection;

  const PaymentTrends({
    required this.revenueGrowth,
    required this.transactionGrowth,
    required this.averageValueGrowth,
    required this.revenueDirection,
    required this.transactionDirection,
    required this.averageValueDirection,
  });

  /// Create neutral trends
  factory PaymentTrends.neutral() {
    return const PaymentTrends(
      revenueGrowth: 0.0,
      transactionGrowth: 0.0,
      averageValueGrowth: 0.0,
      revenueDirection: TrendDirection.stable,
      transactionDirection: TrendDirection.stable,
      averageValueDirection: TrendDirection.stable,
    );
  }

  /// Create trends from growth percentages
  factory PaymentTrends.fromGrowth({
    required double revenueGrowth,
    required double transactionGrowth,
    required double averageValueGrowth,
  }) {
    return PaymentTrends(
      revenueGrowth: revenueGrowth,
      transactionGrowth: transactionGrowth,
      averageValueGrowth: averageValueGrowth,
      revenueDirection: TrendDirection.fromGrowth(revenueGrowth),
      transactionDirection: TrendDirection.fromGrowth(transactionGrowth),
      averageValueDirection: TrendDirection.fromGrowth(averageValueGrowth),
    );
  }
}

/// Analytics period enum
enum AnalyticsPeriod {
  today('today', 'Today'),
  yesterday('yesterday', 'Yesterday'),
  thisWeek('this_week', 'This Week'),
  lastWeek('last_week', 'Last Week'),
  thisMonth('this_month', 'This Month'),
  lastMonth('last_month', 'Last Month'),
  thisYear('this_year', 'This Year'),
  custom('custom', 'Custom Range');

  const AnalyticsPeriod(this.value, this.displayName);

  final String value;
  final String displayName;

  static AnalyticsPeriod fromString(String value) {
    return AnalyticsPeriod.values.firstWhere(
      (period) => period.value == value.toLowerCase(),
      orElse: () => AnalyticsPeriod.thisMonth,
    );
  }
}

/// Trend direction enum
enum TrendDirection {
  up('up', 'Increasing'),
  down('down', 'Decreasing'),
  stable('stable', 'Stable');

  const TrendDirection(this.value, this.displayName);

  final String value;
  final String displayName;

  static TrendDirection fromGrowth(double growth) {
    if (growth > 5.0) return TrendDirection.up;
    if (growth < -5.0) return TrendDirection.down;
    return TrendDirection.stable;
  }
}

/// Payment report model for generating comprehensive reports
class PaymentReport {
  final String id;
  final String title;
  final DateTime generatedAt;
  final AnalyticsPeriod period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final PaymentAnalytics analytics;
  final List<Map<String, dynamic>> detailedTransactions;
  final String? filePath;
  final ReportFormat format;

  const PaymentReport({
    required this.id,
    required this.title,
    required this.generatedAt,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.analytics,
    required this.detailedTransactions,
    this.filePath,
    required this.format,
  });

  /// Generate unique report ID
  static String _generateReportId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'RPT_$timestamp';
  }

  /// Create a new payment report
  factory PaymentReport.create({
    required String title,
    required AnalyticsPeriod period,
    required DateTime periodStart,
    required DateTime periodEnd,
    required PaymentAnalytics analytics,
    required List<Map<String, dynamic>> detailedTransactions,
    ReportFormat format = ReportFormat.pdf,
  }) {
    return PaymentReport(
      id: _generateReportId(),
      title: title,
      generatedAt: DateTime.now(),
      period: period,
      periodStart: periodStart,
      periodEnd: periodEnd,
      analytics: analytics,
      detailedTransactions: detailedTransactions,
      format: format,
    );
  }

  /// Mark report as exported
  PaymentReport markAsExported(String filePath) {
    return PaymentReport(
      id: id,
      title: title,
      generatedAt: generatedAt,
      period: period,
      periodStart: periodStart,
      periodEnd: periodEnd,
      analytics: analytics,
      detailedTransactions: detailedTransactions,
      filePath: filePath,
      format: format,
    );
  }

  /// Check if report is exported
  bool get isExported => filePath != null;

  /// Get formatted generation date
  String get formattedGeneratedAt {
    return '${generatedAt.day}/${generatedAt.month}/${generatedAt.year} ${generatedAt.hour}:${generatedAt.minute.toString().padLeft(2, '0')}';
  }
}

/// Report format enum
enum ReportFormat {
  pdf('pdf', 'PDF'),
  excel('excel', 'Excel'),
  csv('csv', 'CSV');

  const ReportFormat(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReportFormat fromString(String value) {
    return ReportFormat.values.firstWhere(
      (format) => format.value == value.toLowerCase(),
      orElse: () => ReportFormat.pdf,
    );
  }
}