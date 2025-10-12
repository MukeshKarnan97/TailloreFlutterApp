import 'package:flutter/foundation.dart';
import 'local_db_service.dart';

/// Dashboard service to manage dashboard data and statistics
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final LocalDatabaseService _dbService = LocalDatabaseService();

  /// Dashboard statistics
  Map<String, dynamic> _dashboardStats = {
    'totalCustomers': 0,
    'activeOrders': 0,
    'completedOrders': 0,
    'totalRevenue': 0.0,
    'pendingMeasurements': 0,
    'todayAppointments': 0,
    'monthlyOrders': 0,
    'avgOrderValue': 0.0,
  };

  /// Get current dashboard statistics
  Map<String, dynamic> get dashboardStats => Map.from(_dashboardStats);

  /// Initialize dashboard data from database with optional time period filter
  Future<void> initializeDashboard({
    required String tailorId,
    String timePeriod = 'all_time',
  }) async {
    try {
      debugPrint('Initializing dashboard data for tailor: $tailorId, period: $timePeriod...');
      
      // Get date range for the selected time period
      final dateRange = _getDateRangeForPeriod(timePeriod);
      
      // Fetch real data from database with time filter and tailor filter
      final totalCustomers = await _getTotalCustomers(tailorId, dateRange);
      final activeOrders = await _getActiveOrders(tailorId, dateRange);
      final completedOrders = await _getCompletedOrders(tailorId, dateRange);
      final totalRevenue = await _getTotalRevenue(tailorId, dateRange);
      final pendingMeasurements = await _getPendingMeasurements(tailorId);
      final todayAppointments = await _getTodayAppointments(tailorId);
      final monthlyOrders = await _getMonthlyOrders(tailorId);
      final avgOrderValue = await _getAverageOrderValue(tailorId, dateRange);
      
      _dashboardStats = {
        'totalCustomers': totalCustomers,
        'activeOrders': activeOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
        'pendingMeasurements': pendingMeasurements,
        'todayAppointments': todayAppointments,
        'monthlyOrders': monthlyOrders,
        'avgOrderValue': avgOrderValue,
      };

      debugPrint('Dashboard data initialized successfully');
    } catch (e) {
      debugPrint('Error initializing dashboard: $e');
      rethrow;
    }
  }

  /// Refresh dashboard statistics from database
  Future<void> refreshDashboard({required String tailorId}) async {
    try {
      debugPrint('Refreshing dashboard data for tailor: $tailorId...');
      
      // Re-initialize with fresh data from database
      await initializeDashboard(tailorId: tailorId);
      
      debugPrint('Dashboard data refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      rethrow;
    }
  }

  /// Get specific statistic
  T getStat<T>(String key) {
    return _dashboardStats[key] as T;
  }

  /// Update a specific statistic
  void updateStat(String key, dynamic value) {
    _dashboardStats[key] = value;
    debugPrint('Updated $key to $value');
  }

  /// Get today's summary
  Map<String, dynamic> getTodaySummary() {
    return {
      'appointments': _dashboardStats['todayAppointments'],
      'pendingMeasurements': _dashboardStats['pendingMeasurements'],
      'newOrders': _dashboardStats['activeOrders'],
    };
  }

  /// Get business overview
  Map<String, dynamic> getBusinessOverview() {
    return {
      'totalCustomers': _dashboardStats['totalCustomers'],
      'activeOrders': _dashboardStats['activeOrders'],
      'completedOrders': _dashboardStats['completedOrders'],
      'totalRevenue': _dashboardStats['totalRevenue'],
    };
  }

  /// Get formatted revenue
  String getFormattedRevenue() {
    final revenue = _dashboardStats['totalRevenue'] as double;
    if (revenue >= 100000) {
      return '₹${(revenue / 100000).toStringAsFixed(1)}L';
    } else if (revenue >= 1000) {
      return '₹${(revenue / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${revenue.toStringAsFixed(0)}';
    }
  }

  /// Check if dashboard needs refresh (based on last update time)
  bool needsRefresh() {
    // TODO: Implement actual logic based on timestamp
    return false;
  }

  /// Reset all statistics (for testing purposes)
  void resetStats() {
    _dashboardStats = {
      'totalCustomers': 0,
      'activeOrders': 0,
      'completedOrders': 0,
      'totalRevenue': 0.0,
      'pendingMeasurements': 0,
      'todayAppointments': 0,
      'monthlyOrders': 0,
      'avgOrderValue': 0.0,
    };
    debugPrint('Dashboard statistics reset');
  }

  // Private methods for fetching real-time data from database

  /// Get date range for the given time period
  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;
    
    switch (period) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'this_week':
        // Get start of week (Monday)
        final weekday = now.weekday;
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'this_month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'this_year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        break;
      case 'all_time':
      default:
        startDate = null;
        endDate = null;
        break;
    }
    
    return {'start': startDate, 'end': endDate};
  }

  /// Get total number of active customers
  Future<int> _getTotalCustomers(String tailorId, [Map<String, DateTime?>? dateRange]) async {
    try {
      final customers = await _dbService.select(
        'customer',
        where: 'tailor_id = ? AND is_deleted = ?',
        whereArgs: [tailorId, 0],
      );
      return customers.length;
    } catch (e) {
      debugPrint('Error getting total customers: $e');
      return 0;
    }
  }

  /// Get number of active orders (pending, in_progress, measurement_pending)
  Future<int> _getActiveOrders(String tailorId, [Map<String, DateTime?>? dateRange]) async {
    try {
      String where = 'tailor_id = ? AND status IN (?, ?, ?) AND is_deleted = ?';
      List<dynamic> whereArgs = [tailorId, 'pending', 'in_progress', 'measurement_pending', 0];
      
      if (dateRange != null && dateRange['start'] != null && dateRange['end'] != null) {
        where += ' AND created_at >= ? AND created_at < ?';
        whereArgs.addAll([
          dateRange['start']!.millisecondsSinceEpoch,
          dateRange['end']!.millisecondsSinceEpoch,
        ]);
      }
      
      final orders = await _dbService.select(
        'orders',
        where: where,
        whereArgs: whereArgs,
      );
      return orders.length;
    } catch (e) {
      debugPrint('Error getting active orders: $e');
      return 0;
    }
  }

  /// Get number of completed orders
  Future<int> _getCompletedOrders(String tailorId, [Map<String, DateTime?>? dateRange]) async {
    try {
      String where = 'tailor_id = ? AND status = ? AND is_deleted = ?';
      List<dynamic> whereArgs = [tailorId, 'completed', 0];
      
      if (dateRange != null && dateRange['start'] != null && dateRange['end'] != null) {
        where += ' AND created_at >= ? AND created_at < ?';
        whereArgs.addAll([
          dateRange['start']!.millisecondsSinceEpoch,
          dateRange['end']!.millisecondsSinceEpoch,
        ]);
      }
      
      final orders = await _dbService.select(
        'orders',
        where: where,
        whereArgs: whereArgs,
      );
      return orders.length;
    } catch (e) {
      debugPrint('Error getting completed orders: $e');
      return 0;
    }
  }

  /// Get total revenue from all paid orders
  Future<double> _getTotalRevenue(String tailorId, [Map<String, DateTime?>? dateRange]) async {
    try {
      // Get all orders for this tailor to filter payments
      String orderWhere = 'tailor_id = ? AND is_deleted = ?';
      List<dynamic> orderWhereArgs = [tailorId, 0];
      
      final orders = await _dbService.select(
        'orders',
        where: orderWhere,
        whereArgs: orderWhereArgs,
      );
      
      // Get order IDs for this tailor
      final orderIds = orders.map((o) => o['unique_id'] as String).toList();
      
      if (orderIds.isEmpty) return 0.0;
      
      // Build payment query with date filter if provided
      String paymentWhere = 'order_id IN (${List.filled(orderIds.length, '?').join(',')}) AND is_deleted = ?';
      List<dynamic> paymentWhereArgs = [...orderIds, 0];
      
      if (dateRange != null && dateRange['start'] != null && dateRange['end'] != null) {
        paymentWhere += ' AND paid_on >= ? AND paid_on < ?';
        paymentWhereArgs.addAll([
          dateRange['start']!.toIso8601String(),
          dateRange['end']!.toIso8601String(),
        ]);
      }
      
      // Get all payments for this tailor's orders
      final payments = await _dbService.select(
        'payment',
        where: paymentWhere,
        whereArgs: paymentWhereArgs,
      );
      
      double totalRevenue = 0.0;
      for (final payment in payments) {
        totalRevenue += (payment['amount'] as num).toDouble();
      }
      return totalRevenue;
    } catch (e) {
      debugPrint('Error getting total revenue: $e');
      return 0.0;
    }
  }

  /// Get number of pending measurements
  Future<int> _getPendingMeasurements(String tailorId) async {
    try {
      final orders = await _dbService.select(
        'orders',
        where: 'tailor_id = ? AND status = ? AND is_deleted = ?',
        whereArgs: [tailorId, 'measurement_pending', 0],
      );
      return orders.length;
    } catch (e) {
      debugPrint('Error getting pending measurements: $e');
      return 0;
    }
  }

  /// Get today's appointments (orders with delivery date today)
  Future<int> _getTodayAppointments(String tailorId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final orders = await _dbService.select(
        'orders',
        where: 'tailor_id = ? AND delivery_date >= ? AND delivery_date < ? AND is_deleted = ?',
        whereArgs: [
          tailorId,
          todayStart.millisecondsSinceEpoch,
          todayEnd.millisecondsSinceEpoch,
          0
        ],
      );
      return orders.length;
    } catch (e) {
      debugPrint('Error getting today appointments: $e');
      return 0;
    }
  }

  /// Get this month's orders count
  Future<int> _getMonthlyOrders(String tailorId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);
      
      final orders = await _dbService.select(
        'orders',
        where: 'tailor_id = ? AND created_at >= ? AND created_at < ? AND is_deleted = ?',
        whereArgs: [
          tailorId,
          monthStart.millisecondsSinceEpoch,
          monthEnd.millisecondsSinceEpoch,
          0
        ],
      );
      return orders.length;
    } catch (e) {
      debugPrint('Error getting monthly orders: $e');
      return 0;
    }
  }

  /// Get average order value
  Future<double> _getAverageOrderValue(String tailorId, [Map<String, DateTime?>? dateRange]) async {
    try {
      String where = 'tailor_id = ? AND is_deleted = ?';
      List<dynamic> whereArgs = [tailorId, 0];
      
      if (dateRange != null && dateRange['start'] != null && dateRange['end'] != null) {
        where += ' AND created_at >= ? AND created_at < ?';
        whereArgs.addAll([
          dateRange['start']!.millisecondsSinceEpoch,
          dateRange['end']!.millisecondsSinceEpoch,
        ]);
      }
      
      final orders = await _dbService.select(
        'orders',
        where: where,
        whereArgs: whereArgs,
      );
      
      if (orders.isEmpty) return 0.0;
      
      double totalAmount = 0.0;
      for (final order in orders) {
        totalAmount += (order['total_amount'] as num).toDouble();
      }
      
      return totalAmount / orders.length;
    } catch (e) {
      debugPrint('Error getting average order value: $e');
      return 0.0;
    }
  }
}