import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rag_kit/rag_kit.dart';
import 'package:rag_kit/rag_kit_method_channel.dart';
import 'package:rag_kit/rag_kit_platform_interface.dart';

class MockRagKitPlatform
    with MockPlatformInterfaceMixin
    implements RagKitPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final initialPlatform = RagKitPlatform.instance;

  test('$MethodChannelRagKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRagKit>());
  });

  test('getPlatformVersion', () async {
    final ragKitPlugin = RagKit();
    final fakePlatform = MockRagKitPlatform();
    RagKitPlatform.instance = fakePlatform;

    expect(await ragKitPlugin.getPlatformVersion(), '42');
  });
}
