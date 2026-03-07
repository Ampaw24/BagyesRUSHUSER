import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../constant/app_theme.dart';
import '../../model/vendor_profile.dart';

class DeliverySettingsSheet extends StatefulWidget {
  final VendorProfile profile;
  final ValueChanged<VendorProfile> onSave;

  const DeliverySettingsSheet({
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
      builder: (_) =>
          DeliverySettingsSheet(profile: profile, onSave: onSave),
    );
  }

  @override
  State<DeliverySettingsSheet> createState() => _DeliverySettingsSheetState();
}

class _DeliverySettingsSheetState extends State<DeliverySettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _estTimeCtrl;
  late bool _acceptsPreOrders;

  @override
  void initState() {
    super.initState();
    _radiusCtrl = TextEditingController(
      text: widget.profile.deliveryRadiusKm.toString(),
    );
    _minOrderCtrl = TextEditingController(
      text: widget.profile.minimumOrder.toStringAsFixed(2),
    );
    _deliveryFeeCtrl = TextEditingController(
      text: widget.profile.deliveryFee.toStringAsFixed(2),
    );
    _estTimeCtrl = TextEditingController(
      text: widget.profile.estimatedDeliveryTime,
    );
    _acceptsPreOrders = widget.profile.acceptsPreOrders;
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _minOrderCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _estTimeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.profile.copyWith(
      deliveryRadiusKm: double.tryParse(_radiusCtrl.text.trim()) ?? 5.0,
      minimumOrder: double.tryParse(_minOrderCtrl.text.trim()) ?? 0.0,
      deliveryFee: double.tryParse(_deliveryFeeCtrl.text.trim()) ?? 0.0,
      estimatedDeliveryTime: _estTimeCtrl.text.trim(),
      acceptsPreOrders: _acceptsPreOrders,
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
                  icon: HugeIcons.strokeRoundedDeliveryTruck01,
                  color: AppColors.primary,
                  size: w * 0.055,
                ),
                SizedBox(width: w * 0.02),
                Text(
                  'Delivery Settings',
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
                    // ── Delivery Radius ──
                    _SettingCard(
                      icon: HugeIcons.strokeRoundedMapsLocation01,
                      iconColor: AppColors.info,
                      title: 'Delivery Radius',
                      subtitle: 'Maximum distance you deliver to',
                      w: w,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _radiusCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]'),
                                ),
                              ],
                              style: TextStyle(
                                fontSize: w * 0.04,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: '5.0',
                                suffixText: 'km',
                                suffixStyle: TextStyle(
                                  fontSize: w * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
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
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Minimum Order ──
                    _SettingCard(
                      icon: HugeIcons.strokeRoundedMoneyBag01,
                      iconColor: AppColors.accent,
                      title: 'Minimum Order',
                      subtitle: 'Minimum amount for delivery orders',
                      w: w,
                      child: TextFormField(
                        controller: _minOrderCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.]'),
                          ),
                        ],
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'GH₵ ',
                          prefixStyle: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              double.tryParse(v) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Delivery Fee ──
                    _SettingCard(
                      icon: HugeIcons.strokeRoundedDeliveryTruck01,
                      iconColor: AppColors.success,
                      title: 'Delivery Fee',
                      subtitle: 'Standard delivery charge',
                      w: w,
                      child: TextFormField(
                        controller: _deliveryFeeCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.]'),
                          ),
                        ],
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'GH₵ ',
                          prefixStyle: TextStyle(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              double.tryParse(v) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Estimated Delivery Time ──
                    _SettingCard(
                      icon: HugeIcons.strokeRoundedClock01,
                      iconColor: AppColors.warning,
                      title: 'Est. Delivery Time',
                      subtitle: 'Average delivery duration',
                      w: w,
                      child: TextFormField(
                        controller: _estTimeCtrl,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 25-40 min',
                        ),
                      ),
                    ),
                    SizedBox(height: w * 0.04),

                    // ── Pre-orders Toggle ──
                    Container(
                      padding: EdgeInsets.all(w * 0.04),
                      decoration: BoxDecoration(
                        color: _acceptsPreOrders
                            ? AppColors.success.withValues(alpha: 0.06)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(w * 0.035),
                        border: Border.all(
                          color: _acceptsPreOrders
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(w * 0.025),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(w * 0.025),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar01,
                              color: AppColors.success,
                              size: w * 0.05,
                            ),
                          ),
                          SizedBox(width: w * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accept Pre-Orders',
                                  style: TextStyle(
                                    fontSize: w * 0.036,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: w * 0.005),
                                Text(
                                  'Let customers schedule orders ahead of time',
                                  style: TextStyle(
                                    fontSize: w * 0.028,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _acceptsPreOrders,
                            onChanged: (v) =>
                                setState(() => _acceptsPreOrders = v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w * 0.06),

                    // ── Save button ──
                    SizedBox(
                      width: double.infinity,
                      height: w * 0.135,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(
                          'Save Settings',
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
}

class _SettingCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final double w;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.02),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: iconColor,
                  size: w * 0.045,
                ),
              ),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.035,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: w * 0.026,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.03),
          child,
        ],
      ),
    );
  }
}
