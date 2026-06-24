-- PostgreSQL. Request: 19 March 2026, 10:00–11:00 Asia/Bangkok.
-- doctor_shifts(doctor_id, starts_at timestamptz, ends_at timestamptz,
--               shift_type: 'WORK' | 'BREAK')
-- appointments(doctor_id, starts_at timestamptz, ends_at timestamptz, status)
WITH request AS (
  SELECT
    (DATE '2026-03-19' + TIME '10:00') AT TIME ZONE 'Asia/Bangkok' AS starts_at,
    (DATE '2026-03-19' + TIME '11:00') AT TIME ZONE 'Asia/Bangkok' AS ends_at
)
SELECT d.id, d.full_name
FROM doctors d
CROSS JOIN request r
WHERE d.status = 'confirmed'
  -- The doctor must be on a work shift covering the whole requested period.
  AND EXISTS (
    SELECT 1
    FROM doctor_shifts s
    WHERE s.doctor_id = d.id
      AND s.shift_type = 'WORK'
      AND s.starts_at <= r.starts_at
      AND s.ends_at >= r.ends_at
  )
  -- Any overlapping break makes the doctor unavailable.
  AND NOT EXISTS (
    SELECT 1
    FROM doctor_shifts s
    WHERE s.doctor_id = d.id
      AND s.shift_type = 'BREAK'
      AND s.starts_at < r.ends_at
      AND s.ends_at > r.starts_at
  )
  AND NOT EXISTS (
    SELECT 1
    FROM appointments a
    WHERE a.doctor_id = d.id
      AND a.status = 'confirmed'
      -- Half-open intervals: [start, end); this detects every true overlap.
      AND a.starts_at < r.ends_at
      AND a.ends_at > r.starts_at
  )
ORDER BY d.full_name;

-- Production indexes:
-- CREATE INDEX appointments_doctor_period_idx
--   ON appointments (doctor_id, starts_at, ends_at)
--   WHERE status = 'confirmed';
-- CREATE INDEX doctor_shifts_doctor_period_idx ON doctor_shifts (doctor_id, starts_at, ends_at);
