# ข้อ 4–5 — Business Architecture & Safety

เอกสารนี้สรุป design reference ที่สอดคล้องกับคำตอบใน [README](../README.md)

## ข้อ 4 — Drug Allergy & Safety Design

schema และ trigger อยู่ที่ [`sql/drug-allergy-safety.sql`](../sql/drug-allergy-safety.sql)

### Data model

- `drug_allergies` เก็บ `patient_id`, `drug_id`, `reaction`, `severity`, `status`, ผู้บันทึก และเวลา
- `prescriptions` เก็บ patient, drug, ผู้สั่ง, dose, status และข้อมูล override
- `FOREIGN KEY` รับประกันว่า patient, drug และ user มีอยู่จริง
- `CHECK` จำกัด severity/status และบังคับให้ override fields ครบทั้งชุดหรือไม่มีเลย
- partial unique index ป้องกัน active allergy ของ patient-drug คู่เดิมซ้ำกัน

การตรวจว่า prescription ชนกับ allergy เป็นการตรวจข้ามตาราง จึงใช้ `BEFORE INSERT OR UPDATE` trigger แทน `CHECK` ธรรมดา trigger จะ block เมื่อพบ `drug_allergies.status = 'ACTIVE'` ที่ตรงกับ patient และ drug เว้นแต่ override มีเหตุผล, เวลา, ผู้รับผิดชอบ และผู้ override มี role ที่ได้รับอนุญาต

### Workflow และ override

1. แพทย์เลือกยา ระบบตรวจ active allergy ก่อนบันทึก
2. หากพบ allergy ให้แสดงชื่อยา, reaction, severity และแหล่งประวัติอย่างชัดเจน
3. ทางเลือกหลักคือเปลี่ยนยาและตรวจซ้ำ
4. หากจำเป็นต้องใช้ยาเดิม เฉพาะ `ATTENDING_PHYSICIAN` หรือ `SENIOR_PHYSICIAN` ที่มีสิทธิ์ `ALLERGY_OVERRIDE` จึง override ได้
5. บันทึก clinical reason, เวลา, ผู้ override และ audit log; เภสัชกร hold การจ่ายยาและตรวจทานได้ แต่ไม่ bypass block
6. กรณี severe allergy ควรมี second sign-off ก่อนจ่ายยา

## ข้อ 5 — Scalable และ Private Lab Results

### Storage และ delivery

- เก็บ original DICOM/X-Ray ใน private encrypted object storage; relational database เก็บ metadata เช่น patient ID, object key, checksum และ retention class
- Lab/PACS upload โดย pre-signed URL อายุสั้นตรงไป storage แล้ว worker ตรวจไฟล์และสร้าง thumbnail/mobile derivative แบบ asynchronous
- เก็บ original ที่ diagnostic quality ไว้เสมอ หลีกเลี่ยง lossy compression ที่อาจกระทบการวินิจฉัย
- Mobile app ผ่าน authenticated API ซึ่งตรวจ RBAC และ treatment relationship ก่อนออก signed URL/cookie ให้ private internal CDN
- ใช้ derivative, HTTP range request และ progressive loading เพื่อเปิดภาพบนมือถือเร็วโดยไม่ต้องโหลด original ทุกครั้ง

### PDPA controls

- purpose limitation และ minimum necessary access: เห็นเฉพาะผู้ป่วยที่เกี่ยวข้องกับการรักษา
- TLS, encryption at rest, KMS/key rotation และไม่มี public bucket/CDN endpoint
- immutable audit log สำหรับการดู/ดาวน์โหลด พร้อม alert เมื่อเกิด bulk export
- retention/deletion policy, backup/restore test และ incident response ที่ revoke signed URL และตรวจ log ได้
- de-identify ภาพก่อนใช้ analytics, model training หรือส่ง vendor; แยก re-identification key ออกต่างหาก
