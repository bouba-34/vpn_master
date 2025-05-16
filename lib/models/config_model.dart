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
  final Map<String, dynamic> configJson;

  @HiveField(3)
  final DateTime lastUpdated;

  ConfigModel({
    required this.id,
    required this.remarks,
    required this.configJson,
    required this.lastUpdated,
  });

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    final lastUpdatedValue = json['lastUpdated'];
    DateTime lastUpdated;

    if (lastUpdatedValue == null) {
      lastUpdated = DateTime.now();
    } else if (lastUpdatedValue is String) {
      lastUpdated = DateTime.parse(lastUpdatedValue);
    } else if (lastUpdatedValue is DateTime) {
      lastUpdated = lastUpdatedValue;
    } else {
      // Cas inattendu, par précaution on met DateTime.now()
      lastUpdated = DateTime.now();
    }

    return ConfigModel(
      id: json['_id'] ?? '',
      remarks: json['remarks'] ?? '',
      configJson: json['configJson'] ?? {},
      lastUpdated: lastUpdated,
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
      // Vérifie que configJson est bien un Map (pas une String)
      final updatedConfig = Map<String, dynamic>.from(configJson);

      // Mise à jour de l'UUID dans la configuration V2Ray
      if (updatedConfig.containsKey('outbounds') && updatedConfig['outbounds'] is List) {
        for (var outbound in updatedConfig['outbounds']) {
          if (outbound is Map &&
              outbound['tag'] == 'proxy' &&
              outbound['protocol'] == 'vless' &&
              outbound['settings'] != null &&
              outbound['settings']['vnext'] is List) {
            for (var vnext in outbound['settings']['vnext']) {
              if (vnext['users'] is List) {
                for (var user in vnext['users']) {
                  if (user is Map) {
                    user['id'] = newUuid;
                  }
                }
              }
            }
          }
        }
      }

      return ConfigModel(
        id: id,
        remarks: remarks,
        configJson: updatedConfig,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'UUID: $e');
      return this;
    }
  }
}