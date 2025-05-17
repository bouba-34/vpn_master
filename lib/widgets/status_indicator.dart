import 'package:flutter/material.dart';
import '../services/vpn_service.dart';

class StatusIndicator extends StatelessWidget {
  final VpnStatus status;
  final String? serverName;
  final String bytesIn;
  final String bytesOut;
  final String duration;

  const StatusIndicator({
    super.key,
    required this.status,
    this.serverName,
    this.bytesIn = '0 KB',
    this.bytesOut = '0 KB',
    this.duration = '00:00:00',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: ${_getStatusText()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (serverName != null && status == VpnStatus.connected)
                      Text(
                        'Connecté à: $serverName',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (status == VpnStatus.connected) ...[
            const Divider(height: 24),
            // Ajout de l'affichage de la durée
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Durée: $duration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDataInfo(
                  context,
                  Icons.arrow_downward,
                  bytesIn,
                  'Téléchargés',
                  Colors.green,
                ),
                _buildDataInfo(
                  context,
                  Icons.arrow_upward,
                  bytesOut,
                  'Envoyés',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case VpnStatus.disconnected:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.power_off,
            color: Colors.grey,
            size: 24,
          ),
        );
      case VpnStatus.connecting:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.amberAccent,
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        );
      case VpnStatus.connected:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 24,
          ),
        );
      case VpnStatus.error:
        return Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 24,
          ),
        );
    }
  }

  String _getStatusText() {
    switch (status) {
      case VpnStatus.disconnected:
        return 'Déconnecté';
      case VpnStatus.connecting:
        return 'Connexion en cours...';
      case VpnStatus.connected:
        return 'Connecté';
      case VpnStatus.error:
        return 'Erreur de connexion';
    }
  }

  Widget _buildDataInfo(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
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
}