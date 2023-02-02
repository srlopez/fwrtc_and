import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'dart:io' show Platform;
import 'constants.dart';

class UserSettings {
  static final UserSettings _instancia = UserSettings._internal();

  factory UserSettings() {
    return _instancia;
  }

  UserSettings._internal();

  late SharedPreferences _prefs;

  initPrefs() async {
    String deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId ?? 'deviceId ERROR await';
    } on PlatformException {
      deviceId = 'deviceId ERROR';
    }

    _prefs = await SharedPreferences.getInstance();
    _prefs.setString('peerid', deviceId);
  }

  // Servidores
  String get signalingHost {
    return _prefs.getString('signalig') ?? wsserver;
  }

  set signalingHost(String value) {
    _prefs.setString('signalig', value);
  }

  String get uploadUrl {
    return _prefs.getString('upload') ?? uploadurl;
  }

  set uploadUrl(String value) {
    _prefs.setString('upload', value);
  }

  // peerId
  String get peerId {
    return _prefs.getString('peerid') ?? 'peerId';
  }

  // Platform
  String get platform => Platform.operatingSystemVersion;

  // ALIAS
  String get alias {
    return _prefs.getString('alias') ?? peerId;
  }

  set alias(String value) {
    _prefs.setString('alias', value);
  }

  // DESCRIPCION
  String get description {
    return _prefs.getString('description') ??
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  set description(String value) {
    _prefs.setString('description', value);
  }
}
