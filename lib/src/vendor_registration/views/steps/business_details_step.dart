import 'package:bagyesrushappusernew/constant/config.dart';
import 'package:bagyesrushappusernew/src/auth/models/business_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../constant/app_theme.dart';
import '../../models/business_details_data.dart';
import '../widgets/vendor_text_field.dart';

/// Step 1 - Collects business name, type, contact, location
class BusinessDetailsStep extends StatefulWidget {
  final BusinessDetailsData data;
  final ValueChanged<BusinessDetailsData> onChanged;
  final List<BusinessTypeModel> businessTypes;
  final bool isLoadingBusinessTypes;
  final String? businessTypesError;
  final VoidCallback? onRetryBusinessTypes;

  const BusinessDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
    this.businessTypes = const [],
    this.isLoadingBusinessTypes = false,
    this.businessTypesError,
    this.onRetryBusinessTypes,
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
  late TextEditingController _tinCtrl;

  late FocusNode _nameFocus;
  late FocusNode _contactFocus;
  late FocusNode _phoneFocus;
  late FocusNode _emailFocus;
  late FocusNode _addressFocus;
  late FocusNode _cityFocus;
  late FocusNode _descriptionFocus;
  late FocusNode _tinFocus;

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
    _tinCtrl = TextEditingController(text: widget.data.taxIdentificationNumber ?? '');

    _nameFocus = FocusNode()..addListener(() { if (!_nameFocus.hasFocus) _emit(); });
    _contactFocus = FocusNode()..addListener(() { if (!_contactFocus.hasFocus) _emit(); });
    _phoneFocus = FocusNode()..addListener(() { if (!_phoneFocus.hasFocus) _emit(); });
    _emailFocus = FocusNode()..addListener(() { if (!_emailFocus.hasFocus) _emit(); });
    _addressFocus = FocusNode()..addListener(() { if (!_addressFocus.hasFocus) _emit(); });
    _cityFocus = FocusNode()..addListener(() { if (!_cityFocus.hasFocus) _emit(); });
    _descriptionFocus = FocusNode()..addListener(() { if (!_descriptionFocus.hasFocus) _emit(); });
    _tinFocus = FocusNode()..addListener(() { if (!_tinFocus.hasFocus) _emit(); });
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
    _tinCtrl.dispose();

    _nameFocus.dispose();
    _contactFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _descriptionFocus.dispose();
    _tinFocus.dispose();

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
        taxIdentificationNumber: _tinCtrl.text,
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
          focusNode: _nameFocus,
        ),
        SizedBox(height: size.height * 0.022),

        // Business Type
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
          businessTypes: widget.businessTypes,
          isLoading: widget.isLoadingBusinessTypes,
          error: widget.businessTypesError,
          onRetry: widget.onRetryBusinessTypes,
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
          focusNode: _contactFocus,
        ),
        SizedBox(height: size.height * 0.022),

        // Phone
        VendorTextField(
          label: 'Phone Number',
          hint: '024 123 4567',
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _NoLeadingZeroFormatter(),
          ],
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: size.width * 0.04),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Config.defaultCountryCode,
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
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: size.height * 0.022),

        // Business Address
        VendorTextField(
          label: 'Business Address',
          hint: 'Street address or landmark',
          controller: _addressCtrl,
          focusNode: _addressFocus,
        ),
        SizedBox(height: size.height * 0.022),

        // City
        VendorTextField(
          label: 'City',
          hint: 'e.g. Accra',
          controller: _cityCtrl,
          focusNode: _cityFocus,
        ),
        SizedBox(height: size.height * 0.022),

        // Description (optional)
        VendorTextField(
          label: 'Business Description (optional)',
          hint: 'Tell customers what makes your food special...',
          controller: _descriptionCtrl,
          focusNode: _descriptionFocus,
          maxLines: 3,
        ),
        SizedBox(height: size.height * 0.022),

        // Tax Identification Number (optional)
        VendorTextField(
          label: 'Tax Identification Number (optional)',
          hint: 'e.g. GH-123456-789',
          controller: _tinCtrl,
          focusNode: _tinFocus,
        ),
      ],
    );
  }
}

// StatefulWidget so selection is reflected immediately via local state,
// independent of whether the parent rebuild cycle has fired.
class _BusinessTypeSelector extends StatefulWidget {
  final BusinessTypeModel? selected;
  final List<BusinessTypeModel> businessTypes;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<BusinessTypeModel> onChanged;

  const _BusinessTypeSelector({
    required this.selected,
    required this.businessTypes,
    required this.isLoading,
    required this.onChanged,
    this.error,
    this.onRetry,
  });

  @override
  State<_BusinessTypeSelector> createState() => _BusinessTypeSelectorState();
}

class _BusinessTypeSelectorState extends State<_BusinessTypeSelector> {
  late BusinessTypeModel? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  void didUpdateWidget(_BusinessTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _selected = widget.selected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (widget.isLoading) {
      return SizedBox(
        height: size.height * 0.04,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (widget.error != null) {
      return _FetchErrorTile(
        message: widget.error!,
        onRetry: widget.onRetry,
        size: size,
      );
    }

    if (widget.businessTypes.isEmpty) {
      return Text(
        'No business types available',
        style: TextStyle(
          fontSize: size.width * 0.032,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Wrap(
      spacing: size.width * 0.02,
      runSpacing: size.height * 0.01,
      children: widget.businessTypes.map((type) {
        final isSelected = _selected?.id == type.id;
        return GestureDetector(
          onTap: () {
            setState(() => _selected = type);
            widget.onChanged(type);
          },
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
              type.name,
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

class _FetchErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Size size;

  const _FetchErrorTile({
    required this.message,
    required this.size,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.012,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(size.width * 0.025),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.error, size: size.width * 0.045),
          SizedBox(width: size.width * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: size.width * 0.03,
                color: AppColors.error,
              ),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: size.width * 0.02),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.03,
                  vertical: size.height * 0.006,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: size.width * 0.028,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) return oldValue;
    return newValue;
  }
}
