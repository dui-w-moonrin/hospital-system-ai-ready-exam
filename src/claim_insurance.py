"""Safe parameter construction for the insurance-limit update."""

CLAIM_SQL = """
UPDATE patients
SET insurance_limit = insurance_limit - %s
WHERE id = %s
  AND insurance_limit >= %s
RETURNING id, insurance_limit;
"""


def build_claim_params(patient_id, treatment_cost):
    """Validate values that a DB driver will bind separately from SQL text."""
    if (
        not isinstance(patient_id, int)
        or isinstance(patient_id, bool)
        or patient_id <= 0
        or not isinstance(treatment_cost, int)
        or isinstance(treatment_cost, bool)
        or treatment_cost <= 0
    ):
        raise ValueError("patient_id and treatment_cost must be positive integers")
    return treatment_cost, patient_id, treatment_cost
