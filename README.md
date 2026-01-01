# scrcpy Connection Manager
A simple yet powerful Windows Batch Script designed to simplify connecting and launching of [scrcpy](https://github.com/Genymobile/scrcpy);the powerful Android screen mirroring tool. This manager improves ease of usage for auto connection handling, multiple IP management, and extensive troubleshooting capabilities.

## ✨ Key Features
### 🔌 Smart Connection Management
- **Multiple IP Storage**: Save and manage multiple device IP addresses
- **Automatic Connection**: Attempts all saved IPs automatically on startup
- **Smart Prioritization**: Most recently used/successful IPs are tried first
- **Skip Auto-Connect**: Optional manual control over connection attempts
- **Three Connection Modes**:
  - **Saved Wi-Fi IP**: Connect using stored IP addresses
  - **USB Cable**: Direct connection via USB (scrcpy -d)
  - **New IP Setup**: Add and immediately connect to new devices

### 🛠️ Advanced IP Management
- **Multi-IP Support**: Store unlimited device IP addresses
- **Add/Remove IPs**: Easy management interface with confirmation prompts
- **Duplicate Detection**: Prevents saving the same IP twice
- **Auto-Reordering**: Successfully connected IPs move to top priority
- **IP Validation**: Basic format checking before saving

### 🔧 Robust Error Handling & Recovery
- **Automatic Troubleshooting**: 
  - Direct connection attempt
  - ADB server restart
  - TCP/IP mode setup
  - USB fallback option
- **Tool Verification**: Checks for ADB and scrcpy availability
- **USB Device Detection**: Validates device connection and authorization
- **Network Diagnostics**: Step-by-step guidance for connection issues
- **Multiple Retry Options**: Never get stuck - always have a way forward

### 💡 Enhanced User Experience
- **Welcome Screen**: Clear program explanation on startup
- **Intuitive Prompts**: Plain language instead of cryptic codes
- **Flexible Input**: Accepts Y/N, Yes/No, or 1/0
- **Session Management**: Quick reconnect after disconnection
- **Professional Formatting**: Clean interface with section dividers
- **Portable**: Uses current directory - works from any location

## ⚙️ How It Works

1. **Startup Check**: Looks for `lastip.txt` with saved IP addresses
2. **Auto-Connect Option**: Asks if you want to automatically try all saved IPs
3. **Connection Attempts**: Tries each IP in order (most recent first)
4. **On Success**: Launches scrcpy with optimized settings
5. **On Failure**: Offers troubleshooting, manual selection, USB fallback, or new IP setup
6. **Session End**: Provides quick reconnect options

### Connection Flow
- **Direct Connection**: Attempts `adb connect [IP]:5555` immediately
- **ADB Restart**: If failed, restarts ADB server and retries
- **TCP/IP Setup**: Falls back to `adb tcpip 5555` with USB-connected device
- **USB Mode**: Direct USB connection as final fallback

### Optimized scrcpy Launch
All connections use optimized settings:
- `--video-codec=h264`: Hardware-accelerated encoding
- `--max-size=1080`: 1080p resolution for balance of quality and performance

## 🚀 Requirements
- **Windows OS** (Batch Script)
- **Android Debug Bridge (ADB)** installed and in system PATH
  - Download: [Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)
- **scrcpy** installed and in system PATH
  - Download: [scrcpy releases](https://github.com/Genymobile/scrcpy/releases)
- **Android Device** with USB debugging enabled

## 📋 Setup Instructions

1. **Install Requirements**:
   - Install ADB (Android SDK Platform Tools)
   - Install scrcpy
   - Add both to your system PATH

2. **Download Script**:
   - Save `scrcpy_manager.bat` to any folder
   - (Optional) Create desktop shortcut for quick access

3. **First Run**:
   - Connect your Android device via USB
   - Run the script
   - Enable USB debugging on your device when prompted
   - Follow on-screen instructions to set up Wi-Fi connection

4. **Subsequent Runs**:
   - Script will automatically attempt saved IPs
   - Or choose manual mode for more control

## 🎮 Usage Guide

### Main Menu Options
- **1** - Auto-try all saved IPs
- **2** - Select specific IP to connect
- **3** - Add new IP address
- **4** - Manage saved IPs (view/remove)
- **5** - Try USB connection
- **0** - Exit program

### After Connection Ends
- **1** - Reconnect with same IP/USB
- **2** - Try all saved IPs again / Try wireless
- **3** - Select different saved IP
- **4** - Add new IP address (wireless only)
- **0** - Exit program

### Tips
- Press **1** or **Y** at startup to auto-try all IPs
- Press **0** or **N** for manual control
- Selected IPs automatically move to top priority
- USB connection works as emergency fallback

## 📁 Files Created

- `lastip.txt`: Stores all saved IP addresses (one per line, most recent first)
- `temp_ips.txt`: Temporary file used during IP reordering (auto-deleted)

Both files are created in the same directory as the script.

## 🐛 Troubleshooting

### "ADB not found in PATH"
- Ensure Android SDK Platform Tools are installed
- Add ADB directory to Windows PATH environment variable
- Restart command prompt after PATH changes

### "scrcpy not found in PATH"
- Download and extract scrcpy
- Add scrcpy directory to Windows PATH
- Verify by running `scrcpy --version` in command prompt

### "No USB devices found"
- Check USB cable (must support data transfer)
- Enable USB debugging in Developer Options
- Authorize computer on device when prompted
- Try different USB port

### Connection Fails
- Ensure device and computer on same Wi-Fi network
- Check if wireless debugging is enabled on device
- Verify IP address is correct (Settings → About Phone → Status)
- Try the built-in troubleshooting options (restarts ADB automatically)

### Device Not Authorized
- Check device screen for authorization prompt
- Accept "Allow USB debugging" dialog
- Check "Always allow from this computer" for convenience

---

## 🔄 Update History

### v3.4 - Smart IP Ordering (Current)
- **Selected IP moves to top of list** - "Most Recently Used" ordering
- When user manually selects an IP, it moves to position #1
- Successfully connected IPs automatically move to top
- New IPs added at top of list (highest priority)
- Next auto-try prioritizes most recently used IPs first
- Added `:moveiptotop` subroutine for IP reordering
- Improved duplicate IP handling - moves existing IP to top instead of error

### v3.3 - Skip Auto-Connect
- **Option to skip automatic IP trying** at startup
- Shows saved IPs and asks "Do you want to automatically try all saved IPs?"
- If declined, shows manual menu with full control options
- Better control flow with centralized manual menu
- Added dedicated manual menu for non-auto operations

### v3.2 - Reconnect Enhancement
- **Reconnect after session** ends with multiple options
- Quick reconnect with same IP immediately
- Try all saved IPs again option
- Select different saved IP manually
- Add new IP address
- Different reconnect menu for USB vs wireless connections

### v3.1 - IP Management
- **IP Management Menu** - view and remove saved IPs
- Select any IP by number to remove it
- Confirmation prompt before deletion
- Automatic redirect to add new IP if all IPs removed
- Option to retry all saved IPs after connection failure

**Bug Fixes:**
- Fixed: IP Management displaying "ipcount" instead of actual IPs - corrected variable expansion in display loop

### v3.0 - Multiple IP Support
- **Multiple IP storage** in `lastip.txt` (one IP per line)
- Automatically tries all saved IPs on startup
- Displays all saved IPs with numbering
- Manual IP selection from saved list
- Duplicate IP detection - won't save same IP twice

**Bug Fixes:**
- Fixed: Only first IP being read - changed from `set /p` to proper `for /f` loop
- Fixed: IPs being overwritten - changed from `>` (overwrite) to `>>` (append)

### v2.6 - Flexible Input
- Added case-insensitive input support
- Accepts: Yes, yes, Y, y, 1 for affirmative
- Accepts: No, no, N, n, 0 for negative
- More flexible user input throughout all prompts

**Bug Fixes:**
- Fixed: Complex regex IP validation causing false negatives - simplified to basic dot check
- Fixed: Delayed expansion issues with IP validation

### v2.5 - Enhanced Prompts
- Enhanced all prompts for better user experience
- Added welcome screen with program explanation
- Changed cryptic prompts to plain language
- Improved error messages with context and actionable steps
- Added connection method explainer at startup
- Professional formatting with clear section dividers

### v2.4 - Portable Script
- Changed all file paths to use current working directory (`%~dp0`)
- Files now stored relative to script location instead of hardcoded paths
- Portable - works from any location

### v2.3 - Robust Error Handling
- Added comprehensive error handling throughout the script
- IP format validation (checks for dots)
- Tool availability checks (verifies ADB and scrcpy are in PATH)
- USB device detection with detailed error messages
- Network connection troubleshooting with step-by-step recovery options
- Directory creation checks
- Graceful exit instead of force-killing CMD

### v2.2 - Improved Connection Flow
- Improved connection flow: attempts direct connection before running `adb tcpip 5555`
- Restarts ADB server automatically if initial connection fails
- Falls back to TCP/IP mode setup only after other methods fail
- Added "Retry same IP" option in all error menus

### v2.1 - Initial Version
- Checks for last IP in `lastip.txt`
- Prompts for new IP if file is missing/empty
- Uses fixed 1080p resolution (`--max-size=1080`, `--video-codec=h264`)
- Saves IP when using 'newip' option
- Added `adb tcpip` and `adb connect` commands
- USB mode uses `-d` flag

**Bug Fixes:**
- Fixed: Title never changed to "Connected" - now uses `start /wait` with proper error level checking

## 📝 Notes

- The script maintains IP order based on successful connections
- Most recently used IPs are tried first for faster connections
- All prompts accept multiple input formats (1/0, Y/N, Yes/No)
- The script never gets stuck - there's always an option to proceed
- USB mode works even if all wireless connections fail

## 🤝 Contributing

This project is still maturing. Contributions, suggestions, and bug reports are welcome!


## 📄 License
Free to use and modify. If you improve it, consider sharing your enhancements!

## 🔗 Related Links
[scrcpy GitHub](https://github.com/Genymobile/scrcpy)
[Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)
[ADB Documentation](https://developer.android.com/studio/command-line/adb)

- [scrcpy GitHub](https://github.com/Genymobile/scrcpy)
- [Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)
- [ADB Documentation](https://developer.android.com/studio/command-line/adb)
