import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show AppBar, MaterialPageRoute, Navigator, SafeArea, Scaffold;
import 'package:webview_flutter/webview_flutter.dart';

import 'model/config.dart';
import 'request/authorization_request.dart';

class RequestCode {
  final StreamController<String?> _onCodeListener = StreamController();
  final Config _config;
  late AuthorizationRequest _authorizationRequest;

  Stream<String?>? _onCodeStream;

  RequestCode(Config config) : _config = config {
    _authorizationRequest = AuthorizationRequest(config);
  }

  Future<String?> requestCode() async {
    String? code;
    final String urlParams = _constructUrlParams();
    if (_config.context != null) {
      String initialURL =
          ('${_authorizationRequest.url}?$urlParams').replaceAll(' ', '%20');

      await _mobileAuth(initialURL);
    } else {
      throw Exception('Context is null. Please call setContext(context).');
    }

    code = await _onCode.first;
    return code;
  }

  _mobileAuth(String initialURL) async {
    var webView = WebView(
      initialUrl: initialURL,
      javascriptMode: JavascriptMode.unrestricted,
      onPageFinished: (url) => _getUrlData(url),
    );

    await Navigator.of(_config.context!).push(
      MaterialPageRoute(
        builder: (context) => SafeArea(
          child: _config.pageTitle == null ? webView : _builTitle(webView),
        ),
      ),
    );
  }

  _builTitle(WebView webView) {
    if (Platform.isAndroid || (_config.useMaterialAppBar ?? false)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_config.pageTitle!),
        ),
        body: webView,
      );
    } else if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_config.pageTitle!),
        ),
        child: webView,
      );
    }
  }

  _getUrlData(String _url) {
    var url = _url.replaceFirst('#', '?');
    Uri uri = Uri.parse(url);

    if (uri.queryParameters['error'] != null) {
      Navigator.of(_config.context!).pop();

      if (uri.queryParameters['error_subcode'] != null &&
          uri.queryParameters['error_subcode'] == 'cancel') {
        return;
      }
      _onCodeListener.addError(
        Exception(
          'Access denied or authentication canceled.',
        ),
      );
    }

    var token = uri.queryParameters['code'];
    if (token != null) {
      _onCodeListener.add(token);
      Navigator.of(_config.context!).pop();
    }
  }

  Future<void> clearCookies() async {
    await CookieManager().clearCookies();
  }

  Stream<String?> get _onCode =>
      _onCodeStream ??= _onCodeListener.stream.asBroadcastStream();

  String _constructUrlParams() =>
      _mapToQueryParams(_authorizationRequest.parameters);

  String _mapToQueryParams(Map<String, String> params) {
    final queryParams = <String>[];
    params
        .forEach((String key, String value) => queryParams.add('$key=$value'));
    return queryParams.join('&');
  }

  void setContext(BuildContext context) {
    _config.context = context;
  }
}
