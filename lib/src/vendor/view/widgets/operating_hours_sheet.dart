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

  late Map<String, DayHours> _weeklyHours;
  late List<String> _operatingDays;

  @override
  void initState() {
    super.initState();
    _weeklyHours = Map<String, DayHours>.from(widget.profile.weeklyHours);
    _operatingDays = List<String>.from(widget.profile.operatingDays);

    // Initialize any missing days
    for (final day in _days) {
      _weeklyHours.putIfAbsent(
        day,
        () => DayHours(
          open: widget.profile.openingTime,
          close: widget.profile.closingTime,
          isClosed: !_operatingDays.contains(day),
        ),
      );
    }
  }

  Future<TimeOfDay?> _pickTime(String currentTime) async {
    final parts = currentTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
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
    final operatingDays = <String>[];
    for (final day in _days) {
      if (!(_weeklyHours[day]?.isClosed ?? true)) {
        operatingDays.add(day);
      }
    }

    final updated = widget.profile.copyWith(
      weeklyHours: _weeklyHours,
      operatingDays: operatingDays,
      openingTime: _weeklyHours[_days.first]?.open ?? '08:00',
      closingTime: _weeklyHours[_days.first]?.close ?? '22:00',
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

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
              'Set when your shop is open for each day',
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: w * 0.02),
          const Divider(),
          // Days list
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.04),
              itemCount: _days.length,
              separatorBuilder: (_, _) => SizedBox(height: w * 0.02),
              itemBuilder: (context, index) {
                final day = _days[index];
                final hours = _weeklyHours[day]!;
                final isToday = DateTime.now().weekday - 1 == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.all(w * 0.035),
                  decoration: BoxDecoration(
                    color: hours.isClosed
                        ? AppColors.surfaceVariant.withValues(alpha: 0.5)
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(w * 0.035),
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.border,
                      width: isToday ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  _dayLabels[day]!,
                                  style: TextStyle(
                                    fontSize: w * 0.038,
                                    fontWeight: FontWeight.w600,
                                    color: hours.isClosed
                                        ? AppColors.textHint
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (isToday) ...[
                                  SizedBox(width: w * 0.02),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: w * 0.015,
                                      vertical: w * 0.005,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius:
                                          BorderRadius.circular(w * 0.01),
                                    ),
                                    child: Text(
                                      'TODAY',
                                      style: TextStyle(
                                        fontSize: w * 0.02,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Open/Closed toggle
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _weeklyHours[day] = hours.copyWith(
                                  isClosed: !hours.isClosed,
                                );
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.025,
                                vertical: w * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color: hours.isClosed
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(w * 0.04),
                              ),
                              child: Text(
                                hours.isClosed ? 'Closed' : 'Open',
                                style: TextStyle(
                                  fontSize: w * 0.028,
                                  fontWeight: FontWeight.w700,
                                  color: hours.isClosed
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Time pickers (shown only when open)
                      if (!hours.isClosed) ...[
                        SizedBox(height: w * 0.03),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerTile(
                                label: 'Opens',
                                time: hours.open,
                                onTap: () async {
                                  final picked = await _pickTime(hours.open);
                                  if (picked != null) {
                                    setState(() {
                                      _weeklyHours[day] = hours.copyWith(
                                        open: _formatTimeOfDay(picked),
                                      );
                                    });
                                  }
                                },
                                w: w,
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: w * 0.03),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                color: AppColors.textHint,
                                size: w * 0.04,
                              ),
                            ),
                            Expanded(
                              child: _TimePickerTile(
                                label: 'Closes',
                                time: hours.close,
                                onTap: () async {
                                  final picked = await _pickTime(hours.close);
                                  if (picked != null) {
                                    setState(() {
                                      _weeklyHours[day] = hours.copyWith(
                                        close: _formatTimeOfDay(picked),
                                      );
                                    });
                                  }
                                },
                                w: w,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
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
