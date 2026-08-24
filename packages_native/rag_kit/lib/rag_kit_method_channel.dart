import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:rag_kit/rag_kit_platform_interface.dart';

/// An implementation of [RagKitPlatform] that uses method channels.
class MethodChannelRagKit extends RagKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rag_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
