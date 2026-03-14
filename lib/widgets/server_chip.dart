// ============================================================
// widgets/server_chip.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vpn_models.dart';

class ServerChip extends ConsumerWidget {
  final VpnServer server;
  final VoidCallback onTap;

  const ServerChip({
    super.key,
    required this.server,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color protocolColor = server.protocol.index == 0
        ? const Color(0xFF00E5FF)
        : const Color(0xFF7B61FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Text(server.flagEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: protocolColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          server.protocolLabel,
                          style: TextStyle(
                              fontSize: 10,
                              color: protocolColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${server.ping} ms',
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
