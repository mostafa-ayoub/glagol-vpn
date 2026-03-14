// ============================================================
// screens/home_screen_fixed.dart
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vpn_models.dart';
import '../providers/vpn_providers.dart';
import '../widgets/connect_button.dart';
import '../widgets/stats_card.dart';
import '../widgets/server_chip.dart';

class HomeScreenFixed extends ConsumerWidget {
  const HomeScreenFixed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final statusAsync = ref.watch(vpnStatusProvider);
      final selectedServer = ref.watch(selectedServerProvider);
      final statsAsync = ref.watch(connectionStatsProvider);

      final status = statusAsync.value ?? VpnStatus.disconnected;
      final isConnected = status == VpnStatus.connected;
      final isConnecting =
          status == VpnStatus.connecting || status == VpnStatus.disconnecting;

      return Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A0D14),
                    Color(0xFF111827),
                    Color(0xFF1E293B),
                  ],
                ),
              ),
            ),
            
            // ── Background glow ──────────────────────────────
            _BackgroundGlow(isConnected: isConnected),

            // ── Main content ─────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _Header(isConnected: isConnected),
                    const SizedBox(height: 40),

                    // ── Big connect button ───────────────────
                    ConnectButton(
                      status: status,
                      onTap: () => _handleConnect(ref, status, selectedServer),
                    ),
                    const SizedBox(height: 32),

                    // ── Status label ─────────────────────────
                    _StatusLabel(status: status),
                    const SizedBox(height: 32),

                    // ── Stats (only when connected) ──────────
                    if (isConnected)
                      statsAsync.when(
                        data: (stats) => stats != null
                            ? StatsGrid(stats: stats)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2)
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                    const SizedBox(height: 24),

                    // ── Server selector ──────────────────────
                    if (!isConnecting && selectedServer != null)
                      ServerChip(
                        server: selectedServer!,
                        onTap: () => _showServerPicker(context, ref),
                      ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('HomeScreen error: $e');
      return Scaffold(
        backgroundColor: const Color(0xFF0A0D14),
        body: const Center(
          child: Text(
            'Glagol VPN',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    }
  }

  Future<void> _handleConnect(
      WidgetRef ref, VpnStatus status, VpnServer? server) async {
    final vpnService = ref.read(vpnServiceProvider);
    if (server == null) return;

    if (status == VpnStatus.connected || status == VpnStatus.connecting) {
      await vpnService.disconnect();
    } else {
      await vpnService.connect(server);
    }
  }

  void _showServerPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuickServerPicker(ref: ref),
    );
  }
}

// ── Header widget ────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isConnected;

  const _Header({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Glagol VPN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isConnected ? const Color(0xFF00E5FF) : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isConnected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            fontSize: 14,
            color: isConnected ? const Color(0xFF00E5FF) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Status label widget ───────────────────────────────────
class _StatusLabel extends StatelessWidget {
  final VpnStatus status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (status) {
      case VpnStatus.connected:
        text = 'Connected';
        color = const Color(0xFF10B981);
        break;
      case VpnStatus.connecting:
        text = 'Connecting...';
        color = const Color(0xFFF59E0B);
        break;
      case VpnStatus.disconnecting:
        text = 'Disconnecting...';
        color = const Color(0xFFF59E0B);
        break;
      case VpnStatus.error:
        text = 'Connection Error';
        color = const Color(0xFFEF4444);
        break;
      default:
        text = 'Disconnected';
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Background animated glow ─────────────────────────────────
class _BackgroundGlow extends StatefulWidget {
  final bool isConnected;
  const _BackgroundGlow({required this.isConnected});

  @override
  State<_BackgroundGlow> createState() => _BackgroundGlowState();
}

class _BackgroundGlowState extends State<_BackgroundGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.isConnected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_BackgroundGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isConnected && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isConnected) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: MediaQuery.of(context).size.width * 0.5 - 100,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00E5FF).withOpacity(_animation.value * 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Quick server picker ─────────────────────────────────────
class _QuickServerPicker extends ConsumerWidget {
  const _QuickServerPicker({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serverListProvider);
    final selected = ref.watch(selectedServerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Select Server',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: servers.length,
              itemBuilder: (_, index) {
                final server = servers[index];
                final isSelected = selected?.id == server.id;

                return ListTile(
                  leading: Text(
                    server.flagEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    server.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${server.ping} ms • ${server.protocolLabel}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF00E5FF))
                      : null,
                  onTap: () {
                    ref.read(selectedServerProvider.notifier).state = server;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
