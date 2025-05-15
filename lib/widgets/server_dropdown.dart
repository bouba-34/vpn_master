import 'package:flutter/material.dart';
import '../models/server_model.dart';

class ServerDropdown extends StatelessWidget {
  final List<ServerModel> servers;
  final ServerModel? selectedServer;
  final Function(ServerModel?) onChanged;
  final bool isLoading;

  const ServerDropdown({
    Key? key,
    required this.servers,
    required this.selectedServer,
    required this.onChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: isLoading
          ? const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      )
          : DropdownButtonHideUnderline(
        child: DropdownButton<ServerModel>(
          isExpanded: true,
          value: selectedServer,
          hint: const Text('Choisir un serveur'),
          items: servers.map((ServerModel server) {
            return DropdownMenuItem<ServerModel>(
              value: server,
              child: Row(
                children: [
                  const Icon(Icons.dns, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          server.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (server.description.isNotEmpty)
                          Text(
                            server.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 2,
          style: Theme.of(context).textTheme.bodyLarge,
          dropdownColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}