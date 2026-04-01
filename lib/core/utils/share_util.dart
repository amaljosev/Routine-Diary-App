import 'package:routine/core/constants/app_constants.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static Future<void> shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            "Every day has a story—write yours. 📖\nRecord your thoughts, track your feelings, and cherish your memories in one private space.\nDownload now:\n${AppConstants.playStoreUrl}",
      ),
    );
  }
}
