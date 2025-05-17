import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/config_model.dart';
import '../models/server_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  Db? _db;
  bool _isConnected = false;

  // Singleton pattern
  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<bool> isConnected() async {
    if (_db == null) return false;
    return _isConnected;
  }

  Future<void> connect() async {
    if (_db != null && _isConnected) return;

    try {
      final mongoUrl = dotenv.env['MONGO_URL'] ?? 'mongodb://localhost:27017/vpn_client';
      _db = await Db.create(mongoUrl);
      await _db!.open();
      _isConnected = true;
      print('Connected to MongoDB with uri $mongoUrl');
    } catch (e) {
      print('Failed to connect to MongoDB: $e');
      _isConnected = false;
    }
  }

  Future<void> close() async {
    if (_db != null && _isConnected) {
      await _db!.close();
      _isConnected = false;
      print('Disconnected from MongoDB');
    }
  }

  // Méthodes pour les serveurs
  Future<List<ServerModel>> getServers() async {
    if (!await isConnected()) {
      try {
        await connect();
      } catch (e) {
        return [];
      }
    }

    try {
      final collection = _db!.collection('servers');
      final servers = await collection.find().toList();
      return servers.map((server) => ServerModel.fromJson(server)).toList();
    } catch (e) {
      print('Error getting servers: $e');
      return [];
    }
  }

  Future<ServerModel?> getServerById(String id) async {
    if (!await isConnected()) {
      try {
        await connect();
      } catch (e) {
        return null;
      }
    }

    try {
      final collection = _db!.collection('servers');
      final server = await collection.findOne(where.eq('_id', id));
      if (server == null) return null;
      return ServerModel.fromJson(server);
    } catch (e) {
      print('Error getting server: $e');
      return null;
    }
  }

  // Méthodes pour les configurations
  Future<ConfigModel?> getConfigById(String id) async {
    if (!await isConnected()) {
      try {
        await connect();
      } catch (e) {
        return null;
      }
    }

    try {
      final collection = _db!.collection('configs');
      final config = await collection.findOne(where.eq('_id', id));
      if (config == null) return null;
      return ConfigModel.fromJson(config);
    } catch (e) {
      print('Error getting config: $e');
      return null;
    }
  }

  Future<ConfigModel?> getConfigForServer(String serverId) async {
    final server = await getServerById(serverId);
    if (server == null) return null;
    return getConfigById(server.configId);
  }

  Future<List<ConfigModel>> getConfigs() async {
    if (!await isConnected()) {
      try {
        await connect();
      } catch (e) {
        return [];
      }
    }

    try {
      final collection = _db!.collection('configs');
      final configs = await collection.find().toList();
      return configs.map((config) => ConfigModel.fromJson(config)).toList();
    } catch (e) {
      print('Error getting configs: $e');
      return [];
    }
  }

}