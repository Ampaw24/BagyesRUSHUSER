import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/operational_details_data.dart';

/// Step 3 - Cuisine types, delivery radius.
/// Store hours/operating days/prep time are collected later during KYC.
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
  late double _deliveryRadiusKm;

  // Key to prevent "Duplicate keys found" error in AnimatedSwitcher
  // during rapid slider movements.
  Key _radiusKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _deliveryRadiusKm = -1; // Dummy to trigger key refresh on first sync
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

    if (_deliveryRadiusKm != data.deliveryRadiusKm) {
      _deliveryRadiusKm = data.deliveryRadiusKm;
      _radiusKey = UniqueKey();
    }
  }

  void _emit() {
    widget.onChanged(
      widget.data.copyWith(
        cuisineTypes: _cuisineTypes,
        deliveryRadiusKm: _deliveryRadiusKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cuisine Types ──
        Text(
          'Cuisine Types',
          style: TextStyle(
            fontSize: size.width * 0.034,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.height * 0.005),
        Text(
          'Select all that apply',
          style: TextStyle(
            fontSize: size.width * 0.03,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: size.height * 0.012),
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
            spacing: size.width * 0.02,
            runSpacing: size.height * 0.008,
            children: widget.availableCategories.map((category) {
              final apiValue = category.name.toLowerCase();
              final isSelected = _cuisineTypes.contains(apiValue);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected
                        ? _cuisineTypes.remove(apiValue)
                        : _cuisineTypes.add(apiValue);
                  });
                  _emit();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.035,
                    vertical: size.height * 0.009,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size.width * 0.05),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: size.width * 0.03,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        SizedBox(height: size.height * 0.03),

        // ── Delivery Radius ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Radius',
              style: TextStyle(
                fontSize: size.width * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '${_deliveryRadiusKm.toStringAsFixed(1)} km',
                key: _radiusKey,
                style: TextStyle(
                  fontSize: size.width * 0.034,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: size.height * 0.005,
          ),
          child: Slider(
            value: _deliveryRadiusKm,
            min: 1,
            max: 30,
            divisions: 58,
            onChanged: (val) {
              if (val != _deliveryRadiusKm) {
                setState(() {
                  _deliveryRadiusKm = val;
                  _radiusKey = UniqueKey();
                });
              }
            },
            onChangeEnd: (_) => _emit(),
          ),
        ),
        Text(
          'Set your delivery reach. A smaller radius ensures faster delivery and better food quality for your customers.',
          style: TextStyle(
            fontSize: size.width * 0.028,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),

      ],
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

