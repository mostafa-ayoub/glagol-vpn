# Glagol VPN — Flutter App

## هيكل المشروع

```
lib/
├── main.dart                    # Entry point + navigation shell
├── models/
│   └── vpn_models.dart          # VpnServer, WireGuardConfig, OpenVpnConfig, ConnectionStats
├── services/
│   └── vpn_service.dart         # WireGuard + OpenVPN connection logic
├── providers/
│   └── vpn_providers.dart       # Riverpod state management
├── screens/
│   ├── home_screen.dart         # Main connect screen
│   ├── servers_screen.dart      # Server list with filter
│   └── settings_screen.dart     # Kill switch, auto-connect, etc.
└── widgets/
    ├── connect_button.dart      # Animated connect/disconnect button
    └── stats_card.dart          # Live traffic stats + server chip
```

---

## تشغيل المشروع

```bash
# 1. تثبيت dependencies
flutter pub get

# 2. تشغيل على المحاكي أو الجهاز
flutter run

# 3. بناء APK للـ Android
flutter build apk --release

# 4. بناء IPA للـ iOS
flutter build ios --release
```

---

## ربط WireGuard الحقيقي

في ملف `services/vpn_service.dart`، ابحث عن قسم `_connectWireGuard` وفعّل الكود الحقيقي:

```dart
import 'package:wireguard_flutter/wireguard_flutter.dart';

final wg = WireGuard.instance;
await wg.initialize(interfaceName: 'wg0');

final tunnel = await wg.startVpn(
  serverAddress: server.ip,
  wgQuickConfig: config!.toConfigString(),
  providerBundleIdentifier: 'com.yourcompany.securevpn', // iOS only
);
```

### إنشاء WireGuard config لسيرفرك:
```dart
final wgConfig = WireGuardConfig(
  privateKey: 'YOUR_CLIENT_PRIVATE_KEY',
  publicKey:  'YOUR_CLIENT_PUBLIC_KEY',
  peerPublicKey: 'YOUR_SERVER_PUBLIC_KEY',
  endpoint: '${server.ip}:${server.port}',
  dns: '1.1.1.1',
  persistentKeepalive: 25,
);
```

---

## ربط OpenVPN الحقيقي

في `_connectOpenVpn`:

```dart
import 'package:flutter_openvpn/flutter_openvpn.dart';

await FlutterOpenVpn.initialize(
  groupIdentifier: 'group.com.yourcompany.securevpn',
  localizedDescription: 'SecureVPN',
);

FlutterOpenVpn.connect(
  config!.toOvpnString(),
  server.name,
  username: 'your_username',
  password: 'your_password',
  certIsRequired: true,
);
```

---

## iOS — Network Extension Entitlements

يجب إضافة ملف `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>com.apple.developer.networking.networkextension</key>
  <array>
    <string>packet-tunnel-provider</string>
    <string>app-proxy-provider</string>
  </array>
</dict>
</plist>
```

> ⚠️ يلزم Apple Developer account مع VPN entitlement مفعّل من App Store Connect.

---

## Android — Kill Switch

Kill Switch يمنع التراسل لو انقطع VPN. يُفعَّل تلقائياً عبر:

```dart
// في VpnService._connectWireGuard
// wireguard_flutter يدعم lockdown mode تلقائياً على Android 8+
```

---

## Dependencies الرئيسية

| Package | الغرض |
|---------|--------|
| `wireguard_flutter` | WireGuard tunnel |
| `flutter_openvpn` | OpenVPN tunnel |
| `flutter_riverpod` | State management |
| `flutter_animate` | Animations |
| `flutter_secure_storage` | تخزين آمن للـ keys |
| `shared_preferences` | إعدادات المستخدم |
| `connectivity_plus` | مراقبة الشبكة |
