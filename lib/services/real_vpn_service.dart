// ============================================================
// services/real_vpn_service.dart
// ============================================================
//
// Real VPN implementation using iOS NEVPNManager
// Requires Network Extensions entitlements
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_extension/network_extension.dart'; // Hypothetical package
import '../models/vpn_models.dart';

class RealVpnService {
  static final RealVpnService _instance = RealVpnService._internal();
  factory RealVpnService() => _instance;
  RealVpnService._internal();

  final ValueNotifier<VpnStatus> status = ValueNotifier(VpnStatus.disconnected);
  final ValueNotifier<ConnectionStats?> stats = ValueNotifier(null);
  final ValueNotifier<String?> currentIP = ValueNotifier(null);

  VpnServer? _currentServer;
  Timer? _statsTimer;
  DateTime? _connectedAt;

  // ── Connect Real VPN ─────────────────────────────────────
  Future<bool> connect(VpnServer server) async {
    if (status.value == VpnStatus.connected) await disconnect();

    status.value = VpnStatus.connecting;
    _currentServer = server;

    try {
      if (Platform.isIOS) {
        return await _connectIOS(server);
      } else if (Platform.isAndroid) {
        return await _connectAndroid(server);
      }
      return false;
    } catch (e) {
      debugPrint('[RealVpnService] Connection error: $e');
      status.value = VpnStatus.error;
      return false;
    }
  }

  // ── iOS VPN Connection ───────────────────────────────────
  Future<bool> _connectIOS(VpnServer server) async {
    try {
      // Use NEVPNManager for real iOS VPN
      // This requires Network Extensions entitlements
      
      final vpnManager = NEVPNManager.sharedManager;
      await vpnManager.loadFromPreferences();
      
      // Create VPN configuration
      final protocol = server.protocol == VpnProtocol.wireguard 
          ? NEVPNProtocolIKEv2() 
          : NEVPNProtocolIPSec();
      
      protocol.serverAddress = server.ip;
      protocol.username = "vpnuser";
      protocol.passwordReference = NSData.dataWithString("vpn123");
      protocol.useExtendedAuthentication = true;
      
      vpnManager.protocolConfiguration = protocol;
      vpnManager.localizedDescription = "Glagol VPN";
      vpnManager.enabled = true;
      
      // Save configuration
      await vpnManager.saveToPreferences();
      
      // Start VPN connection
      await vpnManager.startConnection();
      
      // Monitor connection status
      _monitorVPNStatus();
      
      return true;
    } catch (e) {
      debugPrint('[RealVpnService] iOS VPN error: $e');
      return false;
    }
  }

  // ── Android VPN Connection ───────────────────────────────
  Future<bool> _connectAndroid(VpnServer server) async {
    try {
      // Use Android VpnService for real Android VPN
      // This would require a native Android implementation
      
      final vpnService = AndroidVpnService();
      await vpnService.prepare(server.ip);
      await vpnService.connect(
        server.ip,
        username: "vpnuser",
        password: "vpn123",
      );
      
      _monitorVPNStatus();
      return true;
    } catch (e) {
      debugPrint('[RealVpnService] Android VPN error: $e');
      return false;
    }
  }

  // ── Monitor VPN Status ───────────────────────────────────
  void _monitorVPNStatus() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final isConnected = await _checkVPNConnection();
        if (isConnected) {
          if (status.value != VpnStatus.connected) {
            status.value = VpnStatus.connected;
            _connectedAt = DateTime.now();
            _startStatsTimer();
            _updateRealIP();
          }
        } else {
          status.value = VpnStatus.disconnected;
          timer.cancel();
        }
      } catch (e) {
        debugPrint('[RealVpnService] Status check error: $e');
      }
    });
  }

  // ── Check Real VPN Connection ─────────────────────────────
  Future<bool> _checkVPNConnection() async {
    try {
      // Check if VPN interface is active
      final interfaces = await NetworkInterface.list(includeLoopback: false, includeLinkLocal: false);
      
      // Look for VPN interface (utun, tun, or similar)
      for (final interface in interfaces) {
        if (interface.name.contains('utun') || 
            interface.name.contains('tun') || 
            interface.name.contains('ppp')) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── Update Real IP Address ───────────────────────────────
  Future<void> _updateRealIP() async {
    try {
      // Get real external IP through VPN
      final response = await HttpClient().get(
        Uri.parse('https://api.ipify.org'),
      );
      
      final externalIP = await response.transform(utf8.decoder).join();
      currentIP.value = externalIP.trim();
      
      debugPrint('[RealVpnService] Current VPN IP: $externalIP');
    } catch (e) {
      debugPrint('[RealVpnService] IP check error: $e');
      // Fallback to server IP
      currentIP.value = _currentServer?.ip;
    }
  }

  // ── Stats Timer ───────────────────────────────────────────
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;

      // In production, read real stats from VPN interface
      final downloadBytes = 12000 + (DateTime.now().millisecond % 8000);
      final uploadBytes = 3000 + (DateTime.now().millisecond % 2000);

      stats.value = ConnectionStats(
        connectedDuration: DateTime.now().difference(_connectedAt!),
        downloadBytes: downloadBytes,
        uploadBytes: uploadBytes,
        assignedIp: currentIP.value ?? _currentServer?.ip ?? 'Unknown',
      );
    });
  }

  // ── Disconnect ───────────────────────────────────────────
  Future<void> disconnect() async {
    status.value = VpnStatus.disconnecting;
    _stopStatsTimer();

    try {
      if (Platform.isIOS) {
        final vpnManager = NEVPNManager.sharedManager;
        await vpnManager.stopConnection();
      } else if (Platform.isAndroid) {
        final vpnService = AndroidVpnService();
        await vpnService.disconnect();
      }
    } catch (e) {
      debugPrint('[RealVpnService] Disconnect error: $e');
    }

    _currentServer = null;
    _connectedAt = null;
    currentIP.value = null;
    stats.value = null;
    status.value = VpnStatus.disconnected;
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
