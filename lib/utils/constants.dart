class Constants {
  // App
  static const String appName = 'VPN Client';
  static const String appVersion = '1.0.0';

  // Messages
  static const String noServersFound = 'Aucun serveur trouvé';
  static const String noInternetConnection = 'Pas de connexion Internet';
  static const String serverConfigUpdated = 'Configuration du serveur mise à jour';
  static const String errorUpdatingConfig = 'Erreur lors de la mise à jour de la configuration';
  static const String errorConnectingVpn = 'Erreur lors de la connexion au VPN';
  static const String enterUuid = 'Veuillez entrer un UUID valide';
  static const String selectServer = 'Veuillez sélectionner un serveur';
  static const String uuidSaved = 'UUID sauvegardé';
  static const String connectionSuccessful = 'Connexion établie avec succès';
  static const String disconnectionSuccessful = 'Déconnexion réussie';

  // Hive
  static const int serverModelTypeId = 1;
  static const int configModelTypeId = 0;

  // Durations
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration connectTimeout = Duration(seconds: 15);
}