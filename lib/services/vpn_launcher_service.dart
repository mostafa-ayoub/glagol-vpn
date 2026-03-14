// ============================================================
// services/vpn_launcher_service.dart
// ============================================================
//
// Launch external VPN apps and monitor connection status
// Works with popular VPN apps like NordVPN, ExpressVPN, etc.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/vpn_models.dart';

class VpnLauncherService {
  static final VpnLauncherService _instance = VpnLauncherService._internal();
  factory VpnLauncherService() => _instance;
  VpnLauncherService._internal();

  final ValueNotifier<VpnStatus> status = ValueNotifier(VpnStatus.disconnected);
  final ValueNotifier<ConnectionStats?> stats = ValueNotifier(null);
  final ValueNotifier<String?> currentIP = ValueNotifier(null);
  final ValueNotifier<String?> activeVPN = ValueNotifier(null);

  VpnServer? _currentServer;
  Timer? _monitoringTimer;
  DateTime? _connectedAt;
  String? _originalIP;

  // Popular VPN apps URL schemes
  static const Map<String, String> vpnApps = {
    'nordvpn': 'nordvpn://',
    'expressvpn': 'expressvpn://',
    'cyberghost': 'cyberghost://',
    'surfshark': 'surfshark://',
    'privatevpn': 'privatevpn://',
    'protonvpn': 'protonvpn://',
    'tunnelbear': 'tunnelbear://',
    'hotspotshield': 'hotspotshield://',
    'windscribe': 'windscribe://',
    'ipvanish': 'ipvanish://',
    'openvpn': 'openvpn-connect://',
    'wireguard': 'wireguard://',
  };

  // ── Connect using External VPN App ─────────────────────────
  Future<bool> connect(VpnServer server, {String? vpnAppName}) async {
    if (status.value == VpnStatus.connected) await disconnect();

    status.value = VpnStatus.connecting;
    _currentServer = server;

    try {
      // Store original IP for comparison
      _originalIP = await _getCurrentIP();
      
      // Launch VPN app
      if (vpnAppName != null && vpnApps.containsKey(vpnAppName.toLowerCase())) {
        final success = await _launchVPNApp(vpnAppName.toLowerCase());
        if (!success) {
          // Fallback to system settings
          await _launchSystemVPNSettings();
        }
      } else {
        // Try to detect and launch available VPN apps
        await _launchAvailableVPNApp();
      }

      // Start monitoring connection
      _startMonitoring();
      
      return true;
    } catch (e) {
      debugPrint('[VpnLauncherService] Connection error: $e');
      status.value = VpnStatus.error;
      return false;
    }
  }

  // ── Launch Specific VPN App ───────────────────────────────
  Future<bool> _launchVPNApp(String appName) async {
    final url = vpnApps[appName];
    if (url != null && await canLaunch(url)) {
      final success = await launch(url);
      if (success) {
        activeVPN.value = appName;
        debugPrint('[VpnLauncherService] Launched $appName');
        return true;
      }
    }
    return false;
  }

  // ── Launch Available VPN App ─────────────────────────────
  Future<void> _launchAvailableVPNApp() async {
    // Try to launch available VPN apps in order of preference
    final preferredApps = [
      'nordvpn', 'expressvpn', 'cyberghost', 'surfshark', 
      'protonvpn', 'openvpn', 'wireguard'
    ];

    for (final app in preferredApps) {
      if (await _launchVPNApp(app)) {
        return;
      }
    }

    // Fallback to system settings
    await _launchSystemVPNSettings();
  }

  // ── Launch System VPN Settings ───────────────────────────
  Future<void> _launchSystemVPNSettings() async {
    try {
      if (Platform.isIOS) {
        final url = 'App-prefs:VPN';
        if (await canLaunch(url)) {
          await launch(url);
        }
      } else if (Platform.isAndroid) {
        final url = 'android.settings.vpn';
        if (await canLaunch(url)) {
          await launch(url);
        }
      }
    } catch (e) {
      debugPrint('[VpnLauncherService] Settings launch error: $e');
    }
  }

  // ── Start Monitoring VPN Connection ───────────────────────
  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkVPNStatus();
    });
  }

  // ── Check VPN Connection Status ───────────────────────────
  Future<void> _checkVPNStatus() async {
    try {
      final currentIP = await _getCurrentIP();
      final isConnected = await _isVPNActive(currentIP);

      if (isConnected && status.value != VpnStatus.connected) {
        status.value = VpnStatus.connected;
        _connectedAt = DateTime.now();
        _startStatsTimer();
        currentIP.value = currentIP;
        debugPrint('[VpnLauncherService] VPN Connected! IP: $currentIP');
      } else if (!isConnected && status.value == VpnStatus.connected) {
        status.value = VpnStatus.disconnected;
        _stopMonitoring();
        currentIP.value = null;
        activeVPN.value = null;
        debugPrint('[VpnLauncherService] VPN Disconnected');
      } else if (isConnected) {
        // Update IP if it changed
        currentIP.value = currentIP;
      }
    } catch (e) {
      debugPrint('[VpnLauncherService] Status check error: $e');
    }
  }

  // ── Check if VPN is Active ───────────────────────────────
  Future<bool> _isVPNActive(String? currentIP) async {
    if (currentIP == null || _originalIP == null) return false;

    // Check if IP changed (strong indicator of VPN)
    if (currentIP != _originalIP) return true;

    // Check network interfaces for VPN
    final interfaces = await NetworkInterface.list(
      includeLoopback: false, 
      includeLinkLocal: false
    );
    
    for (final interface in interfaces) {
      if (interface.name.contains('utun') || 
          interface.name.contains('tun') || 
          interface.name.contains('ppp')) {
        return true;
      }
    }

    return false;
  }

  // ── Get Current IP Address ───────────────────────────────
  Future<String?> _getCurrentIP() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      final request = await client.getUrl(Uri.parse('https://api.ipify.org'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final data = await response.transform(utf8.decoder).join();
        return data.trim();
      }
    } catch (e) {
      debugPrint('[VpnLauncherService] IP check error: $e');
    }
    return null;
  }

  // ── Start Stats Timer ─────────────────────────────────────
  void _startStatsTimer() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectedAt == null) return;

      final downloadBytes = 12000 + (DateTime.now().millisecond % 8000);
      final uploadBytes = 3000 + (DateTime.now().millisecond % 2000);

      stats.value = ConnectionStats(
        connectedDuration: DateTime.now().difference(_connectedAt!),
        downloadBytes: downloadBytes,
        uploadBytes: uploadBytes,
        assignedIp: currentIP.value ?? 'Checking...',
      );
    });
  }

  // ── Stop Monitoring ─────────────────────────────────────────
  void _stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  // ── Disconnect ─────────────────────────────────────────────
  Future<void> disconnect() async {
    status.value = VpnStatus.disconnecting;
    _stopMonitoring();

    // Note: We can't programmatically disconnect external VPN
    // User needs to disconnect manually from VPN app
    
    _currentServer = null;
    _connectedAt = null;
    _originalIP = null;
    currentIP.value = null;
    activeVPN.value = null;
    stats.value = null;
    status.value = VpnStatus.disconnected;
  }

  // ── Get Available VPN Apps ───────────────────────────────
  Future<List<String>> getAvailableVPNApps() async {
    final availableApps = <String>[];
    
    for (final appName in vpnApps.keys) {
      final url = vpnApps[appName];
      if (url != null && await canLaunch(url)) {
        availableApps.add(appName);
      }
    }
    
    return availableApps;
  }

  // ── Check if VPN App is Installed ───────────────────────────
  Future<bool> isVPNAppInstalled(String appName) async {
    final url = vpnApps[appName.toLowerCase()];
    return url != null && await canLaunch(url);
  }

  void dispose() {
    _stopMonitoring();
    status.dispose();
    stats.dispose();
    currentIP.dispose();
    activeVPN.dispose();
  }
}
