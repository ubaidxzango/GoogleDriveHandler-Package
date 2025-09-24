import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'googledrivehandler_screen.dart';

class GoogleDriveHandler {
  GoogleDriveHandler._internal();
  static final GoogleDriveHandler _googleDriveHandler =
      GoogleDriveHandler._internal();
  factory GoogleDriveHandler() => _googleDriveHandler;

  google_sign_in.GoogleSignInAccount? account;

  String? _googlDriveApiKey;
  String? _serverClientId;
  String? _iosClientId;

  void setup({
    required String apiKey,
    required String serverClientId,
    String? iosClientId,
  }) {
    _googlDriveApiKey = apiKey;
    _serverClientId = serverClientId;
    _iosClientId = iosClientId;
  }

  Future getFileFromGoogleDrive({required BuildContext context}) async {
    if (_googlDriveApiKey != null) {
      await _signinUser();
      if (account != null) {
        // ignore: use_build_context_synchronously
        return await _openGoogleDriveScreen(context);
      } else {
        log("Google Signin was declined by the user!");
      }
    } else {
      log('GOOGLEDRIVEAPIKEY has not yet been set. Please follow the documentation and call GoogleDriveHandler().setApiKey(YourAPIKey); to set your own API key');
    }
  }

  Future<Future> _openGoogleDriveScreen(BuildContext context) async {
    final authHeaders = await account!.authorizationClient
        .authorizationHeaders([drive.DriveApi.driveScope]);
    final authenticateClient = _GoogleAuthClient(authHeaders ?? {});
    final driveApi = drive.DriveApi(authenticateClient);
    drive.FileList fileList = await driveApi.files.list();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoogleDriveScreen(
          fileList: fileList,
          googleDriveApiKey: _googlDriveApiKey.toString(),
          authenticateClient: authenticateClient,
          userName: (account?.displayName ?? "").replaceAll(" ", ""),
        ),
      ),
    );
  }

  Future _signinUser() async {
    google_sign_in.GoogleSignIn googleSignIn;
    // Detect platform for clientId
    // ignore: avoid_dynamic_calls
    bool isIOS = false;
    try {
      // Use defaultTargetPlatform if available, fallback to runtimeType
      isIOS = ThemeData.fallback().platform == TargetPlatform.iOS;
    } catch (_) {}
    if (isIOS && _iosClientId != null) {
      google_sign_in.GoogleSignIn.instance.initialize(
        clientId: _iosClientId,
        serverClientId: _serverClientId,
      );
    } else {
      google_sign_in.GoogleSignIn.instance.initialize(
          clientId: _serverClientId, serverClientId: _serverClientId);
    }
    account =
        await google_sign_in.GoogleSignIn.instance.authenticate(scopeHint: [
      drive.DriveApi.driveScope,
    ]).catchError((error) {
      log("Error signing in: $error");
    });
    return;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
