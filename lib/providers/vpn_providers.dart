// ============================================================
// providers/vpn_providers.dart
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vpn_models.dart';
import '../services/vpn_service.dart';

// ── VPN service provider ───────────────────────────────────
final realVpnServiceProvider = Provider<VpnService>((ref) {
  final service = VpnService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Use VPN service ───────────────────────────────────────────
final vpnServiceProvider = Provider<VpnService>((ref) {
  final service = VpnService();
  ref.onDispose(service.dispose);
  return service;
});

// ── VPN status stream ────────────────────────────────────────
final vpnStatusProvider = StreamProvider<VpnStatus>((ref) {
  final service = ref.watch(vpnServiceProvider);
  return Stream.fromFuture(Future.value(service.status.value)).asyncExpand(
    (_) => Stream.periodic(
      const Duration(milliseconds: 200),
      (_) => service.status.value,
    ).distinct(),
  );
});

// ── Connection stats stream ──────────────────────────────────
final connectionStatsProvider = StreamProvider<ConnectionStats?>((ref) {
  final service = ref.watch(vpnServiceProvider);
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => service.stats.value,
  );
});

// ── Current IP provider ───────────────────────────────────────
final currentIPProvider = StreamProvider<String?>((ref) {
  return Stream.periodic(
    const Duration(seconds: 5),
    (_) => '192.168.1.100', // Simulated IP for demo
  );
});

// ── Active VPN app provider ───────────────────────────────────
final activeVPNProvider = StreamProvider<String?>((ref) {
  return Stream.periodic(
    const Duration(seconds: 2),
    (_) => 'Glagol VPN',
  );
});

// ── Selected server state ────────────────────────────────────
final selectedServerProvider =
    StateProvider<VpnServer?>((ref) => kSampleServers.first);

// ── Server list ──────────────────────────────────────────────
final serverListProvider = Provider<List<VpnServer>>((ref) => kSampleServers);

// ── Selected protocol filter ─────────────────────────────────
final protocolFilterProvider =
    StateProvider<VpnProtocol?>((ref) => null); // null = show all

final filteredServersProvider = Provider<List<VpnServer>>((ref) {
  final servers = ref.watch(serverListProvider);
  final filter = ref.watch(protocolFilterProvider);
  if (filter == null) return servers;
  return servers.where((s) => s.protocol == filter).toList();
});
