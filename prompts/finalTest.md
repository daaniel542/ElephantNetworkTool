# Elephant Network Tool — Internal Release Test Plan

## Purpose

This plan verifies that the packaged **Elephant Network Tool** is safe and practical to distribute to a small internal group of users, likely 2–3 people, for occasional use.

This is a lightweight release plan. It is intentionally smaller than a full enterprise release process because the app is an internal utility, not a widely distributed production product.

The goal is to confirm:

- The app builds successfully.
- The packaged app runs outside the development environment.
- Core features work after packaging.
- Ping, DNS, and Traceroute fail clearly when the network or OS blocks them.
- Password generation and encoding/hash tools remain local-only.
- The recent Encoding page dropdown/scroll fix does not regress.

---

## Product Context

The app is a Flutter desktop utility toolkit for internal technician use.

### Main Utility Areas

1. **Network Tools**
   - Ping
   - DNS lookup through Cloudflare DNS-over-HTTPS
   - Traceroute
   - Live table-style output
   - Copy-friendly terminal-style output
   - Clear unsupported states for browser/web builds

2. **Password Generator**
   - Local secure password generation using `Random.secure()`
   - Length controls
   - Character class toggles
   - Excluded character support
   - No password storage

3. **Encoding/Decoding**
   - Base64 encode/decode
   - Hex encode/decode
   - MD5, SHA-1, and SHA-256 hashing
   - Local-only conversion and hashing

---

## Data Handling Clarification

The app has **no company-hosted backend** and does not store user data.

However, not every operation is purely local:

- Password generation runs entirely locally.
- Encoding, decoding, and hashing run entirely locally.
- Ping and Traceroute intentionally send network probes to the user-entered target.
- DNS lookup intentionally sends HTTPS DNS-over-HTTPS requests to Cloudflare during DNS resolution.

Recommended wording for users:

> Password generation, encoding, decoding, and hashing run locally. Ping and Traceroute send probes to the selected target. DNS lookup uses Cloudflare DNS-over-HTTPS.

---

# Release Gates

For this small internal release, use the following six gates.

| Gate | Name | Purpose | Required |
|---|---|---|---|
| Gate 1 | Automated Tests | Confirm codebase is healthy before packaging | Yes |
| Gate 2 | Release Build + Packaged App Smoke Test | Build/download the real release artifact and confirm it opens outside Flutter dev mode | Yes |
| Gate 3 | Network Reliability Test | Confirm Ping/DNS/Traceroute work or fail clearly | Yes |
| Gate 4 | Local Data Test | Confirm Password/Encoding/Hashing remain local-only | Yes |
| Gate 5 | Encoding Page Regression Test | Confirm the dropdown/scroll fix does not regress | Yes |
| Gate 6 | Small User Trial | Let the intended 2–3 users try the app | Yes |

---

# Gate 1: Automated Tests

## Goal

Confirm the codebase is healthy before building release artifacts.

## Required Commands

Run from the project root:

```bash
flutter pub get
flutter analyze
flutter test
```

## Required Checks

- [ ] `flutter pub get` completes successfully.
- [ ] `flutter analyze` has no blocking issues.
- [ ] `flutter test` passes.
- [ ] No important tests are skipped without a clear reason.

## Exit Criteria

All automated tests pass before release artifacts are built.

---

# Gate 2: Release Build + Packaged App Smoke Test

## Goal

Build the actual release artifact and confirm that the packaged app works outside Flutter development mode.

This gate answers one simple question:

> Can a normal user download the release package, open it, and use the app without installing Flutter or running the project from source?

Do **not** rely only on `flutter run`. `flutter run` proves the app works on a developer machine. Gate 2 proves the distributed app works as a real app.

## Recommended Approach: GitHub Actions Build

For this project, the cleanest approach is to build release artifacts through GitHub Actions instead of manually switching between operating systems.

Use GitHub Actions runners for each target platform:

| Target Artifact | GitHub Runner | Build Command |
|---|---|---|
| macOS | `macos-latest` | `flutter build macos --release` |
| Windows | `windows-latest` | `flutter build windows --release` |
| Linux | `ubuntu-latest` | `flutter build linux --release` |

This avoids needing to personally own or switch between a Mac, Windows machine, and Linux machine for every release.

## Important Build Rule

Flutter desktop builds are native platform builds.

That means:

- macOS releases should be built on macOS.
- Windows releases should be built on Windows.
- Linux releases should be built on Linux.

Docker can help make Linux builds more consistent, but Docker should not be treated as the solution for macOS or Windows desktop release builds. For this project, GitHub Actions is the simpler and cleaner path.

## Build Only the Needed Platforms

Only build and test the operating systems the intended users actually need.

Examples:

- If users are only on macOS and Windows, skip Linux for now.
- If only one person uses Linux, test only that person's Linux distro.
- Do not claim support for an OS until a release artifact has been built and opened on that OS.

## GitHub Actions Artifact Expectations

After the workflow runs, GitHub Actions should produce downloadable artifacts such as:

```text
Elephant-Network-Tool-macos.zip
Elephant-Network-Tool-windows.zip
Elephant-Network-Tool-linux.zip
```

These downloaded artifacts are what should be tested in Gate 2.

The test should use the artifact downloaded from GitHub Actions, not a local development folder.

## Manual Local Build Fallback

If GitHub Actions is not ready yet, manual platform builds are acceptable.

### macOS

```bash
flutter build macos --release
```

Typical output:

```text
build/macos/Build/Products/Release/Elephant Network Tool.app
```

Package by zipping the `.app`:

```bash
ditto -c -k --sequesterRsrc --keepParent \
"build/macos/Build/Products/Release/Elephant Network Tool.app" \
"release/macos/Elephant-Network-Tool-macos.zip"
```

### Windows

```powershell
flutter build windows --release
```

Typical output:

```text
build\windows\x64\runner\Release\
```

Package by zipping the **entire Release folder contents**, not just the `.exe`:

```powershell
Compress-Archive `
  -Path "build\windows\x64\runner\Release\*" `
  -DestinationPath "release\windows\Elephant-Network-Tool-windows.zip" `
  -Force
```

### Linux

```bash
flutter build linux --release
```

Typical output:

```text
build/linux/x64/release/bundle/
```

Package by zipping the full bundle folder:

```bash
cd build/linux/x64/release
zip -r ../../../../release/linux/Elephant-Network-Tool-linux.zip bundle
```

## Basic Build Record

Record enough information to know what was tested and sent:

| Field | Value |
|---|---|
| App version |  |
| Build date |  |
| Git branch |  |
| Git commit, if available |  |
| Build source | GitHub Actions / Manual local build |
| Platform artifact |  |
| Artifact filename |  |
| Tester |  |

## Smoke Test Checklist

Run these checks on each packaged platform you plan to distribute.

- [ ] Download or copy the packaged artifact.
- [ ] Extract/unzip the artifact into a normal user folder such as Desktop or Downloads.
- [ ] Open the app from the packaged release, not from `flutter run`.
- [ ] Confirm the app opens without Flutter installed on the machine.
- [ ] Confirm the app name displays correctly.
- [ ] Confirm the app icon displays correctly, if configured.
- [ ] Confirm the app closes normally.
- [ ] Confirm no orphaned process remains after closing.
- [ ] Confirm navigation/sidebar works.
- [ ] Confirm Network page opens.
- [ ] Confirm Password Generator page opens.
- [ ] Confirm Encoding/Decoding page opens.
- [ ] Confirm copy buttons work.
- [ ] Confirm the app can be deleted/uninstalled using the normal method for that platform.

## Platform Notes

### macOS

- [ ] App opens from the packaged `.app`, zipped `.app`, `.dmg`, or release artifact.
- [ ] If unsigned, expected Gatekeeper warning is documented.
- [ ] User knows the right-click → Open workaround if needed.
- [ ] Confirm whether the artifact was built for Apple Silicon, Intel, or Universal.

### Windows

- [ ] App opens on the target Windows machine.
- [ ] No missing DLL errors appear.
- [ ] The entire `Release` folder was packaged, not just the `.exe`.
- [ ] If SmartScreen appears, the warning is documented.
- [ ] User knows how to click “More info” → “Run anyway” if unsigned.

### Linux

- [ ] App opens on the target Linux distro.
- [ ] No missing shared-library errors appear.
- [ ] App launches without root privileges.
- [ ] Linux support is limited to the distro actually tested unless broader testing is done.

## What This Gate Does Not Test Deeply

Gate 2 is not the full feature-validation pass.

It only proves the release artifact is real, opens properly, and has basic UI functionality.

Detailed Ping, DNS, Traceroute, offline behavior, and regression testing happen in later gates.

## Exit Criteria

The GitHub Actions or manually built release artifact opens, navigates, performs basic UI actions, and closes normally on the actual machines/platforms intended for use.

# Gate 3: Network Reliability Test

## Goal

Confirm Ping, DNS, and Traceroute work correctly, or fail in a clear and non-misleading way.

This is the most important manual test gate because network diagnostics can be affected by OS permissions, firewalls, VPNs, DNS policies, and ICMP filtering.

## Standard User Requirement

Run the app normally as a standard user.

Do not use:

- `sudo`
- administrator mode
- elevated terminal
- developer/debug mode

If the tool only works with elevated permissions, document that clearly. For normal internal users, that may be a release blocker.

## Minimum Network Checklist

### Ping

- [ ] Ping `127.0.0.1`.
- [ ] Ping `1.1.1.1`.
- [ ] Ping `8.8.8.8`.
- [ ] Ping a nonexistent domain such as `missing.invalid`.
- [ ] Ping a malformed IP such as `999.999.999.999`.
- [ ] Confirm packet count, loss, RTT, and sequence numbers look internally consistent.
- [ ] Confirm unknown host does not look like packet loss.
- [ ] Confirm malformed input does not crash the app.

### DNS

- [ ] Lookup `example.com` A record.
- [ ] Lookup `example.com` AAAA record.
- [ ] Lookup `gmail.com` MX record.
- [ ] Lookup a TXT record for a known public domain.
- [ ] Lookup `missing.invalid`.
- [ ] Confirm NXDOMAIN is shown as “domain does not exist.”
- [ ] Confirm valid domains with no matching record type show “no records found,” not a crash.
- [ ] Confirm DNS lookup completes or returns a controlled error within the timeout.

### Traceroute

- [ ] Traceroute `1.1.1.1`.
- [ ] Traceroute `8.8.8.8`.
- [ ] Traceroute `missing.invalid`.
- [ ] Confirm progress appears while trace is running.
- [ ] Confirm silent hops or timeouts do not crash the app.
- [ ] Confirm destination latency is based on the final destination hop, not a sum of intermediate hops.
- [ ] Click Stop during an active trace.
- [ ] Confirm Stop responds promptly and does not append delayed results afterward.

## Compare Against OS Commands When Needed

If a result looks suspicious, compare with the OS command-line tool.

### Windows

```powershell
ping 1.1.1.1
tracert 1.1.1.1
nslookup example.com
```

### macOS / Linux

```bash
ping -c 4 1.1.1.1
traceroute 1.1.1.1
dig example.com A
```

If `traceroute` or `dig` is not installed, record that separately. Do not treat the missing OS command as an app failure.

## VPN / Firewall Check

Only run these if relevant to the intended users.

- [ ] Test with VPN off.
- [ ] Test with VPN on.
- [ ] Test one internal domain if users need internal DNS.
- [ ] Confirm ICMP blocked by firewall/VPN is shown clearly.
- [ ] Confirm DNS-over-HTTPS failure is shown clearly if Cloudflare DoH is blocked.

## Failure Messages Should Be Clear

Bad failure examples:

- Infinite spinner
- Silent failure
- Generic “failed”
- Unknown host shown as packet loss
- Permission error shown as host unreachable
- App crash

Good failure examples:

- “Domain does not exist.”
- “No records found for this type.”
- “DNS request timed out.”
- “Ping is unsupported on this runtime.”
- “Traceroute requires network permissions on this machine.”
- “ICMP may be blocked by firewall or network policy.”

## Exit Criteria

Ping, DNS, and Traceroute either work correctly or fail with clear, accurate, non-misleading messages.

---

# Gate 4: Local Data Test

## Goal

Confirm Password Generator, Encoding/Decoding, and Hashing do not require internet access and do not intentionally send user input over the network.

For this small internal release, a simple offline test is enough. Full Wireshark-level monitoring is optional unless there is a specific security concern.

## Offline Test

Disconnect from the internet, then run:

### Password Generator

- [ ] Generate a 16-character password.
- [ ] Generate a 32-character password.
- [ ] Disable symbols and generate again.
- [ ] Add excluded characters and generate again.
- [ ] Confirm generated passwords respect selected options.
- [ ] Confirm app does not crash offline.

### Encoding/Decoding

- [ ] Base64 encode `hello`.
- [ ] Base64 decode the result back to `hello`.
- [ ] Hex encode `hello`.
- [ ] Hex decode the result back to `hello`.
- [ ] Paste Unicode text and confirm conversion works.
- [ ] Paste large text and confirm UI stays stable.

### Hashing

- [ ] Generate MD5 hash.
- [ ] Generate SHA-1 hash.
- [ ] Generate SHA-256 hash.
- [ ] Confirm hashing works offline.

### Network Tools Offline

- [ ] DNS fails gracefully offline.
- [ ] Ping fails gracefully offline.
- [ ] Traceroute fails gracefully offline.

## Optional Network Monitor Test

If extra verification is needed, use a network monitor while running Password and Encoding operations.

Suggested tools:

| Platform | Tools |
|---|---|
| macOS | Little Snitch, `nettop`, `lsof -i` |
| Windows | Resource Monitor, TCPView, Wireshark |
| Linux | `ss -tup`, `netstat -tup`, `lsof -i`, Wireshark |

Expected result:

- Password Generator sends no outbound traffic.
- Encoding/Decoding sends no outbound traffic.
- Hashing sends no outbound traffic.
- Copy buttons send no outbound traffic.

## Exit Criteria

Password generation, encoding, decoding, and hashing work without internet access. Network tools fail gracefully when offline.

---

# Gate 5: Encoding Page Regression Test

## Goal

Confirm the recent Encoding/Decoding page fix does not regress.

The previous issue involved glitchy scrolling caused by a full-screen dropdown overlay. The current fix uses an inline dropdown and reduces unnecessary vertical overflow.

## Test Checklist

- [ ] Open Encoding/Decoding page.
- [ ] Open the operation dropdown.
- [ ] Scroll while dropdown is open.
- [ ] Scroll while dropdown is closed.
- [ ] Resize the window narrower.
- [ ] Resize the window wider.
- [ ] Rapidly open and close dropdown 10 times.
- [ ] Paste large input near the maximum allowed size.
- [ ] Open dropdown with large input present.
- [ ] Confirm no overflow warning appears.
- [ ] Confirm no clipped content appears.
- [ ] Confirm no scroll jump occurs.
- [ ] Confirm app remains responsive.

## Exit Criteria

No overflow, clipping, scroll jump, dropdown glitch, or responsiveness issue appears on the packaged app.

---

# Gate 6: Small User Trial

## Goal

Let the actual intended users test the app before treating it as released.

For this internal tool, the small user trial replaces a formal pilot rollout.

## Trial Group

Send the app to the intended 2–3 users.

Ask them to test:

- Installation/opening
- Ping
- DNS lookup
- Traceroute
- Password generation
- Encoding/decoding
- Copy output
- Any normal workflow they expect to use

## Message to Include With the App

Recommended message:

```text
Hi,

This is the first packaged version of the Elephant Network Tool.

Please try installing and opening it on your machine. The main things to test are Ping, DNS lookup, Traceroute, Password Generator, and Encoding/Decoding.

Important notes:
- Password generation, encoding, decoding, and hashing run locally.
- Ping and Traceroute send probes to the selected target.
- DNS lookup uses Cloudflare DNS-over-HTTPS.
- Ping or Traceroute may be blocked by firewall, VPN, or OS permissions.

If something breaks, please send:
- Your OS
- What you clicked
- The target/domain/input used
- A screenshot of the error
- Whether VPN was on or off

Thank you.
```

## User Feedback Template

```text
OS:
App version:
What I clicked:
Target/domain/input:
What happened:
Screenshot:
Was VPN on or off:
Did the app crash, freeze, or show an error:
```

## Exit Criteria

The intended users can install, open, and use the app without major friction. Any remaining issues are known, documented, and acceptable for a small internal release.

---

# Launch Blockers

The following issues should block even a small internal release:

1. App does not open from the packaged release.
2. App only works through `flutter run`.
3. App crashes on launch.
4. Core pages cannot be opened.
5. Ping/Traceroute fail silently or misleadingly.
6. Unknown host appears as normal packet loss.
7. DNS lookup hangs indefinitely.
8. DNS errors are mislabeled in a misleading way.
9. Stop button does not stop active Ping/Traceroute runs.
10. Password Generator does not work offline.
11. Encoding/Decoding does not work offline.
12. Hashing does not work offline.
13. Password/Encoding/Hashing unexpectedly trigger network traffic.
14. Packaged Windows build has missing DLL errors.
15. Packaged macOS build cannot be opened by intended users.
16. Packaged Linux build has missing shared-library errors on the target distro.
17. Encoding page dropdown/scroll bug still appears.
18. App freezes or leaves orphaned processes after closing.

---

# Acceptable Known Issues for Small Internal Release

The following may be acceptable if documented clearly:

1. Unsigned macOS Gatekeeper warning.
2. Unsigned Windows SmartScreen warning.
3. Ping blocked by firewall, VPN, or network policy.
4. Traceroute showing silent hops.
5. IPv6 failing on networks without IPv6 support.
6. Cloudflare DNS-over-HTTPS not resolving internal/VPN-only domains.
7. Linux support limited to only the distro used by the intended user.
8. Minor UI differences across platforms.

---

# Final Sign-Off Checklist

| Item | Status | Notes |
|---|---|---|
| Automated tests pass | ☐ Pass / ☐ Fail |  |
| Packaged app opens | ☐ Pass / ☐ Fail |  |
| Basic navigation works | ☐ Pass / ☐ Fail |  |
| Ping tested | ☐ Pass / ☐ Fail |  |
| DNS tested | ☐ Pass / ☐ Fail |  |
| Traceroute tested | ☐ Pass / ☐ Fail |  |
| Stop button tested | ☐ Pass / ☐ Fail |  |
| Password Generator tested offline | ☐ Pass / ☐ Fail |  |
| Encoding/Decoding tested offline | ☐ Pass / ☐ Fail |  |
| Hashing tested offline | ☐ Pass / ☐ Fail |  |
| Encoding dropdown/scroll regression tested | ☐ Pass / ☐ Fail |  |
| Actual users tested the app | ☐ Pass / ☐ Fail |  |
| Known warnings documented | ☐ Pass / ☐ Fail |  |
| No launch blockers remain | ☐ Pass / ☐ Fail |  |

---

# Final Recommendation

For a small internal release to 2–3 occasional users, this lean plan is enough.

Do not spend time building a full enterprise release process unless the app will be distributed more broadly.

Focus on the risks that actually matter:

1. The packaged app must work outside the development environment.
2. Ping, DNS, and Traceroute must not produce misleading results.
3. Password generation, encoding, decoding, and hashing must work locally.
4. The intended users must be able to install and use the app with minimal help.

If those conditions are met, the app is reasonable to distribute internally.
