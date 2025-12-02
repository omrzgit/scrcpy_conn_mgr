# Scrcpy_Wifi_Script
This is a Windows Batch Script designed to simplify the connection and launch of the scrcpy screen mirroring tool, primarily focusing on automated Wi-Fi connections.

✨ Features
Automated Connection: Easily connect your Android device using ADB.

Three Connection Modes:
Saved Wi-Fi IP Connect: Attempts to connect using the IP address previously saved in lastip.txt.
USB Connect: Connects the device using a direct USB cable connection (scrcpy -d).
New Wi-Fi IP: Prompts the user to enter a new IP address, saves it to lastip.txt, and establishes the connection.
Optimized Launch: Launches scrcpy with optimized settings: --video-codec=h264 --max-size=1080.
Persistent Navigation: Uses simple numerical input prompts (1/0) for navigation, allowing quick re-connections or changes between connection modes.

⚙️ How It Works
The script checks for a saved IP in the lastip.txt file.
It prompts the user to choose between using the Saved IP or starting a USB connection.
For Wi-Fi connections, it uses ADB (Android Debug Bridge) to:
Set the device to listen on port 5555 (adb tcpip 5555).
Connect to the specified IP address (adb connect [IP]:5555). 
Finally, it executes the scrcpy command with the appropriate connection flag (-s [IP]:5555 or -d for USB).

🚀 Requirements
>. Windows OS (This is a Batch Script).
>. Android Debug Bridge (ADB) installed and accessible via your system's PATH.
>. scrcpy installed and accessible via your system's PATH.
