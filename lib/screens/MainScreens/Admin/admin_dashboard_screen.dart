import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:street_buddy/models/vendor.dart';
import 'package:street_buddy/utils/styles.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('vendors')
            .stream(primaryKey: ['id'])
            .eq('is_approved', false)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final vendors = snapshot.data ?? [];

          if (vendors.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending vendor approvals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All vendors have been reviewed',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendorData = vendors[index];
              final vendor = VendorModel.fromJson(vendorData['id'], vendorData);
              return _buildVendorCard(vendor);
            },
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(VendorModel vendor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images Carousel
          if (vendor.photoUrl != null && vendor.photoUrl!.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: vendor.photoUrl!.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: vendor.photoUrl![index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Name
                Text(
                  vendor.name ?? 'Unknown Business',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Category
                if (vendor.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      vendor.category!,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Location
                if (vendor.address != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${vendor.address}, ${vendor.city}, ${vendor.state}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Contact Info
                if (vendor.phoneNumber != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20),
                      const SizedBox(width: 8),
                      Text(vendor.phoneNumber!),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                if (vendor.email != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.email, size: 20),
                      const SizedBox(width: 8),
                      Text(vendor.email!),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Business Description
                if (vendor.businessDescription != null &&
                    vendor.businessDescription!.isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor.businessDescription!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],

                // Opening Hours
                if (vendor.openingHours != null &&
                    vendor.openingHours!.isNotEmpty) ...[
                  const Text(
                    'Opening Hours:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...vendor.openingHours!.map((hours) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(hours.day ?? ''),
                            Text('${hours.opensat} - ${hours.closesat}'),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Questions and Answers
                if (vendor.placedata != null &&
                    vendor.placedata!.isNotEmpty) ...[
                  const Text(
                    'Additional Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...vendor.placedata!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${index + 1}. ${data.ques ?? 'Unknown Question'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A: ${data.ans ?? 'No answer provided'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading ? null : () => _denyVendor(vendor),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text(
                          'Deny',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading ? null : () => _approveVendor(vendor),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Approve',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _denyVendor(VendorModel vendor) async {
    setState(() => _isLoading = true);

    try {
      await _supabase
          .from('vendors')
          .update({'is_approved': false}).eq('id', vendor.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vendor.name} has been denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error denying vendor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveVendor(VendorModel vendor) async {
    setState(() => _isLoading = true);

    try {
      // First, update the vendor as approved
      await _supabase
          .from('vendors')
          .update({'is_approved': true}).eq('id', vendor.id!);

      // Then, create the place entry in the places table
      // Generate a unique ID for the place with pcustom_ prefix
      final placeId =
          'pcustom_${vendor.name?.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}_${DateTime.now().millisecondsSinceEpoch}';

      final placeData = {
        'id': placeId,
        'name': vendor.name ?? '',
        'name_lowercase': vendor.name?.toLowerCase() ?? '',
        'vicinity': vendor.address ?? '',
        'description': vendor.businessDescription ?? '',
        'media_urls':
            vendor.photoUrl?.isNotEmpty == true ? vendor.photoUrl! : [],
        'city': vendor.city ?? '',
        'state': vendor.state ?? '',
        'types': vendor.category != null ? [vendor.category] : [],
        'phone_number': vendor.phoneNumber ?? '',
        'opening_hours': vendor.openingHours
                ?.map((h) => {
                      'day': h.day ?? '',
                      'opensat': h.opensat ?? '',
                      'closesat': h.closesat ?? '',
                    })
                .toList() ??
            [],
        'cached_at': DateTime.now().toIso8601String(),
        'is_hidden_gem': false,
        'custom_rating': 0.0,
        'rating': 0.0,
        'latitude': 0.0, // You may want to add coordinates to vendor model
        'longitude': 0.0,
        'tips': '',
        'extras': '',
        'price_range': {},
      };

      await _supabase.from('places').insert(placeData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${vendor.name} has been approved and added to places'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving vendor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
