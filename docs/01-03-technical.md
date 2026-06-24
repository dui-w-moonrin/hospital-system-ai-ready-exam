# Questions 1–3 — Technical & High-Stakes Logic

## 1. Intelligent Priority Queue

**Rule interpretation:** Emergency is always a separate, non-negotiable priority tier. For Normal cases, severity is `1..10`; after a 60-minute wait the patient receives an escalation boost so that an old Normal case cannot starve behind new arrivals. Ties use earlier arrival first (FIFO), which is explainable to staff.

`src/priority_queue.py` exposes the requested `get_urgent_patient(queue, current_time)`, backed by `order_patients`. Complexity is **O(n log n)** because it creates one scored record per patient and sorts them. At 10,000 patients this is fast enough for a periodic triage-board refresh; a long-lived queue can use a heap for **O(log n)** insertion. Memory is **O(n)**.

Operational safeguards:

- Record every automated priority change with rule version, previous/new score, timestamp, and actor/service ID.
- Do not expose a score as a diagnosis; triage staff may override it with a reason.
- Use a single service clock and UTC storage to avoid inconsistent wait calculations.

## 2. Complex SQL — Doctor availability

The SQL is in [`sql/doctor-availability.sql`](../sql/doctor-availability.sql). It finds an active doctor working through **19 March 2026, 10:00–11:00**, who has no overlapping `confirmed` appointment and no overlapping `BREAK` shift.

The critical overlap condition is:

```sql
existing.starts_at < requested.ends_at
AND existing.ends_at > requested.starts_at
```

This catches contained, enclosing, and partial overlaps. It correctly permits an appointment ending exactly when the requested one starts. In production I would add the documented composite indexes and, for PostgreSQL, consider an exclusion constraint on `tstzrange(starts_at, ends_at, '[)')` per doctor to prevent a race between availability checking and booking.

## 3. Code review — Insurance limit race condition and SQL injection

The original pattern has two defects:

1. **Race condition:** two requests read the same balance before either writes, allowing an overspend or a lost update.
2. **SQL injection:** interpolating `patientId` creates executable SQL from user-controlled input.

The safest compact fix is a single atomic conditional update, defined in `src/claim_insurance.py`:

```sql
UPDATE patients
SET insurance_limit = insurance_limit - $1
WHERE id = $2 AND insurance_limit >= $3
RETURNING id, insurance_limit;
```

The DB driver receives `(treatment_cost, patient_id, treatment_cost)` as bound parameters—never a concatenated string. A returned row means the claim succeeded; zero rows means “patient missing or insufficient limit” and should return a non-sensitive business response.

For a multi-row claim (claim header, treatment record, balance, audit event), wrap all statements in one database transaction at `READ COMMITTED` or stronger. Lock the patient row with `SELECT ... FOR UPDATE` before dependent reads, then write the audit event before commit. An idempotency key (`patient_id`, external_request_id) prevents duplicate retries from charging twice. Do not log raw insurance/medical details; log request ID and outcome only.
