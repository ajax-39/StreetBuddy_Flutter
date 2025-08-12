import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:street_buddy/provider/MainScreen/business_info_provider.dart';
import 'package:street_buddy/utils/styles.dart';

class AddBusinessScreen extends StatefulWidget {
  const AddBusinessScreen({Key? key}) : super(key: key);

  @override
  State<AddBusinessScreen> createState() => _AddBusinessScreenState();
}

class _AddBusinessScreenState extends State<AddBusinessScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusinessInfoProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Add Your Business',
            style: AppTypography.subtitle.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Consumer<BusinessInfoProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBusinessInformationSection(provider),
                        const SizedBox(height: 24),
                        _buildLocationDetailsSection(provider),
                        const SizedBox(height: 24),
                        _buildBusinessDescriptionSection(provider),
                        const SizedBox(height: 24),
                        _buildUploadPhotosSection(provider),
                        const SizedBox(height: 24),
                        _buildContactInformationSection(provider),
                        const SizedBox(height: 24),
                        _buildSocialMediaSection(provider),
                        const SizedBox(height: 24),
                        _buildBusinessHoursSection(provider),
                        const SizedBox(height: 24),
                        _buildTermsSection(),
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
                if (provider.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade50,
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<BusinessInfoProvider>(
          builder: (context, provider, child) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: FloatingActionButton.extended(
                onPressed:
                    provider.isLoading ? null : () => _submitForm(provider),
                backgroundColor: AppColors.primary,
                label: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit for Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildBusinessInformationSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Information',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.businessNameController,
          label: 'Business Name *',
          hint: 'Give your guide a catchy title.',
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Business Category *',
          hint: 'Select street food, cafes, shopping...',
          value: provider.selectedCategory,
          items: provider.categories,
          onChanged: provider.setSelectedCategory,
        ),
      ],
    );
  }

  Widget _buildLocationDetailsSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Details',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'State *',
          hint: 'Select state',
          value: provider.selectedState,
          items: provider.states,
          onChanged: provider.setSelectedState,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'City *',
          hint: 'Select city',
          value: provider.selectedCity,
          items: provider.getCitiesForState(provider.selectedState),
          onChanged: provider.setSelectedCity,
          enabled: provider.selectedState != null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.addressController,
          label: 'Address *',
          hint: 'Enter street address',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildSetLocationButton(),
      ],
    );
  }

  Widget _buildBusinessDescriptionSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Description *',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.descriptionController,
          label: 'Business Description *',
          hint: 'Describe your business',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildUploadPhotosSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Photos & Logo',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: provider.pickImages,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: provider.selectedImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: provider.selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              provider.selectedImages[index],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => provider.removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInformationSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.phoneController,
          label: 'Phone Number *',
          hint: '(555) 000-0000',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.emailController,
          label: 'Email *',
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.websiteController,
          label: 'Website (Optional)',
          hint: 'Enter website URL',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: provider.instagramController,
          label: 'Instagram',
          hint: 'Instagram username',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.facebookController,
          label: 'Facebook',
          hint: 'Facebook page URL',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: provider.twitterController,
          label: 'Twitter',
          hint: 'Twitter handle',
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection(BusinessInfoProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Hours',
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...provider.businessHours.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key,
                    style: AppTypography.body,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          value: entry.value['from']!,
                          onChanged: (time) => provider.updateBusinessHours(
                              entry.key, 'from', time),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to'),
                      ),
                      Expanded(
                        child: _buildTimeField(
                          value: entry.value['to']!,
                          onChanged: (time) => provider.updateBusinessHours(
                              entry.key, 'to', time),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I confirm that I am the owner or authorized representative of this business.',
              style: AppTypography.caption.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String value,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(value.split(':')[0]),
            minute: int.parse(value.split(':')[1]),
          ),
        );

        if (pickedTime != null) {
          final formattedTime =
              '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
          onChanged(formattedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _buildSetLocationButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement map picker functionality
        debugPrint(
            '🗺️ Set Location button tapped - Map picker not implemented yet');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map location picker - Coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Set Location',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm(BusinessInfoProvider provider) async {
    debugPrint('📝 Submit form button pressed');
    await provider.submitBusinessInfo();

    if (provider.error == null && context.mounted) {
      debugPrint('✅ Form submitted successfully, showing success message');
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business information submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (provider.error != null && context.mounted) {
      debugPrint('❌ Form submission failed: ${provider.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
