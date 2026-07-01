# networkTool
Network tool for Elephant Technologies LTD

## Vercel deployment

This Flutter app is configured for Vercel as a Flutter Web static build.

Vercel uses:

- Build command: `bash scripts/vercel-build.sh`
- Output directory: `build/web`
- SPA fallback: all routes rewrite to `/index.html`

The build script installs Flutter stable on Vercel when `flutter` is not already
available, enables web support, runs `flutter pub get`, and builds the release
web bundle.

### Web limitations

Browsers cannot send ICMP packets or TTL-limited probes. On Vercel, DNS lookup,
password generation, encoding, and hashing can run client-side, while Ping and
Traceroute show browser-specific availability messages. To support hosted Ping
or Traceroute, add a backend probe service and call it from the Flutter Web app.
