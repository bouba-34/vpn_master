import 'dart:convert';
import 'package:hive/hive.dart';

part 'config_model.g.dart';

@HiveType(typeId: 0)
class ConfigModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String remarks;

  @HiveField(2)
  final String configJson;

  @HiveField(3)
  final DateTime lastUpdated;

  ConfigModel({
    required this.id,
    required this.remarks,
    required this.configJson,
    required this.lastUpdated,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      id: json['_id'] ?? '',
      remarks: json['remarks'] ?? '',
      configJson: json['configJson'] ?? '',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'remarks': remarks,
      'configJson': configJson,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Méthode pour mettre à jour l'UUID dans la configuration
  ConfigModel updateUuid(String newUuid) {
    try {
      Map<String, dynamic> config = jsonDecode(configJson);

      // Mise à jour de l'UUID dans la configuration V2Ray
      if (config.containsKey('outbounds') && config['outbounds'] is List) {
        for (var outbound in config['outbounds']) {
          if (outbound['tag'] == 'proxy' &&
              outbound['protocol'] == 'vless' &&
              outbound['settings'] != null &&
              outbound['settings']['vnext'] is List) {
            for (var vnext in outbound['settings']['vnext']) {
              if (vnext['users'] is List) {
                for (var user in vnext['users']) {
                  user['id'] = newUuid;
                }
              }
            }
          }
        }
      }

      return ConfigModel(
        id: id,
        remarks: remarks,
        configJson: jsonEncode(config),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error updating UUID: $e');
      return this;
    }
  }
}