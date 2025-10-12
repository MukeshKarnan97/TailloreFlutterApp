import '../models/payment_analytics.dart';
import '../models/payment_model.dart';
import '../models/refund_transaction.dart';
import 'local_db_service.dart';
import 'auth_service.dart';
import '../../core/utils/logger.dart';

/// Service for generating payment analytics and reports
class PaymentAnalyticsService {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  final AuthService _authService = AuthService();

  /// Generate analytics for a specific period
  Future<PaymentAnalytics> generateAnalytics({
    required AnalyticsPeriod period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    try {
      Logger.info('PaymentAnalyticsService', 'Generating analytics for period: ${period.value}');

      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      // Get all payments in the period
      final payments = await _getPaymentsInPeriod(startDate, endDate);
      
      // Get all refunds in the period
      final refunds = await _getRefundsInPeriod(startDate, endDate);

      // Calculate basic metrics
      final totalRevenue = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      final totalRefunds = refunds.fold<double>(0.0, (sum, refund) => sum + refund.refundAmount);
      final netRevenue = totalRevenue - totalRefunds;
      final totalTransactions = payments.length;
      final totalRefundTransactions = refunds.length;
      final averageTransactionValue = totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;

      // Calculate revenue by payment method
      final revenueByPaymentMethod = <String, double>{};
      final transactionsByPaymentMethod = <String, int>{};
      
      for (final payment in payments) {
        final method = payment.method.displayName;
        revenueByPaymentMethod[method] = (revenueByPaymentMethod[method] ?? 0.0) + payment.amount;
        transactionsByPaymentMethod[method] = (transactionsByPaymentMethod[method] ?? 0) + 1;
      }

      // Calculate daily revenue
      final revenueByDay = <String, double>{};
      for (final payment in payments) {
        final dayKey = _formatDateKey(payment.paidOn);
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0.0) + payment.amount;
      }

      // Calculate outstanding amount
      final outstandingAmount = await _calculateOutstandingAmount();

      // Get top customers
      final topCustomers = await _getTopCustomers(startDate, endDate);

      // Calculate trends (compare with previous period)
      final trends = await _calculateTrends(period, startDate, endDate, totalRevenue, totalTransactions, averageTransactionValue);

      final analytics = PaymentAnalytics(
        periodStart: startDate,
        periodEnd: endDate,
        period: period,
        totalRevenue: totalRevenue,
        totalRefunds: totalRefunds,
        netRevenue: netRevenue,
        totalTransactions: totalTransactions,
        totalRefundTransactions: totalRefundTransactions,
        revenueByPaymentMethod: revenueByPaymentMethod,
        transactionsByPaymentMethod: transactionsByPaymentMethod,
        revenueByDay: revenueByDay,
        averageTransactionValue: averageTransactionValue,
        outstandingAmount: outstandingAmount,
        topCustomers: topCustomers,
        trends: trends,
      );

      Logger.info('PaymentAnalyticsService', 'Analytics generated successfully');
      return analytics;
    } catch (e, stackTrace) {
      Logger.error('PaymentAnalyticsService', 'Failed to generate analytics', 
                   error: e, stackTrace: stackTrace);
      return PaymentAnalytics.empty(
        periodStart: customStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
        periodEnd: customEndDate ?? DateTime.now(),
        period: period,
      );
    }
  }

  /// Generate payment report
  Future<PaymentReport> generateReport({
    required String title,
    required AnalyticsPeriod period,
    DateTime? customStartDate,
    DateTime? customEndDate,
    ReportFormat format = ReportFormat.pdf,
  }) async {
    try {
      Logger.info('PaymentAnalyticsService', 'Generating payment report: $title');

      final dateRange = _getDateRange(period, customStartDate, customEndDate);
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      // Generate analytics
      final analytics = await generateAnalytics(
        period: period,
        customStartDate: customStartDate,
        customEndDate: customEndDate,
      );

      // Get detailed transactions
      final detailedTransactions = await _getDetailedTransactions(startDate, endDate);

      final report = PaymentReport.create(
        title: title,
        period: period,
        periodStart: startDate,
        periodEnd: endDate,
        analytics: analytics,
        detailedTransactions: detailedTransactions,
        format: format,
      );

      Logger.info('PaymentAnalyticsService', 'Payment report generated: ${report.id}');
      return report;
    } catch (e, stackTrace) {
      Logger.error('PaymentAnalyticsService', 'Failed to generate report', 
                   error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get revenue trends for dashboard
  Future<Map<String, dynamic>> getRevenueTrends({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final payments = await _getPaymentsInPeriod(startDate, endDate);
      
      final dailyRevenue = <String, double>{};
      final dailyTransactions = <String, int>{};

      for (final payment in payments) {
        final dateKey = _formatDateKey(payment.paidOn);
        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + payment.amount;
        dailyTransactions[dateKey] = (dailyTransactions[dateKey] ?? 0) + 1;
      }

      return {
        'daily_revenue': dailyRevenue,
        'daily_transactions': dailyTransactions,
        'total_revenue': payments.fold<double>(0.0, (sum, p) => sum + p.amount),
        'total_transactions': payments.length,
        'period_days': days,
      };
    } catch (e, stackTrace) {
      Logger.error('PaymentAnalyticsService', 'Failed to get revenue trends', 
                   error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Get payment method statistics
  Future<Map<String, dynamic>> getPaymentMethodStats({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final payments = await _getPaymentsInPeriod(startDate, endDate);
      
      final methodStats = <String, Map<String, dynamic>>{};

      for (final payment in payments) {
        final method = payment.method.displayName;
        
        if (!methodStats.containsKey(method)) {
          methodStats[method] = {
            'count': 0,
            'total_amount': 0.0,
            'percentage': 0.0,
          };
        }

        methodStats[method]!['count'] = methodStats[method]!['count'] + 1;
        methodStats[method]!['total_amount'] = methodStats[method]!['total_amount'] + payment.amount;
      }

      // Calculate percentages
      final totalAmount = payments.fold<double>(0.0, (sum, p) => sum + p.amount);
      final totalCount = payments.length;

      for (final method in methodStats.keys) {
        methodStats[method]!['amount_percentage'] = totalAmount > 0 
            ? (methodStats[method]!['total_amount'] / totalAmount) * 100 
            : 0.0;
        methodStats[method]!['count_percentage'] = totalCount > 0 
            ? (methodStats[method]!['count'] / totalCount) * 100 
            : 0.0;
      }

      return {
        'method_stats': methodStats,
        'total_amount': totalAmount,
        'total_transactions': totalCount,
      };
    } catch (e, stackTrace) {
      Logger.error('PaymentAnalyticsService', 'Failed to get payment method stats', 
                   error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Get top performing customers
  Future<List<TopCustomer>> getTopCustomers({int limit = 10, int days = 90}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      return await _getTopCustomers(startDate, endDate, limit: limit);
    } catch (e, stackTrace) {
      Logger.error('PaymentAnalyticsService', 'Failed to get top customers', 
                   error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Private helper methods

  Map<String, DateTime> _getDateRange(AnalyticsPeriod period, DateTime? customStart, DateTime? customEnd) {
    final now = DateTime.now();
    DateTime start, end;

    switch (period) {
      case AnalyticsPeriod.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        end = start.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.thisWeek:
        final weekday = now.weekday;
        start = now.subtract(Duration(days: weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.lastWeek:
        final weekday = now.weekday;
        final thisWeekStart = now.subtract(Duration(days: weekday - 1));
        start = thisWeekStart.subtract(const Duration(days: 7));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.thisYear:
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1).subtract(const Duration(microseconds: 1));
        break;
      case AnalyticsPeriod.custom:
        start = customStart ?? now.subtract(const Duration(days: 30));
        end = customEnd ?? now;
        break;
    }

    return {'start': start, 'end': end};
  }

  Future<List<Payment>> _getPaymentsInPeriod(DateTime start, DateTime end) async {
    try {
      // Get current tailor for filtering
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('PaymentAnalyticsService', 'No tailor logged in');
        return [];
      }
      
      final tailorId = currentTailor.email;
      
      // Get payments filtered by tailor and date range
      final db = await _dbService.database;
      final paymentMaps = await db.rawQuery(
        '''
        SELECT p.* FROM payment p
        INNER JOIN orders o ON p.order_id = o.unique_id
        WHERE o.tailor_id = ? 
          AND p.paid_on BETWEEN ? AND ? 
          AND p.is_deleted = 0
        ORDER BY p.paid_on ASC
        ''',
        [tailorId, start.toIso8601String(), end.toIso8601String()],
      );

      return paymentMaps.map((map) => Payment.fromMap(map)).toList();
    } catch (e) {
      Logger.error('PaymentAnalyticsService', 'Failed to get payments in period', error: e);
      return [];
    }
  }

  Future<List<RefundTransaction>> _getRefundsInPeriod(DateTime start, DateTime end) async {
    try {
      // Get current tailor for filtering
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('PaymentAnalyticsService', 'No tailor logged in');
        return [];
      }
      
      final tailorId = currentTailor.email;
      
      final refundMaps = await _dbService.select(
        'refund_transactions',
        where: 'tailor_id = ? AND processed_at BETWEEN ? AND ?',
        whereArgs: [tailorId, start.toIso8601String(), end.toIso8601String()],
        orderBy: 'processed_at ASC',
      );

      return refundMaps.map((map) => RefundTransaction.fromMap(map)).toList();
    } catch (e) {
      Logger.error('PaymentAnalyticsService', 'Failed to get refunds in period', error: e);
      return [];
    }
  }

  Future<double> _calculateOutstandingAmount() async {
    try {
      // Get current tailor for filtering
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('PaymentAnalyticsService', 'No tailor logged in');
        return 0.0;
      }
      
      final tailorId = currentTailor.email;
      
      // Get orders filtered by tailor
      final orderMaps = await _dbService.select(
        'orders',
        where: 'tailor_id = ? AND status NOT IN (?, ?, ?) AND is_deleted = 0',
        whereArgs: [tailorId, 'completed', 'delivered', 'cancelled'],
      );

      double outstanding = 0.0;
      for (final orderMap in orderMaps) {
        final orderAmount = (orderMap['total_amount'] as num?)?.toDouble() ?? 0.0;
        
        // Get payments for this order
        final paymentMaps = await _dbService.select(
          'payment',
          where: 'order_id = ? AND is_deleted = 0',
          whereArgs: [orderMap['unique_id']],
        );

        final paidAmount = paymentMaps.fold<double>(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));
        outstanding += (orderAmount - paidAmount).clamp(0.0, double.infinity);
      }

      return outstanding;
    } catch (e) {
      Logger.error('PaymentAnalyticsService', 'Failed to calculate outstanding amount', error: e);
      return 0.0;
    }
  }

  Future<List<TopCustomer>> _getTopCustomers(DateTime start, DateTime end, {int limit = 10}) async {
    try {
      // Get current tailor for filtering
      final currentTailor = _authService.currentUser;
      if (currentTailor == null) {
        Logger.warning('PaymentAnalyticsService', 'No tailor logged in');
        return [];
      }
      
      final tailorId = currentTailor.email;
      
      // Get payments filtered by tailor
      final db = await _dbService.database;
      final paymentMaps = await db.rawQuery(
        '''
        SELECT p.* FROM payment p
        INNER JOIN orders o ON p.order_id = o.unique_id
        WHERE o.tailor_id = ?
          AND p.paid_on BETWEEN ? AND ? 
          AND p.is_deleted = 0
        ''',
        [tailorId, start.toIso8601String(), end.toIso8601String()],
      );

      final customerSpending = <String, Map<String, dynamic>>{};

      for (final paymentMap in paymentMaps) {
        final orderId = paymentMap['order_id'] as String;
        final amount = (paymentMap['amount'] as num?)?.toDouble() ?? 0.0;
        final paidOn = DateTime.parse(paymentMap['paid_on'] as String);

        // Get order to find customer
        final orderMaps = await _dbService.select(
          'orders',
          where: 'unique_id = ? AND tailor_id = ?',
          whereArgs: [orderId, tailorId],
          limit: 1,
        );

        if (orderMaps.isNotEmpty) {
          final customerId = orderMaps.first['customer_id'] as String;
          
          if (!customerSpending.containsKey(customerId)) {
            customerSpending[customerId] = {
              'total_spent': 0.0,
              'total_orders': 0,
              'last_order_date': paidOn,
            };
          }

          customerSpending[customerId]!['total_spent'] = 
              customerSpending[customerId]!['total_spent'] + amount;
          customerSpending[customerId]!['total_orders'] = 
              customerSpending[customerId]!['total_orders'] + 1;
          
          if (paidOn.isAfter(customerSpending[customerId]!['last_order_date'])) {
            customerSpending[customerId]!['last_order_date'] = paidOn;
          }
        }
      }

      // Convert to TopCustomer objects and sort
      final topCustomers = <TopCustomer>[];
      for (final customerId in customerSpending.keys) {
        // Get customer name
        final customerMaps = await _dbService.select(
          'customer',
          where: 'unique_id = ?',
          whereArgs: [customerId],
          limit: 1,
        );

        final customerName = customerMaps.isNotEmpty 
            ? (customerMaps.first['name'] as String? ?? 'Customer $customerId')
            : 'Customer $customerId';

        topCustomers.add(TopCustomer(
          customerId: customerId,
          customerName: customerName,
          totalSpent: customerSpending[customerId]!['total_spent'],
          totalOrders: customerSpending[customerId]!['total_orders'],
          lastOrderDate: customerSpending[customerId]!['last_order_date'],
        ));
      }

      // Sort by total spent and return top customers
      topCustomers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
      return topCustomers.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PaymentTrends> _calculateTrends(
    AnalyticsPeriod period,
    DateTime currentStart,
    DateTime currentEnd,
    double currentRevenue,
    int currentTransactions,
    double currentAvgValue,
  ) async {
    try {
      // Calculate previous period dates
      final periodDuration = currentEnd.difference(currentStart);
      final previousEnd = currentStart.subtract(const Duration(microseconds: 1));
      final previousStart = previousEnd.subtract(periodDuration);

      // Get previous period data
      final previousPayments = await _getPaymentsInPeriod(previousStart, previousEnd);
      final previousRevenue = previousPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
      final previousTransactions = previousPayments.length;
      final previousAvgValue = previousTransactions > 0 ? previousRevenue / previousTransactions : 0.0;

      // Calculate growth percentages
      final revenueGrowth = _calculateGrowthPercentage(previousRevenue, currentRevenue);
      final transactionGrowth = _calculateGrowthPercentage(previousTransactions.toDouble(), currentTransactions.toDouble());
      final avgValueGrowth = _calculateGrowthPercentage(previousAvgValue, currentAvgValue);

      return PaymentTrends.fromGrowth(
        revenueGrowth: revenueGrowth,
        transactionGrowth: transactionGrowth,
        averageValueGrowth: avgValueGrowth,
      );
    } catch (e) {
      return PaymentTrends.neutral();
    }
  }

  Future<List<Map<String, dynamic>>> _getDetailedTransactions(DateTime start, DateTime end) async {
    try {
      final paymentMaps = await _dbService.select(
        'payment',
        where: 'paid_on BETWEEN ? AND ? AND is_deleted = 0',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'paid_on DESC',
      );

      final detailedTransactions = <Map<String, dynamic>>[];

      for (final paymentMap in paymentMaps) {
        // Get order details
        final orderMaps = await _dbService.select(
          'orders',
          where: 'unique_id = ?',
          whereArgs: [paymentMap['order_id']],
          limit: 1,
        );

        // Get customer details
        String customerName = 'Unknown Customer';
        if (orderMaps.isNotEmpty) {
          final customerMaps = await _dbService.select(
            'customer',
            where: 'unique_id = ?',
            whereArgs: [orderMaps.first['customer_id']],
            limit: 1,
          );
          
          if (customerMaps.isNotEmpty) {
            customerName = customerMaps.first['name'] ?? 'Customer ${orderMaps.first['customer_id']}';
          }
        }

        detailedTransactions.add({
          'payment_id': paymentMap['unique_id'],
          'order_id': paymentMap['order_id'],
          'customer_name': customerName,
          'amount': paymentMap['amount'],
          'method': paymentMap['method'],
          'paid_on': paymentMap['paid_on'],
          'transaction_id': paymentMap['transaction_id'],
          'notes': paymentMap['notes'],
        });
      }

      return detailedTransactions;
    } catch (e) {
      return [];
    }
  }

  double _calculateGrowthPercentage(double previous, double current) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}