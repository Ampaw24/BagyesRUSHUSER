import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import '../../../../core/services/contact_picker_service.dart';
import '../../../../core/widgets/contact_picker_button.dart';
import '../../../../core/widgets/map_location_picker_sheet.dart';
import 'package:gopady/src/parcel/model/delivery_stop.dart';
import 'package:gopady/src/parcel/model/parcel_direction.dart';
import 'package:gopady/src/parcel/viewmodel/send_parcel_viewmodel.dart';
import 'parcel_form_fields.dart';
import 'parcel_ui.dart';
import 'package:gopady/constant/app_tokens.dart';

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
/// After location is set, each card expands inline to show item details
/// (description, quantity, recipient name, phone, instructions) — the
/// industry-standard fields used by Lalamove, GrabExpress, Kwik, and Bosta.
/// Send: recipient name and phone are required so the rider always has
/// someone to hand the package to. Receive: a single stop at the customer's
/// own address, recipient fields optional (defaults to the customer).
class DeliveryStopsStep extends StatelessWidget {
  final ParcelDirection direction;
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
    this.direction = ParcelDirection.send,
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

    final isReceive = direction.isReceive;
    final canAdd =
        !isReceive &&
        stops.isNotEmpty &&
        stops.last.isComplete &&
        stops.length < maxStops;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.1),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ParcelStepHeader(
            title: isReceive ? 'Deliver to you' : 'Where is it going?',
            subtitle: isReceive
                ? 'Where should the rider bring your package?'
                : stops.length > 1
                ? '${stops.length} stops · one rider handles them all, in order.'
                : 'Add the drop-off and who will receive it.',
          ),
          SizedBox(height: w * 0.05),

          // ── Stop cards ───────────────────────────────────────────────────────
          for (int i = 0; i < stops.length; i++) ...[
            _StopCard(
              key: ValueKey(stops[i].id),
              direction: direction,
              stop: stops[i],
              index: i,
              canRemove: !isReceive && stops.length > 1,
              packageImages: packageImages,
              onLocationSet: (latLng, address) =>
                  onStopUpdated(stops[i].id, latLng, address),
              onDetailsChanged: onStopDetailsChanged,
              onRemove: () => onStopRemoved(stops[i].id),
            ),
            SizedBox(height: w * 0.035),
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
  final ParcelDirection direction;
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
    required this.direction,
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

  void _applyContact(PickedContact contact) {
    if (contact.name.isNotEmpty) _nameCtrl.text = contact.name;
    if (contact.phone.isNotEmpty) _phoneCtrl.text = contact.phone;
    _pushChanges();
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
    // Reveals the details section (incl. the required recipient fields) as
    // soon as a location is picked — gating this on `isComplete` instead
    // would hide those fields until they're already filled in.
    final hasLocation = widget.stop.hasLocation;
    // Drives the "done" styling (green border/badge) — only once the stop,
    // including its required recipient info, is actually complete.
    final isComplete = widget.stop.isCompleteFor(widget.direction);
    final isReceive = widget.direction.isReceive;

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outExpo,
      clipBehavior: Clip.antiAlias,
      decoration: parcelCardDecoration(w, highlighted: isComplete),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Location row ─────────────────────────────────────────────────────
          InkWell(
            onTap: () => _openLocationSheet(context),
            child: Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Row(
                children: [
                  _StopBadge(index: widget.index, isSet: isComplete),
                  SizedBox(width: w * 0.035),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (isReceive
                                  ? 'Your drop-off'
                                  : 'Stop ${widget.index + 1}')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: w * 0.026,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isComplete
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                        SizedBox(height: w * 0.008),
                        Text(
                          hasLocation
                              ? widget.stop.address
                              : 'Set drop-off location',
                          style: TextStyle(
                            fontSize: w * 0.036,
                            fontWeight: hasLocation
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: hasLocation
                                ? AppColors.textPrimary
                                : AppColors.primary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: w * 0.02),
                  HugeIcon(
                    icon: hasLocation
                        ? HugeIcons.strokeRoundedEdit02
                        : HugeIcons.strokeRoundedArrowRight01,
                    size: w * 0.048,
                    color: hasLocation
                        ? AppColors.textSecondary
                        : AppColors.primary,
                  ),
                  if (widget.canRemove)
                    IconButton(
                      tooltip: 'Remove stop',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onRemove,
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: w * 0.048,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Item details — animates in once location is set ───────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: hasLocation
                ? _buildDetailsSection(w)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ── Details section ──────────────────────────────────────────────────────────

  Widget _buildDetailsSection(double w) {
    final isReceive = widget.direction.isReceive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppColors.divider, height: 1),
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.04, w * 0.04, w * 0.045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GroupTitle('What\'s being dropped'),
              SizedBox(height: w * 0.03),
              // ── Photos for this stop ───────────────────────────────────────
              if (widget.packageImages.isNotEmpty) ...[
                ParcelFieldLabel(
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
                            borderRadius: BorderRadius.circular(w * 0.03),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(w * 0.026),
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
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedDeliveryBox01,
                label: 'Item description',
                hint: null,
                required: true,
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
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
                    child: ParcelFieldLabel(
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

              SizedBox(height: w * 0.05),
              _GroupTitle(isReceive ? 'Receiver' : 'Recipient'),
              SizedBox(height: w * 0.03),

              // ── Recipient name ─────────────────────────────────────────────
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedUser,
                label: 'Recipient name',
                hint: isReceive ? 'optional' : null,
                required: !isReceive,
                trailing: ContactPickerButton(onPicked: _applyContact),
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                hint: isReceive
                    ? 'Leave blank to receive it yourself'
                    : 'e.g. John Mensah',
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
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedCall,
                label: 'Recipient phone',
                hint: isReceive ? 'optional' : null,
                required: !isReceive,
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
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
              ParcelFieldLabel(
                icon: HugeIcons.strokeRoundedMessage01,
                label: 'Special instructions',
                hint: 'optional',
                w: w,
              ),
              SizedBox(height: w * 0.02),
              ParcelTextField(
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

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: w * 0.037,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
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
    return Container(
      padding: EdgeInsets.all(w * 0.01),
      decoration: const ShapeDecoration(
        color: AppColors.surface,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
            enabled: qty > 1,
            label: 'Decrease quantity',
            w: w,
          ),
          SizedBox(
            width: w * 0.1,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onTap: onIncrement,
            enabled: qty < 99,
            label: 'Increase quantity',
            w: w,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final double w;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final size = w * 0.08;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? AppColors.card : Colors.transparent,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: w * 0.042,
              color: enabled ? AppColors.textPrimary : AppColors.textHint,
            ),
          ),
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
    final size = w * 0.1;

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.outExpo,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSet ? AppColors.primary : AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isSet
            ? Icon(Icons.check_rounded, color: Colors.white, size: size * 0.5)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: w * 0.036,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
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
    final radius = BorderRadius.circular(w * 0.045);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: w * 0.035,
            horizontal: w * 0.04,
          ),
          child: Row(
            children: [
              ParcelIconBadge(
                icon: HugeIcons.strokeRoundedAdd01,
                active: true,
                sizeFactor: 0.1,
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  'Add another stop',
                  style: TextStyle(
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$stopCount of $maxStops',
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
