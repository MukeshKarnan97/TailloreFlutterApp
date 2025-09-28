import 'package:flutter_test/flutter_test.dart';
import 'package:tailer_app/data/services/dashboard_service.dart';

void main() {
  group('DashboardService Tests', () {
    late DashboardService dashboardService;

    setUp(() {
      dashboardService = DashboardService();
    });

    test('should initialize dashboard data successfully', () async {
      // Act
      await dashboardService.initializeDashboard();
      final stats = dashboardService.dashboardStats;

      // Assert
      expect(stats, isNotEmpty);
      expect(stats['totalCustomers'], isA<int>());
      expect(stats['activeOrders'], isA<int>());
      expect(stats['completedOrders'], isA<int>());
      expect(stats['totalRevenue'], isA<double>());
      expect(stats['pendingMeasurements'], isA<int>());
      expect(stats['todayAppointments'], isA<int>());
    });

    test('should refresh dashboard data successfully', () async {
      // Arrange
      await dashboardService.initializeDashboard();
      final initialActiveOrders = dashboardService.getStat<int>('activeOrders');
      final initialRevenue = dashboardService.getStat<double>('totalRevenue');

      // Act
      await dashboardService.refreshDashboard();

      // Assert
      final newActiveOrders = dashboardService.getStat<int>('activeOrders');
      final newRevenue = dashboardService.getStat<double>('totalRevenue');
      
      expect(newActiveOrders, equals(initialActiveOrders + 1));
      expect(newRevenue, equals(initialRevenue + 500.0));
    });

    test('should get and update specific stats', () async {
      // Arrange
      await dashboardService.initializeDashboard();
      
      // Act
      dashboardService.updateStat('totalCustomers', 100);
      final customers = dashboardService.getStat<int>('totalCustomers');

      // Assert
      expect(customers, equals(100));
    });

    test('should get today\'s summary', () async {
      // Arrange
      await dashboardService.initializeDashboard();

      // Act
      final summary = dashboardService.getTodaySummary();

      // Assert
      expect(summary.containsKey('appointments'), isTrue);
      expect(summary.containsKey('pendingMeasurements'), isTrue);
      expect(summary.containsKey('newOrders'), isTrue);
    });

    test('should get business overview', () async {
      // Arrange
      await dashboardService.initializeDashboard();

      // Act
      final overview = dashboardService.getBusinessOverview();

      // Assert
      expect(overview.containsKey('totalCustomers'), isTrue);
      expect(overview.containsKey('activeOrders'), isTrue);
      expect(overview.containsKey('completedOrders'), isTrue);
      expect(overview.containsKey('totalRevenue'), isTrue);
    });

    test('should format revenue correctly', () async {
      // Arrange
      await dashboardService.initializeDashboard();

      // Test different revenue amounts
      dashboardService.updateStat('totalRevenue', 500.0);
      expect(dashboardService.getFormattedRevenue(), equals('₹500'));

      dashboardService.updateStat('totalRevenue', 1500.0);
      expect(dashboardService.getFormattedRevenue(), equals('₹1.5K'));

      dashboardService.updateStat('totalRevenue', 150000.0);
      expect(dashboardService.getFormattedRevenue(), equals('₹1.5L'));
    });

    test('should reset stats correctly', () async {
      // Arrange
      await dashboardService.initializeDashboard();

      // Act
      dashboardService.resetStats();
      final stats = dashboardService.dashboardStats;

      // Assert
      expect(stats['totalCustomers'], equals(0));
      expect(stats['activeOrders'], equals(0));
      expect(stats['completedOrders'], equals(0));
      expect(stats['totalRevenue'], equals(0.0));
      expect(stats['pendingMeasurements'], equals(0));
      expect(stats['todayAppointments'], equals(0));
    });
  });
}