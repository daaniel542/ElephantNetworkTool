# Elephant Network Tool (ENT)

Internal network utility for Elephant Technologies LTD.

The app is a Flutter desktop tool with Ping, Traceroute, DNS lookup, password
generation, and encoding/hashing utilities. Native desktop builds are the
recommended distribution path because Ping and Traceroute require local operating
system networking capabilities that browser builds cannot provide.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

Run locally on your current platform:

```sh
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

Only run the command for the OS you are currently using. Flutter does not
cross-compile desktop apps from one operating system to another.

## Release Builds

**Versions of ENT can be found in the Github Actions page with their respective OS versions allowing for 
quick download and installation of the app instead of cloning and releasing the Flutter builds.**

Build the native release on each target OS:

```sh
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

Release outputs:

- macOS: `build/macos/Build/Products/Release/Elephant Network Tool.app`
- Windows: `build/windows/x64/runner/Release/`
- Linux: `build/linux/x64/release/bundle/`

For internal distribution, package each release folder as a zip, label it with
the app version and OS, and send the matching package to each IT member. 

## Web Limitations

The Flutter Web target can still compile for browser-safe tools, but browsers
cannot send ICMP packets or TTL-limited probes. DNS lookup, password generation,
encoding, and hashing can run client-side on web. Ping and Traceroute need the
native desktop app or a backend probe service.
