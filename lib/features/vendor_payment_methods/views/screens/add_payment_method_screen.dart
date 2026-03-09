import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import 'add_mobile_money_screen.dart';
import 'add_visa_card_screen.dart';

/// Entry screen where the vendor chooses the type of payment method to add.
class AddPaymentMethodScreen extends StatelessWidget {
  const AddPaymentMethodScreen({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => screen,
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Add Payment Method')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(w * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How would you like to receive payouts?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              _MethodTile(
                icon: Icons.phone_android_rounded,
                title: 'Mobile Money',
                subtitle: 'MTN, Vodafone, AirtelTigo',
                brandColors: const [Color(0xFFFFCC00), Color(0xFFE53935)],
                onTap: () => _navigate(
                  context,
                  const AddMobileMoneyScreen(),
                ),
              ),
              const SizedBox(height: 16),

              _MethodTile(
                icon: Icons.credit_card_rounded,
                title: 'Visa / Mastercard',
                subtitle: 'Debit or credit card',
                brandColors: const [Color(0xFF1A237E), Color(0xFF212121)],
                onTap: () => _navigate(
                  context,
                  const AddVisaCardScreen(),
                ),
              ),

              const Spacer(),

              // Coming soon section
              _ComingSoonSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Method tile ───────────────────────────────────────────────────────────────

class _MethodTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> brandColors;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.brandColors,
    required this.onTap,
  });

  @override
  State<_MethodTile> createState() => _MethodTileState();
}

class _MethodTileState extends State<_MethodTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.brandColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Coming soon ───────────────────────────────────────────────────────────────

class _ComingSoonSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ComingSoonChip(label: 'Bank Transfer'),
            const SizedBox(width: 8),
            _ComingSoonChip(label: 'Apple Pay'),
            const SizedBox(width: 8),
            _ComingSoonChip(label: 'Google Pay'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  final String label;
  const _ComingSoonChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
