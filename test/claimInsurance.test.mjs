import assert from 'node:assert/strict';
import test from 'node:test';
import { buildClaimParams } from '../src/claimInsurance.mjs';

test('accepts positive integer claim values', () => {
  assert.deepEqual(buildClaimParams(42, 500), [500, 42, 500]);
});

test('rejects SQL-injection-shaped patient identifiers', () => {
  assert.throws(() => buildClaimParams("1' OR '1'='1", 50), /positive integer/);
});

test('rejects a zero treatment cost', () => {
  assert.throws(() => buildClaimParams(42, 0), /positive integer/);
});
