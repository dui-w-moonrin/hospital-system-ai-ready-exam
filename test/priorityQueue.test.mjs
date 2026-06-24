import assert from 'node:assert/strict';
import test from 'node:test';
import { orderPatients } from '../src/priorityQueue.mjs';

test('puts emergency patients before normal patients', () => {
  const now = new Date('2026-12-15T10:00:00Z');
  const patients = [
    { id: 'N1', triage: 'NORMAL', severity: 10, arrivedAt: '2026-12-15T09:55:00Z' },
    { id: 'E1', triage: 'EMERGENCY', severity: 1, arrivedAt: '2026-12-15T09:59:00Z' },
    { id: 'N2', triage: 'NORMAL', severity: 1, arrivedAt: '2026-12-15T08:00:00Z' },
  ];

  assert.deepEqual(orderPatients(patients, now).map((patient) => patient.id), ['E1', 'N2', 'N1']);
});

test('rejects a normal patient with an invalid severity', () => {
  const now = new Date('2026-12-15T10:00:00Z');
  assert.throws(
    () => orderPatients([{ id: 'N1', triage: 'NORMAL', severity: 11, arrivedAt: now.toISOString() }], now),
    /severity must be an integer from 1 to 10/,
  );
});
