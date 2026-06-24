from contextlib import contextmanager
import unittest

from src.claim_insurance import build_claim_params, claim_insurance


class FakeConnection:
    def __init__(self, insurance_limit):
        self.insurance_limit = insurance_limit
        self.events = []

    @contextmanager
    def transaction(self):
        self.events.append("begin")
        try:
            yield self
        except Exception:
            self.events.append("rollback")
            raise
        else:
            self.events.append("commit")

    def fetch_one(self, sql, params):
        self.events.append(("lock", sql, params))
        return {"insurance_limit": self.insurance_limit}

    def execute(self, sql, params):
        self.events.append(("update", sql, params))
        self.insurance_limit -= params[0]


class ClaimInsuranceTests(unittest.TestCase):
    def test_valid_claim_returns_bound_parameter_values(self):
        self.assertEqual(build_claim_params(42, 500), (500, 42, 500))

    def test_injection_shaped_id_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "positive integers"):
            build_claim_params("1' OR '1'='1", 50)

    def test_zero_treatment_cost_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "positive integers"):
            build_claim_params(42, 0)

    def test_claim_locks_patient_before_deducting_limit(self):
        connection = FakeConnection(insurance_limit=100)

        self.assertTrue(claim_insurance(connection, patient_id=42, treatment_cost=30))
        self.assertEqual(connection.insurance_limit, 70)
        self.assertEqual(connection.events[0], "begin")
        self.assertEqual(connection.events[1][0], "lock")
        self.assertIn("FOR UPDATE", connection.events[1][1])
        self.assertEqual(connection.events[2][0], "update")
        self.assertEqual(connection.events[3], "commit")

    def test_claim_does_not_update_when_limit_is_insufficient(self):
        connection = FakeConnection(insurance_limit=20)

        self.assertFalse(claim_insurance(connection, patient_id=42, treatment_cost=30))
        self.assertEqual(connection.insurance_limit, 20)
        self.assertEqual(connection.events, ["begin", connection.events[1], "commit"])


if __name__ == "__main__":
    unittest.main()
