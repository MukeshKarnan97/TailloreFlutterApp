import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/data/models/measurement_model.dart';

class MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final bool showActions;

  const MeasurementCard({
    Key? key,
    required this.measurement,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Dress type icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: measurement.isDeleted 
                                ? Colors.red.withOpacity(0.1)
                                : _getDressTypeColor(measurement.dressType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getDressTypeIcon(measurement.dressType),
                            color: measurement.isDeleted 
                                ? Colors.red 
                                : _getDressTypeColor(measurement.dressType),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Dress type name and ID
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dressTypeDetails?['name'] ?? measurement.dressType,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.2),
                                          width: 1,
                                        ),
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
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${measurement.uniqueId}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getDressTypeColor(measurement.dressType),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Progress section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completion Progress',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${completionPercentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _getCompletionColor(completionPercentage),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getCompletionColor(completionPercentage),
                          ),
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${measurement.measurements.length} of ${requiredMeasurements.length} measurements completed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Metadata row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${_formatDate(measurement.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (measurement.updatedAt != measurement.createdAt) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Updated: ${_formatDate(measurement.updatedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              if (showActions) _buildActionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    if (measurement.isDeleted) {
      return Container(
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
              onPressed: onRestore,
            ),
          ],
        ),
      );
    }

    return Container(
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
            onPressed: onTap,
          ),
          _buildActionButton(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: const Color(AppConstants.primaryTeal),
            onPressed: onEdit,
          ),
          _buildActionButton(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
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

  Color _getDressTypeColor(String dressType) {
    switch (dressType.toLowerCase()) {
      case 'shirt':
        return Colors.blue;
      case 'pant':
        return Colors.indigo;
      case 'suit':
        return Colors.purple;
      case 'blazer':
        return Colors.deepPurple;
      case 'kurta':
        return Colors.orange;
      case 'sherwani':
        return Colors.amber;
      case 'dress':
        return Colors.pink;
      case 'blouse':
        return Colors.red;
      case 'lehenga':
        return Colors.teal;
      case 'saree_blouse':
        return Colors.green;
      default:
        return const Color(AppConstants.primaryTeal);
    }
  }

  IconData _getDressTypeIcon(String dressType) {
    switch (dressType.toLowerCase()) {
      case 'shirt':
        return Icons.person_outline;
      case 'pant':
        return Icons.man_rounded;
      case 'suit':
        return Icons.business_center_rounded;
      case 'blazer':
        return Icons.work_outline_rounded;
      case 'kurta':
      case 'sherwani':
        return Icons.self_improvement_rounded;
      case 'dress':
      case 'blouse':
      case 'lehenga':
      case 'saree_blouse':
        return Icons.woman_rounded;
      default:
        return Icons.checkroom_rounded;
    }
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}