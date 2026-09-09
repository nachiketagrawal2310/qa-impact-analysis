# On-Premise & Hybrid Integration Checklist

Apply when changes touch on-premise connectors, local sync agents, edge services, hybrid cloud ↔ on-prem communication, or gateway sync jobs.

---

## 1. Key Areas of Inspection

### Connectivity & Network Failures
- **Cloud → On-Prem Disconnection:** What happens if the on-premise firewall blocks outbound/inbound traffic, or the VPN/tunnel drops?
- **Connection Timeout:** Are timeouts configured gracefully (e.g., 5s vs hanging indefinitely)?
- **Network Interruption Midway:** Does a network drop during a 10MB payload sync leave corrupt or partial data on either side?

### Authentication & Security
- **Local Credentials & mTLS:** How are tokens, mTLS certificates, or local API keys rotated or validated?
- **Expired Local Agent Token:** Does the on-premise agent fail silently, crash, or emit an alert when cloud credentials expire?

### Data Synchronization & Out-of-Order Delivery
- **Sync Lag & Latency:** How does the system handle records updated simultaneously on cloud and on-premise?
- **Out-of-Order Updates:** If update #2 arrives before update #1 due to network retries, does it overwrite with older data?
- **Replay & Duplicate Delivery:** If the cloud re-sends a batch sync after a timeout, does the on-premise connector create duplicate records?

### Version Coexistence & Compatibility
- **Cloud v2 + Agent v1:** If the cloud API adds required fields or changes payload schemas, do older deployed on-premise agents continue functioning without crashing?
- **Backward Compatibility Window:** Does the cloud service support older agent versions?

### State Inconsistency & Reconciliation
- **Partial Synchronization:** If 3 out of 10 items in a batch sync succeed on-premise, does the cloud mark the entire batch as failed or track per-item status?
- **Reconciliation Job:** Is there a periodic reconciliation workflow to detect and resolve drift between cloud and on-premise databases?

---

## 2. Mandatory Test Scenarios for Hybrid Changes

1. **Simulated Network Drop During Active Sync:**
   - Terminate connection midway through sync. Verify that no partial/corrupted records are committed, and the agent successfully retries upon reconnection.
2. **Duplicate Batch Replay (Idempotency):**
   - Replay the exact same sync payload twice. Verify that local database records are updated/ignored, never duplicated.
3. **Older Agent Version Compatibility:**
   - Send payload formatted for legacy agent version. Verify cloud correctly processes or maps fields without throwing unhandled exceptions.
