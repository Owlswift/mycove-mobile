import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/birthday.dart';
import '../data/my_cove_api.dart';

/// Providers for the handful of detail screens whose data isn't already
/// sitting in the bootstrap-loaded lists in [AppState]. These read the raw
/// decoded JSON map directly rather than adding one-off model classes for
/// detail-only shapes.
final myCoveApiProvider = Provider<MyCoveApi>((ref) => MyCoveApi());

/// The resident's domestic staff and the entry-code requests waiting for their approval.
final domesticStaffProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async => (await ref.watch(myCoveApiProvider).domesticStaff()).cast<Map<String, dynamic>>(),
);

final domesticRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async => (await ref.watch(myCoveApiProvider).domesticRequests()).cast<Map<String, dynamic>>(),
);

/// The resident's own birthday and any celebration prompt. Invalidate after
/// saving so the dashboard cards refresh.
final myBirthdayProvider = FutureProvider.autoDispose<MyBirthday>(
  (ref) async => MyBirthday.fromJson(await ref.watch(myCoveApiProvider).myBirthday()),
);

final announcementDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(myCoveApiProvider).announcement(id),
);

final meetingDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(myCoveApiProvider).meeting(id),
);

final projectDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(myCoveApiProvider).project(id),
);
