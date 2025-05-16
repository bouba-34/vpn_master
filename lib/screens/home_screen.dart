import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/server_model.dart';
import '../models/config_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/vpn_service.dart';
import '../widgets/server_dropdown.dart';
import '../widgets/uuid_input.dart';
import '../widgets/connection_button.dart';
import '../widgets/status_indicator.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final VpnService _vpnService = VpnService();
  final DatabaseService _databaseService = DatabaseService.instance;

  List<ServerModel> _servers = [];
  ServerModel? _selectedServer;
  String _uuid = '';
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isConfigUpdated = false;
  ConfigModel? _currentConfig;
  String _bytesIn = '0 KB';
  String _bytesOut = '0 KB';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    // Charger l'UUID sauvegardé
    final savedUuid = _storageService.getUuid();
    if (savedUuid != null && savedUuid.isNotEmpty) {
      setState(() {
        _uuid = savedUuid;
      });
    } else {
      // Générer un nouvel UUID si aucun n'est sauvegardé
      final newUuid = const Uuid().v4();
      await _storageService.saveUuid(newUuid);
      setState(() {
        _uuid = newUuid;
      });
    }

    // Charger les serveurs depuis le stockage local
    _loadLocalServers();

    // Essayer de se connecter à la base de données et synchroniser
    _syncWithDatabase();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadLocalServers() async {
    final localServers = _storageService.getServers();

    if (localServers.isNotEmpty) {
      setState(() {
        _servers = localServers;
      });

      // Charger le serveur précédemment sélectionné
      final lastSelectedServerId = _storageService.getLastSelectedServerId();
      if (lastSelectedServerId != null) {
        final server = _servers.firstWhere(
              (s) => s.id == lastSelectedServerId,
          orElse: () => _servers.first,
        );
        _selectServer(server);
      } else if (_servers.isNotEmpty) {
        _selectServer(_servers.first);
      }
    }
  }

  Future<void> _syncWithDatabase() async {
    // Vérifier la connectivité
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(Constants.noInternetConnection),
            duration: Constants.snackBarDuration,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isRefreshing = true;
      });

      // Se connecter à la base de données
      await _databaseService.connect();

      // Récupérer les serveurs
      final remoteServers = await _databaseService.getServers();

      if (remoteServers.isNotEmpty) {
        // Sauvegarder les serveurs localement
        await _storageService.saveServers(remoteServers);

        setState(() {
          _servers = remoteServers;
        });

        // Si aucun serveur n'est sélectionné, sélectionner le premier
        if (_selectedServer == null && _servers.isNotEmpty) {
          _selectServer(_servers.first);
        }
      }
    } catch (e) {
      print('Erreur de synchronisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de synchronisation: $e'),
            duration: Constants.snackBarDuration,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _selectServer(ServerModel server) {
    setState(() {
      _selectedServer = server;
      _isConfigUpdated = false;
    });

    _storageService.saveLastSelectedServerId(server.id);
  }

  Future<void> _updateConfig() async {
    if (_selectedServer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(Constants.selectServer),
          duration: Constants.snackBarDuration,
        ),
      );
      return;
    }

    if (_uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(Constants.enterUuid),
          duration: Constants.snackBarDuration,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Essayer d'abord de récupérer la configuration depuis la base de données
      ConfigModel? config;

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        try {
          await _databaseService.connect();
          config = await _databaseService.getConfigForServer(_selectedServer!.id);

          //print("config from db ${jsonEncode(config!.configJson)}");
        } catch (e) {
          print('Erreur de récupération depuis la BDD: $e');
        }
      }

      // Si la configuration n'est pas disponible en ligne, essayer de la récupérer localement
      config ??= _storageService.getConfig(_selectedServer!.configId);

      if (config != null) {
        // Mettre à jour l'UUID dans la configuration
        final updatedConfig = config.updateUuid(_uuid);
        // Sauvegarder la configuration mise à jour localement
        await _storageService.saveConfig(updatedConfig);

        setState(() {
          _currentConfig = updatedConfig;
          _isConfigUpdated = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(Constants.serverConfigUpdated),
            duration: Constants.snackBarDuration,
          ),
        );
      } else {
        throw Exception('Configuration non trouvée');
      }
    } catch (e) {
      print('Erreur de mise à jour de la configuration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Constants.errorUpdatingConfig}: $e'),
          duration: Constants.snackBarDuration,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectVpn() async {
    if (_currentConfig == null || !_isConfigUpdated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord mettre à jour la configuration'),
          duration: Constants.snackBarDuration,
        ),
      );
      return;
    }

    try {
      final success = await _vpnService.connect(_currentConfig!);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(Constants.connectionSuccessful),
            duration: Constants.snackBarDuration,
          ),
        );
      } else {
        throw Exception(_vpnService.errorMessage);
      }
    } catch (e) {
      print('Erreur de connexion VPN: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${Constants.errorConnectingVpn}: $e'),
          duration: Constants.snackBarDuration,
        ),
      );
    }
  }

  Future<void> _disconnectVpn() async {
    try {
      await _vpnService.disconnect();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(Constants.disconnectionSuccessful),
          duration: Constants.snackBarDuration,
        ),
      );
    } catch (e) {
      print('Erreur de déconnexion VPN: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion: $e'),
          duration: Constants.snackBarDuration,
        ),
      );
    }
  }

  void _onUuidChanged(String value) {
    setState(() {
      _uuid = value;
      _isConfigUpdated = false;
    });

    _storageService.saveUuid(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('V2Ray VPN Client'),
        actions: [
          IconButton(
            icon: Icon(_isRefreshing ? Icons.sync : Icons.refresh),
            onPressed: _isRefreshing ? null : _syncWithDatabase,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<VpnService>(
      builder: (context, vpnService, _) {
        final vpnStatus = vpnService.status;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur de statut
              StatusIndicator(
                status: vpnStatus,
                serverName: _selectedServer?.name,
                bytesIn: _bytesIn,
                bytesOut: _bytesOut,
              ),
              const SizedBox(height: 24),

              // Sélection du serveur
              const Text(
                'Serveur',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ServerDropdown(
                servers: _servers,
                selectedServer: _selectedServer,
                onChanged: (server) => _selectServer(server!),
                isLoading: _isRefreshing,
              ),
              const SizedBox(height: 24),

              // Champ UUID
              const Text(
                'UUID',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              UuidInput(
                initialValue: _uuid,
                onChanged: _onUuidChanged,
                onRandomGenerate: () {
                  setState(() {
                    _isConfigUpdated = false;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Boutons de connexion/déconnexion
              ConnectionButton(
                status: vpnStatus,
                onConnect: _connectVpn,
                onDisconnect: _disconnectVpn,
                onUpdateConfig: _updateConfig,
                isConfigUpdated: _isConfigUpdated,
              ),
            ],
          ),
        );
      },
    );
  }
}