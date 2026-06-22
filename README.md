# Habit Track

A comprehensive habit tracking application featuring a backend built with NestJS and a mobile application built with Flutter.

## Project Structure

The project is structured as a monorepo containing both the backend and the mobile app:

```bash
habit_track/
├── apps/
│   ├── backend/       # NestJS backend application
│   └── mobile_app/    # Flutter mobile application
```

## Backend System

The backend is built using the robust **NestJS** framework for Node.js, providing a scalable and easily testable architecture.

### Tech Stack
- Framework: [NestJS](https://nestjs.com/) (Node.js)
- Language: TypeScript
- Node Version: Node.js 18+ recommended

### Running the Backend Local Server

1. Navigate to the backend directory:
   ```bash
   cd apps/backend
   ```
2. Install the necessary dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   # Development mode
   npm run dev
   
   # Or using Nest's default start scripts:
   npm run start:dev
   ```

## Mobile App

The mobile application is a cross-platform client built using **Flutter**.

### Tech Stack
- Framework: [Flutter](https://flutter.dev/)
- Language: Dart
- Target Platforms: Android, iOS, Web, Windows, macOS, Linux (depending on your Flutter setup requirements).

### Running the Mobile App Locally

1. Navigate to the mobile app directory:
   ```bash
   cd apps/mobile_app
   ```
2. Fetch required dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### Building and Distributing for macOS (Testing)

To share a macOS build of the app with friends or QA testers without going through the Apple App Store, follow these steps:

#### 1. Generate the macOS Release Build
1. Navigate to the mobile application directory:
   ```bash
   cd apps/mobile_app
   ```
2. Run the Flutter build command for macOS in release mode:
   ```bash
   flutter build macos --release
   ```
   This compiles the application and generates the `.app` bundle at:
   `apps/mobile_app/build/macos/Build/Products/Release/ezecute.app`

#### 2. Compress the Application
Since `.app` packages are directories on macOS, they must be compressed into a `.zip` archive before they can be sent via email, Slack, Google Drive, or other file-sharing services.

Run the following command to create a zip archive while preserving symlinks and metadata:
```bash
cd build/macos/Build/Products/Release
zip -r ezecute.zip ezecute.app
```
*(Alternatively, you can right-click `ezecute.app` in Finder and select **Compress "ezecute"**)*.

#### 3. Bypassing macOS Gatekeeper / Apple Validation (For the Tester)
When the tester downloads and extracts the zip file, macOS automatically flags it with a quarantine attribute. Opening the app might trigger security warnings such as:
- *"ezecute is damaged and can’t be opened. You should move it to the Trash."*
- *"ezecute cannot be opened because the developer cannot be verified."*

To bypass these security checks, the tester can use one of the following methods:

##### Method A: Remove the Quarantine Flag (Recommended)
1. Open the **Terminal** app.
2. Run the following command to remove the quarantine attribute:
   ```bash
   xattr -d com.apple.quarantine /path/to/ezecute.app
   ```
   *(Tip: The tester can type `xattr -d com.apple.quarantine ` and then drag and drop the `ezecute.app` icon from Finder directly into the Terminal window to auto-populate the path.)*

##### Method B: GUI Bypass via Privacy Settings
1. Right-click (or Control-click) `ezecute.app` in Finder and select **Open**.
2. If a dialog appears stating the developer is unverified, click **Open** (if the option is available).
3. If it does not let you open, go to **System Settings > Privacy & Security**.
4. Scroll down to the **Security** section. You will see a notice saying: *"ezecute was blocked from use because it is not from an identified developer."*
5. Click **Open Anyway** and enter your macOS administrator password to confirm.

## Contributing

1. Ensure you have the latest versions of Flutter, Dart, Node.js, and npm installed.
2. Follow the standard code styling options defined in the respective directories (`.prettierrc` and ESLint configuration in NestJS, and `analysis_options.yaml` in Flutter).
