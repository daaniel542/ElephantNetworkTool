🔄 Transitioning from Web to Native Desktop

This guide outlines the exact steps required to transition the Net Utility Toolkit from a browser-sandboxed Vercel deployment back into a fully native desktop application for macOS and Windows.

By running natively, the application regains access to the host operating system's networking stack, allowing dart_ping and custom ICMP traceroute logic to function without web-safe fallbacks.

🧹 Step 1: The Great Codebase Cleanup

Since the application will no longer be deployed to the web, we must remove the web-specific workarounds and deployment scripts.

Remove Web Fallbacks: Open lib/features/network/ping_service.dart and lib/features/network/traceroute_service.dart. Remove any kIsWeb conditional checks or mock HTTP responses. Revert the logic to strictly use the dart_ping package.

Delete Vercel Configs: You can safely delete vercel.json and the scripts/vercel-build.sh file, as they are no longer needed.

(Optional) Disable Web Target: If you want to prevent accidental web builds in the future, you can remove the web/ folder from the root of your project directory.

⚙️ Step 2: Enable Desktop Support

By default, Flutter might only be configured for mobile or web on your machine. You need to explicitly tell the Flutter toolchain to allow desktop compilation.

Open your terminal in the root of your project and run:

flutter config --enable-macos-desktop
flutter config --enable-windows-desktop

Note: You must restart your IDE (VS Code or Android Studio) after running these commands so the device dropdown recognizes your desktop as a valid run target.

🍎 Step 3: macOS Specific Configuration (Critical)

Unlike Windows, macOS applications are strictly sandboxed by Apple by default. If you try to run your Ping tool right now on a Mac, you will get a terrifying SocketException: Connection failed (OS Error: Operation not permitted) error.

You must grant your macOS app permission to act as a network client to send ICMP packets.

Open macos/Runner/DebugProfile.entitlements in your code editor.

Add the following key/value pair inside the main <dict> block:

<key>com.apple.security.network.client</key>
<true/>

Open macos/Runner/Release.entitlements and do the exact same thing.

(Failure to add this to the Release.entitlements file means the app will work when you are debugging, but will instantly break when you package it for your users!)

🪟 Step 4: Windows Specific Configuration

Windows does not require strict entitlement files for basic network client access. However, because dart_ping utilizes the underlying Windows ping.exe subprocess, ensure that your application handles string encodings properly, as Windows command prompts often use localized codepages.

No additional file modifications are strictly required for Windows to regain ICMP capabilities.

🚀 Step 5: Run and Build Locally

You are now ready to run the application directly on your operating system.

To test the application locally (Debug Mode):

# If you are on a Mac

flutter run -d macos

# If you are on Windows

flutter run -d windows

Test the Ping and Traceroute tabs. Because the app is running natively, it bypasses browser CORS and sandbox restrictions, meaning the real network packets will successfully route out to the internet and back.

To build the final production release for distribution:

flutter build macos --release

# OR

flutter build windows --release

(Refer to the native_deployment.md strategy guide for instructions on where to find the output files and how to zip them for users).
