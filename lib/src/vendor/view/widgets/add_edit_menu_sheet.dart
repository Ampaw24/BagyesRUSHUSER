import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../../constant/app_theme.dart';
import '../../model/menu_item.dart';
import '../../viewmodel/menu_viewmodel.dart';

const _categories = [
  'Meals',
  'Sides',
  'Drinks',
  'Snacks',
  'Desserts',
  'Breakfast',
  'Specials',
];

const _allTags = [
  'Spicy',
  'Vegan',
  'Vegetarian',
  'Gluten-Free',
  'Bestseller',
  'New',
  'Seasonal',
];

class AddEditMenuSheet extends StatefulWidget {
  final MenuItem? item;

  const AddEditMenuSheet({super.key, this.item});

  static Future<void> show(BuildContext context, {MenuItem? item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditMenuSheet(item: item),
    );
  }

  @override
  State<AddEditMenuSheet> createState() => _AddEditMenuSheetState();
}

class _AddEditMenuSheetState extends State<AddEditMenuSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = _categories.first;
  List<String> _selectedTags = [];
  int _prepTime = 15;
  bool _isFeatured = false;
  bool _isAvailable = true;
  bool _isOutOfStock = false;
  XFile? _pickedImage;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text =
          item.price.replaceAll(RegExp(r'[^\d.]'), '');
      _descriptionController.text = item.description;
      _selectedCategory = _categories.contains(item.category)
          ? item.category
          : _categories.first;
      _selectedTags = List<String>.from(item.tags);
      _prepTime = item.prepTimeMinutes;
      _isFeatured = item.isFeatured;
      _isAvailable = item.isAvailable;
      _isOutOfStock = item.isOutOfStock;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final w = MediaQuery.sizeOf(ctx).width;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
          ),
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.01,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(w * 0.005),
                ),
              ),
              SizedBox(height: w * 0.05),
              Text(
                'Select Photo',
                style: TextStyle(
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: w * 0.04),
              _SourceOption(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              SizedBox(height: w * 0.03),
              _SourceOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null) return;

    final picked = await ImagePicker().pickImage(
      source: choice,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'price': _priceController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'tags': _selectedTags,
      'prep_time_minutes': _prepTime,
      'is_featured': _isFeatured,
      'is_available': _isAvailable,
      'is_out_of_stock': _isOutOfStock,
      if (_pickedImage != null) 'local_image_path': _pickedImage!.path,
      if (_isEditing && _pickedImage == null && widget.item?.imageUrl != null)
        'image_url': widget.item!.imageUrl,
    };

    final vm = context.read<MenuViewModel>();
    if (_isEditing) {
      await vm.updateItem(widget.item!.id, data);
    } else {
      await vm.addItem(data);
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
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
          // ── Header ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.04,
              w * 0.05,
              w * 0.01,
            ),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Edit Item' : 'Add New Item',
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
                    decoration: BoxDecoration(
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
          // ── Scrollable form ──
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
                    // ── Photo upload ──
                    _SectionLabel(label: 'Photo', w: w),
                    SizedBox(height: w * 0.025),
                    GestureDetector(
                      onTap: _pickImage,
                      child: _ImageUploadArea(
                        pickedImage: _pickedImage,
                        existingUrl: widget.item?.imageUrl,
                        w: w,
                      ),
                    ),
                    SizedBox(height: w * 0.05),

                    // ── Name ──
                    _SectionLabel(label: 'Item Name *', w: w),
                    SizedBox(height: w * 0.02),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: w * 0.038),
                      decoration: InputDecoration(
                        hintText: 'e.g. Jollof Rice & Chicken',
                        prefixIcon: Icon(
                          Icons.fastfood_rounded,
                          size: w * 0.05,
                          color: AppColors.textHint,
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Item name is required'
                              : null,
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Category ──
                    _SectionLabel(label: 'Category *', w: w),
                    SizedBox(height: w * 0.02),
                    _CategorySelector(
                      selected: _selectedCategory,
                      onChanged: (c) =>
                          setState(() => _selectedCategory = c),
                      w: w,
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Price + Prep time ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(label: 'Price (₦) *', w: w),
                              SizedBox(height: w * 0.02),
                              TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]'),
                                  ),
                                ],
                                style: TextStyle(fontSize: w * 0.038),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w * 0.03,
                                    ),
                                    child: Text(
                                      '₦',
                                      style: TextStyle(
                                        fontSize: w * 0.042,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints:
                                      const BoxConstraints(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(v) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: w * 0.04),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(label: 'Prep Time', w: w),
                              SizedBox(height: w * 0.02),
                              _PrepTimeStepper(
                                value: _prepTime,
                                onChanged: (v) =>
                                    setState(() => _prepTime = v),
                                w: w,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Description ──
                    _SectionLabel(label: 'Description', w: w),
                    SizedBox(height: w * 0.02),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: TextStyle(fontSize: w * 0.038),
                      decoration: const InputDecoration(
                        hintText:
                            'Describe the dish, ingredients, special notes…',
                        alignLabelWithHint: true,
                      ),
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Dietary Tags ──
                    _SectionLabel(label: 'Dietary & Labels', w: w),
                    SizedBox(height: w * 0.02),
                    Wrap(
                      spacing: w * 0.02,
                      runSpacing: w * 0.02,
                      children: _allTags.map((tag) {
                        final selected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: selected,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                          selectedColor: AppColors.primary
                              .withValues(alpha: 0.12),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: w * 0.032,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Toggles ──
                    _ToggleRow(
                      icon: Icons.star_rounded,
                      iconColor: AppColors.accent,
                      label: 'Featured / Daily Special',
                      subtitle: 'Pin to top of your menu',
                      value: _isFeatured,
                      onChanged: (v) =>
                          setState(() => _isFeatured = v),
                      w: w,
                    ),
                    SizedBox(height: w * 0.025),
                    _ToggleRow(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.success,
                      label: 'Available for Order',
                      subtitle: 'Customers can order this item',
                      value: _isAvailable,
                      onChanged: (v) =>
                          setState(() => _isAvailable = v),
                      w: w,
                    ),
                    SizedBox(height: w * 0.025),
                    _ToggleRow(
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.warning,
                      label: 'Mark as Out of Stock',
                      subtitle: 'Temporarily hide from customers',
                      value: _isOutOfStock,
                      onChanged: (v) =>
                          setState(() => _isOutOfStock = v),
                      w: w,
                    ),
                    SizedBox(height: w * 0.06),

                    // ── Save button ──
                    Consumer<MenuViewModel>(
                      builder: (context, vm, _) {
                        final isBusy =
                            vm.state.pendingOperation != null;
                        return SizedBox(
                          width: double.infinity,
                          height: w * 0.135,
                          child: ElevatedButton(
                            onPressed:
                                isBusy ? null : () => _save(context),
                            child: isBusy
                                ? SizedBox(
                                    width: w * 0.055,
                                    height: w * 0.055,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isEditing
                                        ? 'Save Changes'
                                        : 'Add to Menu',
                                    style: TextStyle(
                                      fontSize: w * 0.042,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        );
                      },
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
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final double w;

  const _SectionLabel({required this.label, required this.w});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: w * 0.035,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ImageUploadArea extends StatelessWidget {
  final XFile? pickedImage;
  final String? existingUrl;
  final double w;

  const _ImageUploadArea({
    required this.pickedImage,
    required this.existingUrl,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedImage != null || existingUrl != null;

    return Container(
      height: w * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(
          color: hasImage ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          width: hasImage ? 1.5 : 1,
          style: hasImage ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (pickedImage != null)
                  Image.file(
                    File(pickedImage!.path),
                    fit: BoxFit.cover,
                  )
                else if (existingUrl != null)
                  Image.network(
                    existingUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        _emptyState(w),
                  ),
                // Change photo overlay
                Positioned(
                  bottom: w * 0.03,
                  right: w * 0.03,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * 0.03,
                      vertical: w * 0.015,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(w * 0.02),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: w * 0.035,
                          color: Colors.white,
                        ),
                        SizedBox(width: w * 0.015),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: w * 0.03,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _emptyState(w),
    );
  }

  Widget _emptyState(double w) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: w * 0.08,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: w * 0.03),
        Text(
          'Upload Food Photo',
          style: TextStyle(
            fontSize: w * 0.038,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.01),
        Text(
          'Tap to choose from gallery or camera',
          style: TextStyle(
            fontSize: w * 0.03,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final double w;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = cat == selected;
          return Padding(
            padding: EdgeInsets.only(right: w * 0.02),
            child: GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: w * 0.025,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.025),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrepTimeStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double w;

  const _PrepTimeStepper({
    required this.value,
    required this.onChanged,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: w * 0.13,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StepBtn(
            icon: Icons.remove,
            onTap: () {
              if (value > 5) onChanged(value - 5);
            },
            w: w,
          ),
          Expanded(
            child: Text(
              '${value}m',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            onTap: () => onChanged(value + 5),
            w: w,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double w;

  const _StepBtn({
    required this.icon,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.1,
        alignment: Alignment.center,
        child: Icon(icon, size: w * 0.045, color: AppColors.primary),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double w;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.04,
        vertical: w * 0.03,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.02),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: Icon(icon, size: w * 0.045, color: iconColor),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: w * 0.028,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: iconColor,
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: w * 0.055, color: AppColors.primary),
            SizedBox(width: w * 0.04),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
