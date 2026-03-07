import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../constant/app_theme.dart';
import '../../model/vendor_profile.dart';

const _availableCuisines = [
  'Ghanaian',
  'West African',
  'Nigerian',
  'Grills',
  'Chinese',
  'Indian',
  'Italian',
  'Fast Food',
  'Seafood',
  'Vegan',
  'Bakery',
  'Beverages',
  'Desserts',
  'Healthy',
  'Continental',
];

class EditShopInfoSheet extends StatefulWidget {
  final VendorProfile profile;
  final ValueChanged<VendorProfile> onSave;

  const EditShopInfoSheet({
    super.key,
    required this.profile,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required VendorProfile profile,
    required ValueChanged<VendorProfile> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditShopInfoSheet(profile: profile, onSave: onSave),
    );
  }

  @override
  State<EditShopInfoSheet> createState() => _EditShopInfoSheetState();
}

class _EditShopInfoSheetState extends State<EditShopInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _facebookCtrl;
  late final TextEditingController _tiktokCtrl;
  late final TextEditingController _websiteCtrl;
  late List<String> _selectedCuisines;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.businessName);
    _descCtrl = TextEditingController(text: p.description ?? '');
    _ownerCtrl = TextEditingController(text: p.ownerName);
    _phoneCtrl = TextEditingController(text: p.phone);
    _emailCtrl = TextEditingController(text: p.email);
    _addressCtrl = TextEditingController(text: p.address);
    _cityCtrl = TextEditingController(text: p.city);
    _instagramCtrl = TextEditingController(text: p.instagramUrl ?? '');
    _facebookCtrl = TextEditingController(text: p.facebookUrl ?? '');
    _tiktokCtrl = TextEditingController(text: p.tiktokUrl ?? '');
    _websiteCtrl = TextEditingController(text: p.websiteUrl ?? '');
    _selectedCuisines = List<String>.from(p.cuisineTypes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _tiktokCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.profile.copyWith(
      businessName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      ownerName: _ownerCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      cuisineTypes: _selectedCuisines,
      instagramUrl:
          _instagramCtrl.text.trim().isEmpty ? null : _instagramCtrl.text.trim(),
      facebookUrl:
          _facebookCtrl.text.trim().isEmpty ? null : _facebookCtrl.text.trim(),
      tiktokUrl:
          _tiktokCtrl.text.trim().isEmpty ? null : _tiktokCtrl.text.trim(),
      websiteUrl:
          _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: EdgeInsets.only(top: w * 0.035),
            child: Container(
              width: w * 0.1,
              height: w * 0.01,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(w * 0.005),
              ),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.01),
            child: Row(
              children: [
                Text(
                  'Edit Shop Info',
                  style: TextStyle(
                    fontSize: w * 0.05,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: w * 0.045,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.02,
                w * 0.05,
                bottomInset + w * 0.04,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ──
                    _SectionHeader(label: 'Basic Info', w: w),
                    SizedBox(height: w * 0.025),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Business Name *',
                      hint: 'e.g. Mama\'s Kitchen',
                      icon: HugeIcons.strokeRoundedStore01,
                      w: w,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _descCtrl,
                      label: 'Description',
                      hint: 'Tell customers about your shop...',
                      icon: HugeIcons.strokeRoundedTextAlignLeft01,
                      w: w,
                      maxLines: 4,
                    ),
                    SizedBox(height: w * 0.05),

                    // ── Contact Info ──
                    _SectionHeader(label: 'Contact', w: w),
                    SizedBox(height: w * 0.025),
                    _buildField(
                      controller: _ownerCtrl,
                      label: 'Owner Name *',
                      hint: 'Full name',
                      icon: HugeIcons.strokeRoundedUser,
                      w: w,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone *',
                      hint: '+233 XX XXX XXXX',
                      icon: HugeIcons.strokeRoundedCall,
                      w: w,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email *',
                      hint: 'your@email.com',
                      icon: HugeIcons.strokeRoundedMail01,
                      w: w,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: w * 0.05),

                    // ── Location ──
                    _SectionHeader(label: 'Location', w: w),
                    SizedBox(height: w * 0.025),
                    _buildField(
                      controller: _addressCtrl,
                      label: 'Address *',
                      hint: 'Street address',
                      icon: HugeIcons.strokeRoundedLocation01,
                      w: w,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _cityCtrl,
                      label: 'City *',
                      hint: 'e.g. Accra',
                      icon: HugeIcons.strokeRoundedBuilding01,
                      w: w,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: w * 0.05),

                    // ── Cuisine Types ──
                    _SectionHeader(label: 'Cuisine Types', w: w),
                    SizedBox(height: w * 0.025),
                    Wrap(
                      spacing: w * 0.02,
                      runSpacing: w * 0.02,
                      children: _availableCuisines.map((cuisine) {
                        final selected = _selectedCuisines.contains(cuisine);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedCuisines.remove(cuisine);
                              } else {
                                _selectedCuisines.add(cuisine);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.035,
                              vertical: w * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(w * 0.05),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              cuisine,
                              style: TextStyle(
                                fontSize: w * 0.03,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: w * 0.05),

                    // ── Social Links ──
                    _SectionHeader(label: 'Social Links', w: w),
                    SizedBox(height: w * 0.025),
                    _buildField(
                      controller: _instagramCtrl,
                      label: 'Instagram',
                      hint: 'username',
                      icon: HugeIcons.strokeRoundedInstagram,
                      w: w,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _facebookCtrl,
                      label: 'Facebook',
                      hint: 'page name or URL',
                      icon: HugeIcons.strokeRoundedFacebook01,
                      w: w,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _tiktokCtrl,
                      label: 'TikTok',
                      hint: 'username',
                      icon: HugeIcons.strokeRoundedTiktok,
                      w: w,
                    ),
                    SizedBox(height: w * 0.035),
                    _buildField(
                      controller: _websiteCtrl,
                      label: 'Website',
                      hint: 'https://...',
                      icon: HugeIcons.strokeRoundedGlobe02,
                      w: w,
                      keyboardType: TextInputType.url,
                    ),
                    SizedBox(height: w * 0.06),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: w * 0.135,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: w * 0.042,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<List<dynamic>> icon,
    required double w,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: w * 0.036),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1
                ? Padding(
                    padding: EdgeInsets.all(w * 0.03),
                    child: HugeIcon(
                      icon: icon,
                      color: AppColors.textHint,
                      size: w * 0.045,
                    ),
                  )
                : null,
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final double w;

  const _SectionHeader({required this.label, required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: w * 0.008,
          height: w * 0.04,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(w * 0.004),
          ),
        ),
        SizedBox(width: w * 0.02),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
