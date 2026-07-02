# Network Failure Trial

Use this checklist for native desktop trials only. Keep these runs out of CI
because live ICMP, DNS, and traceroute results vary by ISP, VPN, firewall, OS,
and time of day.

## Run Metadata

- Date/time:
- App version/build:
- OS and device:
- Network type:
- VPN/proxy/firewall state:
- Location/network owner:
- Baseline command used for comparison:
- Tester:

## Acceptance Signals

- The UI streams progress within 1 second after starting a live operation.
- Stop actions complete within about 1.5 seconds.
- DNS lookup completes or returns a controlled error within about 5 seconds.
- Ping packet counts, loss, sequence numbers, RTT, and TTL are internally
  consistent.
- Traceroute never sums hop averages; end-to-end latency is the final
  destination-hop average when the destination is reached.
- Unsupported browser/runtime cases are labeled unsupported, not network failed.

## Ping Matrix

Record target, expected behavior, actual output, elapsed time, OS command output,
and whether the app result could be misunderstood.

| Case | Target | Expected | Notes |
| --- | --- | --- | --- |
| Loopback IPv4 | 127.0.0.1 | Fast success | Confirms local ICMP path. |
| LAN gateway | Router IP | Fast success or local policy block | Compare against OS ping. |
| Public resolver | 1.1.1.1 | Usually success | Anycast IP; location may vary. |
| Public resolver | 8.8.8.8 | Usually success | ICMP may be filtered on some networks. |
| Nonexistent domain | missing.invalid | Unknown host | Must not look like packet loss. |
| Malformed IPv4 | 999.999.999.999 | Clean error | Must not crash. |
| IPv6 loopback | ::1 | Success if IPv6 supported | Note OS/runtime support. |
| Public IPv6 | 2606:4700:4700::1111 | Depends on IPv6 route | Failure may mean no IPv6 route. |
| Blackhole | 192.0.2.1 or local lab drop host | 100 percent loss | Verify timeout budget. |
| ICMP filtered host | Known firewall target | Loss or no reply | Does not prove host is down. |

False-positive notes to check:

- ICMP success does not prove HTTP/TCP service health.
- ICMP failure does not prove the server is down.
- DNS names may resolve to anycast, CDN, or rotating addresses.
- One reply in a lossy run should not make the result look healthy.
- Sequence numbers must match the provider event convention.

## DNS Matrix

Compare Cloudflare DoH behavior with local resolver behavior when relevant.

| Case | Domain/type | Expected | Notes |
| --- | --- | --- | --- |
| A | example.com A | IPv4 answers | Mocked in CI; live answer may vary. |
| AAAA | example.com AAAA | IPv6 answers or empty | Empty can be valid. |
| CNAME | www host CNAME | CNAME or empty | Apex domains often have no CNAME. |
| MX | gmail.com MX | Mail exchanger answers | Order may vary. |
| TXT | domain TXT | Long TXT values preserved | SPF/DKIM values may be long. |
| NS | example.com NS | Name server answers | TTL may vary. |
| NXDOMAIN | missing.invalid A | Domain does not exist | Must not be shown as empty success. |
| SERVFAIL | Controlled resolver/lab case | Resolver failed | Must not be shown as empty success. |
| NOERROR no Answer | Valid domain/type with no records | No records found | This is not an error. |
| Split horizon | Internal/VPN host | May fail in Cloudflare DoH | Local dig may succeed. |

Unsupported UI types for the current app: SOA, SRV, CAA, PTR, DS, DNSKEY,
RRSIG, HTTPS/SVCB, NAPTR, and usually ANY.

## Traceroute Matrix

Record elapsed time, first-hop time, per-hop timing, stop latency, final summary,
and whether partial failures could be misunderstood.

| Case | Target | Expected | Notes |
| --- | --- | --- | --- |
| Short complete route | Nearby reliable host | Destination reached | Summary latency equals final hop average. |
| Public resolver | 1.1.1.1 or 8.8.8.8 | Reaches or filters | Some hops may be silent. |
| Exactly 30 hops | Lab or known deep path | Stops at hop 30 | Worst case is about 180 seconds today. |
| Never reaches destination | Blackhole/lab target | Not reached after max hops | Progress must remain visible. |
| Intermittent silent routers | Public internet route | Mixed `*` probes | Partial hop timeouts must not stop trace. |
| Early no route | Disconnected route/lab | Stops early | Clean no-route message. |
| Unknown host | missing.invalid | Stops early | Clean unknown-host message. |
| Stop during trace | Any slow target | Stops promptly | No delayed hop should append after stop. |

## Timing Log

For each manual network run, capture:

- Operation:
- Target:
- Config:
- Start time:
- First result time:
- Completion time:
- Stop clicked time:
- Stop completed time:
- Total elapsed:
- App result:
- OS comparison:
- Misleading-result risk:
- Follow-up issue filed:
