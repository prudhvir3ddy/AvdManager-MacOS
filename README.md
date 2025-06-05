# Android Emulator Manager

A macOS status bar app for managing Android emulators with ease.

## Features

- 📱 **View all Android emulators** - Lists all available AVDs (Android Virtual Devices) on your system
- ▶️ **Start emulators** - Launch any emulator with a single click
- ⏹️ **Stop emulators** - Terminate running emulators easily
- 🔄 **Real-time status** - See which emulators are currently running
- 🎯 **Status bar integration** - Lives in your macOS status bar for quick access
- 🔄 **Auto-refresh** - Automatically updates emulator status

## Requirements

- macOS 15.4+ (Sequoia)
- Android SDK installed with:
  - Android Studio or command line tools
  - `adb` (Android Debug Bridge)
  - `emulator` command line tool
  - At least one AVD created

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd avdmanager
   ```

2. Open the project in Xcode:
   ```bash
   open avdmanager.xcodeproj
   ```

3. Build and run the project (⌘+R)

## Building & Releases

### Local Development

To build the project locally:

```bash
xcodebuild -configuration Release
```

### Creating a Release DMG

For distribution, you can create a DMG file:

```bash
# Install create-dmg if not already installed
brew install create-dmg

# Run the build script
./scripts/build_release.sh
```

This will create a DMG file with proper installation setup.

### Automated Releases

This project uses GitHub Actions for automated releases:

#### Release Process

1. **Tag a version**: Create and push a git tag starting with `v` (e.g., `v1.0.0`)
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Automatic build**: GitHub Actions will automatically:
   - Build the app for Release
   - Create a DMG with installation setup
   - Generate checksums
   - Create a GitHub release with assets

#### Manual Trigger

You can also trigger the build manually from the GitHub Actions tab.

#### Release Assets

Each release includes:
- `AVD-Manager-{version}.dmg` - The installable DMG file
- `AVD-Manager-{version}.dmg.sha256` - SHA256 checksum for verification

## Usage

1. **Launch the app** - After building, the app will appear in your status bar as a smartphone icon
2. **Click the icon** - Opens a popover showing all your Android emulators
3. **Start an emulator** - Click the green "Start" button next to any stopped emulator
4. **Stop an emulator** - Click the red "Stop" button next to any running emulator
5. **Refresh the list** - Click the refresh icon to update the emulator status
6. **Quit the app** - Click "Quit" at the bottom of the popover

## Architecture

The app consists of several key components:

### `AndroidEmulatorManager.swift`
- Core business logic for interacting with Android emulators
- Executes command-line tools (`emulator`, `adb`, `avdmanager`)
- Manages emulator state and provides async operations
- Automatically discovers Android SDK installation paths

### `StatusBarManager.swift`
- Handles macOS status bar integration
- Creates and manages the popover UI
- Provides the main user interface components

### `avdmanagerApp.swift`
- Main app entry point
- Configures the app as a status bar accessory (no dock icon)
- Sets up the app lifecycle

## Technical Details

- **Language**: Swift 5
- **Framework**: SwiftUI + AppKit
- **Architecture**: MVVM with ObservableObject
- **Platform**: macOS 15.4+
- **Permissions**: Runs without app sandbox for command execution

## Troubleshooting

### No emulators found
- Ensure Android SDK is properly installed
- Check that AVDs are created in Android Studio
- Verify `emulator` and `adb` commands are accessible

### Can't start/stop emulators
- Make sure Android SDK tools are in your PATH
- Check that the Android SDK platform-tools are installed
- Ensure no other Android development tools are interfering

### App doesn't appear in status bar
- Check that the app has proper permissions
- Restart the app if needed
- Look for the smartphone icon in your status bar

## Common Android SDK Paths

The app automatically searches for Android SDK tools in these locations:
- `~/Library/Android/sdk/`
- `~/Android/Sdk/`
- `/usr/local/bin/`
- `/opt/homebrew/bin/`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[Your License Here]

## Credits

Created with ❤️ for Android developers on macOS. 