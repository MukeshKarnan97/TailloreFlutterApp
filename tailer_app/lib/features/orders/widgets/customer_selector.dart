import 'package:flutter/material.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/services/local_db_service.dart';
import '../../../core/utils/logger.dart';

class CustomerSelector extends StatelessWidget {
  final Customer? selectedCustomer;
  final Function(Customer?) onCustomerSelected;
  final bool enabled;

  const CustomerSelector({
    super.key,
    required this.selectedCustomer,
    required this.onCustomerSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Customer Selection Button
            InkWell(
              onTap: enabled ? () => _showCustomerSelection(context) : null,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: enabled ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: enabled ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCustomer?.name ?? 'Select Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: selectedCustomer != null ? FontWeight.w500 : FontWeight.normal,
                              color: selectedCustomer != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          if (selectedCustomer != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${selectedCustomer!.uniqueId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (selectedCustomer!.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Phone: ${selectedCustomer!.phone}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: enabled ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerSelection(BuildContext context) async {
    try {
      Logger.info('CustomerSelector', 'Loading customers for selection');
      
      final dbService = LocalDatabaseService();
      
      // Get all customers regardless of tailor ID for now
      // TODO: Update when proper authentication is implemented
      final allCustomerMaps = await dbService.select('customer', orderBy: 'name ASC');
      final customers = allCustomerMaps.map((map) => Customer.fromMap(map)).toList();
      
      Logger.info('CustomerSelector', 'Found ${customers.length} customers total');
      
      if (!context.mounted) return;
      
      if (customers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customers found. Please add customers first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final selectedCustomer = await showDialog<Customer>(
        context: context,
        builder: (context) => CustomerSelectionDialog(customers: customers),
      );

      if (selectedCustomer != null) {
        onCustomerSelected(selectedCustomer);
      }
    } catch (e, stackTrace) {
      Logger.error('CustomerSelector', 'Failed to load customers', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load customers. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CustomerSelectionDialog extends StatefulWidget {
  final List<Customer> customers;

  const CustomerSelectionDialog({
    super.key,
    required this.customers,
  });

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  String _searchQuery = '';
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredCustomers = widget.customers.where((customer) {
        final searchLower = query.toLowerCase();
        return customer.name.toLowerCase().contains(searchLower) ||
               customer.phone.toLowerCase().contains(searchLower) ||
               customer.uniqueId.toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Select Customer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search Field
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, or ID...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterCustomers,
            ),
            const SizedBox(height: 16),
            
            // Customer List
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No customers available'
                            : 'No customers found matching "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${customer.uniqueId}'),
                                if (customer.phone.isNotEmpty)
                                  Text('Phone: ${customer.phone}'),
                              ],
                            ),
                            onTap: () => Navigator.of(context).pop(customer),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}