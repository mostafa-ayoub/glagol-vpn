// ============================================================
// services/vpn_service.dart
// ============================================================
//
// This service abstracts both WireGuard and OpenVPN connections.
// For demo purposes, simulates VPN connection with network monitoring.
// ============================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/vpn_models.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  // ── State ────────────────────────────────────────────────
  final ValueNotifier<VpnStatus> status =
      ValueNotifier(VpnStatus.disconnected);
  final ValueNotifier<ConnectionStats?> stats = ValueNotifier(null);

  VpnServer? _currentServer;
  Timer? _statsTimer;
  DateTime? _connectedAt;

  // Simulated traffic counters (replace with real byte counts from plugins)
  int _downloadBytes = 0;
  int _uploadBytes = 0;

  VpnServer? get currentServer => _currentServer;

  // ── Connect ──────────────────────────────────────────────
  Future<bool> connect(
    VpnServer server, {
    WireGuardConfig? wgConfig,
    OpenVpnConfig? ovpnConfig,
  }) async {
    if (status.value == VpnStatus.connected) await disconnect();

    status.value = VpnStatus.connecting;
    _currentServer = server;

    try {
      bool success;
      if (server.protocol == VpnProtocol.wireguard) {
        success = await _connectWireGuard(server, wgConfig);
      } else {
        success = await _connectOpenVpn(server, ovpnConfig);
      }

      if (success) {
        status.value = VpnStatus.connected;
        _connectedAt = DateTime.now();
        _startStatsTimer();
        return true;
      } else {
        status.value = VpnStatus.error;
        return false;
      }
    } catch (e) {
      debugPrint('[VpnService] Connection error: $e');
      status.value = VpnStatus.error;
      return false;
    }
  }

  // ── WireGuard ────────────────────────────────────────────
  Future<bool> _connectWireGuard(
      VpnServer server, WireGuardConfig? config) async {
    try {
      // Simulate VPN connection with network configuration
      debugPrint('[VpnService] Simulating WireGuard connection to ${server.ip}');
      
      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Monitor network changes
      _monitorNetworkChanges();
      
      return true;
    } catch (e) {
      debugPrint('[VpnService] WireGuard error: $e');
      return false;
    }
  }

  // ── OpenVPN ──────────────────────────────────────────────
  Future<bool> _connectOpenVpn(
      VpnServer server, OpenVpnConfig? config) async {
    try {
      // Simulate OpenVPN connection
      debugPrint('[VpnService] Simulating OpenVPN connection to ${server.ip}');
      
      // Simulate connection delay
      await Future.delayed(const Duration(milliseconds: 2200));
      
      // Monitor network changes
      _monitorNetworkChanges();
      
      return true;
    } catch (e) {
      debugPrint('[VpnService] OpenVPN error: $e');
      return false;
    }
  }

  // ── Disconnect ───────────────────────────────────────────
  Future<void> disconnect() async {
    status.value = VpnStatus.disconnecting;
    _stopStatsTimer();

    try {
      // Stop network monitoring
      _stopNetworkMonitoring();
      
      debugPrint('[VpnService] Disconnected from VPN');
    } catch (e) {
      debugPrint('[VpnService] Disconnect error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 800));

    _currentServer = null;
    _connectedAt = null;
    _downloadBytes = 0;
    _uploadBytes = 0;
    stats.value = null;
    status.value = VpnStatus.disconnected;
  }

  // ── Network Monitoring ────────────────────────────────────
  StreamSubscription<ConnectivityResult>? _networkSubscription;
  
  void _monitorNetworkChanges() {
    _networkSubscription = Connectivity().onConnectivityChanged.listen((result) {
      debugPrint('[VpnService] Network status: $result');
      // In real VPN, you'd monitor tunnel status here
    });
  }
  
  void _stopNetworkMonitoring() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
  }

  // ── Stats timer ──────────────────────────────────────────
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;

      // In production: read real byte counts from the VPN tunnel interface
      _downloadBytes += 12000 + (DateTime.now().millisecond % 8000);
      _uploadBytes += 3000 + (DateTime.now().millisecond % 2000);

      stats.value = ConnectionStats(
        connectedDuration: DateTime.now().difference(_connectedAt!),
        downloadBytes: _downloadBytes,
        uploadBytes: _uploadBytes,
        assignedIp: '10.8.0.${_currentServer.hashCode % 200 + 2}',
      );
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void dispose() {
    _stopStatsTimer();
    _stopNetworkMonitoring();
    status.dispose();
    stats.dispose();
  }
}
