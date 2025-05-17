import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:path_provider/path_provider.dart';
import '../models/config_model.dart';
import '../utils/config_helper.dart';

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

  String _bytesIn = '0 KB';
  String _bytesOut = '0 KB';
  String _duration = '00:00:00';
  int _downloadSpeed = 0;
  int _uploadSpeed = 0;

  VpnStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get bytesIn => _bytesIn;
  String get bytesOut => _bytesOut;
  String get duration => _duration;

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
        // Réinitialiser les statistiques lors de la déconnexion
        _resetTrafficStats();
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

    // Mettre à jour les statistiques de trafic si connecté
    if (_status == VpnStatus.connected) {
      _updateTrafficStats(status);
    }

    notifyListeners();
  }

  void _resetTrafficStats() {
    _bytesIn = '0 KB';
    _bytesOut = '0 KB';
    _duration = '00:00:00';
    _downloadSpeed = 0;
    _uploadSpeed = 0;
    notifyListeners();
  }

  // Méthode pour mettre à jour les statistiques de trafic à partir de V2RayStatus
  void _updateTrafficStats(V2RayStatus status) {
    _duration = status.duration;
    _downloadSpeed = status.downloadSpeed;
    _uploadSpeed = status.uploadSpeed;

    // Formater les totaux de download/upload pour affichage
    _bytesIn = ConfigHelper.formatBytes(status.download);
    _bytesOut = ConfigHelper.formatBytes(status.upload);
  }


  Future<bool> connect(ConfigModel config) async {
    if (_status == VpnStatus.connected || _status == VpnStatus.connecting) {
      await disconnect();
    }

    try {
      if(await _v2ray.requestPermission()){
        _status = VpnStatus.connecting;
        notifyListeners();

        final configFile = await _saveConfigToFile(config);
        _configPath = configFile.path;

        final configContent = await configFile.readAsString();

        await _v2ray.startV2Ray(
          remark: "VPN MASTER",
          config: configContent
        );
      }

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