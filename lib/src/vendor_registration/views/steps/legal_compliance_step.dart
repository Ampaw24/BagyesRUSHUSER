import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/legal_compliance_data.dart';
import '../widgets/document_upload_card.dart';
import '../widgets/vendor_text_field.dart';

/// Step 2 - Upload legal/compliance documents
class LegalComplianceStep extends StatelessWidget {
  final LegalComplianceData data;
  final ValueChanged<LegalComplianceData> onChanged;

  const LegalComplianceStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  Future<void> _pickDocument(BuildContext context, String documentType) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    // Store local file path only — upload will happen on submission when APIs are ready
    switch (documentType) {
      case 'business_registration':
        onChanged(data.copyWith(businessRegistrationCertPath: file.path));
      case 'food_safety_license':
        onChanged(data.copyWith(foodSafetyLicensePath: file.path));
      case 'owner_id':
        onChanged(data.copyWith(ownerIdPath: file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: EdgeInsets.all(size.width * 0.035),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.03),
            color: const Color(0xFFFFF8E1),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFFF9A825),
                size: size.width * 0.055,
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Text(
                  'Documents help verify your business. You can upload images or scanned copies.',
                  style: TextStyle(
                    fontSize: size.width * 0.03,
                    color: const Color(0xFF5D4037),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size.height * 0.025),

        // Owner ID (required)
        DocumentUploadCard(
          title: 'Owner / Manager ID',
          description: 'National ID, Passport, or Driver\'s License',
          filePath: data.ownerIdPath,
          isRequired: true,
          isLoading: false,
          onTap: () => _pickDocument(context, 'owner_id'),
        ),
        SizedBox(height: size.height * 0.018),

        // Business Registration Certificate (optional)
        DocumentUploadCard(
          title: 'Business Registration Certificate',
          description: 'Company registration document',
          filePath: data.businessRegistrationCertPath,
          onTap: () => _pickDocument(context, 'business_registration'),
        ),
        SizedBox(height: size.height * 0.018),

        // Food Safety License (optional)
        DocumentUploadCard(
          title: 'Food Safety / Hygiene License',
          description: 'Health inspection or food handling permit',
          filePath: data.foodSafetyLicensePath,
          onTap: () => _pickDocument(context, 'food_safety_license'),
        ),
        SizedBox(height: size.height * 0.025),

        // Tax ID
        VendorTextField(
          label: 'Tax Identification Number (optional)',
          hint: 'TIN number',
          initialValue: data.taxIdentificationNumber,
          keyboardType: TextInputType.text,
          onChanged: (val) {
            onChanged(data.copyWith(taxIdentificationNumber: val));
          },
        ),
      ],
    );
  }
}
