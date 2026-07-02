We are building/fixing on top of our current dns service.

## 1. Input Options (Configurable Parameters)

Every standard ping tool must allow the user to configure the following parameters:

* **Destination Host:** The target IPv4 address, IPv6 address, or Fully Qualified Domain Name (FQDN) to ping.
* **Packet Size:** The size of the ICMP payload in bytes. (Default: 32 or 56 bytes. Range: up to ~65,500 bytes).
* **Timeout:** The duration to wait for a reply before declaring the packet "lost". (Typical range: 1000ms – 4000ms).
* **Ping Count / Continuous Mode:** The number of ICMP Echo Requests to send. Must support a finite count (e.g., 4) or an infinite continuous loop until manually stopped.
* **TTL (Time to Live):** The maximum number of network hops the packet is permitted to take before being discarded.

## 2. Output Metrics (Essential Statistics)

At the conclusion of a ping session, the tool must calculate and display:

* **Packet Statistics:**
  * Packets Sent
  * Packets Received
  * Packets Lost (Total count and Percentage)
* **Round-Trip Time (RTT) Metrics:**
  * **Minimum RTT (ms):** The fastest response time.
  * **Maximum RTT (ms):** The slowest response time.
  * **Average RTT (ms):** The mean response time across all received packets.
* **Standard Deviation (StdDev) (ms):** The avg response time.
* **Jitter (ms):** The statistical variance/fluctuation in latency between successive packets (crucial for assessing connection stability).

## 3. Comprehensive Testing Checklist

### 3.1 Functional & Boundary Testing

* **Successful Resolutions:** Test against local loopback (`127.0.0.1`) and reliable public DNS (`8.8.8.8`).
* **Invalid Destinations:** Input malformed IPs (`999.999.999.999`), invalid characters, or non-existent domains. Ensure clean error handling ("Unknown host").
* **Packet Size Extremes:** Test minimum sizes, default sizes, and maximum allowable sizes before fragmentation errors occur.
* **Negative/Zero Inputs:** Attempt to input `0` or negative values for Count, Timeout, and Packet Size to verify input validation logic.

### 3.2 Network Edge Cases

* **Total Packet Loss (Black Hole):** Target an IP that drops ICMP traffic. Verify the tool honors the timeout duration exactly and reports 100% loss.
* **Intermittent Connection:** Simulate network drops (e.g., every 4th packet lost) or extreme latency spikes to verify jitter calculation.
* **High Latency Targets:** Ping geographically distant servers to verify UI rendering of slow, delayed responses.
* **Total DNS Failure:** Disconnect internet access and attempt to ping a domain to verify resolution failure handling.

### 3.3 Performance & Resource Management

* **The Flood Test:** Run the ping at rapid-fire intervals (e.g., 10ms) to ensure it does not cause memory leaks or freeze the UI thread.
* **Abrupt Cancellation:** Start a high-count or continuous ping and cancel it midway. The tool must stop instantly and print summary statistics for only the packets sent up to that exact moment.
* **Timeout Overlap:** If packet RTT exceeds the interval between sends, ensure asynchronous responses are matched to the correct sequence numbers and not misattributed.

### 3.4 UI / UX Requirements

Maintain the current UI/UX flow 
