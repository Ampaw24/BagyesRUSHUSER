import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/vendor_enums.dart';
import '../../models/vendor_registration_state.dart';

/// Step 6 - Review all entered data before submission
class ReviewSubmitStep extends StatelessWidget {
  final VendorRegistrationState data;
  final ValueChanged<VendorRegistrationStep> onEditStep;

  const ReviewSubmitStep({
    super.key,
    required this.data,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header info
        Container(
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size.width * 0.03),
            color: AppColors.primary.withValues(alpha: 0.06),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: AppColors.primary,
                size: size.width * 0.06,
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Text(
                  'Please review your details before submitting your application.',
                  style: TextStyle(
                    fontSize: size.width * 0.032,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size.height * 0.025),

        // Business Details section
        _ReviewSection(
          title: 'Business Details',
          icon: Icons.storefront_outlined,
          onEdit: () => onEditStep(VendorRegistrationStep.businessDetails),
          items: [
            _ReviewItem('Business Name', data.businessDetails.businessName),
            _ReviewItem(
              'Type',
              data.businessDetails.businessType?.label ?? 'Not set',
            ),
            _ReviewItem('Contact Person', data.businessDetails.contactPersonName),
            _ReviewItem('Phone', '+233 ${data.businessDetails.phone}'),
            _ReviewItem('Email', data.businessDetails.email),
            _ReviewItem('Address', data.businessDetails.businessAddress),
            _ReviewItem('City', data.businessDetails.city),
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // Legal section
        _ReviewSection(
          title: 'Legal & Compliance',
          icon: Icons.verified_user_outlined,
          onEdit: () => onEditStep(VendorRegistrationStep.legalCompliance),
          items: [
            _ReviewItem(
              'Owner ID',
              data.legalCompliance.ownerIdPath != null
                  ? 'Uploaded'
                  : 'Not uploaded',
            ),
            _ReviewItem(
              'Business Cert.',
              data.legalCompliance.businessRegistrationCertPath != null
                  ? 'Uploaded'
                  : 'Not uploaded',
            ),
            _ReviewItem(
              'Food Safety License',
              data.legalCompliance.foodSafetyLicensePath != null
                  ? 'Uploaded'
                  : 'Not uploaded',
            ),
            _ReviewItem(
              'Tax ID',
              data.legalCompliance.taxIdentificationNumber ?? 'Not provided',
            ),
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // Operations section
        _ReviewSection(
          title: 'Operations',
          icon: Icons.schedule_outlined,
          onEdit: () => onEditStep(VendorRegistrationStep.operationalDetails),
          items: [
            _ReviewItem(
              'Cuisine',
              data.operationalDetails.cuisineTypes
                  .map((c) => c.label)
                  .join(', '),
            ),
            _ReviewItem(
              'Delivery Radius',
              '${data.operationalDetails.deliveryRadiusKm.toStringAsFixed(1)} km',
            ),
            _ReviewItem(
              'Hours',
              '${data.operationalDetails.openingTime} – ${data.operationalDetails.closingTime}',
            ),
            _ReviewItem(
              'Prep Time',
              '~${data.operationalDetails.estimatedPrepTimeMinutes} min',
            ),
            _ReviewItem(
              'Days',
              data.operationalDetails.operatingDays
                  .map((d) => d.substring(0, 3))
                  .join(', '),
            ),
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // Payout section
        _ReviewSection(
          title: 'Payout Details',
          icon: Icons.account_balance_outlined,
          onEdit: () => onEditStep(VendorRegistrationStep.payoutDetails),
          items: [
            if (data.payoutDetails.bankName.isNotEmpty) ...[
              _ReviewItem('Bank', data.payoutDetails.bankName),
              _ReviewItem(
                'Account',
                _maskAccount(data.payoutDetails.accountNumber),
              ),
              _ReviewItem('Account Name', data.payoutDetails.accountName),
            ],
            if ((data.payoutDetails.mobileMoneyProvider ?? '').isNotEmpty) ...[
              _ReviewItem(
                'MoMo Provider',
                data.payoutDetails.mobileMoneyProvider!,
              ),
              _ReviewItem(
                'MoMo Number',
                data.payoutDetails.mobileMoneyNumber ?? '',
              ),
            ],
          ],
        ),
        SizedBox(height: size.height * 0.02),

        // Verification status
        _ReviewSection(
          title: 'Verification',
          icon: Icons.verified_outlined,
          onEdit: () => onEditStep(VendorRegistrationStep.verification),
          items: [
            _ReviewItem(
              'Phone Verified',
              data.isOtpVerified ? 'Yes' : 'No',
            ),
          ],
        ),
      ],
    );
  }

  String _maskAccount(String account) {
    if (account.length <= 4) return account;
    final visible = account.substring(account.length - 4);
    return '****$visible';
  }
}

class _ReviewItem {
  final String label;
  final String value;
  const _ReviewItem(this.label, this.value);
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<_ReviewItem> items;

  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.width * 0.03),
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: size.width * 0.02,
            offset: Offset(0, size.height * 0.002),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.014,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: size.width * 0.05),
                SizedBox(width: size.width * 0.025),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: size.width * 0.038,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                        size: size.width * 0.04,
                      ),
                      SizedBox(width: size.width * 0.01),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          // Items
          Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.008),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: size.width * 0.3,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: size.width * 0.032,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.value.isNotEmpty ? item.value : '—',
                          style: TextStyle(
                            fontSize: size.width * 0.032,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
