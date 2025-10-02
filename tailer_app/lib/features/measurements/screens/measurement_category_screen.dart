import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/core/constants/app_constants.dart';
import 'package:tailer_app/core/constants/measurement_constants.dart';
import 'package:tailer_app/core/mixins/navigation_mixin.dart';
import 'package:tailer_app/widgets/custom_header.dart';
import 'package:tailer_app/routes/app_routes.dart';

class MeasurementCategoryScreen extends StatefulWidget {
  final String customerId;
  
  const MeasurementCategoryScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<MeasurementCategoryScreen> createState() => _MeasurementCategoryScreenState();
}

class _MeasurementCategoryScreenState extends State<MeasurementCategoryScreen> with NavigationMixin {
  final _searchController = TextEditingController();
  List<String> _filteredDressTypes = [];

  @override
  void initState() {
    super.initState();
    _filteredDressTypes = MeasurementConstants.getAllDressTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: DashboardHeader(
        title: 'Select Dress Type',
        backgroundColor: const Color(AppConstants.primaryTeal),
        notificationCount: 3,
        onBackPressed: () {
          context.goNamed(
            RouteNames.measurementList,
            pathParameters: {'customerId': widget.customerId},
          );
        },
        onNotificationTap: () {
          showNavigationMessage(context, 'Notifications');
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildSearchSection(),
            Expanded(child: _buildDressTypeGrid()),
          ],
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
            const Color(AppConstants.primaryTeal).withOpacity(0.1),
            const Color(AppConstants.primaryTeal).withOpacity(0.05),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(AppConstants.primaryTeal).withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
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
              gradient: const LinearGradient(
                colors: [
                  Color(AppConstants.primaryTeal),
                  Color(0xFF00A693),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryTeal).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.checkroom_rounded,
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
                  'Choose Dress Type',
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
                    color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(AppConstants.primaryTeal).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_filteredDressTypes.length} Available Types',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(AppConstants.primaryTeal),
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

  Widget _buildSearchSection() {
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
        onChanged: _filterDressTypes,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search dress types...',
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

  Widget _buildDressTypeGrid() {
    if (_filteredDressTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No dress types found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredDressTypes.length,
      itemBuilder: (context, index) {
        final dressType = _filteredDressTypes[index];
        return _buildDressTypeCard(dressType);
      },
    );
  }

  Widget _buildDressTypeCard(String dressType) {
    final dressTypeDetails = MeasurementConstants.getDressTypeDetails(dressType);
    final requiredMeasurements = MeasurementConstants.getMeasurementsForDressType(dressType);
    final measurementCount = requiredMeasurements.length;
    
    return GestureDetector(
      onTap: () => _selectDressType(dressType),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(AppConstants.primaryTeal).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getDressTypeColor(dressType),
                    _getDressTypeColor(dressType).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getDressTypeColor(dressType).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getDressTypeIcon(dressType),
                size: 40,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dress type name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                dressTypeDetails?['name'] ?? dressType,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            if (dressTypeDetails?['description'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  dressTypeDetails!['description'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Measurement count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getDressTypeColor(dressType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getDressTypeColor(dressType).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                '$measurementCount measurements',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getDressTypeColor(dressType),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _getDressTypeColor(String dressType) {
    switch (dressType) {
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
    switch (dressType) {
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

  void _filterDressTypes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDressTypes = MeasurementConstants.getAllDressTypes();
      } else {
        _filteredDressTypes = MeasurementConstants.getAllDressTypes().where((dressType) {
          final dressTypeDetails = MeasurementConstants.getDressTypeDetails(dressType);
          final name = dressTypeDetails?['name'] ?? dressType;
          final description = dressTypeDetails?['description'] ?? '';
          
          return name.toLowerCase().contains(query.toLowerCase()) ||
                 description.toLowerCase().contains(query.toLowerCase()) ||
                 dressType.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _selectDressType(String dressType) {
    // Navigate to add measurement screen with selected dress type
    context.goNamed(
      RouteNames.addMeasurement,
      pathParameters: {'customerId': widget.customerId},
      queryParameters: {'dressType': dressType},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}