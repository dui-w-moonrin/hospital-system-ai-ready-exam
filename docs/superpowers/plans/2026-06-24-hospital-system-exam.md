# Hospital System Exam Solution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a compact, reviewable GitHub-ready solution for all seven hospital-system exam prompts.

**Architecture:** The repository is a documentation-first solution: Markdown answers expose assumptions, threat controls, and Mermaid diagrams; SQL and TypeScript provide executable reference implementations for the two algorithmic prompts. Tests prove the priority order and input validation without creating a nonessential application.

**Tech Stack:** Markdown, Mermaid, TypeScript (Node built-in test runner), PostgreSQL-flavoured SQL.

---

### Task 1: Repository guide and priority-queue implementation

**Files:**
- Create: `README.md`
- Create: `src/priorityQueue.mjs`
- Create: `test/priorityQueue.test.mjs`

- [ ] **Step 1: Write failing priority-order and wait-escalation tests**

```js
assert.deepEqual(orderPatients(patients, now), ['E1', 'N2', 'N1']);
```

- [ ] **Step 2: Run the test and confirm it fails because the module is absent**

Run: `node --test test/priorityQueue.test.mjs`

- [ ] **Step 3: Implement deterministic priority ordering**

```js
export function orderPatients(patients, now) { /* emergency first; normal severity plus wait boost */ }
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `node --test test/priorityQueue.test.mjs`

### Task 2: SQL, concurrency and safety architecture documentation

**Files:**
- Create: `sql/doctor-availability.sql`
- Create: `src/claimInsurance.mjs`
- Create: `test/claimInsurance.test.mjs`
- Create: `docs/01-03-technical.md`
- Create: `docs/04-05-business-safety.md`

- [ ] **Step 1: Write failing validation tests for insurance amounts**

```js
assert.throws(() => buildClaimParams("1' OR '1'='1", 50), /positive integer/);
```

- [ ] **Step 2: Run the test and confirm it fails because the module is absent**

Run: `node --test test/claimInsurance.test.mjs`

- [ ] **Step 3: Implement parameter validation and transactional SQL statement definitions**

```js
export function buildClaimParams(patientId, treatmentCost) { /* validate integer inputs */ }
```

- [ ] **Step 4: Run all tests and confirm they pass**

Run: `node --test`

### Task 3: AI integrity answers and delivery checklist

**Files:**
- Create: `docs/06-07-ai-integrity.md`
- Modify: `README.md`

- [ ] **Step 1: Document a strict JSON prompt, schema validation, and refusal rules**
- [ ] **Step 2: Document interaction-checker architecture, audit path, and human approval gates**
- [ ] **Step 3: Add a ten-minute video outline and test evidence to README**
- [ ] **Step 4: Run `node --test` and inspect every Markdown file for missing question coverage**
