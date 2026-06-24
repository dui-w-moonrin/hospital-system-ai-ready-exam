"""Safe transaction and row-locking reference for insurance-limit claims."""

LOCK_PATIENT_SQL = """
SELECT insurance_limit
FROM patients
WHERE id = %s
FOR UPDATE;
"""

CLAIM_SQL = """
UPDATE patients
SET insurance_limit = insurance_limit - %s
WHERE id = %s;
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


def claim_insurance(connection, patient_id, treatment_cost):
    """Deduct a claim while holding a row lock until the transaction commits.

    `connection` represents a DB adapter with transaction(), fetch_one(), and
    execute() methods. Values are always passed separately from SQL text.
    """
    build_claim_params(patient_id, treatment_cost)

    with connection.transaction():
        patient = connection.fetch_one(LOCK_PATIENT_SQL, (patient_id,))
        if patient is None or patient["insurance_limit"] < treatment_cost:
            return False

        connection.execute(CLAIM_SQL, (treatment_cost, patient_id))
        return True
