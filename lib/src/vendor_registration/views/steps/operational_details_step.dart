import 'package:bagyesrushappusernew/src/home/models/category_element.model.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';
import '../../models/operational_details_data.dart';

/// Step 3 - Cuisine types, delivery radius, operating hours/days
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
  static const _allDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  late List<String> _cuisineTypes;
  late List<String> _operatingDays;
  late double _deliveryRadiusKm;
  late String _openingTime;
  late String _closingTime;
  late int _estimatedPrepTimeMinutes;

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
    if (widget.data != oldWidget.data) {
      _syncFromData(widget.data);
    }
  }

  void _syncFromData(OperationalDetailsData data) {
    _cuisineTypes = List<String>.from(data.cuisineTypes);
    _operatingDays = List<String>.from(data.operatingDays);
    _deliveryRadiusKm = data.deliveryRadiusKm;
    _openingTime = data.openingTime;
    _closingTime = data.closingTime;
    _estimatedPrepTimeMinutes = data.estimatedPrepTimeMinutes;
  }

  void _emit() {
    widget.onChanged(
      widget.data.copyWith(
        cuisineTypes: _cuisineTypes,
        operatingDays: _operatingDays,
        deliveryRadiusKm: _deliveryRadiusKm,
        openingTime: _openingTime,
        closingTime: _closingTime,
        estimatedPrepTimeMinutes: _estimatedPrepTimeMinutes,
      ),
    );
  }

  Future<void> _pickTime(String currentTime, ValueChanged<String> onPicked) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onPicked('$h:$m');
    }
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
              final apiValue = category.name;
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
                key: ValueKey(_deliveryRadiusKm),
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
            onChanged: (val) => setState(() => _deliveryRadiusKm = val),
            onChangeEnd: (_) => _emit(),
          ),
        ),

        SizedBox(height: size.height * 0.02),

        // ── Operating Hours ──
        Text(
          'Operating Hours',
          style: TextStyle(
            fontSize: size.width * 0.034,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.height * 0.012),
        Row(
          children: [
            Expanded(
              child: _TimePickerTile(
                label: 'Opens',
                time: _openingTime,
                onTap: () => _pickTime(_openingTime, (t) {
                  setState(() => _openingTime = t);
                  _emit();
                }),
              ),
            ),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: _TimePickerTile(
                label: 'Closes',
                time: _closingTime,
                onTap: () => _pickTime(_closingTime, (t) {
                  setState(() => _closingTime = t);
                  _emit();
                }),
              ),
            ),
          ],
        ),

        SizedBox(height: size.height * 0.025),

        // ── Estimated Prep Time ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estimated Prep Time',
              style: TextStyle(
                fontSize: size.width * 0.034,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$_estimatedPrepTimeMinutes min',
                key: ValueKey(_estimatedPrepTimeMinutes),
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
            value: _estimatedPrepTimeMinutes.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            onChanged: (val) => setState(() => _estimatedPrepTimeMinutes = val.round()),
            onChangeEnd: (_) => _emit(),
          ),
        ),

        SizedBox(height: size.height * 0.02),

        // ── Operating Days ──
        Text(
          'Operating Days',
          style: TextStyle(
            fontSize: size.width * 0.034,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.height * 0.012),
        Wrap(
          spacing: size.width * 0.02,
          runSpacing: size.height * 0.008,
          children: _allDays.map((day) {
            final isSelected = _operatingDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected
                      ? _operatingDays.remove(day)
                      : _operatingDays.add(day);
                });
                _emit();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.03,
                  vertical: size.height * 0.009,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  day.substring(0, 3),
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

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.016,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          color: AppColors.surfaceVariant,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedClock01,
              color: AppColors.primary,
              size: size.width * 0.05,
            ),
            SizedBox(width: size.width * 0.02),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: size.width * 0.028,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: size.width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
