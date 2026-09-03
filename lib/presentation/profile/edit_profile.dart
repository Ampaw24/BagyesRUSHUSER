import 'dart:io';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/services/auth.service.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_state.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/views/change_password_sheet.dart';
import 'package:bagyesrushappusernew/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _emailController   = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading        = false;
  bool _profileLoaded  = false;
  bool _uploadingAvatar = false;
  File? _pickedAvatar;

  // Snapshot of the loaded values — compared against the live controllers
  // to decide whether the Save button should be enabled at all.
  String _initialName    = '';
  String _initialPhone   = '';
  String _initialEmail   = '';
  String _initialAddress = '';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleFieldChanged);
    _phoneController.addListener(_handleFieldChanged);
    _emailController.addListener(_handleFieldChanged);
    _addressController.addListener(_handleFieldChanged);
  }

  void _handleFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty =>
      _nameController.text.trim() != _initialName ||
      _phoneController.text.trim() != _initialPhone ||
      _emailController.text.trim() != _initialEmail ||
      _addressController.text.trim() != _initialAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoaded) return;

    // On cold start, restoreSession() sets a placeholder user (empty
    // name/email, no profile) before the real profile arrives via a
    // background fetch. Watching here — instead of a one-off context.read —
    // means that if this screen opens before that fetch resolves, the form
    // fills in the moment the real data lands instead of staying blank.
    final user = context.watch<CurrentUserProvider>().user;
    if (user == null || user.profile == null) return;
    _profileLoaded = true;

    final first = user.profile?.firstName ?? '';
    final last  = user.profile?.lastName  ?? '';
    _nameController.text  = '$first $last'.trim();
    // Phone is stored as +233XXXXXXXXX — show only the 9-digit part
    final raw = user.phone;
    _phoneController.text = raw.startsWith('+233') ? raw.substring(4) : raw;
    _emailController.text = user.email;
    _addressController.text = user.profile?.address ?? '';

    _initialName    = _nameController.text;
    _initialPhone   = _phoneController.text;
    _initialEmail   = _emailController.text;
    _initialAddress = _addressController.text;
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleFieldChanged);
    _phoneController.removeListener(_handleFieldChanged);
    _emailController.removeListener(_handleFieldChanged);
    _addressController.removeListener(_handleFieldChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(BuildContext context) async {
    final currentUser = context.read<CurrentUserProvider>().user;
    if (currentUser == null) return;

    final fullName = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final phone    = _phoneController.text.trim();
    final address  = _addressController.text.trim();

    final parts     = fullName.split(' ');
    final firstName = parts.first;
    final lastName  = parts.length > 1 ? parts.skip(1).join(' ') : '';

    setState(() => _loading = true);

    // Routed through AuthViewmodel (not the repository directly) so the
    // response is merged onto the cached user before CurrentUserProvider is
    // updated — a text-only edit response that omits the avatar URL won't
    // wipe out the photo the user just uploaded, and vice versa.
    final result = await context.read<AuthViewmodel>().updateProfile(
      firstName: firstName,
      lastName:  lastName,
      email:     email,
      phone:     phone.isNotEmpty ? '+233$phone' : currentUser.phone,
      address:   address,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => CustomDialog.showError(
        context: context,
        title: 'Update Failed',
        subtitle: failure.message,
      ),
      (_) => Navigator.pop(context),
    );
  }

  Future<void> _pickAndUploadAvatar(
    BuildContext sheetContext,
    ImageSource source,
  ) async {
    Navigator.pop(sheetContext);
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    await _uploadAvatar(File(picked.path));
  }

  Future<void> _uploadAvatar(File file) async {
    setState(() {
      _pickedAvatar = file;
      _uploadingAvatar = true;
    });

    final authViewModel = context.read<AuthViewmodel>();
    await authViewModel.uploadAvatar(file.path);

    if (!mounted) return;
    setState(() => _uploadingAvatar = false);

    // AuthViewmodel already updates CurrentUserProvider with the new avatar
    // on success — only failures need to be surfaced here.
    final state = authViewModel.state;
    if (state is AuthError) {
      CustomDialog.showError(
        context: context,
        title: 'Photo Update Failed',
        subtitle: state.message,
      );
    }
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
                        onPressed:
                            _isDirty ? () => _saveProfile(context) : null,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.08),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.4),
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
                localAvatar: _pickedAvatar,
                avatarUrl: context
                    .watch<CurrentUserProvider>()
                    .user
                    ?.profile
                    ?.profilePictureUrl,
                isUploading: _uploadingAvatar,
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
                SizedBox(height: w * 0.032),
                _FieldCard(
                  icon: HugeIcons.strokeRoundedUser,
                  iconColor: AppColors.primary,
                  label: 'Full Name',
                  builder: (focusNode) => TextFormField(
                    controller: _nameController,
                    focusNode: focusNode,
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDec('e.g. John Doe'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(height: w * 0.03),
                _FieldCard(
                  icon: HugeIcons.strokeRoundedMail01,
                  iconColor: const Color(0xFF3182CE),
                  label: 'Email',
                  builder: (focusNode) => TextFormField(
                    controller: _emailController,
                    focusNode: focusNode,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDec('e.g. you@email.com'),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(height: w * 0.03),
                _FieldCard(
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                  iconColor: AppColors.success,
                  label: 'Phone',
                  builder: (focusNode) => TextFormField(
                    controller: _phoneController,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _NoLeadingZeroFormatter(),
                    ],
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDec('e.g. 241234567').copyWith(
                      counterText: '',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(height: w * 0.03),
                _FieldCard(
                  icon: HugeIcons.strokeRoundedLocation01,
                  iconColor: const Color(0xFF805AD5),
                  label: 'Address',
                  builder: (focusNode) => TextFormField(
                    controller: _addressController,
                    focusNode: focusNode,
                    maxLines: 2,
                    minLines: 1,
                    style: TextStyle(
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDec('e.g. 12 Ring Road, Accra'),
                    textInputAction: TextInputAction.done,
                  ),
                ),

                if (_referralCode(context).isNotEmpty) ...[
                  SizedBox(height: w * 0.07),
                  _FormSection(label: 'Referral'),
                  SizedBox(height: w * 0.032),
                  _ReferralCard(
                    code: _referralCode(context),
                    count: _referralCount(context),
                    onCopy: () => _copyReferralCode(context),
                  ),
                ],

                SizedBox(height: w * 0.07),

                // ── Account ──
                _FormSection(label: 'Account'),
                SizedBox(height: w * 0.032),
                _FormCard(
                  children: [
                    _ActionRow(
                      icon: HugeIcons.strokeRoundedLockPassword,
                      iconColor: AppColors.info,
                      label: 'Change Password',
                      onTap: () => ChangePasswordSheet.show(context),
                    ),
                    _FieldDivider(w: w),
                    _ActionRow(
                      icon: HugeIcons.strokeRoundedLogout01,
                      iconColor: AppColors.textSecondary,
                      label: 'Log Out',
                      onTap: () => _confirmLogout(context),
                    ),
                    _FieldDivider(w: w),
                    _ActionRow(
                      icon: HugeIcons.strokeRoundedDelete02,
                      iconColor: AppColors.error,
                      label: 'Delete Account',
                      labelColor: AppColors.error,
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ],
                ),

                SizedBox(height: w * 0.09),

                // ── Save button ──
                SizedBox(
                  width: double.infinity,
                  height: (w * 0.14).clamp(48.0, 62.0),
                  child: ElevatedButton(
                    onPressed: (_loading || !_isDirty)
                        ? null
                        : () => _saveProfile(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.35),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.7),
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

  void _confirmLogout(BuildContext context) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'Log Out',
      subtitle: 'Are you sure you want to log out?',
      confirmText: 'Log Out',
      cancelText: 'Cancel',
      onConfirm: () async {
        final authViewModel = context.read<AuthViewmodel>();
        final appState = context.read<AppState>();

        await authViewModel.logout();

        if (!context.mounted) return;
        appState.setUser(IUser());
        appState.setPayload(ISignup());
        context.go(AppRoutes.login);
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account',
      subtitle:
          'This action is permanent and cannot be undone. All your orders, '
          'saved details, and wallet history will be permanently deleted.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: () {
        // TODO: Call AuthRepository.deleteAccount() via AuthViewmodel once
        // the backend endpoint for customer account deletion is available.
        CustomDialog.showInfo(
          context: context,
          title: 'Coming Soon',
          subtitle: 'Account deletion isn\'t available yet. Please contact '
              'support if you need your account removed.',
        );
      },
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
              onTap: () => _pickAndUploadAvatar(ctx, ImageSource.camera),
            ),
            SizedBox(height: w * 0.03),
            _BottomSheetOption(
              icon: HugeIcons.strokeRoundedImage01,
              label: 'Choose from Gallery',
              color: const Color(0xFF805AD5),
              onTap: () => _pickAndUploadAvatar(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  String _referralCode(BuildContext context) =>
      context.watch<CurrentUserProvider>().user?.profile?.referralCode ?? '';

  num _referralCount(BuildContext context) =>
      context.watch<CurrentUserProvider>().user?.profile?.referralCount ?? 0;

  void _copyReferralCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _referralCode(context)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }
}

// ─── Edit Profile Hero ─────────────────────────────────────────────────────────

class _EditProfileHero extends StatelessWidget {
  final double w;
  final VoidCallback onTapAvatar;
  final File? localAvatar;
  final String? avatarUrl;
  final bool isUploading;

  const _EditProfileHero({
    required this.w,
    required this.onTapAvatar,
    this.localAvatar,
    this.avatarUrl,
    this.isUploading = false,
  });

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
                          backgroundImage: localAvatar != null
                              ? FileImage(localAvatar!)
                              : (avatarUrl != null && avatarUrl!.isNotEmpty
                                  ? NetworkImage(avatarUrl!) as ImageProvider
                                  : null),
                          child: localAvatar == null &&
                                  (avatarUrl == null || avatarUrl!.isEmpty)
                              ? HugeIcon(
                                  icon: HugeIcons.strokeRoundedUser,
                                  size: w * 0.045,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      if (isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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

// ─── Modern Field Card ──────────────────────────────────────────────────────
//
// Each field is its own bordered, elevatable card rather than a row in a
// shared list — the border and shadow intensify on focus so the input
// affordance (and which field is active) is obvious without relying on a
// hairline divider.

class _FieldCard extends StatefulWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final Widget Function(FocusNode focusNode) builder;

  const _FieldCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.builder,
  });

  @override
  State<_FieldCard> createState() => _FieldCardState();
}

class _FieldCardState extends State<_FieldCard> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.border,
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _focused ? 18 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: w * 0.1,
            height: w * 0.1,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: _focused ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: HugeIcon(
                icon: widget.icon,
                color: widget.iconColor,
                size: w * 0.036,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: (w * 0.027).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: _focused ? AppColors.primary : AppColors.textHint,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: w * 0.006),
                widget.builder(_focusNode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account Action Row ─────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.038),
          child: Row(
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
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: (w * 0.038).clamp(13.0, 16.0),
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textHint,
                size: w * 0.038,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Referral Card ──────────────────────────────────────────────────────────

class _ReferralCard extends StatelessWidget {
  final String code;
  final num count;
  final VoidCallback onCopy;

  const _ReferralCard({
    required this.code,
    required this.count,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedGift,
                color: Colors.white,
                size: w * 0.06,
              ),
              SizedBox(width: w * 0.025),
              Text(
                'Invite Friends & Earn',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: (w * 0.04).clamp(14.0, 17.0),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.02),
          Text(
            count > 0
                ? 'You\'ve referred ${count.toInt()} ${count == 1 ? 'friend' : 'friends'} so far.'
                : 'Share your code — friends get a discount, you earn rewards.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: (w * 0.032).clamp(11.0, 14.0),
            ),
          ),
          SizedBox(height: w * 0.04),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.025,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: (w * 0.045).clamp(15.0, 19.0),
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.all(w * 0.022),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCopy01,
                      color: AppColors.primary,
                      size: w * 0.04,
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
