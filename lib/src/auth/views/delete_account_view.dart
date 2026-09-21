import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/report/model/report_reason.dart';

/// Full-screen "Delete Account" flow — reachable from the customer, courier
/// and vendor "Delete Account" entry points alike, since account deletion
/// (`POST /account/delete`) is role-agnostic just like password auth.
///
/// Requires the user to pick a reason and re-enter their password, then
/// confirms once more (irreversible action) before calling
/// [AuthViewmodel.deleteAccount].
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

const List<ReportReasonOption> _deletionReasons = [
  ReportReasonOption(code: 'no_longer_needed', label: 'I no longer need the app'),
  ReportReasonOption(code: 'found_alternative', label: 'I found a better alternative'),
  ReportReasonOption(code: 'privacy_concerns', label: 'I have privacy or data concerns'),
  ReportReasonOption(
    code: 'bad_experience',
    label: 'I had a bad experience with an order or vendor',
  ),
  ReportReasonOption(code: 'too_many_notifications', label: 'I receive too many notifications'),
  ReportReasonOption(code: 'other', label: 'Other'),
];

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _otherReasonController = TextEditingController();

  String? _selectedReasonCode;
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refresh);
    _otherReasonController.addListener(_refresh);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _isOtherSelected => _selectedReasonCode == 'other';

  bool get _canSubmit =>
      _selectedReasonCode != null &&
      _passwordController.text.isNotEmpty &&
      (!_isOtherSelected || _otherReasonController.text.trim().isNotEmpty);

  String? get _resolvedReason {
    if (_selectedReasonCode == null) return null;
    if (_isOtherSelected) return _otherReasonController.text.trim();
    return _deletionReasons
        .firstWhere((r) => r.code == _selectedReasonCode)
        .label;
  }

  void _handleDeletePressed() {
    if (_submitting || !_canSubmit) return;
    FocusScope.of(context).unfocus();

    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account Permanently?',
      subtitle:
          'This is your last chance to back out. Once deleted, your profile, '
          'order history, saved addresses and wallet balance cannot be '
          'recovered.',
      confirmText: 'Yes, Delete',
      cancelText: 'Keep My Account',
      onConfirm: _submit,
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final authViewModel = context.read<AuthViewmodel>();
    await authViewModel.deleteAccount(
      password: _passwordController.text,
      reason: _resolvedReason,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final state = authViewModel.state;
    if (state is AccountDeleted) {
      authViewModel.resetState();
      context.go(AppRoutes.login);
      CustomDialog.showSuccess(
        context: context,
        title: 'Account Deleted',
        subtitle:
            'Your account has been permanently deleted. We\'re sorry to see '
            'you go.',
      );
    } else if (state is AuthError) {
      CustomDialog.showError(
        context: context,
        title: 'Couldn\'t Delete Account',
        subtitle: state.message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            _Header(w: w, onBack: () => context.pop()),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.02, w * 0.05, w * 0.06),
                  children: [
                    _WarningBanner(w: w),
                    SizedBox(height: w * 0.07),
                    Text(
                      'Why are you leaving?',
                      style: TextStyle(
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.015),
                    Text(
                      'Help us improve — choose the reason that fits best.',
                      style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: w * 0.045),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _deletionReasons.length,
                      separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
                      itemBuilder: (context, i) {
                        final reason = _deletionReasons[i];
                        return _ReasonTile(
                          w: w,
                          label: reason.label,
                          isSelected: reason.code == _selectedReasonCode,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedReasonCode = reason.code);
                          },
                        );
                      },
                    ),
                    if (_isOtherSelected) ...[
                      SizedBox(height: w * 0.04),
                      TextFormField(
                        controller: _otherReasonController,
                        maxLength: 500,
                        maxLines: 3,
                        style: TextStyle(fontSize: w * 0.036, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Tell us more (optional details help us improve)',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: w * 0.04,
                            vertical: w * 0.032,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: w * 0.08),
                    Text(
                      'Confirm your password',
                      style: TextStyle(
                        fontSize: w * 0.045,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.015),
                    Text(
                      'For your security, enter your password to continue.',
                      style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: w * 0.04),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        fontSize: (w * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: w * 0.04,
                          vertical: w * 0.032,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: HugeIcon(
                            icon: _obscurePassword
                                ? HugeIcons.strokeRoundedView
                                : HugeIcons.strokeRoundedViewOffSlash,
                            color: AppColors.textHint,
                            size: w * 0.045,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActionBar(
              w: w,
              enabled: _canSubmit,
              isSubmitting: _submitting,
              onTap: _handleDeletePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double w;
  final VoidCallback onBack;

  const _Header({required this.w, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.03),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: EdgeInsets.all(w * 0.022),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft02,
                color: AppColors.textPrimary,
                size: w * 0.055,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
          Text(
            'Delete Account',
            style: TextStyle(
              fontSize: w * 0.048,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final double w;

  const _WarningBanner({required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert01,
            color: AppColors.error,
            size: w * 0.06,
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action is permanent',
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.015),
                Text(
                  'Deleting your account permanently removes your profile, order '
                  'history, saved addresses, wallet balance and any pending '
                  'orders. This cannot be undone.',
                  style: TextStyle(
                    fontSize: w * 0.032,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final double w;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.w,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(w * 0.035),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.035),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.07)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.035),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _ReasonSelector(isSelected: isSelected, w: w),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.036,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonSelector extends StatelessWidget {
  final bool isSelected;
  final double w;

  const _ReasonSelector({required this.isSelected, required this.w});

  @override
  Widget build(BuildContext context) {
    final size = w * 0.055;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected ? Icon(Icons.check, size: size * 0.62, color: Colors.white) : null,
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final double w;
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _BottomActionBar({
    required this.w,
    required this.enabled,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        w * 0.05,
        w * 0.03,
        w * 0.05,
        w * 0.03 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: (w * 0.14).clamp(48.0, 58.0),
        child: ElevatedButton(
          onPressed: enabled && !isSubmitting ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.error.withValues(alpha: 0.35),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'Delete My Account',
                  style: TextStyle(
                    fontSize: (w * 0.04).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
