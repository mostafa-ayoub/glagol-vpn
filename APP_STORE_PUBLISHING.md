# 📱 Glagol VPN - نشر على App Store

## المطور: مهندس مصطفي أيوب
📱 +79891574730 | 📧 mostafaayoub1210@mail.ru

## الخطوات لنشر التطبيق على App Store:

### 1. Apple Developer Account
```bash
# اشتراك Apple Developer Program
# التكلفة: $99/سنة
# الرابط: https://developer.apple.com/programs/
```

### 2. إنشاء App ID
- تسجيل الدخول إلى Apple Developer
- App IDs → Register New App
- Bundle ID: com.moustafa.glagolvpn
- اسم التطبيق: Glagol VPN

### 3. إعداد Provisioning Profiles
- Development Profile (للاختبار)
- Distribution Profile (للنشر)

### 4. تحديث التطبيق للنشر
```dart
// إزالة debug code
// إضافة App Store icons
// تحديث metadata
```

### 5. إنشاء App Store Connect
- تسجيل الدخول إلى App Store Connect
- إنشاء تطبيق جديد
- ربط App ID

### 6. إعداد App Store Metadata
- اسم التطبيق: Glagol VPN
- الوصف: تطبيق VPN احترافي سريع وآمن
- الكلمات المفتاحية: VPN, privacy, security, proxy
- الفئة: Utilities

### 7. رفع التطبيق
```bash
# Build for release
flutter build ios --release

# رفع إلى App Store Connect
xcrun altool --upload-app --type ios --file build/ios/ipa/GlagolVPN.ipa
```

### 8. مراجعة Apple
- انتظار مراجعة Apple (1-7 أيام)
- الرد على أي استفسارات

### 9. النشر
- الموافقة على النشر
- التطبيق متاح على App Store

## المستندات المطلوبة:
- ✅ Privacy Policy
- ✅ Terms of Service
- ✅ Support URL
- ✅ Marketing URL

## التكلفة الإجمالية:
- Apple Developer: $99/سنة
- الخوادم: $60/سنة
- إجمالي: ~$159 للسنة الأولى

## الوقت المقدر: 2-4 أسابيع
