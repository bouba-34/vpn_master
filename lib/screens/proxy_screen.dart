import 'dart:developer';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../services/proxy_service.dart';
import '../utils/config_helper.dart';

class ProxyScreen extends StatefulWidget {
  const ProxyScreen({super.key});

  @override
  State<ProxyScreen> createState() => _ProxyScreenState();
}

class _ProxyScreenState extends State<ProxyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _portController = TextEditingController(text: '8888');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _authRequired = false;
  ProxyProtocol _protocol = ProxyProtocol.http;
  bool _shareVpnConnection = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialisation des contrôleurs avec les valeurs du service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final proxyService = Provider.of<ProxyService>(context, listen: false);
      _portController.text = proxyService.port.toString();
      _usernameController.text = proxyService.username;
      _passwordController.text = proxyService.password;
      _authRequired = proxyService.authRequired;
      _protocol = proxyService.protocol;
      _shareVpnConnection = proxyService.shareVpnConnection;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveSettings(ProxyService proxyService) async {
    final port = int.tryParse(_portController.text) ?? 8888;
    await proxyService.setProxySettings(
      port: port,
      username: _usernameController.text,
      password: _passwordController.text,
      authRequired: _authRequired,
      protocol: _protocol,
      shareVpnConnection: _shareVpnConnection,
    );
  }

  void _copyProxyInfo(ProxyService proxyService) async {
    final proxyUrl = proxyService.proxyUrl;
    if (proxyUrl.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: proxyUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations proxy copiées dans le presse-papiers')),
      );
    }
  }

  void _shareProxyInfo(ProxyService proxyService) async {
    final proxyUrl = proxyService.proxyUrl;
    if (proxyUrl.isNotEmpty) {
      final protocol = proxyService.protocol == ProxyProtocol.http ? 'HTTP' : 'SOCKS5';
      await Share.share(
        'Configuration proxy $protocol:\n\n'
            'Serveur: ${proxyService.localIpAddress}\n'
            'Port: ${proxyService.port}\n'
            '${proxyService.authRequired ? 'Identifiant: ${proxyService.username}\nMot de passe: ${proxyService.password}\n' : ''}'
            '\nURL complète: $proxyUrl',
        subject: 'Configuration proxy $protocol',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProxyService>(
      builder: (context, proxyService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Partage de connexion'),
            actions: [
              if (proxyService.isRunning)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareProxyInfo(proxyService),
                  tooltip: 'Partager',
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.settings), text: 'Configuration'),
                Tab(icon: Icon(Icons.qr_code), text: 'QR Code'),
                Tab(icon: Icon(Icons.history), text: 'Historique'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSettingsTab(proxyService),
              _buildQrCodeTab(proxyService),
              _buildHistoryTab(proxyService),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: proxyService.isRunning
                    ? () => proxyService.stopProxy()
                    : () async {
                  _saveSettings(proxyService);
                  final success = await proxyService.startProxy();
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Impossible de démarrer le serveur proxy. Vérifiez votre connexion Wi-Fi.')),
                    );
                  } else if (success && mounted) {
                    _tabController.animateTo(1); // Afficher l'onglet QR Code
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: proxyService.isRunning ? Colors.red : Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(proxyService.isRunning ? Icons.stop : Icons.play_arrow),
                    const SizedBox(width: 8),
                    Text(proxyService.isRunning ? 'Arrêter le serveur proxy' : 'Démarrer le serveur proxy'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(ProxyService proxyService) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Status
        if (proxyService.isRunning)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('État du serveur', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('En cours d\'exécution', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Adresse: ${proxyService.localIpAddress}'),
                  Text('Port: ${proxyService.port}'),
                  if (proxyService.authRequired) ...[
                    Text('Identifiant: ${proxyService.username}'),
                    Text('Mot de passe: ${proxyService.password}'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copier'),
                        onPressed: () => _copyProxyInfo(proxyService),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Configuration du port
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuration du serveur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                    helperText: 'Port d\'écoute du serveur proxy (par défaut: 8888)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !proxyService.isRunning,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProxyProtocol>(
                  value: _protocol,
                  decoration: const InputDecoration(
                    labelText: 'Protocole',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ProxyProtocol.http,
                      child: Text('HTTP'),
                    ),
                    DropdownMenuItem(
                      value: ProxyProtocol.socks5,
                      child: Text('SOCKS5'),
                    ),
                  ],
                  onChanged: proxyService.isRunning
                      ? null
                      : (value) {
                    if (value != null) {
                      setState(() {
                        _protocol = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Partager la connexion VPN'),
                  subtitle: const Text('Étendre la connexion VPN à tous les appareils connectés'),
                  value: _shareVpnConnection,
                  onChanged: proxyService.isRunning
                      ? null
                      : (value) {
                    setState(() {
                      _shareVpnConnection = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Configuration de l'authentification
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Authentification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Activer l\'authentification'),
                  subtitle: const Text('Exiger un identifiant et un mot de passe'),
                  value: _authRequired,
                  onChanged: proxyService.isRunning
                      ? null
                      : (value) {
                    setState(() {
                      _authRequired = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_authRequired) ...[
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !proxyService.isRunning && _authRequired,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    enabled: !proxyService.isRunning && _authRequired,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeTab(ProxyService proxyService) {
    if (!proxyService.isRunning || proxyService.localIpAddress.isEmpty) {
      return const Center(
        child: Text('Le serveur proxy n\'est pas en cours d\'exécution.'),
      );
    }

    final qrData = proxyService.proxyUrl;
    final protocol = proxyService.protocol == ProxyProtocol.http ? 'HTTP' : 'SOCKS5';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Scannez ce code QR pour configurer le proxy sur un autre appareil',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Serveur: ${proxyService.localIpAddress}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Port: ${proxyService.port}'),
                  Text('Protocole: $protocol'),
                  if (proxyService.authRequired) ...[
                    Text('Identifiant: ${proxyService.username}'),
                    Text('Mot de passe: ${proxyService.password}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Instructions:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: CircleAvatar(child: Text('1')),
            title: Text('Connectez-vous au même réseau Wi-Fi'),
          ),
          const ListTile(
            leading: CircleAvatar(child: Text('2')),
            title: Text('Scannez le code QR ou entrez les informations manuellement'),
          ),
          const ListTile(
            leading: CircleAvatar(child: Text('3')),
            title: Text('Configurez les paramètres proxy sur votre appareil'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copier les informations'),
                onPressed: () => _copyProxyInfo(proxyService),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Partager'),
                onPressed: () => _shareProxyInfo(proxyService),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ProxyService proxyService) {
    final sessions = proxyService.sessions;

    if (sessions.isEmpty) {
      return const Center(
        child: Text('Aucune connexion n\'a été établie.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Connexions: ${sessions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Effacer l\'historique'),
                onPressed: () => proxyService.clearSessionHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[sessions.length - 1 - index]; // Ordre inversé

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: session.isActive ? Colors.green : Colors.grey,
                  child: Icon(
                    Icons.computer,
                    color: Colors.white,
                  ),
                ),
                title: Text(session.clientIp),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.targetHost.isNotEmpty)
                      Text('Destination: ${session.targetHost}:${session.targetPort}'),
                    Text('Début: ${_formatDateTime(session.startTime)}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('↓ ${ConfigHelper.formatBytes(session.bytesSent)}'),
                    Text('↑ ${ConfigHelper.formatBytes(session.bytesReceived)}'),
                  ],
                ),
              );
            },
          ),
        ),
        if (proxyService.isRunning)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTrafficInfo(
                  context: context,
                  icon: Icons.arrow_downward,
                  value: ConfigHelper.formatBytes(proxyService.totalBytesSent),
                  label: 'Reçus',
                  color: Colors.green,
                ),
                _buildTrafficInfo(
                  context: context,
                  icon: Icons.arrow_upward,
                  value: ConfigHelper.formatBytes(proxyService.totalBytesReceived),
                  label: 'Envoyés',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTrafficInfo({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

}

// Extension pour calculer le logarithme
extension on num {
  double log(num base) => log(base) / log(10);
}