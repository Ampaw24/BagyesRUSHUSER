import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/widgets/map_location_picker_sheet.dart';
import '../../data/models/delivery_stop.dart';
import '../viewmodels/send_parcel_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Delivery stops step — replaces the single [LocationPickerStep] for
/// [ParcelStep.deliveryLocation].
///
/// Single-delivery users see one blank stop card and experience an
/// identical flow to before. Multi-stop users see the "Add another stop"
/// button animate in once the first stop is confirmed.
///
/// After location is set, each card expands inline to show optional
/// item details (description, quantity, recipient name, phone) — the
/// industry-standard fields used by Lalamove, GrabExpress, Kwik, and Bosta.
class DeliveryStopsStep extends StatelessWidget {
  final List<DeliveryStop> stops;
  final List<File> packageImages;
  final void Function(String id, LatLng latLng, String address) onStopUpdated;
  final VoidCallback onAddStop;
  final void Function(String id) onStopRemoved;
  final void Function(
    String id, {
    required String itemDescription,
    required int quantity,
    required String recipientName,
    required String recipientPhone,
    required String specialInstructions,
    required List<int> selectedImageIndices,
  })
  onStopDetailsChanged;
  final int maxStops;

  const DeliveryStopsStep({
    super.key,
    required this.stops,
    required this.packageImages,
    required this.onStopUpdated,
    required this.onAddStop,
    required this.onStopRemoved,
    required this.onStopDetailsChanged,
    required this.maxStops,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    final canAdd =
        stops.isNotEmpty && stops.last.isComplete && stops.length < maxStops;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Text(
            'Delivery Location',
            style: TextStyle(
              fontSize: w * 0.055,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            stops.length > 1
                ? 'Managing ${stops.length} stops — one rider handles all.'
                : 'Where should your package be delivered?',
            style: TextStyle(
              fontSize: w * 0.035,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          SizedBox(height: w * 0.05),

          // ── Stop cards ───────────────────────────────────────────────────────
          for (int i = 0; i < stops.length; i++) ...[
            _StopCard(
              key: ValueKey(stops[i].id),
              stop: stops[i],
              index: i,
              canRemove: stops.length > 1,
              packageImages: packageImages,
              onLocationSet: (latLng, address) =>
                  onStopUpdated(stops[i].id, latLng, address),
              onDetailsChanged: onStopDetailsChanged,
              onRemove: () => onStopRemoved(stops[i].id),
            ),
            SizedBox(height: w * 0.03),
          ],

          // ── Add another stop — animated reveal ───────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: canAdd
                ? _AddStopButton(
                    stopCount: stops.length,
                    maxStops: maxStops,
                    onTap: onAddStop,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stop card — StatefulWidget (owns text controllers + qty state)
// ─────────────────────────────────────────────────────────────────────────────

class _StopCard extends StatefulWidget {
  final DeliveryStop stop;
  final int index;
  final bool canRemove;
  final List<File> packageImages;
  final void Function(LatLng latLng, String address) onLocationSet;
  final void Function(
    String id, {
    required String itemDescription,
    required int quantity,
    required String recipientName,
    required String recipientPhone,
    required String specialInstructions,
    required List<int> selectedImageIndices,
  })
  onDetailsChanged;
  final VoidCallback onRemove;

  const _StopCard({
    super.key,
    required this.stop,
    required this.index,
    required this.canRemove,
    required this.packageImages,
    required this.onLocationSet,
    required this.onDetailsChanged,
    required this.onRemove,
  });

  @override
  State<_StopCard> createState() => _StopCardState();
}

class _StopCardState extends State<_StopCard> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _instrCtrl;
  late int _qty;
  late Set<int> _selectedIndices;

  final FocusNode _descFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _instrFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.stop.itemDescription);
    _nameCtrl = TextEditingController(text: widget.stop.recipientName);
    _phoneCtrl = TextEditingController(text: widget.stop.recipientPhone);
    _instrCtrl = TextEditingController(text: widget.stop.specialInstructions);
    _qty = widget.stop.quantity.clamp(1, 99);
    _selectedIndices = widget.stop.selectedImageIndices.toSet();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _instrCtrl.dispose();
    _descFocus.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _instrFocus.dispose();
    super.dispose();
  }

  void _pushChanges() {
    widget.onDetailsChanged(
      widget.stop.id,
      itemDescription: _descCtrl.text.trim(),
      quantity: _qty,
      recipientName: _nameCtrl.text.trim(),
      recipientPhone: _phoneCtrl.text.trim(),
      specialInstructions: _instrCtrl.text.trim(),
      selectedImageIndices: _selectedIndices.toList()..sort(),
    );
  }

  void _toggleImage(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
    _pushChanges();
  }

  void _adjustQty(int delta) {
    final next = (_qty + delta).clamp(1, 99);
    if (next == _qty) return;
    setState(() => _qty = next);
    _pushChanges();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isSet = widget.stop.isComplete;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSet
            ? AppColors.success.withValues(alpha: 0.02)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(
          color: isSet
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: isSet ? 1.5 : 1.0,
        ),
        boxShadow: isSet
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Location row ─────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openLocationSheet(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StopBadge(index: widget.index, isSet: isSet),
                  SizedBox(width: w * 0.035),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stop ${widget.index + 1}',
                          style: TextStyle(
                            fontSize: w * 0.027,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isSet
                                ? AppColors.success
                                : AppColors.textHint,
                          ),
                        ),
                        SizedBox(height: w * 0.008),
                        Text(
                          isSet
                              ? widget.stop.address
                              : 'Tap to set delivery location',
                          style: TextStyle(
                            fontSize: w * 0.036,
                            color: isSet
                                ? AppColors.textPrimary
                                : AppColors.textHint,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSet
                            ? Icons.edit_location_alt_outlined
                            : Icons.add_location_alt_outlined,
                        size: w * 0.055,
                        color: isSet ? AppColors.primary : AppColors.textHint,
                      ),
                      if (widget.canRemove) ...[
                        SizedBox(height: w * 0.018),
                        GestureDetector(
                          onTap: widget.onRemove,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.all(w * 0.01),
                            child: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: w * 0.048,
                              color: AppColors.error.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Item details — animates in once location is set ───────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: isSet ? _buildDetailsSection(w) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Details section ──────────────────────────────────────────────────────────

  Widget _buildDetailsSection(double w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04),
          child: Divider(color: AppColors.divider, height: 1),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.035, w * 0.04, w * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photos for this stop ───────────────────────────────────────
              if (widget.packageImages.isNotEmpty) ...[
                _DetailLabel(
                  icon: HugeIcons.strokeRoundedImage01,
                  label: 'Photos for this stop',
                  hint: 'tap to tag',
                  w: w,
                ),
                SizedBox(height: w * 0.02),
                SizedBox(
                  height: w * 0.2,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.packageImages.length,
                    separatorBuilder: (_, _) => SizedBox(width: w * 0.025),
                    itemBuilder: (_, i) {
                      final selected = _selectedIndices.contains(i);
                      return GestureDetector(
                        onTap: () => _toggleImage(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          width: w * 0.18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(w * 0.025),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 2.5 : 1.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(w * 0.022),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  widget.packageImages[i],
                                  fit: BoxFit.cover,
                                  cacheWidth:
                                      (w *
                                              0.18 *
                                              MediaQuery.devicePixelRatioOf(
                                                context,
                                              ))
                                          .round(),
                                ),
                                if (selected)
                                  Container(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.35,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: w * 0.07,
                                        height: w * 0.07,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: w * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: w * 0.035),
              ],

              // ── Item description ───────────────────────────────────────────
              _DetailLabel(
                icon: HugeIcons.strokeRoundedDeliveryBox01,
                label: 'Item description',
                hint: 'optional',
                w: w,
              ),
              SizedBox(height: w * 0.02),
              _DetailTextField(
                controller: _descCtrl,
                focusNode: _descFocus,
                hint: 'e.g. 2 sealed documents, 1 phone box',
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_nameFocus),
                maxLength: 100,
                onChanged: (_) => _pushChanges(),
                w: w,
              ),

              SizedBox(height: w * 0.035),

              // ── Quantity stepper ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _DetailLabel(
                      icon: HugeIcons.strokeRoundedPackageAdd,
                      label: 'Quantity',
                      hint: null,
                      w: w,
                    ),
                  ),
                  _QtyStepper(
                    qty: _qty,
                    onDecrement: () => _adjustQty(-1),
                    onIncrement: () => _adjustQty(1),
                    w: w,
                  ),
                ],
              ),

              SizedBox(height: w * 0.035),

              // ── Recipient name ─────────────────────────────────────────────
              _DetailLabel(
                icon: HugeIcons.strokeRoundedUser,
                label: 'Recipient name',
                hint: 'optional',
                w: w,
              ),
              SizedBox(height: w * 0.02),
              _DetailTextField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                hint: 'e.g. John Mensah',
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
                maxLength: 60,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                ],
                onChanged: (_) => _pushChanges(),
                w: w,
              ),

              SizedBox(height: w * 0.035),

              // ── Recipient phone ────────────────────────────────────────────
              _DetailLabel(
                icon: HugeIcons.strokeRoundedCall,
                label: 'Recipient phone',
                hint: 'optional',
                w: w,
              ),
              SizedBox(height: w * 0.02),
              _DetailTextField(
                controller: _phoneCtrl,
                focusNode: _phoneFocus,
                hint: 'e.g. +233 50 000 0000',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_instrFocus),
                maxLength: 20,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s\+\-\(\)]')),
                ],
                onChanged: (_) => _pushChanges(),
                w: w,
              ),

              SizedBox(height: w * 0.035),

              // ── Special instructions ───────────────────────────────────────
              _DetailLabel(
                icon: HugeIcons.strokeRoundedMessage01,
                label: 'Special instructions',
                hint: 'optional',
                w: w,
              ),
              SizedBox(height: w * 0.02),
              _DetailTextField(
                controller: _instrCtrl,
                focusNode: _instrFocus,
                hint: 'e.g. Leave at front desk, ring bell',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _instrFocus.unfocus(),
                maxLength: 150,
                onChanged: (_) => _pushChanges(),
                w: w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerSheet(
        title: 'Set Delivery Location',
        initialPosition: widget.stop.latLng,
        onConfirm: (latLng, address) {
          widget.onLocationSet(latLng, address);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail section sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DetailLabel extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String? hint;
  final double w;

  const _DetailLabel({
    required this.icon,
    required this.label,
    required this.hint,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: AppColors.textSecondary, size: w * 0.038),
        SizedBox(width: w * 0.02),
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.033,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (hint != null) ...[
          SizedBox(width: w * 0.015),
          Text(
            '($hint)',
            style: TextStyle(fontSize: w * 0.028, color: AppColors.textHint),
          ),
        ],
      ],
    );
  }
}

class _DetailTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final double w;

  const _DetailTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.w,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onFieldSubmitted,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: w * 0.036,
        color: AppColors.textPrimary,
        fontFamily: 'Mukta',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: w * 0.034,
          color: AppColors.textHint,
          fontFamily: 'Mukta',
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.032,
        ),
        filled: true,
        fillColor: AppColors.scaffold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(w * 0.03),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(w * 0.03),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(w * 0.03),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final double w;

  const _QtyStepper({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyButton(
          icon: Icons.remove_rounded,
          onTap: onDecrement,
          enabled: qty > 1,
          w: w,
        ),
        Container(
          width: w * 0.12,
          alignment: Alignment.center,
          child: Text(
            '$qty',
            style: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _QtyButton(
          icon: Icons.add_rounded,
          onTap: onIncrement,
          enabled: qty < 99,
          w: w,
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final double w;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: w * 0.09,
        height: w * 0.09,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.border.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(w * 0.025),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: w * 0.042,
          color: enabled ? AppColors.primary : AppColors.textHint,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stop number badge
// ─────────────────────────────────────────────────────────────────────────────

class _StopBadge extends StatelessWidget {
  final int index;
  final bool isSet;

  const _StopBadge({required this.index, required this.isSet});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: w * 0.11,
      height: w * 0.11,
      decoration: BoxDecoration(
        color: isSet
            ? AppColors.success
            : AppColors.border.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isSet
            ? Icon(Icons.check_rounded, color: Colors.white, size: w * 0.048)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: w * 0.034,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHint,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Add another stop" button
// ─────────────────────────────────────────────────────────────────────────────

class _AddStopButton extends StatelessWidget {
  final int stopCount;
  final int maxStops;
  final VoidCallback onTap;

  const _AddStopButton({
    required this.stopCount,
    required this.maxStops,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: w * 0.042,
          horizontal: w * 0.04,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: w * 0.052,
            ),
            SizedBox(width: w * 0.025),
            Text(
              'Add another stop',
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: w * 0.025),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.02,
                vertical: w * 0.006,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Text(
                '$stopCount / $maxStops',
                style: TextStyle(
                  fontSize: w * 0.028,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
