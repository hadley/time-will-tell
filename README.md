# Talk Timer

A simple iOS app to help speakers track their remaining time with color-coded visual warnings.

## Features

- Large countdown display visible from across the room
- Color-coded backgrounds:
  - **Black**: Safe zone - plenty of time remaining
  - **Yellow**: Warning - approaching the end
  - **Red**: Danger - wrap it up!
  - **Flashing**: Time's up!
- Haptic vibration alerts when entering warning zones
- Configurable talk duration and warning thresholds
- Screen stays awake during countdown

## Requirements

- macOS with Xcode 14+ installed
- An Apple ID (free or paid Developer account)
- An iPhone running iOS 15 or later

## Installing on Your iPhone

### Option 1: Free Apple ID (Personal Use)

You can install apps on your own device for free, but they expire after 7 days and need to be reinstalled.

1. **Open the project in Xcode**
   - Double-click `TalkTimer.xcodeproj`

2. **Sign in with your Apple ID**
   - Go to Xcode → Settings → Accounts
   - Click `+` and sign in with your Apple ID

3. **Configure signing**
   - Select the TalkTimer project in the navigator
   - Select the TalkTimer target
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your "Personal Team" from the Team dropdown

4. **Connect your iPhone**
   - Connect via USB cable
   - Trust the computer on your iPhone if prompted

5. **Select your device**
   - In the Xcode toolbar, click the device dropdown
   - Select your iPhone

6. **Build and run**
   - Click the Play button (or Cmd+R)
   - First time: You'll see "Unable to verify app" on your iPhone
   - On iPhone: Go to Settings → General → VPN & Device Management
   - Tap your Apple ID under "Developer App" and tap "Trust"
   - Run again from Xcode

### Option 2: Paid Developer Account ($99/year)

With a paid account, apps don't expire and you can distribute to others.

1. Follow steps 1-5 above
2. Your team will show your organization name instead of "Personal Team"
3. Build and run - no trust step needed after first install

## Building from the Command Line

You can build and run the app without opening Xcode.

**Build for simulator:**
```bash
xcodebuild -project TalkTimer.xcodeproj -scheme TalkTimer -sdk iphonesimulator build
```

**Build and run on iOS Simulator:**
```bash
# Build for simulator
xcodebuild -project TalkTimer.xcodeproj -scheme TalkTimer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

# Launch the simulator and install/run the app
xcrun simctl boot "iPhone 15"
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/TalkTimer-*/Build/Products/Debug-iphonesimulator/TalkTimer.app
xcrun simctl launch booted com.talktimer.app
```

**List available simulators:**
```bash
xcrun simctl list devices available
```

## Usage

1. **Configure your talk**
   - Tap the gear icon to open settings
   - Set total talk duration
   - Set yellow warning threshold (minutes remaining)
   - Set red warning threshold (minutes remaining)

2. **Start the timer**
   - Tap the play button
   - Point the phone at yourself or prop it up visible to you

3. **During the talk**
   - Phone vibrates when entering yellow zone
   - Phone vibrates when entering red zone
   - Screen flashes when time is up

4. **Controls**
   - Tap pause to freeze the countdown
   - Tap reset to start over

## Tips

- Place the phone where you can see it but the audience can't
- Consider using a small phone stand
- For longer talks, connect to power (screen stays on the whole time)
