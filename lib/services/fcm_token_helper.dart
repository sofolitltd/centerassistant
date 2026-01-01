import 'fcm_token_helper_io.dart';

abstract class FcmTokenHelper {
  Future<String?> getAccessToken(Map<String, dynamic> serviceAccount);

  static FcmTokenHelper get instance => getFcmTokenHelper();
}
