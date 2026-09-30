import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/widgets/network_avatar.dart';

/// Circular participant avatar: the photo when one is known, initials
/// otherwise, with an optional role badge (rider / vendor) in the corner.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    required this.size,
    this.photoUrl,
    this.role,
    this.showRoleBadge = false,
  });

  final String name;
  final double size;
  final String? photoUrl;

  /// Participant role from the chat API (`rider`, `vendor`, `customer`).
  final String? role;
  final bool showRoleBadge;

  IconData? get _roleIcon => switch (role) {
    'rider' => Icons.two_wheeler_rounded,
    'vendor' => Icons.storefront_rounded,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final avatar = NetworkAvatar(name: name, photoUrl: photoUrl, size: size);

    final roleIcon = _roleIcon;
    if (!showRoleBadge || roleIcon == null) return avatar;

    final badge = size * 0.4;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -badge * 0.1,
            bottom: -badge * 0.1,
            child: Container(
              width: badge,
              height: badge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: badge * 0.1),
              ),
              child: Icon(roleIcon, size: badge * 0.55, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
