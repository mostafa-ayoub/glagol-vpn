# iOS Setup Instructions for Glagol VPN

## Current Status
✅ iOS project structure created
✅ VPN entitlements added
✅ VPN permissions added to Info.plist
✅ CocoaPods installed
✅ Podfile created and installed

## Required Steps to Run on iPhone

### 1. Install Xcode
```bash
# Option A: Via App Store (Recommended)
open "macappstore://itunes.apple.com/app/xcode/id497799835"

# Option B: Via Xcodes App (Already installed)
open /Applications/Xcodes.app
# Install Xcode 15.x or later
```

### 2. Configure Xcode
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 3. Open Project in Xcode
```bash
open ios/Runner.xcworkspace
```

### 4. Configure Team and Bundle ID
1. Open Xcode project
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Add your Apple Developer Team
5. Change Bundle Identifier to something unique (e.g., com.yourname.glagolvpn)
6. Enable "Network Extensions" capability

### 5. Run on Device/Simulator
```bash
# Check available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or run from Xcode
# Select your device and press Run button
```

## VPN Configuration Notes

### Network Extensions Entitlement
The app includes Network Extensions entitlement for:
- packet-tunnel-provider
- app-proxy-provider

### Required Permissions
- NSNetworkExtensionUsageDescription
- NSVPNConfigurationUsageDescription

### Bundle Identifier Format
Use reverse domain notation: com.company.appname

## Testing Without Real VPN
The current app has VPN dependencies commented out for demo purposes. To test the UI:
1. Run on web or macOS desktop
2. The app will show the VPN interface without actual connection

## Next Steps
1. Install Xcode (8GB+ download)
2. Configure Apple Developer account ($99/year)
3. Enable Network Extensions capability
4. Test on physical device or simulator
