import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/report_target_tile.dart';

/// Step 2 — "Who are you reporting?" A searchable list of past
/// vendors/riders/customers, sourced from the reporter's own order history.
class ReportTargetPickerStep extends StatefulWidget {
  final String heading;
  final List<ReportableTarget> targets;
  final ValueChanged<ReportableTarget> onSelect;

  const ReportTargetPickerStep({
    super.key,
    required this.heading,
    required this.targets,
    required this.onSelect,
  });

  @override
  State<ReportTargetPickerStep> createState() => _ReportTargetPickerStepState();
}

class _ReportTargetPickerStepState extends State<ReportTargetPickerStep> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final filtered = _query.isEmpty
        ? widget.targets
        : widget.targets
            .where((t) => t.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, 0),
          child: Text(
            widget.heading,
            style: TextStyle(
              fontSize: w * 0.052,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: w * 0.04),
        if (widget.targets.length > 5)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.05),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(vertical: w * 0.032),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(w * 0.03),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        SizedBox(height: w * 0.03),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(w: w)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.05,
                    0,
                    w * 0.05,
                    w * 0.06,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => SizedBox(height: w * 0.03),
                  itemBuilder: (context, i) => ReportTargetTile(
                    name: filtered[i].name,
                    subtitle: filtered[i].subtitle,
                    imageUrl: filtered[i].imageUrl,
                    onTap: () => widget.onSelect(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double w;
  const _EmptyState({required this.w});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSearchRemove,
              size: w * 0.14,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'Nothing to show here yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.04,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              "You'll be able to pick from your recent orders here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
