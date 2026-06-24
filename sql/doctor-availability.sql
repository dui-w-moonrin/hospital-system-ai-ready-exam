-- PostgreSQL. Inputs: :target_date = DATE '2026-12-15',
-- :requested_start = TIME '10:00', :duration_minutes = 100.
-- doctor_shifts(doctor_id, starts_at timestamptz, ends_at timestamptz)
-- appointments(doctor_id, starts_at timestamptz, ends_at timestamptz, status)
WITH request AS (
  SELECT
    (DATE '2026-12-15' + TIME '10:00') AT TIME ZONE 'Asia/Bangkok' AS starts_at,
    ((DATE '2026-12-15' + TIME '10:00') AT TIME ZONE 'Asia/Bangkok')
      + INTERVAL '100 minutes' AS ends_at
)
SELECT d.id, d.full_name
FROM doctors d
CROSS JOIN request r
WHERE d.status = 'confirmed'
  AND EXISTS (
    SELECT 1
    FROM doctor_shifts s
    WHERE s.doctor_id = d.id
      AND s.starts_at <= r.starts_at
      AND s.ends_at >= r.ends_at
  )
  AND NOT EXISTS (
    SELECT 1
    FROM appointments a
    WHERE a.doctor_id = d.id
      AND a.status IN ('pending', 'confirmed')
      -- Half-open intervals: [start, end); this detects every true overlap.
      AND a.starts_at < r.ends_at
      AND a.ends_at > r.starts_at
  )
ORDER BY d.full_name;

-- Production indexes:
-- CREATE INDEX appointments_doctor_period_idx
--   ON appointments (doctor_id, starts_at, ends_at)
--   WHERE status IN ('pending', 'confirmed');
-- CREATE INDEX doctor_shifts_doctor_period_idx ON doctor_shifts (doctor_id, starts_at, ends_at);
