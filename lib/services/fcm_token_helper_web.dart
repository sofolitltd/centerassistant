import 'fcm_token_helper.dart';

class FcmTokenHelperWeb extends FcmTokenHelper {
  @override
  Future<String?> getAccessToken(Map<String, dynamic> serviceAccount) async {
    // Note: googleapis_auth with service accounts usually requires dart:io for crypto.
    // For web, it's highly recommended to use a backend to sign tokens.
    print(
      'FCM Access Token generation is not supported on Web client due to security/library restrictions.',
    );
    return null;
  }
}

FcmTokenHelper getFcmTokenHelper() => FcmTokenHelperWeb();
