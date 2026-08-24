import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:rag_kit/rag_kit_method_channel.dart';

abstract class RagKitPlatform extends PlatformInterface {
  /// Constructs a RagKitPlatform.
  RagKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static RagKitPlatform _instance = MethodChannelRagKit();

  /// The default instance of [RagKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelRagKit].
  static RagKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RagKitPlatform] when
  /// they register themselves.
  static set instance(RagKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
