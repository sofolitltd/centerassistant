import 'package:center_assistant/services/fcm_token_helper.dart' as prefix0;

import 'fcm_token_helper_io.dart';

abstract class FcmTokenHelper {
  Future<String?> getAccessToken(Map<String, dynamic> serviceAccount);

  static prefix0.FcmTokenHelper get instance => getFcmTokenHelper();
}
