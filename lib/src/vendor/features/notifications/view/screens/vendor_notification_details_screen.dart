import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../../../../constant/app_theme.dart';
import '../../../../../notification/model/notification.model.dart';
import '../../../../../notification/utils/notification_style.dart';
import '../../../../../notification/viewmodel/notification_viewmodel.dart';

/// Rich detail view for a single [NotificationModel], pushed from
/// [VendorNotificationsScreen] when a tile is tapped.
class VendorNotificationDetailsScreen extends StatefulWidget {
  const VendorNotificationDetailsScreen({super.key, required this.notification});

  final NotificationModel notification;

  @override
  State<VendorNotificationDetailsScreen> createState() =>
      _VendorNotificationDetailsScreenState();
}

class _VendorNotificationDetailsScreenState
    extends State<VendorNotificationDetailsScreen> {
  late NotificationModel _notification;

  @override
  void initState() {
    super.initState();
    _notification = widget.notification;
  }

  static const Set<String> _hiddenDataKeys = {
    'type',
    'title',
    'body',
    'message',
  };

  Iterable<MapEntry<String, dynamic>> get _extraDetails =>
      _notification.data.entries.where(
        (e) => !_hiddenDataKeys.contains(e.key) && e.value != null,
      );

  String _prettyKey(String key) {
    final spaced = key.replaceAll('_', ' ');
    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  void _deleteNotification() {
    final w = MediaQuery.sizeOf(context).width;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: w * 0.12,
                  height: 4,
                  margin: EdgeInsets.only(bottom: w * 0.05),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: AppColors.error,
                    size: w * 0.055,
                  ),
                  title: Text(
                    'Delete notification',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context
                        .read<NotificationViewmodel>()
                        .deleteNotification(
                          _notification.id,
                          wasUnread: !_notification.isRead,
                        );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final n = _notification;
    final bg = NotificationStyle.avatarBg(n.type);
    final fg = NotificationStyle.avatarFg(n.type);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onDelete: _deleteNotification),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.05,
                    w * 0.02,
                    w * 0.05,
                    w * 0.06,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Icon + title hero ─────────────────────────
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(w * 0.05),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(w * 0.045),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(w * 0.035),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: HugeIcon(
                                    icon: NotificationStyle.icon(n.type),
                                    color: fg,
                                    size: w * 0.075,
                                  ),
                                ),
                                SizedBox(width: w * 0.04),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Pill(
                                        label: NotificationStyle.label(n.type),
                                        bg: bg,
                                        fg: fg,
                                      ),
                                      SizedBox(height: w * 0.022),
                                      Text(
                                        n.title.isNotEmpty
                                            ? n.title
                                            : 'Notification',
                                        style: TextStyle(
                                          fontFamily: 'Mukta',
                                          fontSize: w * 0.05,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: w * 0.04),
                            Row(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedClock01,
                                  color: AppColors.textHint,
                                  size: w * 0.035,
                                ),
                                SizedBox(width: w * 0.015),
                                Expanded(
                                  child: Text(
                                    NotificationStyle.fullTimestamp(
                                        n.createdAt),
                                    style: TextStyle(
                                      fontFamily: 'Mukta',
                                      fontSize: w * 0.031,
                                      color: AppColors.textHint,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!n.isRead)
                                  Container(
                                    width: w * 0.02,
                                    height: w * 0.02,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: w * 0.04),

                      // ── Message body ────────────────────────────────
                      _SectionLabel('Message'),
                      SizedBox(height: w * 0.025),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(w * 0.045),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(w * 0.04),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Text(
                          n.body.isNotEmpty
                              ? n.body
                              : 'No additional details for this notification.',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: w * 0.037,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),

                      // ── Extra data ───────────────────────────────────
                      if (_extraDetails.isNotEmpty) ...[
                        SizedBox(height: w * 0.05),
                        _SectionLabel('Details'),
                        SizedBox(height: w * 0.025),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(w * 0.04),
                            border:
                                Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Column(
                            children: [
                              for (final entry in _extraDetails)
                                _DetailRow(
                                  label: _prettyKey(entry.key),
                                  value: entry.value.toString(),
                                  isLast: entry.key == _extraDetails.last.key,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
            'Notification',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.048,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: EdgeInsets.all(w * 0.022),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: AppColors.error,
                size: w * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small pieces ────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(w * 0.02),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: w * 0.028,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Mukta',
        fontSize: w * 0.03,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isLast,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.032),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.033,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.033,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
