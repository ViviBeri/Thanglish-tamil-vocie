# Thanglish ⇄ Tamil Voice App

Full build guide: `thanglish-tamil-voice-app-guide.md`

## What's in this zip

```
backend/
  app.py                  ← Flask server: translation + Tamil voice generation
  requirements.txt        ← Python dependencies

app_flutter_lib/
  main.dart                                ← drop into app/lib/main.dart
  pubspec_dependencies_to_add.yaml         ← lines to add to app/pubspec.yaml
  AndroidManifest_permissions_to_add.xml   ← lines to add to the Android manifest
```

## Quick start

**Backend:**
```
cd backend
pip install -r requirements.txt
python app.py
```

**Frontend** (after installing Flutter):
```
flutter create app
# then copy app_flutter_lib/main.dart over app/lib/main.dart
# add the pubspec dependencies and manifest permissions as noted in those files
cd app
flutter pub get
flutter run
```

**Before running:** open `main.dart` and replace `YOUR-RENDER-URL` with your actual
backend URL once it's deployed (see Part C of the full guide).

**Build the APK:**
```
flutter build apk --release
```
APK will be at `app/build/app/outputs/flutter-apk/app-release.apk`.

See the full guide for GitHub repo setup, deploying the backend to Render, and
step-by-step explanations of every part.
