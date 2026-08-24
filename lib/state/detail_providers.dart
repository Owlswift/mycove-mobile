import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/my_cove_api.dart';

/// Providers for the handful of detail screens whose data isn't already
/// sitting in the bootstrap-loaded lists in [AppState]. These read the raw
/// decoded JSON map directly rather than adding one-off model classes for
/// detail-only shapes.
final myCoveApiProvider = Provider<MyCoveApi>((ref) => MyCoveApi());

final announcementDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(myCoveApiProvider).announcement(id),
);

final meetingDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(myCoveApiProvider).meeting(id),
);

final projectDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(myCoveApiProvider).project(id),
);
