/// Keys must match FEATURE_FLAG_KEYS in mycove-api's
/// feature-flags.service.ts exactly — these are plain strings on both
/// sides rather than a shared enum since the two live in separate repos.
class FeatureFlagKeys {
  static const duesPayments = 'dues_payments';
  static const utilityPayments = 'utility_payments';
  static const visitorPasses = 'visitor_passes';
}
