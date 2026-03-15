# LIORA - Personal AI Companion

Your Personal AI with Vision, Listening, Threat Detection, Cloud Sync & Bilingual Reports.

## Features

- 👀 **Vision** - Camera-based hazard detection with TFLite
- 🎙️ **Listening** - Voice input with speech-to-text
- 🛡️ **Threat Detection** - Real-time hazard alerts
- 💾 **Memory** - Reflections, lessons, hazards storage
- ☁️ **Cloud Sync** - Firebase Firestore + Storage
- 📄 **PDF/CSV Export** - 3 templates (Narrative, Tabular, Infographic)
- ☁️ **Cloud Upload** - Google Drive & OneDrive
- 📅 **Scheduled Reports** - Weekly/monthly auto-reports
- 🌐 **Bilingual** - English + Filipino reports
- 🎨 **Theming** - Custom colors & templates

## Quick Start (Local)

```bash
cd personal_ai_app
flutter pub get
flutter run
```

## Cloud Build (GitHub Actions)

### 1. Push to GitHub
```bash
git init
git add .
git commit -m "LIORA - Personal AI"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/lora-app.git
git push -u origin main
```

### 2. Set GitHub Secrets
Go to Settings → Secrets → New repository secret:
- `FIREBASE_TOKEN` - Get from: `firebase login:ci`

### 3. Workflows Run Automatically
- **Android APK** - Builds on every push
- **Web Build** - Builds on every push  
- **Firebase Deploy** - Deploys to Firebase Hosting

## Codemagic (Alternative)

1. Go to https://codemagic.io
2. Connect your GitHub repo
3. The `codemagic.yaml` will auto-detect
4. Build generates APK, iOS, Web

## Environment Variables

Edit these files to configure:

| File | Key |
|------|-----|
| `lib/services/cloud_ai.dart` | OpenAI, Google AI, Bing keys |
| `lib/services/cloud_upload_service.dart` | Google Drive, OneDrive tokens |
| `lib/firebase_options.dart` | Firebase config (already set) |

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── hazard.dart
│   ├── reflection.dart
│   └── lesson.dart
├── screens/
│   ├── liora_chat_screen.dart
│   ├── dashboard_screen.dart
│   └── camera_screen.dart
├── services/
│   ├── local_ai.dart
│   ├── cloud_ai.dart
│   ├── memory_service.dart
│   ├── vision_service.dart
│   ├── listening_service.dart
│   ├── threat_detection_service.dart
│   ├── alert_service.dart
│   ├── recording_service.dart
│   ├── export_service.dart
│   ├── cloud_sync_service.dart
│   ├── cloud_upload_service.dart
│   └── scheduled_reports_service.dart
└── widgets/
    └── message_bubble.dart
```

## Deployment

### Firebase Hosting (Web)
```bash
firebase init hosting
firebase deploy
```

### Android APK
```bash
flutter build apk --release
```

### iOS (macOS only)
```bash
flutter build ios --release
```
