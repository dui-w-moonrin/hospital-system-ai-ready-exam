-- PostgreSQL reference schema for MedCare drug-allergy safety.
CREATE TABLE drug_allergies (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id BIGINT NOT NULL REFERENCES patients(id),
  drug_id BIGINT NOT NULL REFERENCES drugs(id),
  reaction TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('MILD', 'MODERATE', 'SEVERE')),
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESOLVED')),
  recorded_by BIGINT NOT NULL REFERENCES users(id),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One active allergy record per patient and drug.
CREATE UNIQUE INDEX drug_allergies_one_active_record
  ON drug_allergies(patient_id, drug_id)
  WHERE status = 'ACTIVE';

CREATE TABLE prescriptions (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  patient_id BIGINT NOT NULL REFERENCES patients(id),
  drug_id BIGINT NOT NULL REFERENCES drugs(id),
  prescribed_by BIGINT NOT NULL REFERENCES users(id),
  dose TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'APPROVED', 'OVERRIDDEN', 'CANCELLED')),
  allergy_override_by BIGINT REFERENCES users(id),
  allergy_override_reason TEXT,
  allergy_override_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (
    (allergy_override_by IS NULL AND allergy_override_reason IS NULL AND allergy_override_at IS NULL)
    OR
    (allergy_override_by IS NOT NULL AND allergy_override_reason IS NOT NULL AND allergy_override_at IS NOT NULL)
  )
);

CREATE OR REPLACE FUNCTION prevent_allergic_prescription()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM drug_allergies da
    WHERE da.patient_id = NEW.patient_id
      AND da.drug_id = NEW.drug_id
      AND da.status = 'ACTIVE'
  ) THEN
    -- Only a physician with explicit override details may proceed.
    IF NEW.allergy_override_by IS NULL
       OR NEW.allergy_override_reason IS NULL
       OR NOT EXISTS (
         SELECT 1 FROM users u
         WHERE u.id = NEW.allergy_override_by
           AND u.role IN ('ATTENDING_PHYSICIAN', 'SENIOR_PHYSICIAN')
       ) THEN
      RAISE EXCEPTION 'Active drug allergy: prescription is blocked';
    END IF;

    NEW.status := 'OVERRIDDEN';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prescriptions_block_active_allergy
BEFORE INSERT OR UPDATE OF patient_id, drug_id, allergy_override_by, allergy_override_reason
ON prescriptions
FOR EACH ROW EXECUTE FUNCTION prevent_allergic_prescription();
