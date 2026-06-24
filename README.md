# Hospital System — AI-Ready Solution

> Submission for the Fullstack Developer (Specialized: Hospital System) e-Exam.

This repository deliberately favours **safe, explainable system design** over an unfinished UI. It contains executable reference code for the queue and claim logic, PostgreSQL SQL for appointment availability, and concise architecture answers for all seven questions.

## Exam brief (for video narration)

### Part 1 — Technical & High-Stakes Logic (40 points)

1. **The Intelligent Priority Queue (15):** Write `getUrgentPatient(queue, currentTime)`. Emergency (E) is before Normal (N); within a group use Severity Score 1–10; a Normal patient waiting over 60 minutes is temporarily escalated to Emergency-equivalent priority. Explain performance with 10,000 patients.
2. **Complex SQL — Doctor's Availability (10):** Find available doctors on **19 March 2026, 10:00–11:00**. Exclude a doctor with a `confirmed` appointment in the interval, a doctor on a break according to `doctor_shifts`, and an appointment that overlaps into 10:00.
3. **Code Review — The Race Condition (15):** Repair concurrent insurance-limit claims. Identify SQL Injection and Race Condition, and rewrite using a database transaction and row-level locking (`SELECT FOR UPDATE`).

### Part 2 — Business Architecture & Safety (30 points)

4. **Drug Allergy & Safety Design (15):** Design `drug_allergies` and `prescriptions` with constraints that prevent an allergic prescription; describe alert and override workflow.
5. **System Scalability — Lab Results (15):** Design high-resolution X-Ray storage and smooth mobile delivery (compression/internal CDN), while enforcing PDPA privacy.

### Part 3 — AI Integrity (30 points)

6. **Symptom to Structured Data (10):** Write a prompt that turns this text into JSON: _“ปวดท้องบิดๆ มา 2 ชั่วโมง กินส้มตำปูปลาร้ามา”_. Prevent diagnosis/hallucination; return only patient-provided facts.
7. **Smart Drug Interaction Checker (20):** Draw the integration between drug database and AI model. Design human-in-the-loop safety when the AI is uncertain.

> **Narration tip:** State the requirement first, then open the linked evidence below and explain the safety decision behind it.

## Contents

| Exam item | Evidence |
|---|---|
| 1. Intelligent Priority Queue | `src/priority_queue.py`, `tests/test_priority_queue.py` (`get_urgent_patient`) |
| 2. Doctor availability SQL | `sql/doctor-availability.sql` |
| 3. Race condition / injection | `src/claim_insurance.py`, `docs/01-03-technical.md` |
| 4–5. Drug safety and lab scale | `docs/04-05-business-safety.md` |
| 6–7. AI integrity | `docs/06-07-ai-integrity.md` |

## Run the executable examples

```powershell
python -m unittest discover -s tests -v
```

The standard-library test suite covers emergency-first triage, wait-time escalation, validation, and injection-shaped identifiers. The project intentionally has no external dependency.

## Key assumptions

- All timestamps are stored as `timestamptz` in UTC and displayed in `Asia/Bangkok`.
- Appointment time intervals are half-open: `[starts_at, ends_at)`. Back-to-back appointments therefore do not overlap.
- A model never makes the final clinical decision. It can extract, retrieve, and explain; a qualified clinician approves any safety-relevant action.
- In this reference rule, any Normal patient waiting at least 60 minutes is escalated above newly arriving Normal patients, but **never above an Emergency patient**.

## 8–10 minute video outline

1. **0:00–0:40** — Repository map and safety-first design principle.
2. **0:40–2:10** — Queue rule and unit tests; explain why emergency is an immutable priority tier.
3. **2:10–3:20** — Availability SQL and the interval-overlap predicate.
4. **3:20–4:35** — Atomic insurance claim update; parameter binding and transaction isolation.
5. **4:35–6:10** — Allergy data model, override audit trail, and lab storage/CDN privacy.
6. **6:10–8:40** — Strict symptom JSON extraction and drug-interaction human-in-the-loop workflow.
7. **8:40–9:10** — Tests, limitations, and production next steps.

## AI use and human accountability

AI was used as a drafting and review accelerator. The final solution applies explicit assumptions, deterministic rules for safety-critical paths, parameterized SQL, schema validation, auditability, and human approval gates. These controls matter more than simply adding an LLM.
