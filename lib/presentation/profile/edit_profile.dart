import 'dart:io';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/core/widgets/network_avatar.dart';
import 'package:bagyesrushappusernew/src/auth/viewmodels/auth_viewmodel.dart';
import 'package:bagyesrushappusernew/src/auth/views/change_password_sheet.dart';
import 'package:bagyesrushappusernew/core/utils/phone_utils.dart';
import 'package:bagyesrushappusernew/src/auth/views/widgets/phone_change_flow_sheet.dart';
import 'package:bagyesrushappusernew/src/referral/widgets/referral_code_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bagyesrushappusernew/src/auth/views/logout_action.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey();
  final _emailFieldKey = GlobalKey();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _loading = false;
  bool _profileLoaded = false;
  bool _uploadingAvatar = false;
  File? _pickedAvatar;

  // Snapshot of the loaded values — compared against the live controllers
  // to decide whether the Save button should be enabled at all.
  String _initialName = '';
  String _initialEmail = '';
  String _initialAddress = '';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleFieldChanged);
    _emailController.addListener(_handleFieldChanged);
    _addressController.addListener(_handleFieldChanged);
  }

  void _handleFieldChanged() {
    if (mounted) setState(() {});
  }

  /// Trims and collapses runs of whitespace, so "  John   Doe " and
  /// "John Doe" are the same name for both the dirty check and the save.
  static String _normalizeName(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// First word is the first name; everything after it is the last name.
  static (String, String) _splitName(String raw) {
    final name = _normalizeName(raw);
    final space = name.indexOf(' ');
    if (space == -1) return (name, '');
    return (name.substring(0, space), name.substring(space + 1));
  }

  bool get _isDirty =>
      _normalizeName(_nameController.text) != _initialName ||
      _emailController.text.trim() != _initialEmail ||
      _addressController.text.trim() != _initialAddress;

  String? _validateName(String? value) {
    final name = _normalizeName(value ?? '');
    if (name.isEmpty) return 'Please enter your name';
    if (name.length < 2) return 'Name is too short';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter your email address';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

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
    final last = user.profile?.lastName ?? '';
    _nameController.text = _normalizeName('$first $last');
    _emailController.text = user.email;
    _addressController.text = user.profile?.address ?? '';

    _initialName = _nameController.text;
    _initialEmail = _emailController.text;
    _initialAddress = _addressController.text;
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleFieldChanged);
    _emailController.removeListener(_handleFieldChanged);
    _addressController.removeListener(_handleFieldChanged);
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Drop the keyboard first so it can't cover the validation messages or
    // the result dialog.
    FocusScope.of(context).unfocus();
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _revealFirstError();
      return;
    }

    final currentUser = context.read<CurrentUserProvider>().user;
    if (currentUser == null) return;

    final (firstName, lastName) = _splitName(_nameController.text);
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    final viewModel = context.read<AuthViewmodel>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _loading = true);

    // Phone is kept unchanged during basic detail updates
    final result = await viewModel.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: currentUser.phone,
      address: address,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (failure) => CustomDialog.showError(
        context: context,
        title: 'Update Failed',
        subtitle: failure.message,
      ),
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        context.pop();
      },
    );
  }

  /// The validation messages sit under Name/Email at the top of the form —
  /// off-screen when someone has just edited the address below — so without
  /// this a blocked save looks like the button did nothing.
  void _revealFirstError() {
    final firstInvalid = _validateName(_nameController.text) != null
        ? _nameFieldKey
        : _validateEmail(_emailController.text) != null
        ? _emailFieldKey
        : null;
    final fieldContext = firstInvalid?.currentContext;
    if (fieldContext != null) {
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.3,
      );
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
  }

  void _changePhone() {
    FocusScope.of(context).unfocus();
    final provider = context.read<CurrentUserProvider>();
    final viewModel = context.read<AuthViewmodel>();
    final currentUser = provider.user;
    if (currentUser == null) return;

    PhoneChangeFlowSheet.show(
      context,
      oldPhone: currentUser.phone,
      onPhoneUpdated: (newPhone) async {
        // Send the *saved* profile alongside the new number, not the form:
        // changing a phone shouldn't silently persist half-typed (and
        // unvalidated) edits to the other fields.
        final saved = provider.user ?? currentUser;
        final result = await viewModel.updateProfile(
          firstName: saved.profile?.firstName ?? '',
          lastName: saved.profile?.lastName ?? '',
          email: saved.email,
          phone: PhoneUtils.formatToInternational(newPhone),
          address: saved.profile?.address,
        );

        result.fold((failure) => throw Exception(failure.message), (_) {});
      },
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
    // Last photo the server actually accepted, restored if this one fails so
    // the hero never shows a picture that wasn't saved.
    final lastSaved = _pickedAvatar;
    setState(() {
      _pickedAvatar = file;
      _uploadingAvatar = true;
    });

    // AuthViewmodel already updates CurrentUserProvider with the new avatar
    // on success — only failures need to be surfaced here.
    final result = await context.read<AuthViewmodel>().uploadAvatar(file.path);

    if (!mounted) return;
    setState(() {
      _uploadingAvatar = false;
      if (result.isLeft()) _pickedAvatar = lastSaved;
    });

    result.fold(
      (failure) => CustomDialog.showError(
        context: context,
        title: 'Photo Update Failed',
        subtitle: failure.message,
      ),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final user = context.watch<CurrentUserProvider>().user;
    final referralCode = user?.profile?.referralCode ?? '';
    final firstName = user?.profile?.firstName ?? '';
    final lastName = user?.profile?.lastName ?? '';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                onPressed: () => context.pop(),
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
                          onPressed: _isDirty ? _saveProfile : null,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            disabledForegroundColor: Colors.white.withValues(
                              alpha: 0.4,
                            ),
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
                  name: _normalizeName('$firstName $lastName'),
                  avatarUrl: user?.profile?.profilePictureUrl,
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
                  _ProfileField(
                    key: _nameFieldKey,
                    icon: HugeIcons.strokeRoundedUser,
                    label: 'Full Name',
                    hint: 'e.g. John Doe',
                    controller: _nameController,
                    validator: _validateName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                  ),
                  SizedBox(height: w * 0.04),
                  _ProfileField(
                    key: _emailFieldKey,
                    icon: HugeIcons.strokeRoundedMail01,
                    label: 'Email',
                    hint: 'e.g. you@email.com',
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  SizedBox(height: w * 0.04),
                  _ReadOnlyPhoneCard(
                    phone: user?.phone ?? '',
                    onEditRequested: _changePhone,
                  ),
                  SizedBox(height: w * 0.04),
                  _ProfileField(
                    icon: HugeIcons.strokeRoundedLocation01,
                    label: 'Address',
                    hint: 'e.g. 12 Ring Road, Accra',
                    controller: _addressController,
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),

                  if (referralCode.isNotEmpty) ...[
                    SizedBox(height: w * 0.07),
                    _FormSection(label: 'Referral'),
                    SizedBox(height: w * 0.032),
                    _ReferralCard(
                      code: referralCode,
                      count: user?.profile?.referralCount ?? 0,
                      onCopy: () => _copyReferralCode(referralCode),
                      onShare: () => _shareReferralCode(referralCode),
                      onTap: () => context.push(AppRoutes.inviteFriend),
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
                        iconColor: AppColors.secondary,
                        label: 'Change Password',
                        onTap: () => ChangePasswordSheet.show(context),
                      ),
                      _FieldDivider(w: w),
                      _ActionRow(
                        icon: HugeIcons.strokeRoundedLogout01,
                        iconColor: AppColors.secondary,
                        label: 'Log Out',
                        onTap: () => confirmLogout(context),
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
                      onPressed: (_loading || !_isDirty) ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(
                          alpha: 0.35,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.7,
                        ),
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
                                  icon:
                                      HugeIcons.strokeRoundedCheckmarkCircle01,
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
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account',
      subtitle:
          'This action is permanent and cannot be undone. All your orders, '
          'saved details, and wallet history will be permanently deleted.',
      confirmText: 'Continue',
      cancelText: 'Cancel',
      onConfirm: () => context.push(AppRoutes.deleteAccount),
    );
  }

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

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied')));
  }

  void _shareReferralCode(String code) {
    if (code.isEmpty) return;
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join me on bagyesRUSH! Use my referral code $code when you sign up.',
      ),
    );
  }
}

// ─── Edit Profile Hero ─────────────────────────────────────────────────────────

class _EditProfileHero extends StatelessWidget {
  final double w;
  final VoidCallback onTapAvatar;
  final File? localAvatar;
  final String name;
  final String? avatarUrl;
  final bool isUploading;

  const _EditProfileHero({
    required this.w,
    required this.onTapAvatar,
    required this.name,
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
                        child: localAvatar != null
                            ? ClipOval(
                                child: Image.file(
                                  localAvatar!,
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : NetworkAvatar(
                                name: name,
                                size: avatarRadius * 2,
                                photoUrl: avatarUrl,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                                foregroundColor: Colors.white,
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

// ─── Profile Field ──────────────────────────────────────────────────────────
//
// Deliberately neutral: a quiet filled field with a hairline border and a
// grey icon, label above. Focus darkens the border instead of tinting the
// whole card, so the form reads as one calm surface rather than a stack of
// colour-coded boxes. Only validation errors introduce colour.

class _ProfileField extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int minLines;
  final ValueChanged<String>? onSubmitted;

  const _ProfileField({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.maxLines = 1,
    this.minLines = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        SizedBox(height: w * 0.02),
        TextFormField(
          controller: controller,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          maxLines: maxLines,
          minLines: minLines,
          onFieldSubmitted: onSubmitted,
          cursorColor: AppColors.primary,
          style: TextStyle(
            fontSize: (w * 0.04).clamp(14.0, 17.0),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textHint,
              fontSize: (w * 0.037).clamp(13.0, 16.0),
            ),
            isDense: true,
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.036),
              child: HugeIcon(
                icon: icon,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.01,
              vertical: w * 0.038,
            ),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary, 1.6),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error, 1.4),
            errorStyle: TextStyle(
              color: AppColors.error,
              fontSize: (w * 0.03).clamp(11.0, 13.0),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      text,
      style: TextStyle(
        fontSize: (w * 0.033).clamp(12.0, 14.0),
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
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
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.045,
            vertical: w * 0.038,
          ),
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
                  child: HugeIcon(
                    icon: icon,
                    color: iconColor,
                    size: w * 0.036,
                  ),
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
  final VoidCallback onShare;
  final VoidCallback onTap;

  const _ReferralCard({
    required this.code,
    required this.count,
    required this.onCopy,
    required this.onShare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(w * 0.045),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              Color(0xFFEF5350),
            ],
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
                Expanded(
                  child: Text(
                    'Invite Friends & Earn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: (w * 0.04).clamp(14.0, 17.0),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: w * 0.05,
                ),
              ],
            ),
            SizedBox(height: w * 0.02),
            Text(
              count > 0
                  ? 'You\'ve referred ${count.toInt()} ${count == 1 ? 'friend' : 'friends'} so far.'
                  : 'Share your code with friends and family.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: (w * 0.032).clamp(11.0, 14.0),
              ),
            ),
            SizedBox(height: w * 0.04),
            ReferralCodeCard(code: code, onCopy: onCopy, onShare: onShare),
          ],
        ),
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

class _ReadOnlyPhoneCard extends StatelessWidget {
  final String phone;
  final VoidCallback onEditRequested;

  const _ReadOnlyPhoneCard({
    required this.phone,
    required this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Phone Number'),
        SizedBox(height: w * 0.02),
        Container(
          padding: EdgeInsets.only(
            left: w * 0.036,
            right: w * 0.02,
            top: w * 0.012,
            bottom: w * 0.012,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSmartPhone01,
                color: AppColors.textSecondary,
                size: 20,
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Text(
                  phone.isNotEmpty ? phone : 'Not set',
                  style: TextStyle(
                    fontSize: (w * 0.04).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEditRequested,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                ),
                child: Text(
                  'Change',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: (w * 0.034).clamp(12.0, 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
