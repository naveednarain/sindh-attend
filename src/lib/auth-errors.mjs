/** Public, actionable messages without disclosing whether an account exists. */
export function authErrorMessage(error) {
  if (error.status === 429 || ['over_email_send_rate_limit', 'over_request_rate_limit'].includes(error.code)) return 'Too many attempts. Please wait a few minutes before trying again.';
  if (error.code === 'weak_password') return 'Choose a stronger password with at least 12 characters, including letters, numbers, and a symbol.';
  if (error.status >= 500 || error.name === 'AuthRetryableFetchError') return 'The university sign-up service could not finish your request. Please try again shortly. If it continues, contact the administrator to check email delivery and authentication settings.';
  if (error.code === 'signup_disabled') return 'Student registration is temporarily closed. Please contact your department.';
  if (error.code === 'email_address_invalid') return 'Enter your complete university email address, for example 2K26BBA117@usindh.edu.pk.';
  return 'We could not complete this request. Check your details. If you already registered, try signing in or resetting your password.';
}
