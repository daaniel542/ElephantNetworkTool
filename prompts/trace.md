**Context:**
We are updating our traceroute feature. **Do not change or dictate the UI layout, styling, or theme.** Your task is strictly to implement the state management, data structures, and mathematical logic required to power the traceroute table and summary components.

## 1. Required Data State

You need to build the state management to track and update the following core metrics dynamically as the traceroute progresses:

### A. Hop-by-Hop Data (Array of Objects)

Each object in the array represents a single hop and must contain:

- **Status:** (e.g., pending, success, timeout)
- **Hop Number:** Sequential integer.
- **IP Address:** The router's IP string (or null/"Request Timed Out").
- **Probe 1:** Latency in ms.
- **Probe 2:** Latency in ms.
- **Probe 3:** Latency in ms.
- **Avg RTT:** The mathematical mean of the successful probes in ms.

### B. Summary Metrics (Derived State)

Extract and maintain these specific totals to be displayed when the trace finishes:

- **Destination Reached:** The target IP address.
- **Total End-to-End Latency:** See Math Rules below.
- **Total Hops:** The final hop count.

## 2. Mathematical & Functional Rules

**CRITICAL RULE - Cumulative Latency:** Traceroute latencies are inherently cumulative. The time shown for any given hop is the round-trip time from the source to that specific hop.

- **DO NOT** sum the average RTTs of the individual rows.
- The **Total End-to-End Latency** must strictly equal the **Average RTT of the final successful hop** (the destination).

**Timeout Handling:**

- If a probe drops, handle the null/timeout state gracefully without breaking the Average RTT calculation (average only the successful probes for that hop).
- If all 3 probes fail for a hop, mark the IP as a timeout and set Avg RTT to null/dashed.

## 3. Output Request

Please provide the necessary data models, state management hooks/logic (e.g., React `useState`/`useEffect`, Vue `ref`, or plain JS classes depending on our stack), and the mock data streaming function to simulate the incoming probe data. Integrate this logic seamlessly so it can be plugged directly into our existing UI components.
"""
