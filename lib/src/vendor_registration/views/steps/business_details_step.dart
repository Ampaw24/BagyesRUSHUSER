import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constant/app_theme.dart';
import '../../models/vendor_enums.dart';
import '../../models/business_details_data.dart';
import '../widgets/vendor_text_field.dart';

/// Step 1 - Collects business name, type, contact, location
class BusinessDetailsStep extends StatefulWidget {
  final BusinessDetailsData data;
  final ValueChanged<BusinessDetailsData> onChanged;

  const BusinessDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<BusinessDetailsStep> createState() => _BusinessDetailsStepState();
}

class _BusinessDetailsStepState extends State<BusinessDetailsStep> {
  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data.businessName);
    _contactCtrl = TextEditingController(text: widget.data.contactPersonName);
    _phoneCtrl = TextEditingController(text: widget.data.phone);
    _emailCtrl = TextEditingController(text: widget.data.email);
    _addressCtrl = TextEditingController(text: widget.data.businessAddress);
    _cityCtrl = TextEditingController(text: widget.data.city);
    _descriptionCtrl = TextEditingController(text: widget.data.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.data.copyWith(
        businessName: _nameCtrl.text,
        contactPersonName: _contactCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        businessAddress: _addressCtrl.text,
        city: _cityCtrl.text,
        description: _descriptionCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Name
        VendorTextField(
          label: 'Business Name',
          hint: 'e.g. Mama\'s Kitchen',
          controller: _nameCtrl,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: size.height * 0.022),

        // Business Type dropdown
        Text(
          'Business Type',
          style: TextStyle(
            fontSize: size.width * 0.034,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.height * 0.008),
        _BusinessTypeSelector(
          selected: widget.data.businessType,
          onChanged: (type) {
            widget.onChanged(widget.data.copyWith(businessType: type));
          },
        ),
        SizedBox(height: size.height * 0.022),

        // Contact Person Name
        VendorTextField(
          label: 'Contact Person Name',
          hint: 'Full name of owner or manager',
          controller: _contactCtrl,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: size.height * 0.022),

        // Phone
        VendorTextField(
          label: 'Phone Number',
          hint: '024 123 4567',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _emit(),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: size.width * 0.04),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+233',
                  style: TextStyle(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: size.width * 0.02),
                Container(
                  width: 1,
                  height: size.height * 0.025,
                  color: AppColors.border,
                ),
                SizedBox(width: size.width * 0.02),
              ],
            ),
          ),
        ),
        SizedBox(height: size.height * 0.022),

        // Email
        VendorTextField(
          label: 'Email Address',
          hint: 'business@example.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: size.height * 0.022),

        // Business Address
        VendorTextField(
          label: 'Business Address',
          hint: 'Street address or landmark',
          controller: _addressCtrl,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: size.height * 0.022),

        // City
        VendorTextField(
          label: 'City',
          hint: 'e.g. Accra',
          controller: _cityCtrl,
          onChanged: (_) => _emit(),
        ),
        SizedBox(height: size.height * 0.022),

        // Description (optional)
        VendorTextField(
          label: 'Business Description (optional)',
          hint: 'Tell customers what makes your food special...',
          controller: _descriptionCtrl,
          maxLines: 3,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}

/// Horizontal scrollable chips for business type selection
class _BusinessTypeSelector extends StatelessWidget {
  final BusinessType? selected;
  final ValueChanged<BusinessType> onChanged;

  const _BusinessTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Wrap(
      spacing: size.width * 0.02,
      runSpacing: size.height * 0.01,
      children: BusinessType.values.map((type) {
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.01,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.06),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              type.label,
              style: TextStyle(
                fontSize: size.width * 0.032,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
