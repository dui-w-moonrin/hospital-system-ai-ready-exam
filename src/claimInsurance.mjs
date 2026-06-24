export const CLAIM_SQL = `
  UPDATE patients
  SET insurance_limit = insurance_limit - $1
  WHERE id = $2
    AND insurance_limit >= $3
  RETURNING id, insurance_limit;
`;

/** Return parameter values only; callers pass CLAIM_SQL and this array to a DB driver. */
export function buildClaimParams(patientId, treatmentCost) {
  for (const value of [patientId, treatmentCost]) {
    if (!Number.isSafeInteger(value) || value <= 0) {
      throw new RangeError('patientId and treatmentCost must be positive integers');
    }
  }
  return [treatmentCost, patientId, treatmentCost];
}
