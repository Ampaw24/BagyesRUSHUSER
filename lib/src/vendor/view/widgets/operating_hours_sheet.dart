import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../constant/app_theme.dart';
import '../../model/vendor_profile.dart';

class OperatingHoursSheet extends StatefulWidget {
  final VendorProfile profile;
  final ValueChanged<VendorProfile> onSave;

  const OperatingHoursSheet({
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
      builder: (_) => OperatingHoursSheet(profile: profile, onSave: onSave),
    );
  }

  @override
  State<OperatingHoursSheet> createState() => _OperatingHoursSheetState();
}

class _OperatingHoursSheetState extends State<OperatingHoursSheet> {
  static const _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  static const _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  // The backend stores a single opening/closing time shared by every
  // operating day — not per-day hours — so the sheet edits exactly that:
  // one time range plus which days it applies to.
  late String _openingTime;
  late String _closingTime;
  late List<String> _operatingDays;

  @override
  void initState() {
    super.initState();
    _openingTime = widget.profile.openingTime;
    _closingTime = widget.profile.closingTime;
    _operatingDays = List<String>.from(widget.profile.operatingDays);
  }

  Future<TimeOfDay?> _pickTime(String currentTime) async {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        // Clamp text scaling: an inflated system font scale can push the
        // picker's intrinsic height past its dialog constraints, producing
        // an invalid (minHeight > maxHeight) BoxConstraints at layout time.
        final clampedScaler = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                  ),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _save() {
    final updated = widget.profile.copyWith(
      openingTime: _openingTime,
      closingTime: _closingTime,
      operatingDays: _operatingDays,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final today = _days[DateTime.now().weekday - 1];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
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
            padding:
                EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.01),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: AppColors.primary,
                  size: w * 0.055,
                ),
                SizedBox(width: w * 0.02),
                Text(
                  'Operating Hours',
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: Text(
              'One set of hours applies to every day you\'re open',
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: w * 0.02),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(label: 'Hours', w: w),
                  SizedBox(height: w * 0.03),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerTile(
                          label: 'Opens',
                          time: _openingTime,
                          onTap: () async {
                            final picked = await _pickTime(_openingTime);
                            if (picked != null) {
                              setState(
                                () => _openingTime = _formatTimeOfDay(picked),
                              );
                            }
                          },
                          w: w,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: AppColors.textHint,
                          size: w * 0.04,
                        ),
                      ),
                      Expanded(
                        child: _TimePickerTile(
                          label: 'Closes',
                          time: _closingTime,
                          onTap: () async {
                            final picked = await _pickTime(_closingTime);
                            if (picked != null) {
                              setState(
                                () => _closingTime = _formatTimeOfDay(picked),
                              );
                            }
                          },
                          w: w,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.06),
                  _SectionHeader(label: 'Open Days', w: w),
                  SizedBox(height: w * 0.03),
                  Wrap(
                    spacing: w * 0.025,
                    runSpacing: w * 0.025,
                    children: _days.map((day) {
                      final isOpen = _operatingDays.contains(day);
                      final isToday = day == today;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isOpen) {
                              _operatingDays.remove(day);
                            } else {
                              _operatingDays.add(day);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.035,
                            vertical: w * 0.022,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(w * 0.03),
                            border: isToday
                                ? Border.all(
                                    color: isOpen
                                        ? Colors.white
                                        : AppColors.primary,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Text(
                            _dayLabels[day]!,
                            style: TextStyle(
                              fontSize: w * 0.033,
                              fontWeight: FontWeight.w600,
                              color: isOpen
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.02,
              w * 0.05,
              MediaQuery.viewPaddingOf(context).bottom + w * 0.04,
            ),
            child: SizedBox(
              width: double.infinity,
              height: w * 0.135,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  'Save Hours',
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

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  final double w;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.03,
          vertical: w * 0.025,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.025),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.024,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: w * 0.008),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  color: AppColors.primary,
                  size: w * 0.04,
                ),
                SizedBox(width: w * 0.015),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
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
