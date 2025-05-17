/*import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class ConnectionButton extends StatelessWidget {
  final VpnStatus status;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onUpdateConfig;
  final bool isConfigUpdated;

  const ConnectionButton({
    super.key,
    required this.status,
    required this.onConnect,
    required this.onDisconnect,
    required this.onUpdateConfig,
    required this.isConfigUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bouton de mise à jour de la configuration
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onUpdateConfig,
            icon: const Icon(Icons.refresh),
            label: const Text('Mettre à jour la configuration'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Bouton de connexion/déconnexion
        SizedBox(
          width: double.infinity,
          height: 56,
          child: _buildActionButton(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (status) {
      case VpnStatus.disconnected:
        return ElevatedButton.icon(
          onPressed: isConfigUpdated ? onConnect : null,
          icon: const Icon(Icons.power_settings_new),
          label: const Text('Se connecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case VpnStatus.connecting:
        return ElevatedButton.icon(
          onPressed: onDisconnect,
          icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          label: const Text('Connexion en cours...'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case VpnStatus.connected:
        return ElevatedButton.icon(
          onPressed: onDisconnect,
          icon: const Icon(Icons.stop),
          label: const Text('Déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case VpnStatus.error:
        return ElevatedButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.error),
          label: const Text('Erreur - Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }
}*/

import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class ConnectionButton extends StatelessWidget {
  final VpnStatus status;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final bool isConfigUpdated;

  const ConnectionButton({
    super.key,
    required this.status,
    required this.onConnect,
    required this.onDisconnect,
    required this.isConfigUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: _buildActionButton(context),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (status) {
      case VpnStatus.disconnected:
        return ElevatedButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.power_settings_new),
          label: const Text('Se connecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case VpnStatus.connecting:
        return ElevatedButton.icon(
          onPressed: onDisconnect,
          icon: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          label: const Text('Connexion en cours...'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case VpnStatus.connected:
        return ElevatedButton.icon(
          onPressed: onDisconnect,
          icon: const Icon(Icons.stop),
          label: const Text('Déconnecter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case VpnStatus.error:
        return ElevatedButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.error),
          label: const Text('Erreur - Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }
}