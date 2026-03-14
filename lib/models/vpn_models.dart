// ============================================================
// models/vpn_models.dart
// ============================================================

enum VpnStatus { disconnected, connecting, connected, disconnecting, error }

enum VpnProtocol { wireguard, openvpn }

class VpnServer {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String flagEmoji;
  final String ip;
  final int port;
  final VpnProtocol protocol;
  final int ping; // ms
  final double load; // 0.0 - 1.0
  final bool isPremium;

  const VpnServer({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.flagEmoji,
    required this.ip,
    required this.port,
    required this.protocol,
    required this.ping,
    required this.load,
    this.isPremium = false,
  });

  String get protocolLabel =>
      protocol == VpnProtocol.wireguard ? 'WireGuard' : 'OpenVPN';

  String get loadLabel {
    if (load < 0.4) return 'Low';
    if (load < 0.7) return 'Medium';
    return 'High';
  }
}

class WireGuardConfig {
  final String privateKey;
  final String publicKey;
  final String peerPublicKey;
  final String endpoint;
  final String allowedIPs;
  final String dns;
  final int? persistentKeepalive;

  const WireGuardConfig({
    required this.privateKey,
    required this.publicKey,
    required this.peerPublicKey,
    required this.endpoint,
    this.allowedIPs = '0.0.0.0/0, ::/0',
    this.dns = '1.1.1.1, 1.0.0.1',
    this.persistentKeepalive,
  });

  /// Generates the WireGuard .conf file content
  String toConfigString() {
    final sb = StringBuffer();
    sb.writeln('[Interface]');
    sb.writeln('PrivateKey = $privateKey');
    sb.writeln('DNS = $dns');
    sb.writeln();
    sb.writeln('[Peer]');
    sb.writeln('PublicKey = $peerPublicKey');
    sb.writeln('Endpoint = $endpoint');
    sb.writeln('AllowedIPs = $allowedIPs');
    if (persistentKeepalive != null) {
      sb.writeln('PersistentKeepalive = $persistentKeepalive');
    }
    return sb.toString();
  }
}

class OpenVpnConfig {
  final String serverIp;
  final int port;
  final String protocol; // 'udp' or 'tcp'
  final String caCert;
  final String clientCert;
  final String clientKey;
  final String tlsAuth;
  final bool useCompression;

  const OpenVpnConfig({
    required this.serverIp,
    required this.port,
    this.protocol = 'udp',
    required this.caCert,
    required this.clientCert,
    required this.clientKey,
    required this.tlsAuth,
    this.useCompression = false,
  });

  /// Generates the .ovpn config file content
  String toOvpnString() {
    final sb = StringBuffer();
    sb.writeln('client');
    sb.writeln('dev tun');
    sb.writeln('proto $protocol');
    sb.writeln('remote $serverIp $port');
    sb.writeln('resolv-retry infinite');
    sb.writeln('nobind');
    sb.writeln('persist-key');
    sb.writeln('persist-tun');
    if (!useCompression) sb.writeln('comp-lzo no');
    sb.writeln('verb 3');
    sb.writeln('<ca>');
    sb.writeln(caCert);
    sb.writeln('</ca>');
    sb.writeln('<cert>');
    sb.writeln(clientCert);
    sb.writeln('</cert>');
    sb.writeln('<key>');
    sb.writeln(clientKey);
    sb.writeln('</key>');
    sb.writeln('<tls-auth>');
    sb.writeln(tlsAuth);
    sb.writeln('</tls-auth>');
    return sb.toString();
  }
}

class ConnectionStats {
  final Duration connectedDuration;
  final int downloadBytes;
  final int uploadBytes;
  final String assignedIp;

  const ConnectionStats({
    required this.connectedDuration,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.assignedIp,
  });

  String get downloadFormatted => _formatBytes(downloadBytes);
  String get uploadFormatted => _formatBytes(uploadBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String get durationFormatted {
    final h = connectedDuration.inHours.toString().padLeft(2, '0');
    final m = (connectedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (connectedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Sample server data ─────────────────────────────────────
final kSampleServers = <VpnServer>[
  VpnServer(
    id: 'us-ny-1',
    name: 'New York #1',
    country: 'United States',
    countryCode: 'US',
    flagEmoji: '🇺🇸',
    ip: '104.21.10.1',
    port: 51820,
    protocol: VpnProtocol.wireguard,
    ping: 28,
    load: 0.35,
  ),
  VpnServer(
    id: 'nl-ams-1',
    name: 'Amsterdam #1',
    country: 'Netherlands',
    countryCode: 'NL',
    flagEmoji: '🇳🇱',
    ip: '185.220.101.5',
    port: 51820,
    protocol: VpnProtocol.wireguard,
    ping: 42,
    load: 0.28,
  ),
  VpnServer(
    id: 'de-fra-1',
    name: 'Frankfurt #1',
    country: 'Germany',
    countryCode: 'DE',
    flagEmoji: '🇩🇪',
    ip: '194.165.16.10',
    port: 1194,
    protocol: VpnProtocol.openvpn,
    ping: 55,
    load: 0.52,
  ),
  VpnServer(
    id: 'jp-tok-1',
    name: 'Tokyo #1',
    country: 'Japan',
    countryCode: 'JP',
    flagEmoji: '🇯🇵',
    ip: '45.77.88.21',
    port: 51820,
    protocol: VpnProtocol.wireguard,
    ping: 120,
    load: 0.41,
    isPremium: true,
  ),
  VpnServer(
    id: 'sg-sin-1',
    name: 'Singapore #1',
    country: 'Singapore',
    countryCode: 'SG',
    flagEmoji: '🇸🇬',
    ip: '139.59.210.5',
    port: 1194,
    protocol: VpnProtocol.openvpn,
    ping: 95,
    load: 0.63,
    isPremium: true,
  ),
  VpnServer(
    id: 'uk-lon-1',
    name: 'London #1',
    country: 'United Kingdom',
    countryCode: 'GB',
    flagEmoji: '🇬🇧',
    ip: '46.101.60.12',
    port: 51820,
    protocol: VpnProtocol.wireguard,
    ping: 72,
    load: 0.74,
  ),
];
