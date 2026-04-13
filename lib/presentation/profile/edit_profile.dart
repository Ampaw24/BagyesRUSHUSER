import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/src/auth/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _oldPasswordController     = TextEditingController();
  final _newPasswordController     = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading        = false;
  bool _obscureOld     = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _sessionLoaded  = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionLoaded) return;
    _sessionLoaded = true;
    final user = context.read<CurrentUserProvider>().user;
    if (user != null) {
      final first = user.profile?.firstName ?? '';
      final last  = user.profile?.lastName  ?? '';
      _nameController.text  = '$first $last'.trim();
      // Phone is stored as +233XXXXXXXXX — show only the 9-digit part
      final raw = user.phone;
      _phoneController.text = raw.startsWith('+233') ? raw.substring(4) : raw;
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(BuildContext context) async {
    final currentUser = context.read<CurrentUserProvider>().user;
    if (currentUser == null) return;

    final fullName = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final phone    = _phoneController.text.trim();

    final parts     = fullName.split(' ');
    final firstName = parts.first;
    final lastName  = parts.length > 1 ? parts.skip(1).join(' ') : '';

    setState(() => _loading = true);

    final result = await GetIt.instance<AuthRepository>().updateProfile(
      firstName: firstName,
      lastName:  lastName,
      email:     email,
      phone:     phone.isNotEmpty ? '+233$phone' : currentUser.phone,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => CustomDialog.showError(
        context: context,
        title: 'Update Failed',
        subtitle: failure.message,
      ),
      (updatedUser) {
        context.read<CurrentUserProvider>().setUser(updatedUser);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: w * 0.55,
            pinned: true,
            backgroundColor: AppColors.primary,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(w * 0.015),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: w * 0.04),
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: () => _saveProfile(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.045,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: (w * 0.038).clamp(13.0, 16.0),
                          ),
                        ),
                      ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _EditProfileHero(
                w: w,
                onTapAvatar: _selectPhotoBottomSheet,
              ),
            ),
          ),

          // ── Form ──
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              w * 0.05,
              w * 0.04,
              w * 0.05,
              w * 0.08,
            ),
            sliver: SliverList.list(
              children: [
                _FormSection(label: 'Basic Info'),
                SizedBox(height: w * 0.03),
                _FormCard(
                  children: [
                    _FieldRow(
                      icon: HugeIcons.strokeRoundedUser,
                      iconColor: AppColors.primary,
                      label: 'Full Name',
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDec('e.g. John Doe'),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    _FieldDivider(w: w),
                    _FieldRow(
                      icon: HugeIcons.strokeRoundedMail01,
                      iconColor: const Color(0xFF3182CE),
                      label: 'Email',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDec('e.g. you@email.com'),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    _FieldDivider(w: w),
                    _FieldRow(
                      icon: HugeIcons.strokeRoundedSmartPhone01,
                      iconColor: AppColors.success,
                      label: 'Phone',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 9,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _NoLeadingZeroFormatter(),
                        ],
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDec('e.g. 241234567').copyWith(
                          counterText: '',
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: w * 0.06),
                _FormSection(label: 'Change Password'),
                SizedBox(height: w * 0.03),
                _FormCard(
                  children: [
                    _FieldRow(
                      icon: HugeIcons.strokeRoundedLock,
                      iconColor: AppColors.warning,
                      label: 'Old Password',
                      child: TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOld,
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDec('Current password').copyWith(
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscureOld
                                  ? HugeIcons.strokeRoundedViewOff
                                  : HugeIcons.strokeRoundedView,
                              color: AppColors.textHint,
                              size: w * 0.038,
                            ),
                            onPressed: () =>
                                setState(() => _obscureOld = !_obscureOld),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    _FieldDivider(w: w),
                    _FieldRow(
                      icon: HugeIcons.strokeRoundedPasswordValidation,
                      iconColor: const Color(0xFF805AD5),
                      label: 'New Password',
                      child: TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDec('New password').copyWith(
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscureNew
                                  ? HugeIcons.strokeRoundedViewOff
                                  : HugeIcons.strokeRoundedView,
                              color: AppColors.textHint,
                              size: w * 0.038,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    _FieldDivider(w: w),
                    _FieldRow(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      iconColor: AppColors.info,
                      label: 'Confirm',
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        style: TextStyle(
                          fontSize: (w * 0.038).clamp(13.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDec('Confirm new password').copyWith(
                          suffixIcon: IconButton(
                            icon: HugeIcon(
                              icon: _obscureConfirm
                                  ? HugeIcons.strokeRoundedViewOff
                                  : HugeIcons.strokeRoundedView,
                              color: AppColors.textHint,
                              size: w * 0.038,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: w * 0.08),

                // ── Save button ──
                SizedBox(
                  width: double.infinity,
                  height: (w * 0.14).clamp(48.0, 62.0),
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _saveProfile(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                                color: Colors.white,
                                size: w * 0.038,
                              ),
                              SizedBox(width: w * 0.025),
                              Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: (w * 0.042).clamp(14.0, 18.0),
                                  fontWeight: FontWeight.w800,
                                  
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    isDense: true,
    hintStyle: TextStyle(
      color: AppColors.textHint,
      fontSize: MediaQuery.sizeOf(context).width * 0.034,
    ),
  );

  void _selectPhotoBottomSheet() {
    final w = MediaQuery.sizeOf(context).width;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Update Profile Photo',
              style: TextStyle(
                fontSize: (w * 0.043).clamp(14.0, 18.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.05),
            _BottomSheetOption(
              icon: HugeIcons.strokeRoundedCamera01,
              label: 'Take a Photo',
              color: AppColors.primary,
              onTap: () => Navigator.pop(ctx),
            ),
            SizedBox(height: w * 0.03),
            _BottomSheetOption(
              icon: HugeIcons.strokeRoundedImage01,
              label: 'Choose from Gallery',
              color: const Color(0xFF805AD5),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Profile Hero ─────────────────────────────────────────────────────────

class _EditProfileHero extends StatelessWidget {
  final double w;
  final VoidCallback onTapAvatar;

  const _EditProfileHero({required this.w, required this.onTapAvatar});

  @override
  Widget build(BuildContext context) {
    final avatarRadius = (w * 0.14).clamp(50.0, 80.0);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // decorative circle
          Positioned(
            top: -w * 0.08,
            right: -w * 0.08,
            child: Container(
              width: w * 0.45,
              height: w * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: w * 0.1),
                GestureDetector(
                  onTap: onTapAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            size: w * 0.045,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(w * 0.022),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCamera01,
                          color: AppColors.primary,
                          size: w * 0.036,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: w * 0.025),
                Text(
                  'Tap to change photo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: (w * 0.03).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w400,
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

// ─── Form helpers ──────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String label;
  const _FormSection({required this.label});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: (w * 0.03).clamp(10.0, 13.0),
        fontWeight: FontWeight.w800,
        color: AppColors.textHint,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  final double w;
  const _FieldDivider({required this.w});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: w * 0.22),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final Widget child;

  const _FieldRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.038),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: HugeIcon(icon: icon, color: iconColor, size: w * 0.036),
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: (w * 0.028).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: w * 0.008),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet Option ───────────────────────────────────────────────────────

class _BottomSheetOption extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.045,
            vertical: w * 0.038,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.016),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: icon, color: color, size: w * 0.036),
              ),
              SizedBox(width: w * 0.04),
              Text(
                label,
                style: TextStyle(
                  fontSize: (w * 0.038).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.startsWith('0')) return oldValue;
    return newValue;
  }
}
