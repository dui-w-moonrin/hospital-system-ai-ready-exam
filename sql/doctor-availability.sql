-- PostgreSQL: ค้นหาแพทย์ว่างวันที่ 19 มีนาคม 2026 เวลา 10:00–11:00
-- doctor_shifts(doctor_id, starts_at timestamptz, ends_at timestamptz,
--               shift_type: 'WORK' | 'BREAK')
-- appointments(doctor_id, starts_at timestamptz, ends_at timestamptz, status)
WITH request AS (
  SELECT
    (DATE '2026-03-19' + TIME '10:00') AT TIME ZONE 'Asia/Bangkok' AS starts_at,
    (DATE '2026-03-19' + TIME '11:00') AT TIME ZONE 'Asia/Bangkok' AS ends_at
),
working_doctors AS (
  SELECT DISTINCT s.doctor_id
  FROM doctor_shifts s
  CROSS JOIN request r
  WHERE s.shift_type = 'WORK'
    AND s.starts_at <= r.starts_at
    AND s.ends_at >= r.ends_at
),
break_doctors AS (
  SELECT DISTINCT s.doctor_id
  FROM doctor_shifts s
  CROSS JOIN request r
  WHERE s.shift_type = 'BREAK'
    AND s.starts_at < r.ends_at
    AND s.ends_at > r.starts_at
),
booked_doctors AS (
  SELECT DISTINCT a.doctor_id
  FROM appointments a
  CROSS JOIN request r
  WHERE a.status = 'confirmed'
    -- Half-open intervals: [start, end); detects every true overlap.
    AND a.starts_at < r.ends_at
    AND a.ends_at > r.starts_at
)
SELECT d.id, d.full_name
FROM doctors d
JOIN working_doctors w ON w.doctor_id = d.id
LEFT JOIN break_doctors b ON b.doctor_id = d.id
LEFT JOIN booked_doctors a ON a.doctor_id = d.id
WHERE d.status = 'confirmed'
  AND b.doctor_id IS NULL
  AND a.doctor_id IS NULL
ORDER BY d.full_name;

-- Production indexes:
-- CREATE INDEX appointments_doctor_period_idx
--   ON appointments (doctor_id, starts_at, ends_at)
--   WHERE status = 'confirmed';
-- CREATE INDEX doctor_shifts_doctor_period_idx ON doctor_shifts (doctor_id, starts_at, ends_at);
