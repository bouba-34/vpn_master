import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/config_model.dart';
import '../models/server_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _serversBoxName = 'servers';
  static const String _configsBoxName = 'configs';
  static const String _settingsBoxName = 'settings';

  late Box<ServerModel> _serversBox;
  late Box<ConfigModel> _configsBox;
  late Box<String> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Enregistrer les adaptateurs
    //Hive.registerAdapter(ServerModelAdapter());
    //Hive.registerAdapter(ConfigModelAdapter());

    // Ouvrir les boxes
    _serversBox = await Hive.openBox<ServerModel>(_serversBoxName);
    _configsBox = await Hive.openBox<ConfigModel>(_configsBoxName);
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // Méthodes pour les serveurs
  List<ServerModel> getServers() {
    return _serversBox.values.toList();
  }

  Future<void> saveServer(ServerModel server) async {
    await _serversBox.put(server.id, server);
  }

  Future<void> saveServers(List<ServerModel> servers) async {
    final Map<String, ServerModel> serverMap = {};
    for (var server in servers) {
      serverMap[server.id] = server;
    }
    await _serversBox.putAll(serverMap);
  }

  Future<void> deleteServer(String id) async {
    await _serversBox.delete(id);
  }

  ServerModel? getServerById(String id) {
    return _serversBox.get(id);
  }

  // Méthodes pour les configurations
  ConfigModel? getConfig(String id) {
    return _configsBox.get(id);
  }

  Future<void> saveConfig(ConfigModel config) async {
    await _configsBox.put(config.id, config);
  }

  Future<void> saveConfigs(List<ConfigModel> configs) async {
    final Map<String, ConfigModel> configMap = {};
    for (var config in configs) {
      configMap[config.id] = config;
    }
    await _configsBox.putAll(configMap);
  }

  Future<void> deleteConfig(String id) async {
    await _configsBox.delete(id);
  }

  // Méthodes pour les paramètres
  String? getUuid() {
    return _settingsBox.get('uuid');
  }

  Future<void> saveUuid(String uuid) async {
    await _settingsBox.put('uuid', uuid);
  }

  String? getLastSelectedServerId() {
    return _settingsBox.get('lastSelectedServer');
  }

  Future<void> saveLastSelectedServerId(String serverId) async {
    await _settingsBox.put('lastSelectedServer', serverId);
  }
}