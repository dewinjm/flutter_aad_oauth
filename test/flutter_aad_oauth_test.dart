import 'package:azure_oauth/azure_oauth.dart';
import 'package:azure_oauth/model/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds one to input values', () {
    final Config config = Config(
        azureTenantId: 'YOUR TENANT ID',
        clientId: 'YOUR CLIENT ID',
        scope: 'openid profile offline_access',
        redirectUri: 'redirectUri',
        responseType: 'code');
    final FlutterAadOauth oauth = FlutterAadOauth(config);
    oauth.toString();
  });
}
