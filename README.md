# Android Emulator Manager

A macOS status bar app for managing Android emulators with ease.

![Screenshot 2025-06-06 at 2 22 53 AM](https://github.com/user-attachments/assets/4fc69a8e-ee4f-48db-b488-92edfe1fdd50)


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

### from releases 

- Find the latest DMG [here](https://github.com/prudhvir3ddy/AvdManager-MacOS/releases)
- Download
- Double click to install and drag the AvdManager to the Applications folder

When you try to run, you will face this error because I didn't pay $99 to Apple

![Screenshot 2025-06-06 at 9 44 21 AM](https://github.com/user-attachments/assets/ed252708-8819-45d5-805d-734596d6840b)

Click on cancel and run this command in the terminal 

```bash
xattr -rd com.apple.quarantine /Applications/avdmanager.app/
```


### from sources

1. Open the project in Xcode:
   ```bash
   open avdmanager.xcodeproj
   ```

2. Build and run the project (⌘+R)

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

This will create a DMG file with a proper installation setup.

### Automated Releases

This project uses GitHub Actions for automated releases:

## Usage

1. **Launch the app** - After building, the app will appear in your status bar as a smartphone icon
2. **Click the icon** - Opens a popover showing all your Android emulators
3. **Start an emulator** - Click the green "Start" button next to any stopped emulator
4. **Stop an emulator** - Click the red "Stop" button next to any running emulator
5. **Refresh the list** - Click the refresh icon to update the emulator status
6. **Quit the app** - Click "Quit" at the bottom of the popover

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

### App doesn't appear in the status bar
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

1. Raise an issue
2. Fork the repository
3. Create a feature branch
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Credits

Created with ❤️ for Android developers on macOS. 
