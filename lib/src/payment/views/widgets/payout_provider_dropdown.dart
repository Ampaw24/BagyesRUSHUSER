import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../model/payout_provider_model.dart';
import 'payout_provider_visuals.dart';

/// A modern, data-driven dropdown for picking a live-fetched payout
/// provider (bank or mobile money). Expands/collapses inline via
/// [AnimatedSize] so it drops safely into any scroll view, with a rotating
/// chevron and per-row selection highlight animating on top.
class PayoutProviderDropdown extends StatefulWidget {
  const PayoutProviderDropdown({
    super.key,
    required this.label,
    required this.providers,
    required this.selected,
    required this.onSelected,
    this.placeholder = 'Select an option',
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  final String label;
  final String placeholder;
  final List<PayoutProviderModel> providers;
  final PayoutProviderModel? selected;
  final ValueChanged<PayoutProviderModel> onSelected;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<PayoutProviderDropdown> createState() => _PayoutProviderDropdownState();
}

class _PayoutProviderDropdownState extends State<PayoutProviderDropdown> {
  bool _open = false;

  void _toggle() {
    if (widget.isLoading || widget.error != null || widget.providers.isEmpty) return;
    setState(() => _open = !_open);
  }

  void _select(PayoutProviderModel provider) {
    widget.onSelected(provider);
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasSelection = widget.selected != null;
    final accent = hasSelection
        ? payoutProviderVisual(widget.selected!).color
        : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: w * 0.032,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.018),
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: w * 0.032, vertical: w * 0.028),
            decoration: BoxDecoration(
              color: hasSelection ? accent.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(
                color: _open || hasSelection ? accent : AppColors.border,
                width: _open ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: w * 0.05,
                    height: w * 0.05,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasSelection)
                  PayoutProviderAvatar(provider: widget.selected!, size: w * 0.08)
                else
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.textSecondary,
                    size: w * 0.05,
                  ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    widget.isLoading
                        ? 'Loading providers...'
                        : (widget.selected?.name ?? widget.placeholder),
                    style: TextStyle(
                      fontSize: w * 0.038,
                      color: hasSelection ? AppColors.textPrimary : AppColors.textHint,
                      fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!widget.isLoading)
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: w * 0.055,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.error != null)
          Padding(
            padding: EdgeInsets.only(top: w * 0.02),
            child: _ErrorRow(message: widget.error!, onRetry: widget.onRetry, w: w),
          ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open ? const SizedBox(width: double.infinity) : _buildPanel(w),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(double w) {
    return Container(
      margin: EdgeInsets.only(top: w * 0.02),
      constraints: BoxConstraints(maxHeight: w * 0.72),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.providers.isEmpty
          ? Padding(
              padding: EdgeInsets.all(w * 0.04),
              child: Text(
                'No options available',
                style: TextStyle(color: AppColors.textSecondary, fontSize: w * 0.034),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: w * 0.015),
              itemCount: widget.providers.length,
              itemBuilder: (context, i) {
                final provider = widget.providers[i];
                final isSelected = widget.selected == provider;
                final visual = payoutProviderVisual(provider);
                return InkWell(
                  onTap: () => _select(provider),
                  borderRadius: BorderRadius.circular(w * 0.03),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.symmetric(horizontal: w * 0.015, vertical: w * 0.006),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.024),
                    decoration: BoxDecoration(
                      color: isSelected ? visual.color.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(w * 0.03),
                      border: isSelected
                          ? Border.all(color: visual.color.withValues(alpha: 0.3))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: w * 0.009,
                          height: w * 0.075,
                          decoration: BoxDecoration(
                            color: isSelected ? visual.color : Colors.transparent,
                            borderRadius: BorderRadius.circular(w * 0.01),
                          ),
                        ),
                        SizedBox(width: w * 0.022),
                        PayoutProviderAvatar(provider: provider, size: w * 0.1),
                        SizedBox(width: w * 0.03),
                        Expanded(
                          child: Text(
                            provider.name,
                            style: TextStyle(
                              fontSize: w * 0.036,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? visual.color : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: visual.color, size: w * 0.05),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.w, this.onRetry});

  final String message;
  final double w;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.024),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(w * 0.025),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: AppColors.error, size: w * 0.045),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: w * 0.03, color: AppColors.error),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
