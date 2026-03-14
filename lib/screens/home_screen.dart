// ============================================================
// screens/home_screen.dart
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            
            children: [
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

  void _showVPNInstructions(WidgetRef ref) {
    final context = ref.context;
    if (context == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('VPN Connection'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. VPN app will open automatically'),
            SizedBox(height: 8),
            Text('2. Connect to any server in the VPN app'),
            SizedBox(height: 8),
            Text('3. Return to this app to see status'),
            SizedBox(height: 8),
            Text('4. Your IP will change and blocked sites will open'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
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
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.isConnected
        ? const Color(0xFF00E5FF)
        : const Color(0xFF7B61FF);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        top: -100,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            width: 400 + (_ctrl.value * 80),
            height: 400 + (_ctrl.value * 80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glowColor.withOpacity(0.12 + _ctrl.value * 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isConnected;
  const _Header({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF7B61FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Glagol VPN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected
                ? const Color(0xFF00E5FF).withOpacity(0.12)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected
                  ? const Color(0xFF00E5FF).withOpacity(0.4)
                  : const Color(0xFF334155),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      isConnected ? const Color(0xFF00E5FF) : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Protected' : 'Exposed',
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected
                      ? const Color(0xFF00E5FF)
                      : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status label ─────────────────────────────────────────────
class _StatusLabel extends StatelessWidget {
  final VpnStatus status;
  const _StatusLabel({required this.status});

  String get _label {
    return switch (status) {
      VpnStatus.connected => 'Your connection is secure',
      VpnStatus.connecting => 'Establishing tunnel...',
      VpnStatus.disconnecting => 'Closing tunnel...',
      VpnStatus.error => 'Connection failed. Tap to retry.',
      _ => 'Your traffic is unprotected',
    };
  }

  Color get _color {
    return switch (status) {
      VpnStatus.connected => const Color(0xFF00E5FF),
      VpnStatus.connecting || VpnStatus.disconnecting => Colors.amber,
      VpnStatus.error => Colors.redAccent,
      _ => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _label,
        key: ValueKey(status),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: _color,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

// ── Quick server picker ──────────────────────────────────────
class _QuickServerPicker extends StatelessWidget {
  final WidgetRef ref;
  const _QuickServerPicker({required this.ref});

  @override
  Widget build(BuildContext context) {
    final servers = ref.read(serverListProvider);
    final selected = ref.read(selectedServerProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Quick select server',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          ...servers.map(
            (s) => ListTile(
              leading: Text(s.flagEmoji, style: const TextStyle(fontSize: 24)),
              title: Text(s.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(
                '${s.protocolLabel} • ${s.ping}ms',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              trailing: s.id == selected?.id
                  ? const Icon(Icons.check_circle, color: Color(0xFF00E5FF))
                  : null,
              onTap: () {
                ref.read(selectedServerProvider.notifier).state = s;
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
