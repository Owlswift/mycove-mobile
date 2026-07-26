/// Static UI option lists that aren't user data and have no backend
/// endpoint — everything else that used to live here now comes from the
/// API (see lib/data/community_hub_api.dart).
const complaintCategoryOptions = <String>['Maintenance', 'Security', 'Noise', 'Billing', 'Other'];

const donationPresets = <int>[5000, 10000, 25000];
