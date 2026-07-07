# Habit Track - Mobile Application

This directory contains the cross-platform mobile application client built using **Flutter**.

## Getting Started

### Prerequisites
- Flutter SDK (v3.10.3 or higher recommended)
- Dart SDK
- Xcode (for iOS/macOS building)
- CocoaPods (`pod install` requirements)

### Running Locally

1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Launch the app on your preferred simulator or connected device:
   ```bash
   flutter run
   ```

---

## Building and Distributing for macOS (Testing)

To compile and share a macOS standalone build with testers, follow these instructions.

### 1. Build the Release Bundle
Run the following build command:
```bash
flutter build macos --release
```
The compiled standalone `.app` bundle is generated at:
`build/macos/Build/Products/Release/execut.app`

### 2. Compress the Application for Sharing
Since macOS `.app` packages are directories, they must be zipped before sharing over the internet:
```bash
cd build/macos/Build/Products/Release
zip -r execut.zip execut.app
```

### 3. Bypassing macOS Gatekeeper / Apple Validation (For the Tester)
When your friend or tester downloads and extracts `execut.zip`, macOS will block running the unnotarized binary with warnings like:
- *"execut is damaged and can’t be opened."*
- *"execut cannot be opened because the developer cannot be verified."*

Here is how the tester can bypass this:

#### Method A: Remove Quarantine Flags via Terminal (Recommended)
Open **Terminal** and run:
```bash
xattr -cr /path/to/execut.app
```
*(Tip: Type `xattr -cr ` and then drag-and-drop the `execut.app` file from Finder into Terminal to automatically paste the absolute path).*

#### Method B: Security Settings Dialog
1. In Finder, **Right-click / Control-click** `execut.app` and choose **Open**.
2. If blocked, navigate to **System Settings > Privacy & Security**.
3. Under the **Security** section, find the notice stating *"execut was blocked..."* and click **Open Anyway**.

---

## Building for Android (Play Store)

To build the app for publishing on the Google Play Store, you need to generate an App Bundle (`.aab`).

### 1. Configure Signing
Ensure your `android/app/build.gradle` is configured with a release keystore. You will need a `key.properties` file in the `android/` directory containing your keystore alias and passwords.

### 2. Build the App Bundle
Run the following command to generate the release `.aab` file:
```bash
flutter build appbundle
```
The App Bundle will be generated at:
`build/app/outputs/bundle/release/app-release.aab`

You can now upload this `.aab` file to the Google Play Console for distribution.

