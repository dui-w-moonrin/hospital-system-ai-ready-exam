"""Deterministic, explainable ordering for a hospital triage queue."""

from datetime import datetime, timezone


def order_patients(patients, now=None):
    """Return patients ordered by triage tier, priority score, then arrival time.

    Emergency patients always remain ahead of Normal patients. A Normal patient
    waiting at least 60 minutes receives a +10 escalation boost.
    """
    if now is None:
        now = datetime.now(timezone.utc)

    scored_patients = []
    for patient in patients:
        if patient["triage"] not in {"EMERGENCY", "NORMAL"}:
            raise ValueError("triage must be EMERGENCY or NORMAL")
        severity = patient["severity"]
        if not isinstance(severity, int) or not 1 <= severity <= 10:
            raise ValueError("severity must be an integer from 1 to 10")

        waited_minutes = max(0, int((now - patient["arrived_at"]).total_seconds() // 60))
        escalation_boost = 10 if patient["triage"] == "NORMAL" and waited_minutes >= 60 else 0
        scored_patients.append((patient, severity + escalation_boost))

    return [
        patient
        for patient, _score in sorted(
            scored_patients,
            key=lambda item: (
                0 if item[0]["triage"] == "EMERGENCY" else 1,
                -item[1],
                item[0]["arrived_at"],
            ),
        )
    ]


def get_urgent_patient(queue, current_time=None):
    """Return the next patient to treat, or None when the queue is empty."""
    ordered_queue = order_patients(queue, current_time)
    return ordered_queue[0] if ordered_queue else None
