import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/proxy_screen.dart';
import '../services/proxy_service.dart';
import '../services/vpn_service.dart';

class ProxyButton extends StatelessWidget {
  const ProxyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnService>(
      builder: (context, vpnService, _) {
        final isVpnConnected = vpnService.status == VpnStatus.connected;

        return Consumer<ProxyService>(
          builder: (context, proxyService, _) {
            return Container(
              margin: const EdgeInsets.only(top: 16.0),
              child: OutlinedButton.icon(
                icon: Icon(
                  proxyService.isRunning ? Icons.wifi_tethering : Icons.wifi_tethering_off_outlined,
                  color: proxyService.isRunning ? Colors.green : null,
                ),
                label: Text(
                  proxyService.isRunning
                      ? 'Partage VPN actif'
                      : 'Partager la connexion VPN',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: BorderSide(
                    color: proxyService.isRunning ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (!isVpnConnected && !proxyService.isRunning) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connectez-vous d\'abord au VPN avant de partager la connexion')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProxyScreen()),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}