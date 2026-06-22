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
`build/macos/Build/Products/Release/ezecute.app`

### 2. Compress the Application for Sharing
Since macOS `.app` packages are directories, they must be zipped before sharing over the internet:
```bash
cd build/macos/Build/Products/Release
zip -r ezecute.zip ezecute.app
```

### 3. Bypassing macOS Gatekeeper / Apple Validation (For the Tester)
When your friend or tester downloads and extracts `ezecute.zip`, macOS will block running the unnotarized binary with warnings like:
- *"ezecute is damaged and can’t be opened."*
- *"ezecute cannot be opened because the developer cannot be verified."*

Here is how the tester can bypass this:

#### Method A: Remove Quarantine Flags via Terminal (Recommended)
Open **Terminal** and run:
```bash
xattr -d com.apple.quarantine /path/to/ezecute.app
```
*(Tip: Type `xattr -d com.apple.quarantine ` and then drag-and-drop the `ezecute.app` file from Finder into Terminal to automatically paste the absolute path).*

#### Method B: Security Settings Dialog
1. In Finder, **Right-click / Control-click** `ezecute.app` and choose **Open**.
2. If blocked, navigate to **System Settings > Privacy & Security**.
3. Under the **Security** section, find the notice stating *"ezecute was blocked..."* and click **Open Anyway**.
