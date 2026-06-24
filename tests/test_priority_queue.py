from datetime import datetime, timezone
import unittest

from src.priority_queue import order_patients


class PriorityQueueTests(unittest.TestCase):
    def test_emergency_is_before_normal_and_waiting_normal_is_escalated(self):
        now = datetime(2026, 12, 15, 10, 0, tzinfo=timezone.utc)
        patients = [
            {"id": "N1", "triage": "NORMAL", "severity": 10, "arrived_at": datetime(2026, 12, 15, 9, 55, tzinfo=timezone.utc)},
            {"id": "E1", "triage": "EMERGENCY", "severity": 1, "arrived_at": datetime(2026, 12, 15, 9, 59, tzinfo=timezone.utc)},
            {"id": "N2", "triage": "NORMAL", "severity": 1, "arrived_at": datetime(2026, 12, 15, 8, 0, tzinfo=timezone.utc)},
        ]
        self.assertEqual([patient["id"] for patient in order_patients(patients, now)], ["E1", "N2", "N1"])

    def test_invalid_severity_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "severity must be an integer from 1 to 10"):
            order_patients([{"id": "N1", "triage": "NORMAL", "severity": 11, "arrived_at": datetime.now(timezone.utc)}])


if __name__ == "__main__":
    unittest.main()
