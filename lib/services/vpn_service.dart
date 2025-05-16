import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:path_provider/path_provider.dart';
import '../models/config_model.dart';

enum VpnStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class VpnService extends ChangeNotifier {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal() {
    _initV2Ray();
  }

  late FlutterV2ray _v2ray;
  VpnStatus _status = VpnStatus.disconnected;
  String _errorMessage = '';
  String? _configPath;

  VpnStatus get status => _status;
  String get errorMessage => _errorMessage;

  Future<void> _initV2Ray() async {
    _v2ray = FlutterV2ray(
      onStatusChanged: (status) {
        _handleStatusChange(status);
      },
    );

    await _v2ray.initializeV2Ray(
      notificationIconResourceName: "ic_launcher",
      notificationIconResourceType: "mipmap",
    );
  }

  void _handleStatusChange(V2RayStatus status) {
    switch (status.state.toUpperCase()) {
      case 'DISCONNECTED':
      case 'STOPPED':
      case 'STOPPING':
        _status = VpnStatus.disconnected;
        break;
      case 'CONNECTING':
      case 'STARTING':
        _status = VpnStatus.connecting;
        break;
      case 'CONNECTED':
      case 'STARTED':
        _status = VpnStatus.connected;
        break;
      case 'ERROR':
        _status = VpnStatus.error;
        break;
      default:
        _status = VpnStatus.disconnected;
        break;
    }

    notifyListeners();
  }


  Future<bool> connect(ConfigModel config) async {
    if (_status == VpnStatus.connected || _status == VpnStatus.connecting) {
      await disconnect();
    }

    try {
      _status = VpnStatus.connecting;
      notifyListeners();

      final configFile = await _saveConfigToFile(config);
      _configPath = configFile.path;

      final configContent = await configFile.readAsString();

      //print("connecting using config content");


      await _v2ray.startV2Ray(
        remark: "VPN Connection",
        config: configContent,
      );

      return true;
    } catch (e) {
      _status = VpnStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_status != VpnStatus.disconnected) {
      try {
        await _v2ray.stopV2Ray();
        _status = VpnStatus.disconnected;
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
        notifyListeners();
      }
    }
  }

  /*Future<File> _saveConfigToFile(ConfigModel config) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/v2ray_config.json');
    await file.writeAsString(config.configJson);
    return file;
  }*/

  Future<File> _saveConfigToFile(ConfigModel config) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/v2ray_config.json');

    // Convertir le JSON en chaîne avant d'écrire dans le fichier
    final jsonString = jsonEncode(config.configJson);

    await file.writeAsString(jsonString);
    return file;
  }


  Future<bool> isV2RayRunning() async {
    try {
      final version = await _v2ray.getCoreVersion();
      return version.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}