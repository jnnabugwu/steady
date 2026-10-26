import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'fake_coach_model.dart';
import 'fake_coach_repository.dart';
import 'fake_domains.dart';

/// The fixed "now" the coach tests read: Sunday, Oct 25 2026, 8pm.
final coachTestNow = DateTime(2026, 10, 25, 20);

/// Every coach provider bound to a fake, as the iPhone binds them.
List<Override> coachTestOverrides({
  required FakeCoachModel model,
  required FakeCoachRepository repository,
  FakeCheckIns? checkIns,
  FakeCravings? cravings,
  DateTime Function()? now,
  String sessionId = 'session-1',
}) => [
  coachSupportAvailableProvider.overrideWithValue(true),
  coachModelProvider.overrideWithValue(model),
  coachRepositoryProvider.overrideWithValue(repository),
  coachCheckInRepositoryProvider.overrideWithValue(
    checkIns ?? FakeCheckIns({DateTime(2026, 10, 24): CheckInStatus.logged}),
  ),
  coachMetricsRepositoryProvider.overrideWithValue(
    FakeMetrics({DateTime(2026, 10, 24): 1800}),
  ),
  coachHealthKitRepositoryProvider.overrideWithValue(FakeHealth()),
  coachCravingRepositoryProvider.overrideWithValue(cravings ?? FakeCravings()),
  coachClockProvider.overrideWithValue(now ?? () => coachTestNow),
  coachIdGeneratorProvider.overrideWithValue(() => sessionId),
];
