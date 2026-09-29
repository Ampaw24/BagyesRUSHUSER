import 'package:bagyesrushappusernew/core/router/app_routes.dart';

/// Host the legal pages are served from; in-page links elsewhere open in
/// the external browser.
const String legalSiteHost = 'bagyesrushdelivery.com';

/// Legal pages hosted on the bagyesRUSH website, shown in-app via
/// `LegalWebViewScreen`.
enum LegalDocument {
  privacyPolicy(
    title: 'Privacy Policy',
    url: 'https://$legalSiteHost/privacy-policy',
    routePath: AppRoutes.privacyPolicy,
  ),
  termsConditions(
    title: 'Terms & Conditions',
    url: 'https://$legalSiteHost/terms-conditions',
    routePath: AppRoutes.termsConditions,
  ),
  refundPolicy(
    title: 'Refund Policy',
    url: 'https://$legalSiteHost/refund-policy',
    routePath: AppRoutes.refundPolicy,
  );

  const LegalDocument({
    required this.title,
    required this.url,
    required this.routePath,
  });

  final String title;
  final String url;
  final String routePath;
}
