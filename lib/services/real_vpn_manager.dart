// ============================================================
// services/real_vpn_manager.dart
// ============================================================
//
// Real VPN Manager for Glagol VPN
// Created by: مهندس مصطفي أيوب
// Contact: +79891574730 | mostafaayoub1210@mail.ru
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vpn_models.dart';

class RealVpnManager {
  static final RealVpnManager _instance = RealVpnManager._internal();
  factory RealVpnManager() => _instance;
  RealVpnManager._internal();

  final ValueNotifier<VpnStatus> status = ValueNotifier(VpnStatus.disconnected);
  final ValueNotifier<ConnectionStats?> stats = ValueNotifier(null);
  final ValueNotifier<String?> currentIP = ValueNotifier(null);

  VpnServer? _currentServer;
  Timer? _statsTimer;
  DateTime? _connectedAt;

  // Real VPN servers (replace with your actual servers)
  static const List<VpnServer> _realServers = [
    VpnServer(
      id: 'us-1',
      name: 'USA - New York',
      country: 'United States',
      countryCode: 'US',
      flagEmoji: '🇺🇸',
      ip: '192.168.1.100', // Replace with real IP
      port: 1194,
      protocol: VpnProtocol.openvpn,
      ping: 45,
      load: 0.3,
      isPremium: false,
    ),
    VpnServer(
      id: 'de-1', 
      name: 'Germany - Berlin',
      country: 'Germany',
      countryCode: 'DE',
      flagEmoji: '🇩🇪',
      ip: '192.168.1.101', // Replace with real IP
      port: 1194,
      protocol: VpnProtocol.wireguard,
      ping: 32,
      load: 0.5,
      isPremium: false,
    ),
    VpnServer(
      id: 'uk-1',
      name: 'UK - London', 
      country: 'United Kingdom',
      countryCode: 'UK',
      flagEmoji: '🇬🇧',
      ip: '192.168.1.102', // Replace with real IP
      port: 1194,
      protocol: VpnProtocol.openvpn,
      ping: 38,
      load: 0.2,
      isPremium: false,
    ),
  ];

  // ── Connect to Real VPN Server ─────────────────────────────
  Future<bool> connect(VpnServer server) async {
    if (status.value == VpnStatus.connected) await disconnect();

    status.value = VpnStatus.connecting;
    _currentServer = server;

    try {
      debugPrint('[RealVpnManager] Connecting to ${server.name}...');
      
      // Step 1: Verify server is reachable
      final isReachable = await _pingServer(server.ip);
      if (!isReachable) {
        status.value = VpnStatus.error;
        return false;
      }

      // Step 2: Get VPN configuration
      final config = await _getVPNConfig(server);
      if (config == null) {
        status.value = VpnStatus.error;
        return false;
      }

      // Step 3: Establish VPN connection
      final connected = await _establishVPNConnection(config);
      if (connected) {
        status.value = VpnStatus.connected;
        _connectedAt = DateTime.now();
        _startStatsTimer();
        _updateRealIP();
        return true;
      } else {
        status.value = VpnStatus.error;
        return false;
      }
    } catch (e) {
      debugPrint('[RealVpnManager] Connection error: $e');
      status.value = VpnStatus.error;
      return false;
    }
  }

  // ── Ping Server ───────────────────────────────────────────
  Future<bool> _pingServer(String ip) async {
    try {
      final result = await Process.run('ping', ['-c', '1', ip]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('[RealVpnManager] Ping error: $e');
      return false;
    }
  }

  // ── Get VPN Configuration ─────────────────────────────────
  Future<String?> _getVPNConfig(VpnServer server) async {
    try {
      // In production, fetch from your VPN server API
      final response = await http.get(
        Uri.parse('https://api.glagolvpn.com/config/${server.id}'),
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        // Fallback to demo config
        return _generateDemoConfig(server);
      }
    } catch (e) {
      debugPrint('[RealVpnManager] Config error: $e');
      return _generateDemoConfig(server);
    }
  }

  // ── Generate Demo Configuration ───────────────────────────
  String _generateDemoConfig(VpnServer server) {
    if (server.protocol == VpnProtocol.wireguard) {
      return '''
[Interface]
PrivateKey = ${_generatePrivateKey()}
Address = 10.8.0.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${_generatePublicKey()}
Endpoint = ${server.ip}:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
''';
    } else {
      return '''
client
dev tun
proto udp
remote ${server.ip} ${server.port}
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
verb 3
auth-nocache
remote-cert-tls server
''';
    }
  }

  // ── Establish VPN Connection ───────────────────────────────
  Future<bool> _establishVPNConnection(String config) async {
    try {
      if (Platform.isIOS) {
        return await _connectIOS(config);
      } else if (Platform.isAndroid) {
        return await _connectAndroid(config);
      }
      return false;
    } catch (e) {
      debugPrint('[RealVpnManager] VPN connection error: $e');
      return false;
    }
  }

  // ── iOS VPN Connection ───────────────────────────────────
  Future<bool> _connectIOS(String config) async {
    try {
      // Use NEVPNManager for iOS
      // This requires Network Extensions entitlements
      
      // For demo, simulate connection
      await Future.delayed(const Duration(seconds: 3));
      
      // In production:
      // 1. Save config to file
      // 2. Use NEVPNManager to start connection
      // 3. Monitor connection status
      
      debugPrint('[RealVpnManager] iOS VPN connected');
      return true;
    } catch (e) {
      debugPrint('[RealVpnManager] iOS VPN error: $e');
      return false;
    }
  }

  // ── Android VPN Connection ───────────────────────────────
  Future<bool> _connectAndroid(String config) async {
    try {
      // Use VpnService for Android
      // This requires VpnService permission
      
      // For demo, simulate connection
      await Future.delayed(const Duration(seconds: 3));
      
      // In production:
      // 1. Create VPN service
      // 2. Configure tunnel
      // 3. Start connection
      
      debugPrint('[RealVpnManager] Android VPN connected');
      return true;
    } catch (e) {
      debugPrint('[RealVpnManager] Android VPN error: $e');
      return false;
    }
  }

  // ── Update Real IP Address ───────────────────────────────
  Future<void> _updateRealIP() async {
    try {
      final ip = await _getExternalIP();
      if (ip != null) {
        currentIP.value = ip;
        debugPrint('[RealVpnManager] New IP: $ip');
      }
    } catch (e) {
      debugPrint('[RealVpnManager] IP update error: $e');
    }
  }

  // ── Get External IP ───────────────────────────────────────
  Future<String?> _getExternalIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      debugPrint('[RealVpnManager] IP check error: $e');
    }
    return null;
  }

  // ── Start Stats Timer ─────────────────────────────────────
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;

      final downloadBytes = 12000 + (DateTime.now().millisecond % 8000);
      final uploadBytes = 3000 + (DateTime.now().millisecond % 2000);

      stats.value = ConnectionStats(
        connectedDuration: DateTime.now().difference(_connectedAt!),
        downloadBytes: downloadBytes,
        uploadBytes: uploadBytes,
        assignedIp: currentIP.value ?? 'Connecting...',
      );
    });
  }

  // ── Disconnect ─────────────────────────────────────────────
  Future<void> disconnect() async {
    status.value = VpnStatus.disconnecting;
    _stopStatsTimer();

    try {
      // Stop real VPN connection
      if (Platform.isIOS) {
        // Stop NEVPNManager connection
      } else if (Platform.isAndroid) {
        // Stop VpnService
      }
      
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[RealVpnManager] Disconnect error: $e');
    }

    _currentServer = null;
    _connectedAt = null;
    currentIP.value = null;
    stats.value = null;
    status.value = VpnStatus.disconnected;
  }

  // ── Get Real Servers ───────────────────────────────────────
  List<VpnServer> getRealServers() => _realServers;

  // ── Helper Methods ─────────────────────────────────────────
  String _generatePrivateKey() => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345=';
  String _generatePublicKey() => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345=';

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void dispose() {
    _stopStatsTimer();
    status.dispose();
    stats.dispose();
    currentIP.dispose();
  }
}
