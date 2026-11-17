import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_data/onboarding_data.dart';
import 'package:onboarding_data/testing/onboarding_repository_contract.dart';
import 'package:onboarding_domain/testing/in_memory_onboarding_repository.dart';

void main() {
  group('FileOnboardingRepository', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('onboarding_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    runOnboardingRepositoryContractTests(
      () => FileOnboardingRepository(File('${dir.path}/onboarding.json')),
    );
  });

  group('InMemoryOnboardingRepository', () {
    runOnboardingRepositoryContractTests(InMemoryOnboardingRepository.new);
  });
}
