// ============================================================
// services/demo_vpn_service.dart
// ============================================================
//
// Demo VPN service that shows how real VPN would work
// Created by: مهندس مصطفي أيوب
// Contact: +79891574730 | mostafaayoub1210@mail.ru
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/vpn_models.dart';

class DemoVpnService {
  static final DemoVpnService _instance = DemoVpnService._internal();
  factory DemoVpnService() => _instance;
  DemoVpnService._internal();

  final ValueNotifier<VpnStatus> status = ValueNotifier(VpnStatus.disconnected);
  final ValueNotifier<ConnectionStats?> stats = ValueNotifier(null);
  final ValueNotifier<String?> currentIP = ValueNotifier(null);

  VpnServer? _currentServer;
  Timer? _statsTimer;
  DateTime? _connectedAt;
  String? _originalIP;

  // Demo servers with realistic IPs
  static const List<VpnServer> _demoServers = [
    VpnServer(
      id: 'us-1',
      name: 'USA - New York',
      country: 'United States',
      countryCode: 'US',
      flagEmoji: '🇺🇸',
      ip: '104.224.173.120', // Real US IP
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
      ip: '95.217.200.130', // Real German IP
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
      ip: '51.195.47.97', // Real UK IP
      port: 1194,
      protocol: VpnProtocol.openvpn,
      ping: 38,
      load: 0.2,
      isPremium: false,
    ),
  ];

  // ── Connect to Demo VPN Server ─────────────────────────────
  Future<bool> connect(VpnServer server) async {
    if (status.value == VpnStatus.connected) await disconnect();

    status.value = VpnStatus.connecting;
    _currentServer = server;

    try {
      debugPrint('[DemoVpnService] Connecting to ${server.name}...');
      
      // Store original IP
      _originalIP = await _getCurrentIP();
      
      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate successful connection
      status.value = VpnStatus.connected;
      _connectedAt = DateTime.now();
      _startStatsTimer();
      
      // Show new IP (simulated)
      currentIP.value = server.ip;
      
      debugPrint('[DemoVpnService] Connected! New IP: ${server.ip}');
      return true;
      
    } catch (e) {
      debugPrint('[DemoVpnService] Connection error: $e');
      status.value = VpnStatus.error;
      return false;
    }
  }

  // ── Get Current IP Address ───────────────────────────────
  Future<String?> _getCurrentIP() async {
    try {
      // For demo, return a simulated local IP
      // In production, this would get real external IP
      return '192.168.1.100';
    } catch (e) {
      debugPrint('[DemoVpnService] IP check error: $e');
      return null;
    }
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

    await Future.delayed(const Duration(seconds: 1));

    _currentServer = null;
    _connectedAt = null;
    currentIP.value = _originalIP;
    stats.value = null;
    status.value = VpnStatus.disconnected;
    
    debugPrint('[DemoVpnService] Disconnected');
  }

  // ── Get Demo Servers ───────────────────────────────────────
  List<VpnServer> getDemoServers() => _demoServers;

  // ── Show Instructions ─────────────────────────────────────
  void showInstructions() {
    debugPrint('''
    ╔══════════════════════════════════════════════════════════════╗
    ║                    Glagol VPN - Instructions                 ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  This is a DEMO version of Glagol VPN.                      ║
    ║                                                              ║
    ║  For REAL VPN functionality:                                ║
    ║  1. Subscribe to a VPN service (NordVPN, ExpressVPN, etc.) ║
    ║  2. Get configuration files                                 ║
    ║  3. Update the app with real server IPs                      ║
    ║  4. Add SSL certificates                                     ║
    ║                                                              ║
    ║  Developer: مهندس مصطفي أيوب                                ║
    ║  Contact: +79891574730 | mostafaayoub1210@mail.ru          ║
    ╚══════════════════════════════════════════════════════════════╝
    ''');
  }

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
