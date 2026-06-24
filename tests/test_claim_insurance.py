import unittest

from src.claim_insurance import build_claim_params


class ClaimInsuranceTests(unittest.TestCase):
    def test_valid_claim_returns_bound_parameter_values(self):
        self.assertEqual(build_claim_params(42, 500), (500, 42, 500))

    def test_injection_shaped_id_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "positive integers"):
            build_claim_params("1' OR '1'='1", 50)

    def test_zero_treatment_cost_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "positive integers"):
            build_claim_params(42, 0)


if __name__ == "__main__":
    unittest.main()
