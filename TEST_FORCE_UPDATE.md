# Testing Force Update on Emulators

## Quick Start - Test the Force Update Overlay

### Step 1: Enable Force Update Test Mode

1. Open `lib/services/mock_backend.dart`
2. Find the `_shouldForceUpdate` method (around line 1351)
3. Change this line:
   ```dart
   const bool FORCE_UPDATE_TEST_MODE = false; // ← Change this
   ```
   To:
   ```dart
   const bool FORCE_UPDATE_TEST_MODE = true; // ← Enable testing
   ```

### Step 2: Run the App

```bash
flutter run
```

### Step 3: Observe the Behavior

When you launch the app:
- ✅ The app will check for updates
- ✅ The blocking "Update Required" overlay will appear
- ✅ Back button will be disabled (you can't go back)
- ✅ You'll see the update message and "Update Now" button

### Step 4: Test the Update Button

Click "Update Now":
- On emulator: Will try to open Play Store (may show "not found" if app not published - this is expected)
- The important thing is the overlay appears and blocks the app

### Step 5: Disable Test Mode

After testing, change it back:
```dart
const bool FORCE_UPDATE_TEST_MODE = false; // ← Disable testing
```

---

## Testing Different Scenarios

### Scenario 1: Force Update Enabled ✅
```dart
const bool FORCE_UPDATE_TEST_MODE = true;
```
**Expected Result:**
- Blocking overlay appears immediately
- Back button doesn't work
- App is unusable until "Update Now" is clicked

### Scenario 2: Force Update Disabled ✅
```dart
const bool FORCE_UPDATE_TEST_MODE = false;
```
**Expected Result:**
- App works normally
- No overlay appears
- User can use the app

---

## Testing Real Google Play In-App Update (Advanced)

⚠️ **Note:** Real in-app update ONLY works with apps installed from Google Play Store, not with `flutter run` or `adb install`.

### Requirements:
1. App must be published to Google Play Store (Internal/Alpha/Beta/Production track)
2. App must be installed from Play Store (not via `flutter run`)
3. New version must be uploaded to Play Store

### Steps:

1. **Publish app to Play Store Internal Testing:**
   - Build release APK/AAB: `flutter build appbundle` or `flutter build apk --release`
   - Upload to Google Play Console → Internal Testing
   - Install app from Play Store link

2. **Create new version:**
   - Update version in `pubspec.yaml`: `version: 3.1.25+48` (increment from current)
   - Build and upload new version
   - Wait for Play Store processing (5-15 minutes)

3. **Test update:**
   - Launch app with old version
   - In-app update dialog should appear
   - User can update without leaving app

---

## Quick Reference

| Test Mode | Overlay Shown? | App Usable? | Use Case |
|-----------|---------------|-------------|----------|
| `FORCE_UPDATE_TEST_MODE = true` | ✅ Yes | ❌ No | Testing UI/UX |
| `FORCE_UPDATE_TEST_MODE = false` | ❌ No | ✅ Yes | Normal usage |

---

## Troubleshooting

**Q: Overlay doesn't appear even with test mode enabled**
- Check if `_shouldForceUpdate()` is returning `true`
- Check console logs for errors
- Verify the version check API is being called

**Q: "Update Now" button doesn't open Play Store**
- This is normal if app is not published to Play Store
- The overlay still works - it's blocking the app as intended
- In production with published app, it will open Play Store correctly

**Q: Want to test version comparison logic**
- Modify `_shouldForceUpdate()` method
- Set `latestVersion` in `_mockAppVersion()` higher than current version
- The method will automatically compare versions

