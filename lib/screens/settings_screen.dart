// ============================================================
// screens/settings_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings providers
final killSwitchProvider = StateProvider<bool>((ref) => true);
final autoConnectProvider = StateProvider<bool>((ref) => false);
final splitTunnelProvider = StateProvider<bool>((ref) => false);
final dnsLeakProtectionProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Security section ──────────────────────────
              _SectionHeader(label: 'Security'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.power_settings_new,
                iconColor: const Color(0xFFEF4444),
                title: 'Kill switch',
                subtitle: 'Block traffic if VPN drops',
                child: _Switch(provider: killSwitchProvider),
              ),
              _SettingsTile(
                icon: Icons.dns_outlined,
                iconColor: const Color(0xFF00E5FF),
                title: 'DNS leak protection',
                subtitle: 'Use encrypted DNS resolvers',
                child: _Switch(provider: dnsLeakProtectionProvider),
              ),

              const SizedBox(height: 24),

              // ── Connection section ────────────────────────
              _SectionHeader(label: 'Connection'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.wifi_tethering,
                iconColor: const Color(0xFF10B981),
                title: 'Auto-connect',
                subtitle: 'Connect on untrusted networks',
                child: _Switch(provider: autoConnectProvider),
              ),
              _SettingsTile(
                icon: Icons.call_split,
                iconColor: const Color(0xFF7B61FF),
                title: 'Split tunneling',
                subtitle: 'Choose apps that bypass VPN',
                child: _Switch(provider: splitTunnelProvider),
              ),

              const SizedBox(height: 24),

              // ── Account ──────────────────────────────────
              _SectionHeader(label: 'Account'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.person_outline,
                iconColor: Colors.grey,
                title: 'Account',
                subtitle: 'user@example.com',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.star_outline,
                iconColor: Colors.amber,
                title: 'Upgrade to Pro',
                subtitle: 'Unlock all servers',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // ── About ────────────────────────────────────
              _SectionHeader(label: 'About'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF64748B),
                title: 'Version',
                subtitle: '1.0.0 (Build 1)',
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF64748B),
                title: 'Privacy policy',
                subtitle: 'No-logs policy',
                onTap: () {},
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? child;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
            if (child != null) child!,
            if (child == null && onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFF334155), size: 18),
          ],
        ),
      ),
    );
  }
}

class _Switch extends ConsumerWidget {
  final StateProvider<bool> provider;
  const _Switch({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return Switch(
      value: value,
      onChanged: (v) => ref.read(provider.notifier).state = v,
      activeColor: const Color(0xFF00E5FF),
    );
  }
}
