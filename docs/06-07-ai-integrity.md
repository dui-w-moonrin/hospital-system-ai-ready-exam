# ข้อ 6–7 — AI Integrity

เอกสารนี้เป็น safety reference ที่สอดคล้องกับคำตอบใน [README](../README.md)

## ข้อ 6 — Symptom to Structured Data

LLM ทำหน้าที่เป็น text extraction component เท่านั้น ไม่ใช่ระบบวินิจฉัยโรคหรือแนะนำการรักษา

### Output contract

อนุญาตเฉพาะ field ที่มีหลักฐานจากข้อความผู้ป่วย:

```json
{
  "symptoms": [{"text": "string", "duration_hours": "number|null"}],
  "food_intake": ["string"],
  "medications_mentioned": ["string"],
  "negated_symptoms": ["string"],
  "needs_clinician_review": true
}
```

สำหรับข้อความ “ปวดท้องบิดๆ มา 2 ชั่วโมง กินส้มตำปูปลาร้ามา” ผลลัพธ์ต้องมีเพียงอาการ, ระยะเวลา และอาหารที่กล่าวถึง ห้ามเพิ่ม diagnosis เช่นอาหารเป็นพิษ หรือตั้งชื่อยาที่ไม่ได้กล่าวถึง

### Hallucination controls

- system prompt ห้าม diagnose, infer cause, recommend treatment/medicine และกำหนดให้คืน JSON only
- schema validation ปฏิเสธ key เกิน, type ผิด หรือ JSON ที่ parse ไม่ได้
- content policy ปฏิเสธ diagnosis/advice/unsupported facts แม้ JSON จะ valid
- ข้อความผู้ป่วยเป็น untrusted data ใน delimiter เพื่อลด prompt injection
- `needs_clinician_review` เป็น true เสมอ; clinician ตรวจและแก้ผลก่อนใช้ทางคลินิก
- เก็บ raw message, model/prompt version, output และผู้แก้ไขเพื่อ audit

## ข้อ 7 — Smart Drug Interaction Checker

### Role separation

- **Versioned rule engine + curated knowledge base:** ให้ deterministic safety result เช่น contraindication และ severity
- **Evidence retrieval:** ดึงหลักฐานที่มี source ID และ version
- **LLM:** สร้างคำอธิบายจากหลักฐานที่ retrieve มาได้เท่านั้น
- **Clinician/pharmacist:** approve, เปลี่ยนยา หรือ override และรับผิดชอบผลทางคลินิก

LLM ไม่สามารถสร้าง interaction ใหม่, อนุมัติใบสั่งยา หรือแนะนำยาเอง ข้อมูลที่ส่งเข้า model ต้อง minimum necessary และ pseudonymised เท่าที่ทำได้

### Low-confidence และ human-in-the-loop

หาก rule engine พบ high-severity interaction ให้ block การอนุมัติอัตโนมัติ หาก AI confidence ต่ำ, citation ไม่ครบ, schema ไม่ผ่าน หรือ model/retrieval ล่ม ให้ fail safe: ไม่สรุปว่าปลอดภัย, แสดง deterministic result/evidence ที่มี และส่ง clinician หรือ pharmacist review

ทุก decision และ override ต้องเก็บ reason, ผู้ตัดสินใจ, เวลา, rule/evidence version และ audit log การเปลี่ยน model/knowledge base ต้องมี evaluation, versioning, monitoring, rollback และติดตาม severe-interaction sensitivity, false-alert burden, citation validity และ override outcome
