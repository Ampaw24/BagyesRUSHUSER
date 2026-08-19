import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/operational_details_data.dart';

/// Step 3 - Cuisine types.
/// Delivery radius, store hours/operating days/prep time are collected later during KYC.
class OperationalDetailsStep extends StatefulWidget {
  final OperationalDetailsData data;
  final ValueChanged<OperationalDetailsData> onChanged;
  final List<CategoryElement> availableCategories;
  final bool isLoadingCategories;
  final String? categoriesError;
  final VoidCallback? onRetryCategories;

  const OperationalDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
    required this.availableCategories,
    this.isLoadingCategories = false,
    this.categoriesError,
    this.onRetryCategories,
  });

  @override
  State<OperationalDetailsStep> createState() => _OperationalDetailsStepState();
}

class _OperationalDetailsStepState extends State<OperationalDetailsStep> {
  late List<String> _cuisineTypes;

  @override
  void initState() {
    super.initState();
    _syncFromData(widget.data);
  }

  @override
  void didUpdateWidget(OperationalDetailsStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-sync if data was changed externally (e.g. VM reset),
    // not from our own _emit calls.
    if (widget.data != oldWidget.data || widget.availableCategories != oldWidget.availableCategories) {
      _syncFromData(widget.data);
    }
  }

  void _syncFromData(OperationalDetailsData data) {
    _cuisineTypes = data.cuisineTypes.map((item) {
      // If the item matches an ID in availableCategories, convert it to the name.
      // This handles the transition from ID-based to name-based storage.
      try {
        final cat = widget.availableCategories.firstWhere((c) => c.id == item);
        return cat.name.toLowerCase();
      } catch (_) {
        return item;
      }
    }).toSet().toList();
  }

  void _emit() {
    widget.onChanged(widget.data.copyWith(cuisineTypes: _cuisineTypes));
  }

  bool _isKnownCategory(String cuisine) {
    return widget.availableCategories.any((c) => c.name.toLowerCase() == cuisine);
  }

  void _toggleCategory(String apiValue) {
    setState(() {
      _cuisineTypes.contains(apiValue)
          ? _cuisineTypes.remove(apiValue)
          : _cuisineTypes.add(apiValue);
    });
    _emit();
  }

  void _removeCustomCuisine(String cuisine) {
    setState(() => _cuisineTypes.remove(cuisine));
    _emit();
  }

  Future<void> _showAddCustomCuisineSheet() async {
    final controller = TextEditingController();
    final size = MediaQuery.of(context).size;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            size.width * 0.06,
            size.height * 0.015,
            size.width * 0.06,
            size.height * 0.03,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: size.width * 0.1,
                  height: size.height * 0.005,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                'What else do you cook?',
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Waakye, Shawarma',
                ),
                onSubmitted: (value) => Navigator.pop(sheetContext, value),
              ),
              SizedBox(height: size.height * 0.02),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext, controller.text),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final cuisine = result?.trim().toLowerCase();
    if (cuisine != null && cuisine.isNotEmpty && !_cuisineTypes.contains(cuisine)) {
      setState(() => _cuisineTypes.add(cuisine));
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final customCuisines = _cuisineTypes.where((c) => !_isKnownCategory(c)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - size.width * 0.03) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What do you serve?',
                        style: TextStyle(
                          fontSize: size.width * 0.052,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: size.height * 0.004),
                      Text(
                        'Pick every category that applies',
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: size.width * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: size.height * 0.007,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size.width * 0.05),
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    '${_cuisineTypes.length} chosen',
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.02),

            // ── Category Grid ──
            if (widget.isLoadingCategories)
              Padding(
                padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (widget.categoriesError != null)
              _FetchErrorTile(
                message: widget.categoriesError!,
                onRetry: widget.onRetryCategories,
                size: size,
              )
            else
              Wrap(
                spacing: size.width * 0.03,
                runSpacing: size.width * 0.03,
                children: widget.availableCategories.map((category) {
                  final apiValue = category.name.toLowerCase();
                  final isSelected = _cuisineTypes.contains(apiValue);
                  return SizedBox(
                    width: cardWidth,
                    child: _CategoryCard(
                      title: category.name,
                      subtitle: category.description,
                      isSelected: isSelected,
                      size: size,
                      onTap: () => _toggleCategory(apiValue),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: size.height * 0.02),

            // ── Add custom cuisine ──
            DottedBorder(
              borderType: BorderType.RRect,
              radius: Radius.circular(size.width * 0.04),
              dashPattern: const [6, 4],
              strokeWidth: 1.2,
              color: AppColors.border,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size.width * 0.04),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAddCustomCuisineSheet,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.height * 0.015,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: size.width * 0.07,
                            height: size.width * 0.07,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceVariant,
                            ),
                            child: Icon(
                              Icons.add,
                              size: size.width * 0.045,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: size.width * 0.03),
                          Text(
                            'Something else you cook',
                            style: TextStyle(
                              fontSize: size.width * 0.034,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Custom cuisines the user typed in ──
            if (customCuisines.isNotEmpty) ...[
              SizedBox(height: size.height * 0.015),
              Wrap(
                spacing: size.width * 0.02,
                runSpacing: size.height * 0.008,
                children: customCuisines.map((cuisine) {
                  return Chip(
                    label: Text(
                      cuisine,
                      style: TextStyle(
                        fontSize: size.width * 0.03,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    deleteIcon: Icon(
                      Icons.close_rounded,
                      size: size.width * 0.04,
                      color: AppColors.primary,
                    ),
                    onDeleted: () => _removeCustomCuisine(cuisine),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final Size size;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.width * 0.045),
          color: isSelected ? AppColors.textPrimary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: size.width * 0.038,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ),
                SizedBox(width: size.width * 0.02),
                Container(
                  width: size.width * 0.055,
                  height: size.width * 0.055,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: size.width * 0.035,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: size.height * 0.015),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: size.width * 0.028,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
