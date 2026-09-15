/// Why an OTP is being requested/verified — sent to the backend so it can
/// scope rate-limiting, copy, and post-verification side effects per flow.
/// Shared by both the user and vendor auth flows.
enum OtpPurpose {
  signup('signup'),
  login('login'),
  phoneChange('phone_change'),
  transaction('transaction'),
  accountRecovery('account_recovery');

  const OtpPurpose(this.value);

  final String value;
}
