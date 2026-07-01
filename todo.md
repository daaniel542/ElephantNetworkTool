# Net Utility Toolkit - AI Implementation Guide

## 🤖 System Instructions for the AI Assistant

You are an expert Flutter & Dart engineer. Your task is to build the "Net Utility Toolkit" application step-by-step.

1. **Do not write the entire application at once.**
2. Wait for the user to prompt you with "Execute Phase X".
3. When executing a phase, provide complete, copy-pasteable code for the files specified in that phase. Do not use placeholders like `// implement logic here`.
4. Strictly follow the architecture: `Screen` (UI) -> `Controller` (ChangeNotifier) -> `Service` (Business Logic).
5. All code must be null-safe and target the latest stable Flutter SDK.
6. Only use the dependencies listed in Phase 1. Do not introduce new packages.
7. NO AI SLOP. Only write code that is logical and methological, ex. do not write out whole functions if there is library function that can perform the action.
8. Summarize code changes/code implementations so that the user can follow the current development stage/plan as well as to learn and follow your methodology.
---

## 🗂️ Phase 1: Project Initialization & Dependencies

**Goal:** Scaffold the app and install dependencies.

- [x] Create `pubspec.yaml` with the following dependencies:
  - `dart_ping: ^10.0.0`
  - `http: ^1.2.0`
  - `crypto: ^3.0.3`
  - `convert: ^3.1.1`
  - `provider: ^6.1.2` (for state management of our controllers)
- [x] Create the exact folder structure in `lib/`:
  - `app/`
  - `features/network/`
  - `features/password/`
  - `features/converter/`
  - `shared/widgets/`
  - `shared/utils/`

---

## 🏗️ Phase 2: Shared UI Components & Shell

**Goal:** Build the responsive shell and reusable UI widgets.

- [x] Write `lib/shared/utils/clipboard_helper.dart`: A utility to safely copy text to the clipboard and show a success Snackbar.
- [x] Write `lib/shared/widgets/app_button.dart`: A reusable elevated button that supports a disabled/loading state.
- [x] Write `lib/shared/widgets/output_box.dart`: A selectable text container for output results.
- [x] Write `lib/app/responsive_shell.dart`: A layout that uses a `NavigationRail` for wide screens (desktop) and a `BottomNavigationBar` for narrow screens (mobile). It should switch between the Network, Password, and Converter screens.

---

## 🔐 Phase 3: Password Generator Module

**Goal:** Build the completely offline Password Generator.

- [x] Write `lib/features/password/password_service.dart`:
  - Must use `dart:math` `Random.secure()`.
  - Parameters: length, booleans for upper/lower/numbers/special, and a string of excluded characters.
  - Throw clear `Exception` messages if length is out of bounds (4-128) or if the character pool is empty.
- [x] Write `lib/features/password/password_controller.dart`:
  - Extend `ChangeNotifier`.
  - Hold UI state (sliders, checkboxes, output string, error string).
- [x] Write `lib/features/password/password_screen.dart`:
  - Wire up the UI to the controller using `Consumer<PasswordController>`.
- [x] Write `test/password_service_test.dart`: Unit tests confirming exclusions work and lengths are respected.

---

## 🔄 Phase 4: Encoding Converter Module

**Goal:** Build the offline string manipulation tool.

- [x] Write `lib/features/converter/converter_service.dart`:
  - Implement Base64 Encode/Decode, Hex Encode/Decode, MD5, SHA-1, SHA-256 using the `crypto` and `convert` packages.
  - Wrap decoding in `try/catch` to return clean error strings (e.g., "Invalid Base64 input").
- [x] Write `lib/features/converter/converter_controller.dart`:
  - Extend `ChangeNotifier`.
  - Enforce a 50,000 character limit on the input.
- [x] Write `lib/features/converter/converter_screen.dart`:
  - Include an input `TextField`, a dropdown for the operation, a Convert button, and an `OutputBox`.
- [x] Write `test/converter_service_test.dart`: Unit tests for hashing and encode/decode operations.

---

## 🌐 Phase 5: Network Tools Module (Ping & DNS)

**Goal:** Build the platform-specific network tools.

- [x] Write `lib/features/network/ping_service.dart`:
  - Wrap `dart_ping` to stream `PingData`.
  - Provide a `stopPing()` method.
- [x] Write `lib/features/network/dns_service.dart`:
  - Make a `GET` request to `https://cloudflare-dns.com/dns-query?name={domain}&type={type}`.
  - Include `Accept: application/dns-json` headers.
  - Parse the JSON and return formatted records (or handle HTTP 429 Rate Limiting explicitly).
- [x] Write `lib/features/network/network_controller.dart`:
  - Extend `ChangeNotifier`.
  - Manage state for DNS Lookup vs Ping toggles, live stream logs, and loading/debouncing states.
- [x] Write `lib/shared/widgets/terminal_output.dart`: A black-background, monospaced text scrolling list for ping results.
- [x] Write `lib/features/network/network_screen.dart`:
  - The UI for inputting a host/domain, triggering the correct service, and displaying the terminal.

---

## 📡 Phase 6 Extension: Traceroute Implementation

**Goal:** Build the platform-specific traceroute tool using TTL manipulation with the existing `dart_ping` package.

**Context & Rules:**

- Execute this phase by providing complete, copy-pasteable code for the files requested below.
- Do not use placeholders like `// implement logic here`. NO AI SLOP.
- All code must be null-safe and target the latest stable Flutter SDK.
- Maintain the strict architecture: `Screen` -> `Controller` -> `Service`.
- Only use the existing `dart_ping` dependency for network ICMP operations. Do not introduce new packages.

**Files to Create or Update:**

- [x] Create `lib/features/network/traceroute_service.dart`:
  - Implement a traceroute by manually looping the `ttl` parameter from 1 up to a maximum of 30.
  - Send a single ping (`count: 1`) per TTL iteration.
  - Return a `Stream` of hop results so the UI can update progressively.
  - Catch `PingError` events (specifically timeouts) gracefully. Yield a "Request timed out" or similar message for that hop without breaking the loop.
  - Break the loop early if the ping successfully reaches the target destination.

- [x] Update `lib/features/network/network_controller.dart`:
  - Add state for the Traceroute toggle (alongside Ping and DNS).
  - Create a `startTraceroute(String host)` method that listens to the `TracerouteService` stream and populates a log list.
  - Implement strict cancellation logic: track the `StreamSubscription` and ensure any active trace is completely stopped/cancelled if the user clicks "Stop", starts a new trace, or navigates away.

- [x] Update `lib/features/network/network_screen.dart`:
  - Update the UI controls to include a 3-way selector (e.g., segmented button or radio buttons) for: Ping | DNS | Trace.
  - Bind the input field and action button to trigger `startTraceroute` when the trace option is selected.

- [x] Update `lib/shared/widgets/terminal_output.dart`:
  - Ensure the terminal can cleanly render the line-by-line hop data.
  - Include visual feedback (e.g., a blinking cursor or a "Tracing route to [host]..." header) so the user knows the application is actively waiting for a hop response and hasn't frozen.

## 🚀 Phase 7: Assembly & Final Integration

**Goal:** Tie all the modules together in the main entry point, ensuring the newly expanded network tools (including Traceroute) are properly initialized alongside the other features.

**Context & Rules:**

- Execute this phase by providing the complete, copy-pasteable code for the files requested below.
- Do not use placeholders. NO AI SLOP.
- All code must be null-safe and target the latest stable Flutter SDK.
- Ensure the state management setup correctly supports the expanded `NetworkController`.

**Files to Create or Update:**

- [x] Write `lib/main.dart`:
  - Initialize the Flutter application (`runApp`).
  - Wrap `MaterialApp` in a `MultiProvider`.
  - Inject the three primary controllers at the root level: `NetworkController`, `PasswordController`, and `ConverterController`.
  - Set the `home` property to the `ResponsiveShell` created in Phase 2.
  - Apply a clean, utilitarian `ThemeData` (Material 3, Dark Mode by default, with a high-contrast color scheme suitable for developer tools).
  - Ensure any necessary service instantiations (like `TracerouteService`, `PingService`, `DnsService`) are properly handled within or passed to the `NetworkController`.
