import 'package:googleapis_auth/auth_io.dart' as auth;

import 'fcm_token_helper.dart';

class FcmTokenHelperIO extends FcmTokenHelper {
  @override
  Future<String?> getAccessToken(Map<String, dynamic> serviceAccount) async {
    try {
      final credentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccount,
      );
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await auth.clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();

      return accessToken;
    } catch (e) {
      print('Error getting access token (IO): $e');
      return null;
    }
  }
}

FcmTokenHelper getFcmTokenHelper() => FcmTokenHelperIO();
