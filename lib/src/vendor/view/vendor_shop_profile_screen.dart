import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../constant/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/common/app/current_user_provider.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/utils/app_logger.dart';
import '../model/vendor_profile.dart';
import '../repository/vendor_dashboard_repository.dart';
import 'widgets/edit_shop_info_sheet.dart';
import 'widgets/operating_hours_sheet.dart';
import 'widgets/delivery_settings_sheet.dart';

class VendorShopProfileScreen extends StatefulWidget {
  const VendorShopProfileScreen({super.key});

  @override
  State<VendorShopProfileScreen> createState() =>
      _VendorShopProfileScreenState();
}

class _VendorShopProfileScreenState extends State<VendorShopProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final ScrollController _scrollController;

  // Local edits overlay — null means "use live provider data"
  VendorProfile? _localEdits;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
          ),
        );
    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) setState(() => _scrollOffset = _scrollController.offset);
      });
    _entryController.forward();

    // Pull the latest profile from the API on open so the completeness card
    // reflects real server state rather than whatever was cached at login —
    // it may be stale if KYC/profile fields changed since then.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshProfile());
  }

  Future<void> _refreshProfile() async {
    final result = await sl<VendorDashboardRepository>().fetchVendorProfile();
    if (!mounted) return;
    result.fold(
      (failure) => appLogger.w(
        'VendorShopProfileScreen._refreshProfile → failed: ${failure.message}',
      ),
      (profile) {
        final currentUser = context.read<CurrentUserProvider>().user;
        if (currentUser == null) return;
        context.read<CurrentUserProvider>().setUser(
              currentUser.copyWith(profile: profile),
            );
        // Drop any local overlay now that fresh server data has landed —
        // otherwise a stale in-session edit would keep shadowing it.
        if (_localEdits != null) setState(() => _localEdits = null);
      },
    );
  }

  Future<void> _onPullToRefresh() => _refreshProfile();

  @override
  void dispose() {
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Animation<double> _staggeredFade(int index) {
    final start = 0.2 + (index * 0.07);
    final end = (start + 0.35).clamp(0.0, 1.0);
    return Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }

  Animation<Offset> _staggeredSlide(int index) {
    final start = 0.2 + (index * 0.07);
    final end = (start + 0.35).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _uploadImage('cover', picked.path);
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 90,
    );
    if (picked == null) return;
    await _uploadImage('logo', picked.path);
  }

  Future<void> _pickBannerImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _uploadImage('banner', picked.path);
  }

  Future<void> _uploadImage(String type, String filePath) async {
    final result =
        await sl<VendorDashboardRepository>().uploadVendorImage(type, filePath);
    if (!mounted) return;
    result.fold(
      (failure) => _showSaveError(failure.message),
      (profile) => setState(() => _localEdits = profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerProfile =
        context.watch<CurrentUserProvider>().user?.profile as VendorProfile?;
    final profile = _localEdits ?? providerProfile;

    final w = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.paddingOf(context).top;
    final coverHeight = w * 0.52;
    final collapsedProgress =
        (_scrollOffset / (coverHeight - topPadding - w * 0.14)).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: collapsedProgress > 0.5
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            if (profile == null)
              _NoProfilePlaceholder(topPadding: topPadding)
            else
              RefreshIndicator(
                onRefresh: _onPullToRefresh,
                color: AppColors.primary,
                child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _CoverHeroSection(
                          profile: profile,
                          coverHeight: coverHeight,
                          onEditCover: _pickCoverImage,
                          onEditLogo: _pickLogo,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      w * 0.05,
                      w * 0.03,
                      w * 0.05,
                      w * 0.12,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Completion checklist (only when incomplete) ──
                        ..._buildCompletionSection(profile, w),

                        // ── Quick stats ──
                        FadeTransition(
                          opacity: _staggeredFade(0),
                          child: SlideTransition(
                            position: _staggeredSlide(0),
                            child: _QuickStatsRow(profile: profile),
                          ),
                        ),
                        SizedBox(height: w * 0.05),

                        // ── About / Description ──
                        FadeTransition(
                          opacity: _staggeredFade(1),
                          child: SlideTransition(
                            position: _staggeredSlide(1),
                            child: _AboutCard(
                              profile: profile,
                              onEdit: () => _openEditSheet(profile),
                            ),
                          ),
                        ),
                        SizedBox(height: w * 0.04),

                        // ── Business Info ──
                        FadeTransition(
                          opacity: _staggeredFade(2),
                          child: SlideTransition(
                            position: _staggeredSlide(2),
                            child: _BusinessInfoCard(
                              profile: profile,
                              onEdit: () => _openEditSheet(profile),
                            ),
                          ),
                        ),
                        SizedBox(height: w * 0.04),

                        // ── Operating Hours ──
                        FadeTransition(
                          opacity: _staggeredFade(3),
                          child: SlideTransition(
                            position: _staggeredSlide(3),
                            child: _OperatingHoursCard(
                              profile: profile,
                              onEdit: () => _openHoursSheet(profile),
                            ),
                          ),
                        ),
                        SizedBox(height: w * 0.04),

                        // ── Delivery Settings ──
                        FadeTransition(
                          opacity: _staggeredFade(4),
                          child: SlideTransition(
                            position: _staggeredSlide(4),
                            child: _DeliverySettingsCard(
                              profile: profile,
                              onEdit: () => _openDeliverySheet(profile),
                            ),
                          ),
                        ),
                        SizedBox(height: w * 0.04),

                        // ── Cuisine Types ──
                        FadeTransition(
                          opacity: _staggeredFade(5),
                          child: SlideTransition(
                            position: _staggeredSlide(5),
                            child: _CuisineTypesCard(
                              profile: profile,
                              onEdit: () => _openEditSheet(profile),
                            ),
                          ),
                        ),
                        SizedBox(height: w * 0.04),

                        // ── Shop Banner ──
                        FadeTransition(
                          opacity: _staggeredFade(6),
                          child: SlideTransition(
                            position: _staggeredSlide(6),
                            child: _BannerImageCard(
                              bannerUrl: profile.bannerUrl,
                              onEdit: _pickBannerImage,
                            ),
                          ),
                        ),
                        SizedBox(height: w * 0.04),

                        // ── Social Links ──
                        ///Note [To be released as new update]
                        // FadeTransition(
                        //   opacity: _staggeredFade(6),
                        //   child: SlideTransition(
                        //     position: _staggeredSlide(6),
                        //     child: _SocialLinksCard(
                        //       profile: profile,
                        //       onEdit: () => _openEditSheet(profile),
                        //     ),
                        //   ),
                        // ),
                        SizedBox(height: w * 0.06),
                      ]),
                    ),
                  ),
                ],
                ),
              ),

            // ── Collapsing title bar background (can be transparent/ignored) ──
            _CollapsingTitleBar(
              progress: collapsedProgress,
              topPadding: topPadding,
              title: profile?.businessName ?? '',
            ),

            // ── Back button — ALWAYS tappable, never ignored ──
            Positioned(
              top: topPadding + w * 0.02,
              left: w * 0.03,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(w * 0.025),
                  decoration: BoxDecoration(
                    color: collapsedProgress > 0.5
                        ? AppColors.surfaceVariant
                        : Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: collapsedProgress > 0.5
                        ? AppColors.textPrimary
                        : Colors.white,
                    size: w * 0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCompletionSection(VendorProfile profile, double w) {
    final missing = _getMissingFields(profile);
    if (missing.isEmpty) return [];
    return [
      FadeTransition(
        opacity: _staggeredFade(0),
        child: SlideTransition(
          position: _staggeredSlide(0),
          child: _ProfileCompletionCard(missingFields: missing),
        ),
      ),
      SizedBox(height: w * 0.05),
    ];
  }

  /// Backend field key → human-readable label. Sourced directly from
  /// `profile.missingProfileFields` (the API's own `missing_profile_fields`,
  /// the same list it uses to compute `is_profile_complete` — see
  /// `buildVendorSetupSteps` in `setup_progress_card.dart` for the sibling
  /// usage) rather than re-derived from several separate client-side field
  /// checks that can drift out of sync with what the backend considers
  /// outstanding.
  static const _missingFieldLabels = {
    'contact_person_name': 'Contact person name',
    'business_address': 'Business address',
    'city': 'City',
    'description': 'Shop description',
    'tax_identification_number': 'Tax ID (TIN)',
    'cuisine_types': 'Cuisine types',
    'phone': 'Phone number',
    'email': 'Email address',
    'logo_url': 'Shop logo',
    'logo': 'Shop logo',
    'opening_time': 'Opening time',
    'closing_time': 'Closing time',
    'operating_days': 'Operating days',
    'estimated_prep_time_minutes': 'Estimated prep time',
    'delivery_radius_km': 'Delivery radius',
    'min_order': 'Minimum order amount',
    'delivery_fee': 'Delivery fee',
    'documents': 'Identity documents',
    'payout_details': 'Payout details',
  };

  List<String> _getMissingFields(VendorProfile profile) {
    return profile.missingProfileFields
        .map((field) => _missingFieldLabels[field] ?? _humanizeField(field))
        .toList();
  }

  String _humanizeField(String field) {
    return field
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  void _showSaveError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save changes: $error')),
    );
  }

  void _openEditSheet(VendorProfile profile) {
    EditShopInfoSheet.show(
      context,
      profile: profile,
      onSave: (updated) async {
        final result = await sl<VendorDashboardRepository>()
            .updateVendorProfile(updated.toJson());
        result.fold(
          (failure) => _showSaveError(failure.message),
          (_) {
            if (mounted) setState(() => _localEdits = updated);
          },
        );
      },
    );
  }

  void _openHoursSheet(VendorProfile profile) {
    OperatingHoursSheet.show(
      context,
      profile: profile,
      onSave: (updated) async {
        // The backend only stores a single opening/closing time plus the
        // set of operating days — not per-day hours — so the sheet's
        // per-day picks collapse to the first open day's times here.
        final result = await sl<VendorDashboardRepository>().submitOperationalKyc(
          openingTime: updated.openingTime,
          closingTime: updated.closingTime,
          operatingDays: updated.operatingDays,
          estimatedPrepTimeMinutes: updated.estimatedPrepTimeMinutes,
        );
        result.fold(
          (failure) => _showSaveError(failure.message),
          (savedProfile) {
            if (mounted) setState(() => _localEdits = savedProfile);
          },
        );
      },
    );
  }

  void _openDeliverySheet(VendorProfile profile) {
    DeliverySettingsSheet.show(
      context,
      profile: profile,
      onSave: (updated) async {
        final result = await sl<VendorDashboardRepository>()
            .updateVendorProfile(updated.toJson());
        result.fold(
          (failure) => _showSaveError(failure.message),
          (_) {
            if (mounted) setState(() => _localEdits = updated);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── No Profile Placeholder ──────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _NoProfilePlaceholder extends StatelessWidget {
  final double topPadding;
  const _NoProfilePlaceholder({required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedStore01,
            color: AppColors.textHint,
            size: w * 0.14,
          ),
          SizedBox(height: w * 0.04),
          Text(
            'Profile not available',
            style: TextStyle(
              fontSize: w * 0.042,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            'Your shop profile data could not be loaded.',
            style: TextStyle(fontSize: w * 0.032, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Profile Completion Card ─────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileCompletionCard extends StatelessWidget {
  final List<String> missingFields;
  const _ProfileCompletionCard({required this.missingFields});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border(left: BorderSide(color: AppColors.warning, width: 3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: AppColors.warning,
                size: w * 0.045,
              ),
              SizedBox(width: w * 0.02),
              Text(
                'Complete your profile',
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.008,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(w * 0.05),
                ),
                child: Text(
                  '${missingFields.length} missing',
                  style: TextStyle(
                    fontSize: w * 0.026,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.025),
          Text(
            'Add the following to make your shop visible to customers:',
            style: TextStyle(
              fontSize: w * 0.03,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: w * 0.025),
          Wrap(
            spacing: w * 0.02,
            runSpacing: w * 0.018,
            children: missingFields
                .map((field) => _MissingFieldChip(label: field))
                .toList(),
          ),
          SizedBox(height: w * 0.04),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.vendorKyc),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: w * 0.032),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.025),
                ),
              ),
              icon: Icon(Icons.verified_user_outlined, size: w * 0.042, color: Colors.white),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Complete KYC Verification',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

class _MissingFieldChip extends StatelessWidget {
  final String label;
  const _MissingFieldChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.028, vertical: w * 0.012),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.012,
            height: w * 0.012,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: w * 0.015),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.028,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Cover Hero Section ──────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _CoverHeroSection extends StatelessWidget {
  final VendorProfile profile;
  final double coverHeight;
  final VoidCallback onEditCover;
  final VoidCallback onEditLogo;

  const _CoverHeroSection({
    required this.profile,
    required this.coverHeight,
    required this.onEditCover,
    required this.onEditLogo,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final logoSize = w * 0.22;

    return SizedBox(
      height: coverHeight + logoSize * 0.4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover image — tap to edit
          GestureDetector(
            onTap: onEditCover,
            child: Container(
              height: coverHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (profile.coverImageUrl != null)
                    _buildCoverImage(profile.coverImageUrl!),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  // Camera button — top right (always tappable, separate from back button area)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + w * 0.02,
                    right: w * 0.04,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onEditCover,
                      child: Container(
                        padding: EdgeInsets.all(w * 0.025),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(w * 0.03),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCamera01,
                          color: Colors.white,
                          size: w * 0.045,
                        ),
                      ),
                    ),
                  ),
                  // Shop name overlay
                  Positioned(
                    bottom: w * 0.12,
                    left: w * 0.05,
                    right: w * 0.3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.businessName,
                                style: TextStyle(
                                  fontSize: w * 0.058,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            if (profile.isVerified) ...[
                              SizedBox(width: w * 0.02),
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                                color: AppColors.accentLight,
                                size: w * 0.055,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: w * 0.01),
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: w * 0.035,
                            ),
                            SizedBox(width: w * 0.01),
                            Flexible(
                              child: Text(
                                [
                                  if (profile.businessAddress.isNotEmpty)
                                    profile.businessAddress,
                                  if (profile.city.isNotEmpty) profile.city,
                                ].join(', '),
                                style: TextStyle(
                                  fontSize: w * 0.03,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logo avatar
          Positioned(
            bottom: 0,
            right: w * 0.06,
            child: GestureDetector(
              onTap: onEditLogo,
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profile.logoUrl != null && profile.logoUrl!.isNotEmpty
                      ? _buildLogoImage(profile.logoUrl!)
                      : Center(
                          child: Text(
                            profile.businessName.isNotEmpty
                                ? profile.businessName
                                      .split(' ')
                                      .take(2)
                                      .map((s) => s.isNotEmpty ? s[0] : '')
                                      .join()
                                      .toUpperCase()
                                : 'V',
                            style: TextStyle(
                              fontSize: w * 0.07,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          // Camera badge on logo
          Positioned(
            bottom: w * 0.005,
            right: w * 0.06,
            child: GestureDetector(
              onTap: onEditLogo,
              child: Container(
                padding: EdgeInsets.all(w * 0.018),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: Colors.white,
                  size: w * 0.035,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String url) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildLogoImage(String url) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Collapsing Title Bar (background + title only, NO back button) ───────
// ═══════════════════════════════════════════════════════════════════════════

class _CollapsingTitleBar extends StatelessWidget {
  final double progress;
  final double topPadding;
  final String title;

  const _CollapsingTitleBar({
    required this.progress,
    required this.topPadding,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final barHeight = topPadding + w * 0.14;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: progress < 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: barHeight,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: progress),
            boxShadow: progress > 0.8
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.only(top: topPadding),
          child: Row(
            children: [
              // Space for the always-visible back button
              SizedBox(width: w * 0.18),
              Expanded(
                child: Opacity(
                  opacity: progress,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: w * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Quick Stats Row ─────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _QuickStatsRow extends StatelessWidget {
  final VendorProfile profile;
  const _QuickStatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        _StatChip(
          icon: HugeIcons.strokeRoundedStarCircle,
          value: profile.rating.toStringAsFixed(1),
          label: '${profile.reviewCount} reviews',
          iconColor: AppColors.accent,
        ),
        SizedBox(width: w * 0.03),
        _StatChip(
          icon: HugeIcons.strokeRoundedShoppingBag01,
          value: '${profile.totalOrders}',
          label: 'total orders',
          iconColor: AppColors.success,
        ),
        SizedBox(width: w * 0.03),
        _StatChip(
          icon: HugeIcons.strokeRoundedClock01,
          value: profile.estimatedDeliveryTime,
          label: 'delivery',
          iconColor: AppColors.info,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.025,
          vertical: w * 0.03,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            HugeIcon(icon: icon, color: iconColor, size: w * 0.05),
            SizedBox(height: w * 0.015),
            Text(
              value,
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: w * 0.005),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.025,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── About Card ──────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _AboutCard extends StatelessWidget {
  final VendorProfile profile;
  final VoidCallback onEdit;

  const _AboutCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasDesc = profile.description.isNotEmpty;

    return _ProfileCard(
      title: 'About',
      icon: HugeIcons.strokeRoundedInformationCircle,
      onEdit: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasDesc ? profile.description : 'Add a description for your shop…',
            style: TextStyle(
              fontSize: w * 0.034,
              color: hasDesc ? AppColors.textPrimary : AppColors.textHint,
              height: 1.5,
            ),
          ),
          if (profile.cuisineTypes.isNotEmpty) ...[
            SizedBox(height: w * 0.03),
            Wrap(
              spacing: w * 0.02,
              runSpacing: w * 0.02,
              children: profile.cuisineTypes
                  .map(
                    (c) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
                        vertical: w * 0.012,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(w * 0.05),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Business Info Card ──────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _BusinessInfoCard extends StatelessWidget {
  final VendorProfile profile;
  final VoidCallback onEdit;

  const _BusinessInfoCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return _ProfileCard(
      title: 'Business Info',
      icon: HugeIcons.strokeRoundedStore01,
      onEdit: onEdit,
      child: Column(
        children: [
          _InfoRow(
            icon: HugeIcons.strokeRoundedUser,
            label: 'Contact Person',
            value: profile.contactPersonName.isNotEmpty
                ? profile.contactPersonName
                : '—',
          ),
          _divider(w),
          _InfoRow(
            icon: HugeIcons.strokeRoundedCall,
            label: 'Phone',
            value: profile.phone.isNotEmpty ? profile.phone : '—',
          ),
          _divider(w),
          _InfoRow(
            icon: HugeIcons.strokeRoundedMail01,
            label: 'Email',
            value: profile.email.isNotEmpty ? profile.email : '—',
          ),
          _divider(w),
          _InfoRow(
            icon: HugeIcons.strokeRoundedLocation01,
            label: 'Address',
            value: [
              if (profile.businessAddress.isNotEmpty) profile.businessAddress,
              if (profile.city.isNotEmpty) profile.city,
            ].join(', ').let((v) => v.isEmpty ? '—' : v),
          ),
          _divider(w),
          _InfoRow(
            icon: HugeIcons.strokeRoundedDocumentValidation,
            label: 'Tax ID (TIN)',
            value: profile.taxIdentificationNumber.isNotEmpty
                ? profile.taxIdentificationNumber
                : '—',
          ),
          ...[
            _divider(w),
            _InfoRow(
              icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              label: 'Account Status',
              value: _statusLabel(profile.status),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending_review':
        return 'Pending Review';
      case 'suspended':
        return 'Suspended';
      default:
        return status.isNotEmpty ? status : '—';
    }
  }

  Widget _divider(double w) => Padding(
    padding: EdgeInsets.symmetric(vertical: w * 0.02),
    child: const Divider(color: AppColors.divider, height: 1),
  );
}

class _InfoRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isEmpty = value == '—';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.008),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.018),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.02),
            ),
            child: HugeIcon(
              icon: icon,
              color: AppColors.textSecondary,
              size: w * 0.04,
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: w * 0.026,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: w * 0.003),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: w * 0.033,
                    color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
                    fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
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

// ═══════════════════════════════════════════════════════════════════════════
// ── Operating Hours Card ────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _OperatingHoursCard extends StatelessWidget {
  final VendorProfile profile;
  final VoidCallback onEdit;

  const _OperatingHoursCard({required this.profile, required this.onEdit});

  static const _dayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final today = _dayLabels.keys.elementAt(DateTime.now().weekday - 1);

    return _ProfileCard(
      title: 'Operating Hours',
      icon: HugeIcons.strokeRoundedClock01,
      onEdit: onEdit,
      child: profile.weeklyHours.isEmpty
          ? _simpleHours(w)
          : Column(
              children: _dayLabels.entries.map((entry) {
                final hours = profile.weeklyHours[entry.key];
                final isToday = entry.key == today;
                final isClosed =
                    hours?.isClosed ??
                    !profile.operatingDays.contains(entry.key);

                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03,
                    vertical: w * 0.022,
                  ),
                  margin: EdgeInsets.only(bottom: w * 0.015),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(w * 0.02),
                    border: isToday
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: w * 0.12,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: w * 0.032,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: w * 0.015,
                            vertical: w * 0.005,
                          ),
                          margin: EdgeInsets.only(right: w * 0.02),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(w * 0.01),
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
                      const Spacer(),
                      Text(
                        isClosed
                            ? 'Closed'
                            : '${hours?.open ?? profile.openingTime} – ${hours?.close ?? profile.closingTime}',
                        style: TextStyle(
                          fontSize: w * 0.031,
                          fontWeight: FontWeight.w600,
                          color: isClosed
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _simpleHours(double w) {
    if (profile.openingTime.isEmpty && profile.closingTime.isEmpty) {
      return Text(
        'No hours set yet.',
        style: TextStyle(fontSize: w * 0.033, color: AppColors.textHint),
      );
    }
    return Row(
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedClock01,
          color: AppColors.success,
          size: w * 0.045,
        ),
        SizedBox(width: w * 0.02),
        Text(
          '${profile.openingTime} – ${profile.closingTime}',
          style: TextStyle(
            fontSize: w * 0.036,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          'Daily',
          style: TextStyle(fontSize: w * 0.03, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Delivery Settings Card ──────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _DeliverySettingsCard extends StatelessWidget {
  final VendorProfile profile;
  final VoidCallback onEdit;

  const _DeliverySettingsCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return _ProfileCard(
      title: 'Delivery Settings',
      icon: HugeIcons.strokeRoundedDeliveryTruck01,
      onEdit: onEdit,
      child: Column(
        children: [
          _DeliveryInfoTile(
            icon: HugeIcons.strokeRoundedMapsLocation01,
            label: 'Delivery Radius',
            value: profile.deliveryRadiusKm > 0
                ? '${profile.deliveryRadiusKm} km'
                : '—',
            color: AppColors.info,
          ),
          SizedBox(height: w * 0.025),
          _DeliveryInfoTile(
            icon: HugeIcons.strokeRoundedMoneyBag01,
            label: 'Minimum Order',
            value: profile.minOrder > 0
                ? 'GH₵ ${profile.minOrder.toStringAsFixed(2)}'
                : '—',
            color: AppColors.accent,
          ),
          SizedBox(height: w * 0.025),
          _DeliveryInfoTile(
            icon: HugeIcons.strokeRoundedDeliveryTruck01,
            label: 'Delivery Fee',
            value: profile.deliveryFee > 0
                ? 'GH₵ ${profile.deliveryFee.toStringAsFixed(2)}'
                : '—',
            color: AppColors.success,
          ),
          SizedBox(height: w * 0.025),
          _DeliveryInfoTile(
            icon: HugeIcons.strokeRoundedClock01,
            label: 'Est. Delivery Time',
            value: (profile.deliveryTimeMin > 0 || profile.deliveryTimeMax > 0)
                ? profile.estimatedDeliveryTime
                : '—',
            color: AppColors.warning,
          ),
          SizedBox(height: w * 0.025),
          _DeliveryInfoTile(
            icon: HugeIcons.strokeRoundedTime04,
            label: 'Prep Time',
            value: profile.estimatedPrepTimeMinutes > 0
                ? '${profile.estimatedPrepTimeMinutes} min'
                : '—',
            color: AppColors.primary,
          ),
          SizedBox(height: w * 0.025),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.03,
              vertical: w * 0.025,
            ),
            decoration: BoxDecoration(
              color: profile.acceptsPreOrders
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.025),
              border: Border.all(
                color: profile.acceptsPreOrders
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  color: profile.acceptsPreOrders
                      ? AppColors.success
                      : AppColors.textHint,
                  size: w * 0.045,
                ),
                SizedBox(width: w * 0.025),
                Text(
                  'Pre-orders',
                  style: TextStyle(
                    fontSize: w * 0.033,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.025,
                    vertical: w * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: profile.acceptsPreOrders
                        ? AppColors.success
                        : AppColors.textHint,
                    borderRadius: BorderRadius.circular(w * 0.04),
                  ),
                  child: Text(
                    profile.acceptsPreOrders ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: w * 0.026,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _DeliveryInfoTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color color;

  const _DeliveryInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isEmpty = value == '—';
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.02),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(w * 0.02),
          ),
          child: HugeIcon(icon: icon, color: color, size: w * 0.04),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: w * 0.032,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: w * 0.034,
            fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w700,
            color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Cuisine Types Card ──────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _CuisineTypesCard extends StatelessWidget {
  final VendorProfile profile;
  final VoidCallback onEdit;

  const _CuisineTypesCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return _ProfileCard(
      title: 'Cuisine Types',
      icon: HugeIcons.strokeRoundedRestaurant01,
      onEdit: onEdit,
      child: profile.cuisineTypes.isEmpty
          ? Text(
              'No cuisines added yet. Tap edit to add your specialties.',
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textHint),
            )
          : Wrap(
              spacing: w * 0.025,
              runSpacing: w * 0.025,
              children: profile.cuisineTypes.map((cuisine) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: w * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(w * 0.06),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedRestaurant01,
                        color: AppColors.primary,
                        size: w * 0.035,
                      ),
                      SizedBox(width: w * 0.015),
                      Text(
                        cuisine,
                        style: TextStyle(
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Banner Image Card ───────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _BannerImageCard extends StatelessWidget {
  final String? bannerUrl;
  final VoidCallback onEdit;

  const _BannerImageCard({required this.bannerUrl, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasBanner = bannerUrl != null && bannerUrl!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                color: AppColors.primary,
                size: w * 0.045,
              ),
              SizedBox(width: w * 0.02),
              Text(
                'Shop Banner',
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03,
                    vertical: w * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(w * 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: hasBanner
                            ? HugeIcons.strokeRoundedPencilEdit01
                            : HugeIcons.strokeRoundedAdd01,
                        color: AppColors.primary,
                        size: w * 0.032,
                      ),
                      SizedBox(width: w * 0.01),
                      Text(
                        hasBanner ? 'Change' : 'Add',
                        style: TextStyle(
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.03),
          Text(
            'Shown to customers on your storefront card in search and listings.',
            style: TextStyle(
              fontSize: w * 0.03,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: w * 0.03),
          GestureDetector(
            onTap: onEdit,
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.03),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(w * 0.03),
                  child: hasBanner
                      ? _buildBannerImage(bannerUrl!)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedImageAdd01,
                                color: AppColors.textHint,
                                size: w * 0.07,
                              ),
                              SizedBox(height: w * 0.015),
                              Text(
                                'Tap to add a banner image',
                                style: TextStyle(
                                  fontSize: w * 0.03,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerImage(String url) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      final path = url.startsWith('file://') ? url.substring(7) : url;
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Social Links Card ───────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _SocialLinksCard extends StatelessWidget {
  final VendorProfile profile;
  final VoidCallback onEdit;

  const _SocialLinksCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final links = <_SocialLinkData>[
      if (profile.instagramUrl != null && profile.instagramUrl!.isNotEmpty)
        _SocialLinkData('Instagram', profile.instagramUrl!, AppColors.primary),
      if (profile.facebookUrl != null && profile.facebookUrl!.isNotEmpty)
        _SocialLinkData('Facebook', profile.facebookUrl!, AppColors.info),
      if (profile.tiktokUrl != null && profile.tiktokUrl!.isNotEmpty)
        _SocialLinkData('TikTok', profile.tiktokUrl!, AppColors.textPrimary),
      if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty)
        _SocialLinkData('Website', profile.websiteUrl!, AppColors.success),
    ];

    return _ProfileCard(
      title: 'Social Links',
      icon: HugeIcons.strokeRoundedLink01,
      onEdit: onEdit,
      child: links.isEmpty
          ? Text(
              'Connect your social medi to reach more customers.',
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textHint),
            )
          : Column(
              children: links
                  .map(
                    (link) => Padding(
                      padding: EdgeInsets.only(bottom: w * 0.02),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(w * 0.02),
                            decoration: BoxDecoration(
                              color: link.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(w * 0.02),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedLink01,
                              color: link.color,
                              size: w * 0.04,
                            ),
                          ),
                          SizedBox(width: w * 0.03),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                link.platform,
                                style: TextStyle(
                                  fontSize: w * 0.026,
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                link.handle,
                                style: TextStyle(
                                  fontSize: w * 0.032,
                                  fontWeight: FontWeight.w600,
                                  color: link.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SocialLinkData {
  final String platform;
  final String handle;
  final Color color;

  _SocialLinkData(this.platform, this.handle, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════
// ── Shared Profile Card Wrapper ─────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final VoidCallback onEdit;
  final Widget child;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, color: AppColors.primary, size: w * 0.045),
              SizedBox(width: w * 0.02),
              Text(
                title,
                style: TextStyle(
                  fontSize: w * 0.04,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.03,
                    vertical: w * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(w * 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit01,
                        color: AppColors.primary,
                        size: w * 0.032,
                      ),
                      SizedBox(width: w * 0.01),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
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

// Small utility extension to avoid redundant temp variables
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
