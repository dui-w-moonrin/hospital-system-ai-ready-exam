# Hospital System — AI-Ready Solution

> Submission for the Fullstack Developer (Specialized: Hospital System) e-Exam.

This repository deliberately favours **safe, explainable system design** over an unfinished UI. It contains executable reference code for the queue and claim logic, PostgreSQL SQL for appointment availability, and concise architecture answers for all seven questions.

## Contents

| Exam item | Evidence |
|---|---|
| 1. Intelligent Priority Queue | `src/priorityQueue.mjs`, `test/priorityQueue.test.mjs` |
| 2. Doctor availability SQL | `sql/doctor-availability.sql` |
| 3. Race condition / injection | `src/claimInsurance.mjs`, `docs/01-03-technical.md` |
| 4–5. Drug safety and lab scale | `docs/04-05-business-safety.md` |
| 6–7. AI integrity | `docs/06-07-ai-integrity.md` |

## Run the executable examples

```powershell
node --test
```

The test suite covers emergency-first triage, wait-time escalation, validation, and injection-shaped identifiers. The project intentionally has no external dependency.

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
