
# Product Requirements Document (PRD)

## Simple Internet Utility Toolkit

### 1. Product Overview

* **Product Name:** Net Utility Toolkit  
* **Product Type:** Cross-platform utility application for basic internet/network troubleshooting and everyday technical tools.  
* **Target Platforms:** Windows desktop (`.exe`), Linux desktop, iOS mobile (`.ipa`)  
* **Primary Users:** Employees or customers of an internet/network-related company who need quick-access tools for connectivity checks, DNS records lookups, password generation, and data encoding/hashing.  
* **Product Goal:** Build a lightweight toolkit that provides essential network and utility functions in one simple app with the least amount of engineering friction. The app focuses on reliable, easy-to-use tools that work consistently across Windows and iOS without attempting to be an enterprise-grade network diagnostics platform.

---

### 2. Problem Statement

Internet company staff frequently require quick tools for basic troubleshooting or technical tasks. These tools are currently scattered across command-line utilities, various third-party websites, or distinct single-purpose apps. This fragmentation creates friction for non-technical users and slows down simple workflows such as:

* Checking if a host is reachable via raw network requests.
* Looking up a domain’s IP or text records.
* Generating randomized secure passwords.
* Converting text to Base64 or creating cryptographic hashes (MD5, SHA-1, SHA-256).

This app solves the problem by combining these utilities into a single, clean, cohesive, cross-platform interface.

---

### 3. Scope

#### In Scope for Version 1

* **Network Tools:** Ping a host locally, DNS domain resolution via web API, clean terminal-like output.
* **Password Generator:** Secure random password generation using platform CSRNG, length and character type criteria selectors, character exclusion rules.
* **Encoding Converter:** Bi-directional text conversion for Base64 and Hex; hashing for MD5, SHA-1, and SHA-256.
* **Cross-Platform UI:** Single codebase adapting dynamically to a Windows desktop layout and an iOS mobile layout.

#### Out of Scope for Version 1

* Full traceroute on iOS (deferred to prevent development friction due to sandboxing)
* Packet capture and port scanning
* Speed testing and network adapter diagnostics
* Wi-Fi signal or VPN diagnostics
* User accounts, authentication, cloud sync, database backends, and push notifications

---

### 4. Recommended Tech Stack

* **Framework:** Flutter (Stable Channel)
* **Language:** Dart
* **Development Environment:** Primary development on Windows first.
* **Target Builds:** Windows executable (`.exe`), Linux desktop (GTK), iOS app (`.ipa`)

---

### 5. Dependency Plan

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Network tools
  dart_ping: ^10.0.0
  http: ^1.2.0

  # Encoding and hashing
  crypto: ^3.0.3
  convert: ^3.1.1

```

> **State Management Note:** Lightweight `ChangeNotifier` controllers are sufficient for Version 1. Avoid over-engineering unless state becomes structurally unmanageable, in which case `provider: ^6.1.2` may be introduced.

---

### 6. Platform Strategy

* **Windows First:** The app will be written, executed, and entirely polished on Windows first. This allows core business logic, UI responsive constraints, local ping commands, and DoH integrations to be finalized before configuring Apple-specific distribution rules.
* **Linux Desktop:** The Flutter codebase is shared across all platforms. The Linux build uses GTK and requires no additional platform-specific Dart code. Linux users can build via `flutter build linux`.
* **iOS Second:** The iOS phase begins once the Windows client is functionally feature-complete. This phase focuses purely on Xcode project mapping, handling iOS sandboxing constraints, physical device deployment, and visual layout validation on smaller screens.

---

### 7. Key Product Decision

The app will **not** include traceroute functionality in Version 1. Traceroute execution patterns differ sharply between desktop environments and highly restricted mobile environments (iOS). To prevent structural blockers, traceroute is omitted from V1 entirely and prioritized for a V2 architecture layout.

---

### 8. Information Architecture

```text
Net Utility Toolkit
│
├── Network Tools
│   ├── Ping (Host input, count selector, live stream console)
│   └── DNS Lookup (Domain input, record type filter, clean output list)
│
├── Password Generator
│   ├── Input Controls (Length slider, character toggles, exclusion field)
│   └── Output View (Secure field string, copy action)
│
└── Encoding Converter
    ├── Input UI (Text block container with max character caps)
    ├── Operation Selector (Encode, Decode, Hash types)
    └── Output UI (Selectable output block, copy action)

```

---

### 9. User Stories

* **Ping:** As a user, I want to enter a host or IP address and ping it so that I can check whether the destination is physically reachable from my current node.
* **DNS Lookup:** As a user, I want to enter a domain and select a DNS record type so that I can immediately view its resolved public server records.
* **Generate Password:** As a user, I want to generate a secure password with my selected rules so that I can quickly create safe credentials without relying on random web utilities.
* **Exclude Characters:** As a user, I want to exclude confusing characters such as `l`, `I`, `O`, and `0` so that the generated token is highly legible when read manually.
* **Data Transmutation (Convert/Hash):** As a user, I want to convert text payloads to/from structural encodings or generate cryptographic hashes safely without transmitting confidential data over the web.

---

### 10. Functional Requirements

#### 10.1 Network Tools

##### Ping Requirements

* The UI must accept a valid hostname or IP address string.
* Includes a count dropdown selector (Default: 4, Max: 20).
* **UI Action Debouncing:** The "Start Ping" button must transform into a disabled state or show a loading context while a ping stream is active. A distinct "Stop" button must be clickable to abort active ICMP streams safely.
* Results must stream live into a scrollable, terminal-styled interface component displaying host, sequence, packet latency time, or specific error packets.

##### DNS Lookup Requirements

* Domain input validation to strip trailing/leading whitespace or accidental protocol schemas (`http://`).
* Supported record types drop-down element: `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `NS`.
* Request structure must point to Cloudflare DNS-over-HTTPS (`https://cloudflare-dns.com/dns-query`) using standard JSON schemas.
* Output records must be selectable, displaying Record Type, Value, and Time-to-Live (TTL).

#### 10.2 Password Generator

* **Security Imperative:** Must consume platform-native cryptographic primitives via `Random.secure()`. Standard pseudorandom number generators are strictly prohibited.
* **Configuration Enforcements:** Length constraints set to `Minimum: 4`, `Maximum: 128` (Default: 16). Excluded characters string input field defaults to filtering `l, I, O, 0`.
* **Validation Bounds:** Throw a validation warning directly within the form context if user selections result in zero active character pools or if exclusion rules strip 100% of the target set.

#### 10.3 Encoding Converter

* Supported operations include: Base64 (Encode/Decode), Hex (Encode/Decode), MD5, SHA-1, SHA-256.
* **Input Truncation Safeguard:** To prevent UI thread stuttering or local memory panics caused by large payload operations processing synchronously, the main plain text entry block must enforce a strict constraint limit of **50,000 characters**.
* All execution tasks must execute inside safe runtime wrappers (`try/catch`) to ensure corrupt or non-conformant strings generate user-friendly feedback instead of runtime thread crashes.

---

### 11. Non-Functional Requirements

* **Simplicity & Legibility:** Functional designs over styling decoration. Monospaced type handling for hash outputs, password blocks, and network streams.
* **Security & Isolation:** Input payloads for encoding, hashing, and password construction must be processed purely inside local memory contexts. The app must never transmit these configurations across external internet ports.
* **iOS Clipboard Guarding:** Because iOS displays explicit visual warnings when applications intercept systemic clipboards, the codebase must strictly limit clipboard interactions to *write-only tasks* (instigated solely via explicit user interaction with a "Copy" button asset).
* **Maintainability:** Clear layer isolation ensures modules can have their core logic dependencies decoupled without affecting adjacent views.

---

### 12. UI & UX Layout Foundations

#### Desktop Viewports (Wide Screens)

Uses a non-folding navigation column on the left edge. The designated utility tool context expands dynamically across the remaining screen width, split into input execution fields and continuous output terminal cards.

```text
+-------------------------------------------------------------------------+
| Sidebar Navigation     | Active Module Area                             |
|------------------------|------------------------------------------------|
| [X] Network Tools      | Host Input: [ google.com              ] [Ping] |
| [ ] Password Gen       | ---------------------------------------------- |
| [ ] Encoding Convert   | Live Terminal Output:                          |
|                        | Reply from 142.250.190.46: bytes=32 time=14ms  |
|                        | Reply from 142.250.190.46: bytes=32 time=12ms  |
+-------------------------------------------------------------------------+

```

#### Mobile Viewports (Narrow Screens)

The navigation column drops away, substituting an accessible bottom navigation bar component. Input arrays stack strictly down the vertical plane, forcing output and terminal blocks beneath execution triggers.

---

### 13. Module-Level UI Details

* **Global Action States:** All execution elements ("Start Ping", "Lookup", "Convert") must visibly present explicit context changes (spinning indicator, text alterations, or physical button disabling) when an async thread is active. This directly prevents multiple concurrent socket initializations or duplicate cryptographic calculations.

---

### 14. Folder Structure Architecture

```text
lib/
  main.dart
  app/
    app.dart
    responsive_shell.dart
  features/
    network/
      network_screen.dart
      network_controller.dart
      ping_service.dart
      dns_service.dart
    password/
      password_screen.dart
      password_controller.dart
      password_service.dart
    converter/
      converter_screen.dart
      converter_controller.dart
      converter_service.dart
  shared/
    widgets/
      app_card.dart
      app_button.dart
      output_box.dart
      terminal_output.dart
    utils/
      validators.dart
      clipboard_helper.dart

```

---

### 15. Engineering Architecture & Layer Responsibilities

* **UI Screen Layer:** Renders layout components and binds visual state parameters exposed by corresponding Controllers.
* **Controller Layer:** Retains mutable configuration choices, validates screen-level inputs before dispatch, manages loading indicators, and formats text parameters for direct presentation.
* **Service Layer:** Houses atomic business computations. Communicates with system channels (`dart_ping`) or public HTTP endpoints (`http`).

---

### 16. Detailed Service Logic & Safety Rules

* **PingService:** Maps abstract requests to target hosts. Responsible for opening system streams and mapping payload payloads back safely into structured stream models.
* **DnsService:** Constructs clean network frames targeting Cloudflare DoH APIs. Must inspect server HTTP response envelopes explicitly before deserialization.
* **PasswordService:** Combines specified alpha-numeric sets, applies filters, and pulls cryptographically solid random entries.
* **ConverterService:** Handles standard cryptographic translations safely wrapped inside structured error boundaries.

---

### 17. Comprehensive Error Handling Matrices

| Module Context | Failure Root Cause | User Interface Display Error Message |
| --- | --- | --- |
| **Global Network** | System completely offline | `Network unavailable. Check local interface connections.` |
| **Ping Engine** | Hostname missing or unresolvable | `Ping failed. Please check the host.` |
| **DNS Resolving** | Cloudflare API Rate-Limiting (`HTTP 429`) | `Too many requests. Please wait a moment before trying again.` |
| **DNS Resolving** | General server/lookup timeout | `DNS lookup failed. Please check the domain.` |
| **Password Block** | All characters excluded via choices | `No character types selected.` |
| **Password Block** | Custom exclusions wipe character pool | `Excluded characters removed all available characters.` |
| **Converter** | Bad Base64 character sequences | `Invalid Base64 input.` |
| **Converter** | Bad/Malformed non-hex characters | `Invalid hex input.` |

---

### 18. Testing Plan Execution Specs

#### Automated Unit Testing Plan

Because the core functional engines behind password derivation and data conversion are entirely deterministic and platform-agnostic, automated unit testing is a hard criteria condition for build sign-off.

* **`PasswordService` Tests:** Validate that length boundaries below 4 or above 128 throw appropriate validation flags. Confirm via statistical sample checks that excluded string elements are 100% absent from completed outputs.
* **`ConverterService` Tests:** Verify standard strings match known test vectors for MD5, SHA-1, and SHA-256. Assert that intentionally mangled Base64 strings throw controlled parsing errors rather than breaking execution context.

#### Manual Integration Test Cases

* **Network Streams:** Verify that pressing "Stop" during an ongoing ping sequence terminates the underlying native process immediately and resets the button's execution states.
* **Cross-Platform Responsive Scales:** Validate that resizing a Windows or Linux desktop screen downwards shifts UI layers smoothly without clipping layout lines or raising layout overflow banners. Verify same layout performance natively on a physical target iPhone.
