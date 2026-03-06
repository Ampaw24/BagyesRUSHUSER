import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/vendor_enums.dart';
import '../../models/operational_details_data.dart';

/// Step 3 - Cuisine types, delivery radius, operating hours/days
class OperationalDetailsStep extends StatelessWidget {
  final OperationalDetailsData data;
  final ValueChanged<OperationalDetailsData> onChanged;

  const OperationalDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  static const _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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
        Wrap(
          spacing: size.width * 0.02,
          runSpacing: size.height * 0.008,
          children: CuisineType.values.map((cuisine) {
            final isSelected = data.cuisineTypes.contains(cuisine);
            return GestureDetector(
              onTap: () {
                final updated = List<CuisineType>.from(data.cuisineTypes);
                isSelected ? updated.remove(cuisine) : updated.add(cuisine);
                onChanged(data.copyWith(cuisineTypes: updated));
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
                  cuisine.label,
                  style: TextStyle(
                    fontSize: size.width * 0.03,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
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
                '${data.deliveryRadiusKm.toStringAsFixed(1)} km',
                key: ValueKey(data.deliveryRadiusKm),
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
            value: data.deliveryRadiusKm,
            min: 1,
            max: 30,
            divisions: 58,
            onChanged: (val) {
              onChanged(data.copyWith(deliveryRadiusKm: val));
            },
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
                time: data.openingTime,
                onTap: () => _pickTime(context, data.openingTime, (t) {
                  onChanged(data.copyWith(openingTime: t));
                }),
              ),
            ),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: _TimePickerTile(
                label: 'Closes',
                time: data.closingTime,
                onTap: () => _pickTime(context, data.closingTime, (t) {
                  onChanged(data.copyWith(closingTime: t));
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
                '${data.estimatedPrepTimeMinutes} min',
                key: ValueKey(data.estimatedPrepTimeMinutes),
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
            value: data.estimatedPrepTimeMinutes.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            onChanged: (val) {
              onChanged(data.copyWith(estimatedPrepTimeMinutes: val.round()));
            },
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
            final isSelected = data.operatingDays.contains(day);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(data.operatingDays);
                isSelected ? updated.remove(day) : updated.add(day);
                onChanged(data.copyWith(operatingDays: updated));
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onPicked,
  ) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onPicked('$h:$m');
    }
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
            Icon(
              Icons.access_time_rounded,
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
