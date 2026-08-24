
import 'package:rag_kit/rag_kit_platform_interface.dart';

class RagKit {
  Future<String?> getPlatformVersion() {
    return RagKitPlatform.instance.getPlatformVersion();
  }
}
