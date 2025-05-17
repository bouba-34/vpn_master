# VPN Master

Une application mobile Flutter permettant de se connecter à des serveurs VPN en utilisant le protocole VLESS (V2Ray).

## 📋 Table des matières

- [Description](#description)
- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Technologies utilisées](#technologies-utilisées)
- [Structure du projet](#structure-du-projet)
- [Contribution](#contribution)
- [Licence](#licence)

## 📝 Description

VPN Master est une application mobile qui permet aux utilisateurs de se connecter à des serveurs VPN en utilisant le protocole VLESS via la bibliothèque V2Ray. Cette application offre une interface utilisateur intuitive pour gérer les connexions VPN, visualiser les statistiques de trafic et personnaliser les paramètres de connexion.

## ✨ Fonctionnalités

- **Gestion des serveurs VPN** : Affichage, sélection et synchronisation des serveurs depuis une base de données MongoDB
- **Personnalisation UUID** : Modification facile de l'UUID utilisé pour l'authentification
- **Statistiques de trafic** : Visualisation en temps réel du trafic entrant/sortant et de la durée de connexion
- **Thème adaptatif** : Support des thèmes clair et sombre selon les préférences système
- **Stockage local** : Sauvegarde des configurations et préférences pour une utilisation hors ligne
- **Synchronisation** : Mise à jour des serveurs et configurations depuis un serveur distant
- **Interface intuitive** : Design moderne et ergonomique

## 🏗️ Architecture

L'application suit une architecture en couches avec separation des préoccupations:

- **Modèles** : Représentation des données (ServerModel, ConfigModel)
- **Services** : Logique métier et interactions avec les API externes (VpnService, DatabaseService, StorageService)
- **UI** : Écrans et widgets pour l'interface utilisateur
- **Utilitaires** : Fonctions d'aide et constantes partagées

## 🛠️ Prérequis

- Flutter SDK 3.7.2 ou supérieur
- Dart SDK 3.0.0 ou supérieur
- Android Studio / VS Code avec plugins Flutter
- Git

## 📥 Installation

1. Clonez le dépôt:
   ```bash
   git clone https://github.com/yourusername/vpn_master.git
   cd vpn_master
   ```

2. Installez les dépendances:
   ```bash
   flutter pub get
   ```

3. Exécutez les générateurs de code (pour Hive et autres):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Créez un fichier `.env` à la racine du projet avec la configuration suivante:
   ```
   MONGO_URL=votre_url_mongodb
   ```

5. Lancez l'application:
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Base de données MongoDB

L'application utilise MongoDB pour stocker et synchroniser les serveurs et configurations. Votre base de données doit contenir deux collections:

- **servers**: Liste des serveurs VPN disponibles
- **configs**: Configurations V2Ray associées aux serveurs

### Structure des documents

**server:**
```json
{
  "_id": "server_id",
  "name": "Nom du serveur",
  "configId": "id_config_associée",
  "description": "Description du serveur",
  "isActive": true
}
```

**config:**
```json
{
  "_id": "config_id",
  "remarks": "Description de la configuration",
  "configJson": {
    // Configuration V2Ray complète
  },
  "lastUpdated": "2024-05-17T12:00:00.000Z"
}
```

## 🚀 Utilisation

1. Lancez l'application
2. Synchronisez les serveurs en appuyant sur l'icône en haut à droite
3. Sélectionnez un serveur dans la liste déroulante
4. Entrez votre UUID ou utilisez celui généré automatiquement
5. Appuyez sur "Se connecter" pour établir la connexion VPN
6. Visualisez les statistiques de trafic en temps réel
7. Appuyez sur "Déconnecter" pour terminer la session VPN

## 💻 Technologies utilisées

- **Flutter**: Framework UI pour le développement cross-platform
- **Provider**: Gestion d'état et propagation des changements
- **Hive**: Base de données NoSQL locale pour le stockage persistant
- **MongoDB**: Base de données pour stocker les configurations serveur
- **flutter_v2ray**: Plugin pour l'intégration du client V2Ray
- **connectivity_plus**: Détection de l'état de connexion réseau
- **UUID**: Génération d'identifiants uniques

## 📁 Structure du projet

```
lib/
├── models/                  # Modèles de données
├── screens/                 # Écrans de l'application
├── services/                # Services (VPN, stockage, base de données)
├── themes/                  # Thèmes de l'application
├── utils/                   # Utilitaires et constantes
├── widgets/                 # Widgets réutilisables
└── main.dart                # Point d'entrée de l'application
```

## 🤝 Contribution

Les contributions sont les bienvenues! Pour contribuer:

1. Forkez le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'Add some amazing feature'`)
4. Poussez vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

---

Développé avec ❤️ par 0xBOUBA :)
