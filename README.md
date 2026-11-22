# Radio App (Android, Flutter)

Egyptian + worldwide internet radio. Stations come from the free Radio Browser API (no API key).

## Features
- Egyptian stations sorted by popularity, with a filter box and pull to refresh
- Worldwide search by station name
- Favorites, saved locally
- Background playback with notification and lock-screen controls, plus headset/Bluetooth buttons
- Sleep timer (15–90 minutes)
- Remembers the last station you played

## Setup

```bash
# 1. Create the shell project (package name: com.ezzat.radio_app)
flutter create --platforms android --org com.ezzat radio_app
cd radio_app

# 2. Add the dependencies (picks the latest compatible versions)
flutter pub add just_audio audio_service http shared_preferences cached_network_image

# 3. Copy over the files from this zip, replacing the generated ones:
#    lib/                                                  (whole folder)
#    android/app/src/main/AndroidManifest.xml
#    android/app/src/main/kotlin/com/ezzat/radio_app/MainActivity.kt

# 4. Run it on your phone
flutter run
# Release APK:
flutter build apk --release
```

## Notes
- `usesCleartextTraffic="true"` is on because many stations stream over plain `http`.
- If a station won't play, it's usually down at the source. Pick another one.
- `minSdk` from the default Flutter template (21+) is fine.

## Structure
```
lib/
  main.dart                    app entry + AudioService init
  models/station.dart
  services/radio_api.dart      Radio Browser client (mirror fallback)
  services/audio_handler.dart  just_audio + audio_service, sleep timer
  services/favorites_service.dart
  screens/home_screen.dart     tabs: Egypt / Search / Favorites
  widgets/station_tile.dart
  widgets/player_bar.dart      now-playing bar + sleep timer
```
