import 'dart:convert';
import 'dart:math';

import '../models/config_model.dart';

class ConfigHelper {
  // Vérification de la validité d'un fichier de configuration JSON
  static bool isValidConfig(String jsonString) {
    try {
      final config = json.decode(jsonString);

      // Vérifie la présence de la clé 'outbounds' avec au moins un objet vless
      if (config is! Map || !config.containsKey('outbounds') || config['outbounds'] is! List) {
        return false;
      }

      for (var outbound in config['outbounds']) {
        if (outbound['protocol'] == 'vless' &&
            outbound.containsKey('settings') &&
            outbound['settings'].containsKey('vnext')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erreur de validation de configuration: $e');
      return false;
    }
  }

  // Mise à jour de l'UUID dans une configuration VLESS
  static String updateUuidInConfig(String configJson, String uuid) {
    try {
      final config = json.decode(configJson);

      if (config is Map && config.containsKey('outbounds') && config['outbounds'] is List) {
        for (var outbound in config['outbounds']) {
          if (outbound['protocol'] == 'vless' &&
              outbound.containsKey('settings') &&
              outbound['settings'].containsKey('vnext')) {
            for (var server in outbound['settings']['vnext']) {
              if (server.containsKey('users') && server['users'] is List) {
                for (var user in server['users']) {
                  user['id'] = uuid;
                }
              }
            }
          }
        }
      }

      return json.encode(config);
    } catch (e) {
      print('Erreur de mise à jour UUID: $e');
      return configJson;
    }
  }

  // Extraction des infos de serveur (host, port, protocole)
  static Map<String, String> getServerInfoFromConfig(String configJson) {
    try {
      final config = json.decode(configJson);
      String address = '';
      int port = 0;
      String protocol = '';

      if (config is Map && config.containsKey('outbounds') && config['outbounds'] is List) {
        for (var outbound in config['outbounds']) {
          if (outbound['tag'] == 'proxy' &&
              outbound.containsKey('settings') &&
              outbound['settings'].containsKey('vnext')) {
            for (var server in outbound['settings']['vnext']) {
              address = server['address'] ?? '';
              port = server['port'] ?? 0;
            }
            protocol = outbound['protocol'] ?? '';
            break;
          }
        }
      }

      return {
        'address': address,
        'port': port.toString(),
        'protocol': protocol,
      };
    } catch (e) {
      print('Erreur d\'analyse de configuration: $e');
      return {
        'address': '',
        'port': '',
        'protocol': '',
      };
    }
  }

  // Format lisible pour tailles en octets (ex: 10.5 MB)
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }
}