// ============================================================
// screens/servers_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vpn_models.dart';
import '../providers/vpn_providers.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(protocolFilterProvider);
    final servers = ref.watch(filteredServersProvider);
    final selected = ref.watch(selectedServerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Servers',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${servers.length} locations available',
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  // ── Protocol filter chips ────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: filter == null,
                          onTap: () => ref
                              .read(protocolFilterProvider.notifier)
                              .state = null,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'WireGuard',
                          isSelected: filter == VpnProtocol.wireguard,
                          color: const Color(0xFF00E5FF),
                          onTap: () => ref
                              .read(protocolFilterProvider.notifier)
                              .state = VpnProtocol.wireguard,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'OpenVPN',
                          isSelected: filter == VpnProtocol.openvpn,
                          color: const Color(0xFF7B61FF),
                          onTap: () => ref
                              .read(protocolFilterProvider.notifier)
                              .state = VpnProtocol.openvpn,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: servers.length,
                itemBuilder: (_, i) => _ServerTile(
                  server: servers[i],
                  isSelected: servers[i].id == selected?.id,
                  onTap: () {
                    ref.read(selectedServerProvider.notifier).state =
                        servers[i];
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color = const Color(0xFF94A3B8),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? color : const Color(0xFF94A3B8),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Server tile ──────────────────────────────────────────────
class _ServerTile extends StatelessWidget {
  final VpnServer server;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  Color get _loadColor {
    if (server.load < 0.4) return const Color(0xFF10B981);
    if (server.load < 0.7) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color get _protocolColor => server.protocol == VpnProtocol.wireguard
      ? const Color(0xFF00E5FF)
      : const Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00E5FF).withOpacity(0.06)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00E5FF).withOpacity(0.3)
                : const Color(0xFF1E293B),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Flag
            Text(server.flagEmoji,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (server.isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.amber,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Protocol badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _protocolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          server.protocolLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: _protocolColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        server.country,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Metrics
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${server.ping} ms',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _loadColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      server.loadLabel,
                      style: TextStyle(
                        color: _loadColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (isSelected) ...[
              const SizedBox(width: 12),
              const Icon(Icons.check_circle,
                  color: Color(0xFF00E5FF), size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
