import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/data/models/measurement_model.dart';
import 'package:tailer_app/data/services/local_db_service.dart';
import 'package:tailer_app/core/utils/logger.dart';
import 'package:tailer_app/routes/app_routes.dart';

class MeasurementListScreen extends StatefulWidget {
  final String customerId;
  
  const MeasurementListScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<MeasurementListScreen> createState() => _MeasurementListScreenState();
}

class _MeasurementListScreenState extends State<MeasurementListScreen> with NavigationMixin {
  final _searchController = TextEditingController();
  List<Measurement> _allMeasurements = [];
  List<Measurement> _filteredMeasurements = [];
  bool _isLoading = true;
  String? _customerName;
  final LocalDatabaseService _dbService = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  /// Load measurements for the customer
  Future<void> _loadMeasurements() async {
    try {
      setState(() => _isLoading = true);
      
      // Load customer name first
      final customerData = await _dbService.getCustomerByUniqueId(widget.customerId);
      if (customerData != null) {
        _customerName = customerData['name'];
      }
      
      // Load measurements for this customer
      final measurementsData = await _dbService.getMeasurementsByCustomerId(widget.customerId);
      final measurements = measurementsData.map((data) => Measurement.fromMap(data)).toList();
      
      // Sort measurements by creation date (newest first)
      measurements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _allMeasurements = measurements;
        _filteredMeasurements = measurements;
        _isLoading = false;
      });
      
      Logger.info('MeasurementListScreen', 'Loaded ${measurements.length} measurements for customer ${widget.customerId}');
    } catch (e, stackTrace) {
      Logger.error('MeasurementListScreen', 'Failed to load measurements', 
                  error: e, stackTrace: stackTrace);
      setState(() => _isLoading = false);
      
      if (mounted) {
        showNavigationMessage(
          context,
          'Load Failed',
          customMessage: 'Failed to load measurements. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Measurements',
        backgroundColor: const Color(AppConstants.primaryTeal),
        notificationCount: 3,
        onBackPressed: () {
          context.goNamed(
            RouteNames.customerDetails,
            pathParameters: {'customerId': widget.customerId},
          );
        },
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(AppConstants.primaryTeal),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadMeasurements,
                color: const Color(AppConstants.primaryTeal),
                child: Column(
                  children: [
                    _buildHeaderSection(),
                    _buildFilterSection(),
                    Expanded(child: _buildMeasurementsList()),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDressTypeSelection(),
        backgroundColor: const Color(AppConstants.primaryTeal),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Measurement',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purple.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple,
                  Colors.purple.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.straighten_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerName ?? 'Customer Measurements',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_getVisibleMeasurements().length} Measurements',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterMeasurements,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search measurements by dress type...',
          hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(AppConstants.primaryTeal)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(AppConstants.primaryTeal)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMeasurementsList() {
    final measurements = _getVisibleMeasurements();
    
    if (measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No measurements found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first measurement to get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        return _buildMeasurementCard(measurement);
      },
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(measurement.dressType);
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(measurement.dressType);
    final completionPercentage = measurement.getCompletionPercentage(requiredMeasurements);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: measurement.isDeleted 
            ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
            : Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: measurement.isDeleted 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.purple.withOpacity(0.1),
              child: Icon(
                Icons.checkroom_rounded,
                color: measurement.isDeleted ? Colors.red : Colors.purple,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    dressTypeDetails?['name'] ?? measurement.dressType,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: measurement.isDeleted ? Colors.grey[500] : Colors.black87,
                      decoration: measurement.isDeleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (measurement.isDeleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DELETED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: ${measurement.uniqueId}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Completion percentage bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${completionPercentage.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getCompletionColor(completionPercentage),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: completionPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCompletionColor(completionPercentage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Created: ${_formatDate(measurement.createdAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!measurement.isDeleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility_rounded,
                    label: 'View',
                    color: Colors.blue,
                    onPressed: () => _viewMeasurement(measurement),
                  ),
                  _buildActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: const Color(AppConstants.primaryTeal),
                    onPressed: () => _editMeasurement(measurement),
                  ),
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: Colors.red,
                    onPressed: () => _deleteMeasurement(measurement),
                  ),
                ],
              ),
            ),
          if (measurement.isDeleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.restore_rounded,
                    label: 'Restore',
                    color: Colors.green,
                    onPressed: () => _restoreMeasurement(measurement),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Measurement> _getVisibleMeasurements() {
    return _filteredMeasurements.where((measurement) => !measurement.isDeleted).toList();
  }

  void _filterMeasurements(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMeasurements = _allMeasurements;
      } else {
        _filteredMeasurements = _allMeasurements.where((measurement) {
          final dressTypeDetails = MeasurementConstants.getDressTypeDetails(measurement.dressType);
          final dressTypeName = dressTypeDetails?['name'] ?? measurement.dressType;
          
          return dressTypeName.toLowerCase().contains(query.toLowerCase()) ||
                 measurement.dressType.toLowerCase().contains(query.toLowerCase()) ||
                 measurement.uniqueId.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDressTypeSelection() {
    context.goNamed(RouteNames.measurementCategory, pathParameters: {'customerId': widget.customerId});
  }

  void _viewMeasurement(Measurement measurement) {
    // TODO: Navigate to measurement details view
    showNavigationMessage(context, 'View Measurement', 
        customMessage: 'Measurement details view coming soon!');
  }

  void _editMeasurement(Measurement measurement) {
    context.goNamed(
      RouteNames.editMeasurement,
      pathParameters: {'measurementId': measurement.uniqueId},
    );
  }

  void _deleteMeasurement(Measurement measurement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Measurement', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: Text(
            'Are you sure you want to delete this ${MeasurementConstants.getDressTypeDetails(measurement.dressType)?['name']} measurement? This action can be undone later.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.of(context).pop();
                  
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  // Update database
                  await _dbService.updateMeasurement(measurement.uniqueId, {
                    'is_deleted': 1,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  
                  // Hide loading indicator
                  if (mounted) Navigator.of(context).pop();
                  
                  // Reload measurements
                  await _loadMeasurements();
                  
                  Logger.info('MeasurementListScreen', 'Measurement ${measurement.uniqueId} deleted successfully');
                  
                  if (mounted) {
                    showNavigationMessage(
                      context,
                      'Measurement Deleted',
                      customMessage: 'Measurement has been moved to deleted items.',
                      backgroundColor: Colors.orange,
                    );
                  }
                } catch (e, stackTrace) {
                  Logger.error('MeasurementListScreen', 'Failed to delete measurement', 
                              error: e, stackTrace: stackTrace);
                  
                  // Hide loading indicator
                  if (mounted) Navigator.of(context).pop();
                  
                  if (mounted) {
                    showNavigationMessage(
                      context,
                      'Delete Failed',
                      customMessage: 'Failed to delete measurement. Please try again.',
                      backgroundColor: Colors.red,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _restoreMeasurement(Measurement measurement) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Update database
      await _dbService.updateMeasurement(measurement.uniqueId, {
        'is_deleted': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();
      
      // Reload measurements
      await _loadMeasurements();
      
      Logger.info('MeasurementListScreen', 'Measurement ${measurement.uniqueId} restored successfully');
      
      if (mounted) {
        showNavigationMessage(
          context,
          'Measurement Restored',
          customMessage: 'Measurement has been restored successfully.',
          backgroundColor: Colors.green,
        );
      }
    } catch (e, stackTrace) {
      Logger.error('MeasurementListScreen', 'Failed to restore measurement', 
                  error: e, stackTrace: stackTrace);
      
      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        showNavigationMessage(
          context,
          'Restore Failed',
          customMessage: 'Failed to restore measurement. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}