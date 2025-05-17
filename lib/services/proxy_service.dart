import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modèles pour les connexions et sessions
class ProxySession {
  final String id;
  final String clientIp;
  final DateTime startTime;
  int bytesReceived = 0;
  int bytesSent = 0;
  String targetHost = '';
  int targetPort = 0;
  bool isActive = true;

  ProxySession({
    required this.id,
    required this.clientIp,
    required this.startTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientIp': clientIp,
      'startTime': startTime.toIso8601String(),
      'bytesReceived': bytesReceived,
      'bytesSent': bytesSent,
      'targetHost': targetHost,
      'targetPort': targetPort,
      'isActive': isActive,
    };
  }
}

enum ProxyProtocol {
  http,
  socks5,
}

class ProxyService extends ChangeNotifier {
  // Attributs du service
  bool _isRunning = false;
  int _port = 8888;
  String _username = '';
  String _password = '';
  bool _authRequired = false;
  List<ProxySession> _sessions = [];
  ProxyProtocol _protocol = ProxyProtocol.http;
  ServerSocket? _server;
  String _localIpAddress = '';
  bool _shareVpnConnection = true;
  int _totalBytesReceived = 0;
  int _totalBytesSent = 0;
  final Map<String, Socket> _clients = {};
  Timer? _statsTimer;

  // Getters
  bool get isRunning => _isRunning;
  int get port => _port;
  String get username => _username;
  String get password => _password;
  bool get authRequired => _authRequired;
  List<ProxySession> get sessions => _sessions;
  ProxyProtocol get protocol => _protocol;
  String get localIpAddress => _localIpAddress;
  bool get shareVpnConnection => _shareVpnConnection;
  int get totalBytesReceived => _totalBytesReceived;
  int get totalBytesSent => _totalBytesSent;

  String get proxyUrl {
    if (_localIpAddress.isEmpty) return '';

    if (_authRequired) {
      return '$_protocol://$_username:$_password@$_localIpAddress:$_port';
    } else {
      return '$_protocol://$_localIpAddress:$_port';
    }
  }

  // Constructeur et initialisation
  ProxyService() {
    _loadSettings();
    _startStatsTimer();
  }

  // Chargement des paramètres
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _port = prefs.getInt('proxy_port') ?? 8888;
      _username = prefs.getString('proxy_username') ?? '';
      _password = prefs.getString('proxy_password') ?? '';
      _authRequired = prefs.getBool('proxy_auth_required') ?? false;
      _protocol = prefs.getString('proxy_protocol') == 'socks5'
          ? ProxyProtocol.socks5
          : ProxyProtocol.http;
      _shareVpnConnection = prefs.getBool('share_vpn_connection') ?? true;

      // Récupérer l'adresse IP locale
      await updateLocalIpAddress();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des paramètres proxy: $e');
    }
  }

  // Sauvegarde des paramètres
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('proxy_port', _port);
      await prefs.setString('proxy_username', _username);
      await prefs.setString('proxy_password', _password);
      await prefs.setBool('proxy_auth_required', _authRequired);
      await prefs.setString('proxy_protocol', _protocol == ProxyProtocol.socks5 ? 'socks5' : 'http');
      await prefs.setBool('share_vpn_connection', _shareVpnConnection);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des paramètres proxy: $e');
    }
  }

  // Mise à jour de l'adresse IP locale
  Future<void> updateLocalIpAddress() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.wifi) {
        final networkInfo = NetworkInfo();
        final ip = await networkInfo.getWifiIP();
        _localIpAddress = ip ?? '';
      } else {
        _localIpAddress = '';
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'adresse IP locale: $e');
      _localIpAddress = '';
    }
  }

  // Démarrage du serveur proxy
  Future<bool> startProxy() async {
    if (_isRunning) return true;

    try {
      // Vérifier que nous sommes sur un réseau Wifi
      await updateLocalIpAddress();
      if (_localIpAddress.isEmpty) {
        return false;
      }

      // Démarrer le serveur socket
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port);
      _isRunning = true;

      // Écouter les connexions entrantes
      _server!.listen(_handleConnection);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur lors du démarrage du serveur proxy: $e');
      return false;
    }
  }

  // Arrêt du serveur proxy
  Future<void> stopProxy() async {
    if (!_isRunning) return;

    try {
      await _server?.close();
      _server = null;
      _isRunning = false;

      // Fermer toutes les connexions actives
      for (final socket in _clients.values) {
        socket.destroy();
      }
      _clients.clear();

      // Marquer toutes les sessions comme inactives
      for (var session in _sessions) {
        session.isActive = false;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du serveur proxy: $e');
    }
  }

  // Définir les paramètres du proxy
  Future<void> setProxySettings({
    required int port,
    required String username,
    required String password,
    required bool authRequired,
    required ProxyProtocol protocol,
    required bool shareVpnConnection,
  }) async {
    bool needsRestart = _isRunning && (port != _port || protocol != _protocol);

    if (needsRestart) {
      await stopProxy();
    }

    _port = port;
    _username = username;
    _password = password;
    _authRequired = authRequired;
    _protocol = protocol;
    _shareVpnConnection = shareVpnConnection;

    await _saveSettings();

    if (needsRestart) {
      await startProxy();
    }

    notifyListeners();
  }

  // Gestion des connexions entrantes
  void _handleConnection(Socket client) {
    final session = ProxySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientIp: client.remoteAddress.address,
      startTime: DateTime.now(),
    );

    _sessions.add(session);
    _clients[session.id] = client;

    // Protocole HTTP ou SOCKS
    if (_protocol == ProxyProtocol.http) {
      _handleHttpProxy(client, session);
    } else {
      _handleSocks5Proxy(client, session);
    }

    notifyListeners();
  }

  bool isSocketClosed(Socket socket) {
    try {
      socket.write(""); // on teste si on peut écrire
      return false;
    } catch (e) {
      return true;
    }
  }


  // Gestion du proxy HTTP
  void _handleHttpProxy(Socket client, ProxySession session) {
    bool isConnected = false;
    Socket? targetSocket;
    List<int> buffer = [];

    client.listen(
          (Uint8List data) async {
        try {
          if (!isConnected) {
            // Analyser la requête HTTP
            buffer.addAll(data);
            final String request = String.fromCharCodes(buffer);

            // Vérifier l'authentification si nécessaire
            if (_authRequired) {
              final authHeader = _extractHeader(request, 'Proxy-Authorization');
              if (!_verifyProxyAuth(authHeader)) {
                _sendHttpProxyAuth(client);
                client.destroy();
                return;
              }
            }

            // Extraire l'hôte et le port
            final requestLine = request.split('\n')[0];
            final uri = _extractUri(requestLine);
            if (uri == null) {
              client.destroy();
              return;
            }

            session.targetHost = uri.host;
            session.targetPort = uri.port;

            // Se connecter à la cible
            targetSocket = await Socket.connect(uri.host, uri.port);
            isConnected = true;

            // Rediriger les données du client vers la cible
            if (request.startsWith('CONNECT')) {
              // Tunnel SSL/TLS
              client.write('HTTP/1.1 200 Connection established\r\n\r\n');
            } else {
              // Modifier la requête pour supprimer les en-têtes spécifiques au proxy
              final modifiedRequest = _removeProxyHeaders(request);
              targetSocket!.write(modifiedRequest);
            }

            // Configurer le flux de données retour
            targetSocket!.listen(
                  (Uint8List targetData) {
                if (isSocketClosed(client)) return;
                client.add(targetData);
                session.bytesSent += targetData.length;
                _totalBytesSent += targetData.length;
              },
              onDone: () {
                client.destroy();
                session.isActive = false;
                _clients.remove(session.id);
                notifyListeners();
              },
              onError: (e) {
                client.destroy();
                session.isActive = false;
                _clients.remove(session.id);
                notifyListeners();
              },
            );
          } else {
            // Transférer les données vers la cible
            if (targetSocket != null && !isSocketClosed(targetSocket!)) {
              targetSocket!.add(data);
              session.bytesReceived += data.length;
              _totalBytesReceived += data.length;
            }
          }
        } catch (e) {
          client.destroy();
          targetSocket?.destroy();
          session.isActive = false;
          _clients.remove(session.id);
          notifyListeners();
        }
      },
      onDone: () {
        targetSocket?.destroy();
        session.isActive = false;
        _clients.remove(session.id);
        notifyListeners();
      },
      onError: (e) {
        targetSocket?.destroy();
        session.isActive = false;
        _clients.remove(session.id);
        notifyListeners();
      },
    );
  }

  // Gestion du proxy SOCKS5
  void _handleSocks5Proxy(Socket client, ProxySession session) {
    List<int> buffer = [];
    int state = 0; // 0: auth, 1: request, 2: connected
    Socket? targetSocket;

    client.listen(
          (Uint8List data) async {
        try {
          buffer.addAll(data);

          if (state == 0) {
            // Négociation d'authentification
            if (buffer.length < 2) return; // Attendre plus de données

            final version = buffer[0];
            if (version != 5) { // SOCKS5
              client.destroy();
              return;
            }

            final methodsCount = buffer[1];
            if (buffer.length < 2 + methodsCount) return; // Attendre plus de données

            List<int> methods = buffer.sublist(2, 2 + methodsCount);

            if (_authRequired) {
              // Demander une authentification par mot de passe
              if (methods.contains(2)) { // 2 = USERNAME/PASSWORD
                client.add([5, 2]); // Sélectionner auth par mot de passe
                state = 1;
              } else {
                client.add([5, 0xFF]); // Aucune méthode acceptable
                client.destroy();
              }
            } else {
              // Pas d'authentification requise
              if (methods.contains(0)) { // 0 = NO AUTH
                client.add([5, 0]); // Aucune authentification
                state = 2;
              } else {
                client.add([5, 0xFF]); // Aucune méthode acceptable
                client.destroy();
              }
            }

            buffer = [];
          } else if (state == 1) {
            // Authentification par mot de passe
            if (buffer.length < 2) return; // Attendre plus de données

            final subversion = buffer[0];
            if (subversion != 1) { // Version d'authentification
              client.destroy();
              return;
            }

            final usernameLength = buffer[1];
            if (buffer.length < 2 + usernameLength + 1) return; // Attendre plus de données

            final username = String.fromCharCodes(buffer.sublist(2, 2 + usernameLength));
            final passwordLength = buffer[2 + usernameLength];

            if (buffer.length < 2 + usernameLength + 1 + passwordLength) return; // Attendre plus de données

            final password = String.fromCharCodes(buffer.sublist(2 + usernameLength + 1, 2 + usernameLength + 1 + passwordLength));

            if (username == _username && password == _password) {
              client.add([1, 0]); // Authentification réussie
              state = 2;
            } else {
              client.add([1, 1]); // Échec d'authentification
              client.destroy();
            }

            buffer = [];
          } else if (state == 2) {
            // Requête de connexion
            if (buffer.length < 4) return; // Attendre plus de données

            final version = buffer[0];
            if (version != 5) { // SOCKS5
              client.destroy();
              return;
            }

            final cmd = buffer[1];
            if (cmd != 1) { // 1 = CONNECT (seul supporté)
              client.add([5, 7, 0, 1, 0, 0, 0, 0, 0, 0]); // Commande non supportée
              client.destroy();
              return;
            }

            final addressType = buffer[3];
            String host;
            int port;

            if (addressType == 1) { // IPv4
              if (buffer.length < 10) return; // Attendre plus de données
              host = "${buffer[4]}.${buffer[5]}.${buffer[6]}.${buffer[7]}";
              port = (buffer[8] << 8) + buffer[9];

            } else if (addressType == 3) { // Nom de domaine
              if (buffer.length < 5) return; // Attendre plus de données
              final domainLength = buffer[4];
              if (buffer.length < 5 + domainLength + 2) return; // Attendre plus de données
              host = String.fromCharCodes(buffer.sublist(5, 5 + domainLength));
              port = (buffer[5 + domainLength] << 8) + buffer[5 + domainLength + 1];

            } else if (addressType == 4) { // IPv6
              if (buffer.length < 22) return; // Attendre plus de données
              // Format IPv6
              host = buffer.sublist(4, 20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
              port = (buffer[20] << 8) + buffer[21];

            } else {
              client.add([5, 8, 0, 1, 0, 0, 0, 0, 0, 0]); // Type d'adresse non supporté
              client.destroy();
              return;
            }

            session.targetHost = host;
            session.targetPort = port;

            try {
              // Se connecter à la cible
              targetSocket = await Socket.connect(host, port);

              // Répondre au client avec succès
              final responseHeader = [5, 0, 0, 1];
              // Ajouter l'adresse du serveur proxy comme adresse liée
              final ipParts = _localIpAddress.split('.').map(int.parse).toList();
              responseHeader.addAll(ipParts);
              // Ajouter le port d'écoute
              responseHeader.add((_port >> 8) & 0xFF);
              responseHeader.add(_port & 0xFF);

              client.add(responseHeader);

              // Passer en mode connecté
              state = 3;

              // Gérer les données entrantes depuis la cible
              targetSocket!.listen(
                    (Uint8List targetData) {
                  if (isSocketClosed(client)) return;
                  client.add(targetData);
                  session.bytesSent += targetData.length;
                  _totalBytesSent += targetData.length;
                },
                onDone: () {
                  client.destroy();
                  session.isActive = false;
                  _clients.remove(session.id);
                  notifyListeners();
                },
                onError: (e) {
                  client.destroy();
                  session.isActive = false;
                  _clients.remove(session.id);
                  notifyListeners();
                },
              );

              // Transférer les données en attente vers la cible
              if (buffer.length > 0) {
                buffer = [];
              }
            } catch (e) {
              // Erreur de connexion à la cible
              client.add([5, 4, 0, 1, 0, 0, 0, 0, 0, 0]); // Erreur réseau
              client.destroy();
              session.isActive = false;
              _clients.remove(session.id);
              notifyListeners();
            }

          } else if (state == 3) {
            // Mode connecté - transférer les données vers la cible
            if (targetSocket != null && !isSocketClosed(targetSocket!)) {
              targetSocket!.add(data);
              session.bytesReceived += data.length;
              _totalBytesReceived += data.length;
            }
          }
        } catch (e) {
          client.destroy();
          targetSocket?.destroy();
          session.isActive = false;
          _clients.remove(session.id);
          notifyListeners();
        }
      },
      onDone: () {
        targetSocket?.destroy();
        session.isActive = false;
        _clients.remove(session.id);
        notifyListeners();
      },
      onError: (e) {
        targetSocket?.destroy();
        session.isActive = false;
        _clients.remove(session.id);
        notifyListeners();
      },
    );
  }

  // Envoi de l'en-tête d'authentification proxy HTTP
  void _sendHttpProxyAuth(Socket client) {
    client.write(
        'HTTP/1.1 407 Proxy Authentication Required\r\n'
            'Proxy-Authenticate: Basic realm="Proxy"\r\n'
            'Content-Length: 0\r\n'
            'Connection: close\r\n\r\n'
    );
  }

  // Extraction d'un en-tête de la requête HTTP
  String _extractHeader(String request, String headerName) {
    final lines = request.split('\r\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('${headerName.toLowerCase()}:')) {
        return line.substring(headerName.length + 1).trim();
      }
    }
    return '';
  }

  // Vérification de l'authentification proxy
  bool _verifyProxyAuth(String authHeader) {
    if (!_authRequired) return true;
    if (authHeader.isEmpty) return false;

    if (authHeader.startsWith('Basic ')) {
      final credentials = authHeader.substring(6);
      try {
        final decoded = String.fromCharCodes(base64Decode(credentials));
        final parts = decoded.split(':');
        if (parts.length == 2) {
          return parts[0] == _username && parts[1] == _password;
        }
      } catch (e) {
        return false;
      }
    }

    return false;
  }

  // Extraction de l'URI à partir de la ligne de requête HTTP
  Uri? _extractUri(String requestLine) {
    try {
      final parts = requestLine.trim().split(' ');
      if (parts.length < 3) return null;

      final method = parts[0];
      String url = parts[1];

      if (method == 'CONNECT') {
        // Format: CONNECT host:port HTTP/1.1
        if (!url.contains(':')) return null;
        final hostPort = url.split(':');
        return Uri(
          scheme: 'https',
          host: hostPort[0],
          port: int.tryParse(hostPort[1]) ?? 443,
        );
      } else {
        // Format: GET http://host:port/path HTTP/1.1
        if (url.startsWith('/')) {
          // Request to proxy itself
          return null;
        }

        return Uri.parse(url);
      }
    } catch (e) {
      return null;
    }
  }

  // Suppression des en-têtes spécifiques au proxy
  String _removeProxyHeaders(String request) {
    final lines = request.split('\r\n');
    final requestLine = lines[0];

    // Modifier la première ligne pour supprimer l'URL complète
    final parts = requestLine.split(' ');
    if (parts.length >= 3) {
      try {
        final uri = Uri.parse(parts[1]);
        parts[1] = uri.path + (uri.query.isNotEmpty ? '?' + uri.query : '');
        if (parts[1].isEmpty) parts[1] = '/';
      } catch (e) {
        // Ignorer les erreurs
      }
    }

    final modifiedRequestLine = parts.join(' ');

    // Filtrer les en-têtes proxy
    final filteredHeaders = [modifiedRequestLine];

    // Ajouter l'en-tête Host s'il n'existe pas
    bool hasHostHeader = false;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        filteredHeaders.add('');
        filteredHeaders.addAll(lines.sublist(i + 1));
        break;
      }

      if (line.startsWith('Proxy-')) continue;

      if (line.toLowerCase().startsWith('host:')) {
        hasHostHeader = true;
      }

      filteredHeaders.add(line);
    }

    if (!hasHostHeader) {
      try {
        final uri = Uri.parse(parts[1]);
        final host = uri.host + (uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '');
        filteredHeaders.insert(1, 'Host: $host');
      } catch (e) {
        // Ignorer les erreurs
      }
    }

    return filteredHeaders.join('\r\n');
  }

  // Timer pour mettre à jour les statistiques
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        notifyListeners();
      }
    });
  }

  // Effacer l'historique des sessions
  void clearSessionHistory() {
    _sessions = _sessions.where((session) => session.isActive).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    stopProxy();
    _statsTimer?.cancel();
    super.dispose();
  }
}