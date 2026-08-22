import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constant/app_theme.dart';
import '../../../features/consumer/restaurant/domain/entities/addon.dart';
import '../../home/models/category_element.model.dart';
import '../model/menu_item.dart';
import '../../orders/viewmodels/orders_viewmodel.dart';
import '../../orders/viewmodels/orders_state.dart';

const _stepTitles = ['Basic Info', 'Details', 'Photo'];

// TODO: replace with a vendor-scoped addon-options endpoint once available —
// options are currently a fixed dropdown so vendors can't free-type values.
const _dummyAddonOptions = [
  'Egg',
  'Boiled Egg',
  'Fried Egg',
  'Chicken',
  'Beef',
  'Goat Meat',
  'Fish',
  'Turkey',
  'Sausage',
  'Cheese',
  'Extra Cheese',
  'Avocado',
  'Coleslaw',
  'Extra Sauce',
  'Plantain',
  'Salad',
];

class AddEditMenuView extends StatefulWidget {
  final MenuItem? item;

  const AddEditMenuView({super.key, this.item});

  static Future<void> show(BuildContext context, {MenuItem? item}) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditMenuView(item: item)));
  }

  @override
  State<AddEditMenuView> createState() => _AddEditMenuViewState();
}

class _AddEditMenuViewState extends State<AddEditMenuView> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  bool _isFeatured = false;
  bool _isAvailable = true;
  XFile? _pickedImage;

  /// Set once the item is actually created on the backend (right after the
  /// Details step, for new items) so the Photo step has a real id to
  /// upload against. Always non-null while editing, since [widget.item]
  /// already has one.
  MenuItem? _createdItem;

  // Addon state
  List<AddonGroup> _addonGroups = [];
  int _minimumOrderQty = 1;
  int? _maximumOrderQty;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final vm = context.read<OrderViewModel>();
    final state = vm.state is MenuLoadedState
        ? vm.state as MenuLoadedState
        : const MenuLoadedState();
    final categoryOptions = state.categoryOptions;

    final item = widget.item;
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text = item.price.replaceAll(RegExp(r'[^\d.]'), '');
      _descriptionController.text = item.description;
      final match = categoryOptions
          .where((c) => c.name == item.category)
          .toList();
      _selectedCategoryId = match.isNotEmpty
          ? match.first.id
          : (categoryOptions.isNotEmpty ? categoryOptions.first.id : null);
      _isFeatured = item.isFeatured;
      _isAvailable = item.isAvailable;
      _addonGroups = List<AddonGroup>.from(item.addonGroups);
      _minimumOrderQty = item.minimumOrderQty;
      _maximumOrderQty = item.maximumOrderQty;
    } else {
      _selectedCategoryId = categoryOptions.isNotEmpty
          ? categoryOptions.first.id
          : null;
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

  /// Strips client-generated placeholder ids (`grp_…`/`opt_…`, assigned
  /// locally to brand-new, not-yet-persisted addon groups/options so the UI
  /// has something to key off of) before sending to the backend — an id
  /// there should only ever reference a real, already-persisted record.
  List<Map<String, dynamic>> _buildAddonGroupsPayload() {
    return _addonGroups.map((g) {
      final json = Map<String, dynamic>.from(g.toJson());
      if ((json['id'] as String).startsWith('grp_')) json.remove('id');
      json['options'] = (json['options'] as List).map((o) {
        final optJson = Map<String, dynamic>.from(o as Map);
        if ((optJson['id'] as String).startsWith('opt_')) {
          optJson.remove('id');
        }
        return optJson;
      }).toList();
      return json;
    }).toList();
  }

  Map<String, dynamic> _buildItemData() {
    return {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'category_id': int.tryParse(_selectedCategoryId!) ?? _selectedCategoryId,
      'is_available': _isAvailable,
      'is_featured': _isFeatured,
      'minimum_order_qty': _minimumOrderQty,
      if (_maximumOrderQty != null) 'maximum_order_qty': _maximumOrderQty,
      'addon_groups': _buildAddonGroupsPayload(),
    };
  }

  String _errorMessageFrom(OrderViewModel vm) {
    final state = vm.state;
    return state is MenuLoadedState
        ? state.errorMessage ?? 'Something went wrong. Please try again.'
        : 'Something went wrong. Please try again.';
  }

  /// The backend rejects any addon group with zero options, so an empty
  /// group left over from tapping "Add Addon Group" without ever adding an
  /// option must be caught here — otherwise it only surfaces as a 422 after
  /// the request round-trips.
  bool _validateAddonGroups() {
    if (_addonGroups.every((g) => g.options.isNotEmpty)) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Each addon group needs at least one option. Add one or remove the empty group.',
        ),
      ),
    );
    return false;
  }

  /// Final step action. Editing updates the existing item (and its image,
  /// if a new one was picked) in one call. Creating a new item only
  /// uploads the photo here — the item itself was already persisted when
  /// leaving the Details step, via [_goNext].
  Future<void> _save(BuildContext context) async {
    final vm = context.read<OrderViewModel>();

    if (_isEditing) {
      if (!_validateAddonGroups()) return;

      final success = await vm.updateItem(
        widget.item!.id,
        _buildItemData(),
        imagePath: _pickedImage?.path,
      );

      if (!context.mounted) return;

      if (success) {
        Navigator.of(context).pop();
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessageFrom(vm))));
      return;
    }

    if (_pickedImage != null) {
      final success = await vm.uploadItemImage(
        _createdItem!.id,
        _pickedImage!.path,
      );

      if (!context.mounted) return;

      if (!success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessageFrom(vm))));
        return;
      }
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _goNext() async {
    // Only step 0 carries required fields — validate before advancing so a
    // blank name/price or missing category can't be skipped past.
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      setState(() => _currentStep += 1);
      return;
    }

    if (_currentStep == 1) {
      // Leaving Details for a brand-new item: create it now so the Photo
      // step has a real id to upload against. A failed create keeps the
      // user on this step — they never reach the upload screen unless
      // the item itself was persisted successfully. Editing already has
      // an id, so nothing to create here.
      if (!_isEditing && _createdItem == null) {
        if (!_validateAddonGroups()) return;

        final vm = context.read<OrderViewModel>();
        final created = await vm.addItem(_buildItemData());

        if (!mounted) return;

        if (created == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessageFrom(vm))));
          return;
        }
        _createdItem = created;
      }
      setState(() => _currentStep += 1);
      return;
    }
  }

  void _goBack() {
    setState(() => _currentStep -= 1);
  }

  void _showAddGroupDialog() {
    showModalBottomSheet<AddonGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddAddonGroupSheet(),
    ).then((group) {
      if (group != null) {
        setState(() => _addonGroups.add(group));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            size: w * 0.06,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          _isEditing ? 'Edit Menu Item' : 'Add Menu Item',
          style: TextStyle(
            fontSize: w * 0.05,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.03,
                w * 0.05,
                w * 0.03,
              ),
              child: _StepDots(currentStep: _currentStep, w: w),
            ),
            const Divider(height: 1),
            // ── Scrollable form ──
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  w * 0.05,
                  w * 0.04,
                  w * 0.05,
                  w * 0.04,
                ),
                child: Form(
                  key: _formKey,
                  child: switch (_currentStep) {
                    0 => _buildBasicInfoStep(w),
                    1 => _buildDetailsStep(w),
                    _ => _buildPhotoStep(w),
                  },
                ),
              ),
            ),
            // ── Bottom nav ──
            Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.03,
                w * 0.05,
                w * 0.03,
              ),
              child: _buildBottomNav(context, w),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
        ),
        SizedBox(height: w * 0.04),

        // ── Category ──
        _SectionLabel(label: 'Category *', w: w),
        SizedBox(height: w * 0.02),
        Consumer<OrderViewModel>(
          builder: (context, vm, _) {
            final state = vm.state is MenuLoadedState
                ? vm.state as MenuLoadedState
                : const MenuLoadedState();
            final categoryOptions = state.categoryOptions;
            if (categoryOptions.isEmpty) {
              return Text(
                'No categories available yet.',
                style: TextStyle(
                  fontSize: w * 0.033,
                  color: AppColors.textHint,
                ),
              );
            }
            return _CategorySelector(
              categories: categoryOptions,
              selectedId: _selectedCategoryId,
              onChanged: (id) => setState(() => _selectedCategoryId = id),
              w: w,
            );
          },
        ),
        SizedBox(height: w * 0.04),

        // ── Price ──
        _SectionLabel(label: 'Price (GH₵) *', w: w),
        SizedBox(height: w * 0.02),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: TextStyle(fontSize: w * 0.038),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.03),
              child: Text(
                '₵',
                style: TextStyle(
                  fontSize: w * 0.042,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
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
        SizedBox(height: w * 0.04),

        // ── Description ──
        _SectionLabel(label: 'Description', w: w),
        SizedBox(height: w * 0.02),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          style: TextStyle(fontSize: w * 0.038),
          decoration: const InputDecoration(
            hintText: 'Describe the dish, ingredients, special notes…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Order Quantity Limits ──
        _SectionLabel(label: 'Order Quantity Limits', w: w),
        SizedBox(height: w * 0.02),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Qty',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: w * 0.015),
                  _PrepTimeStepper(
                    value: _minimumOrderQty,
                    step: 1,
                    minValue: 1,
                    unit: '',
                    onChanged: (v) => setState(() => _minimumOrderQty = v),
                    w: w,
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Qty (optional)',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: w * 0.015),
                  TextFormField(
                    initialValue: _maximumOrderQty?.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontSize: w * 0.038),
                    decoration: InputDecoration(
                      hintText: '—',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
                        vertical: w * 0.035,
                      ),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      setState(() => _maximumOrderQty = parsed);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: w * 0.04),

        // ── Addons ──
        Row(
          children: [
            Expanded(
              child: _SectionLabel(label: 'Addons', w: w),
            ),
            if (_addonGroups.isNotEmpty)
              Text(
                '${_addonGroups.length} group${_addonGroups.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: w * 0.03, color: AppColors.textHint),
              ),
          ],
        ),
        SizedBox(height: w * 0.02),

        // Addon group editors
        ..._addonGroups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: w * 0.03),
            child: _AddonGroupEditor(
              group: group,
              onChanged: (updated) =>
                  setState(() => _addonGroups[index] = updated),
              onDelete: () => setState(() => _addonGroups.removeAt(index)),
              w: w,
            ),
          );
        }),

        // Add group button
        OutlinedButton.icon(
          onPressed: _showAddGroupDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Addon Group'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(w * 0.025),
            ),
            minimumSize: Size(double.infinity, w * 0.12),
          ),
        ),
        SizedBox(height: w * 0.04),

        // ── Toggles ──
        _ToggleRow(
          icon: Icons.star_rounded,
          iconColor: AppColors.accent,
          label: 'Featured / Daily Special',
          subtitle: 'Pin to top of your menu',
          value: _isFeatured,
          onChanged: (v) => setState(() => _isFeatured = v),
          w: w,
        ),
        SizedBox(height: w * 0.025),
        _ToggleRow(
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          label: 'Available for Order',
          subtitle: 'Customers can order this item',
          value: _isAvailable,
          onChanged: (v) => setState(() => _isAvailable = v),
          w: w,
        ),
      ],
    );
  }

  Widget _buildPhotoStep(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, double w) {
    return Consumer<OrderViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        final isBusy =
            state is MenuLoadedState && state.pendingOperation != null;
        final isLastStep = _currentStep == _stepTitles.length - 1;

        final actionButton = SizedBox(
          width: double.infinity,
          height: w * 0.135,
          child: ElevatedButton(
            onPressed: isBusy
                ? null
                : () => isLastStep ? _save(context) : _goNext(),
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
                    isLastStep
                        ? (_isEditing ? 'Save Changes' : 'Finish')
                        : (!_isEditing && _currentStep == 1
                              ? 'Create Item'
                              : 'Next'),
                    style: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );

        if (_currentStep == 0) return actionButton;

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: w * 0.135,
                child: OutlinedButton(
                  onPressed: isBusy ? null : _goBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: w * 0.042,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(flex: 2, child: actionButton),
          ],
        );
      },
    );
  }
}

// ── Addon Group Editor ────────────────────────────────────────────────────────

class _AddonGroupEditor extends StatefulWidget {
  final AddonGroup group;
  final ValueChanged<AddonGroup> onChanged;
  final VoidCallback onDelete;
  final double w;

  const _AddonGroupEditor({
    required this.group,
    required this.onChanged,
    required this.onDelete,
    required this.w,
  });

  @override
  State<_AddonGroupEditor> createState() => _AddonGroupEditorState();
}

class _AddonGroupEditorState extends State<_AddonGroupEditor> {
  bool _expanded = true;

  void _addOption() {
    final used = widget.group.options.map((o) => o.name).toSet();
    final name = _dummyAddonOptions.firstWhere(
      (o) => !used.contains(o),
      orElse: () => _dummyAddonOptions.first,
    );
    final newOption = AddonOption(
      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      additionalPrice: 0,
    );
    widget.onChanged(
      widget.group.copyWith(options: [...widget.group.options, newOption]),
    );
  }

  void _updateOption(int index, AddonOption updated) {
    final options = List<AddonOption>.from(widget.group.options);
    options[index] = updated;
    widget.onChanged(widget.group.copyWith(options: options));
  }

  void _removeOption(int index) {
    final options = List<AddonOption>.from(widget.group.options)
      ..removeAt(index);
    widget.onChanged(widget.group.copyWith(options: options));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(w * 0.03),
              bottom: _expanded ? Radius.zero : Radius.circular(w * 0.03),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: w * 0.03,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name.isEmpty
                              ? 'Unnamed Group'
                              : widget.group.name,
                          style: TextStyle(
                            fontSize: w * 0.036,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: w * 0.005),
                        Row(
                          children: [
                            if (widget.group.isRequired)
                              _GroupBadge(
                                label: 'Required',
                                color: AppColors.primary,
                                w: w,
                              ),
                            if (widget.group.isRequired)
                              SizedBox(width: w * 0.015),
                            _GroupBadge(
                              label: widget.group.maxSelections == 1
                                  ? 'Single choice'
                                  : 'Up to ${widget.group.maxSelections}',
                              color: AppColors.textSecondary,
                              w: w,
                            ),
                            SizedBox(width: w * 0.015),
                            Text(
                              '${widget.group.options.length} option${widget.group.options.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: w * 0.028,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: w * 0.05,
                    ),
                    onPressed: widget.onDelete,
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: w * 0.05,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(height: 1, color: AppColors.border),

            // Option rows
            ...widget.group.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final usedByOthers = widget.group.options
                  .where((o) => o != opt)
                  .map((o) => o.name)
                  .toSet();
              return _OptionRow(
                option: opt,
                usedNames: usedByOthers,
                onChanged: (updated) => _updateOption(idx, updated),
                onDelete: () => _removeOption(idx),
                w: w,
              );
            }),

            // Add option button
            TextButton.icon(
              onPressed: _addOption,
              icon: Icon(Icons.add, size: w * 0.04),
              label: Text('Add Option', style: TextStyle(fontSize: w * 0.033)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: w * 0.025,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double w;

  const _GroupBadge({
    required this.label,
    required this.color,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.015, vertical: w * 0.003),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: w * 0.026,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  final AddonOption option;
  final Set<String> usedNames;
  final ValueChanged<AddonOption> onChanged;
  final VoidCallback onDelete;
  final double w;

  const _OptionRow({
    required this.option,
    required this.usedNames,
    required this.onChanged,
    required this.onDelete,
    required this.w,
  });

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.option.additionalPrice > 0
          ? widget.option.additionalPrice.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _emitPrice() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    widget.onChanged(widget.option.copyWith(additionalPrice: price));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.02, w * 0.025, w * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<String>(
              initialValue: widget.option.name.isNotEmpty
                  ? widget.option.name
                  : null,
              isExpanded: true,
              style: TextStyle(
                fontSize: w * 0.034,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Select option',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.02,
                ),
                isDense: true,
              ),
              items: _dummyAddonOptions
                  .where(
                    (o) =>
                        o == widget.option.name ||
                        !widget.usedNames.contains(o),
                  )
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                widget.onChanged(widget.option.copyWith(name: v));
              },
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _priceCtrl,
              onChanged: (_) => _emitPrice(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: TextStyle(fontSize: w * 0.034),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: 'GH₵ ',
                prefixStyle: TextStyle(
                  fontSize: w * 0.03,
                  color: AppColors.textSecondary,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.025,
                ),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.error,
              size: w * 0.045,
            ),
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Add Addon Group Sheet ─────────────────────────────────────────────────────

/// One in-progress option row while the vendor is building a new addon
/// group — never persisted directly, converted to an [AddonOption] on
/// submit.
class _OptionDraft {
  String name;
  double price = 0;
  _OptionDraft({required this.name});
}

class _AddAddonGroupSheet extends StatefulWidget {
  const _AddAddonGroupSheet();

  @override
  State<_AddAddonGroupSheet> createState() => _AddAddonGroupSheetState();
}

class _AddAddonGroupSheetState extends State<_AddAddonGroupSheet> {
  final _nameCtrl = TextEditingController();
  bool _isRequired = false;
  int _maxSelections = 1;
  final List<_OptionDraft> _options = [];

  @override
  void initState() {
    super.initState();
    // Start with one option ready to go — options are dropdown-only, so
    // there's always a valid default rather than an empty/unselected row.
    _addOptionDraft();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addOptionDraft() {
    final used = _options.map((o) => o.name).toSet();
    final next = _dummyAddonOptions.firstWhere(
      (o) => !used.contains(o),
      orElse: () => _dummyAddonOptions.first,
    );
    setState(() => _options.add(_OptionDraft(name: next)));
  }

  void _removeOptionDraft(int index) {
    setState(() => _options.removeAt(index));
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Group name is required')));
      return;
    }
    if (_options.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one option')));
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    Navigator.of(context).pop(
      AddonGroup(
        id: 'grp_$timestamp',
        name: name,
        isRequired: _isRequired,
        minSelections: _isRequired ? 1 : 0,
        maxSelections: _maxSelections,
        options: _options
            .asMap()
            .entries
            .map(
              (e) => AddonOption(
                id: 'opt_${timestamp}_${e.key}',
                name: e.value.name,
                additionalPrice: e.value.price,
              ),
            )
            .toList(),
      ),
    );
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
                  'New Addon Group',
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
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                w * 0.05,
                w * 0.04,
                w * 0.05,
                w * 0.04,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Group Name *', w: w),
                  SizedBox(height: w * 0.02),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(fontSize: w * 0.038),
                    decoration: InputDecoration(
                      hintText: 'e.g. Choose Protein',
                      prefixIcon: Icon(
                        Icons.tune_rounded,
                        size: w * 0.05,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  SizedBox(height: w * 0.04),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel(label: 'Max Selections', w: w),
                            SizedBox(height: w * 0.02),
                            _PrepTimeStepper(
                              value: _maxSelections,
                              step: 1,
                              minValue: 1,
                              unit: '',
                              onChanged: (v) =>
                                  setState(() => _maxSelections = v),
                              w: w,
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: w * 0.04),
                      Expanded(
                        child: _ToggleRow(
                          icon: Icons.priority_high_rounded,
                          iconColor: AppColors.primary,
                          label: 'Required',
                          subtitle: 'Customer must choose',
                          value: _isRequired,
                          onChanged: (v) => setState(() => _isRequired = v),
                          w: w,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.05),

                  Row(
                    children: [
                      Expanded(
                        child: _SectionLabel(label: 'Options *', w: w),
                      ),
                      Text(
                        '${_options.length} added',
                        style: TextStyle(
                          fontSize: w * 0.03,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.025),

                  ..._options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final draft = entry.value;
                    final usedByOthers = _options
                        .where((o) => o != draft)
                        .map((o) => o.name)
                        .toSet();
                    return Padding(
                      padding: EdgeInsets.only(bottom: w * 0.03),
                      child: _OptionDraftRow(
                        draft: draft,
                        usedNames: usedByOthers,
                        onNameChanged: (name) =>
                            setState(() => draft.name = name),
                        onPriceChanged: (price) =>
                            setState(() => draft.price = price),
                        onDelete: () => _removeOptionDraft(index),
                        w: w,
                      ),
                    );
                  }),

                  OutlinedButton.icon(
                    onPressed: _addOptionDraft,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Option'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.025),
                      ),
                      minimumSize: Size(double.infinity, w * 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.03,
              w * 0.05,
              bottomInset + w * 0.04,
            ),
            child: SizedBox(
              width: double.infinity,
              height: w * 0.135,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(
                  'Create Group',
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionDraftRow extends StatefulWidget {
  final _OptionDraft draft;
  final Set<String> usedNames;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<double> onPriceChanged;
  final VoidCallback onDelete;
  final double w;

  const _OptionDraftRow({
    required this.draft,
    required this.usedNames,
    required this.onNameChanged,
    required this.onPriceChanged,
    required this.onDelete,
    required this.w,
  });

  @override
  State<_OptionDraftRow> createState() => _OptionDraftRowState();
}

class _OptionDraftRowState extends State<_OptionDraftRow> {
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.draft.price > 0 ? widget.draft.price.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    return Container(
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<String>(
              initialValue: widget.draft.name,
              isExpanded: true,
              style: TextStyle(
                fontSize: w * 0.034,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.02,
                ),
              ),
              items: _dummyAddonOptions
                  .where(
                    (o) =>
                        o == widget.draft.name || !widget.usedNames.contains(o),
                  )
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) widget.onNameChanged(v);
              },
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _priceCtrl,
              onChanged: (v) =>
                  widget.onPriceChanged(double.tryParse(v.trim()) ?? 0.0),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: TextStyle(fontSize: w * 0.034),
              decoration: InputDecoration(
                hintText: '0.00',
                filled: true,
                fillColor: Colors.white,
                prefixText: 'GH₵ ',
                prefixStyle: TextStyle(
                  fontSize: w * 0.03,
                  color: AppColors.textSecondary,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.02,
                ),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: AppColors.error,
              size: w * 0.045,
            ),
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int currentStep;
  final double w;

  const _StepDots({required this.currentStep, required this.w});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_stepTitles.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStep = i ~/ 2;
          final isDone = leftStep < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.symmetric(horizontal: w * 0.015),
              color: isDone ? AppColors.primary : AppColors.border,
            ),
          );
        }

        final step = i ~/ 2;
        final isActive = step == currentStep;
        final isDone = step < currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: w * 0.075,
              height: w * 0.075,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                border: Border.all(
                  color: isActive || isDone
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: isDone
                  ? Icon(
                      Icons.check_rounded,
                      size: w * 0.04,
                      color: Colors.white,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
            ),
            SizedBox(height: w * 0.012),
            Text(
              _stepTitles[step],
              style: TextStyle(
                fontSize: w * 0.026,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

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
          color: hasImage
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: hasImage ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (pickedImage != null)
                  Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                else if (existingUrl != null)
                  Image.network(
                    existingUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _emptyState(w),
                  ),
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
          style: TextStyle(fontSize: w * 0.03, color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<CategoryElement> categories;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final double w;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat.id == selectedId;
          return Padding(
            padding: EdgeInsets.only(right: w * 0.02),
            child: GestureDetector(
              onTap: () => onChanged(cat.id),
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
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
  final int step;
  final int minValue;
  final String unit;
  final double? width;

  const _PrepTimeStepper({
    required this.value,
    required this.onChanged,
    required this.w,
    this.step = 5,
    this.minValue = 5,
    this.unit = 'm',
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
              if (value > minValue) onChanged(value - step);
            },
            w: w,
          ),
          Expanded(
            child: Text(
              '$value$unit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add, onTap: () => onChanged(value + step), w: w),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double w;

  const _StepBtn({required this.icon, required this.onTap, required this.w});

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
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
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
