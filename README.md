# คำตอบข้อสอบ Hospital System — AI-Ready

> คำตอบสำหรับแบบทดสอบ Fullstack Developer (Specialized: Hospital System)

Repository นี้เน้นการออกแบบระบบที่ปลอดภัย อธิบายเหตุผลได้ และนำไปพัฒนาต่อได้จริง มากกว่าการสร้างหน้าจอที่ยังทำไม่เสร็จ มีตัวอย่างโค้ดสำหรับระบบคิวและการตัดวงเงินประกัน, SQL สำหรับหาแพทย์ว่าง และเอกสารคำตอบครบทั้ง 7 ข้อ

## โจทย์ข้อสอบ

### ส่วนที่ 1 — Technical & High-Stakes Logic (40 คะแนน)

1. **The Intelligent Priority Queue (15 คะแนน)**
   - เขียน `getUrgentPatient(queue, currentTime)`
   - Emergency (E) ต้องมาก่อน Normal (N) เสมอ
   - ถ้าอยู่กลุ่มเดียวกัน ให้ผู้ที่มี Severity Score (1–10) สูงกว่าได้รับการรักษาก่อน
   - Normal ที่รอเกิน 60 นาที จะถูกขยับ Priority ขึ้นมาเทียบเท่า Emergency ชั่วคราว
   - วิเคราะห์ Time Complexity เมื่อคิวมี 10,000 คน

2. **Complex SQL — Doctor's Availability (10 คะแนน)**
   - หาแพทย์ว่างในวันที่ 19 มีนาคม 2026 เวลา 10:00–11:00
   - ต้องไม่มีนัดที่ `status = 'confirmed'` ในช่วงดังกล่าว
   - ต้องไม่อยู่ในช่วงพักกะจากตาราง `doctor_shifts`
   - ต้องรองรับนัดก่อนหน้าที่เวลาล้นมาทับช่วง 10:00

3. **Code Review — The Race Condition (15 คะแนน)**
   - แก้โค้ดตัดวงเงินประกัน เมื่อมีการเบิกจาก 2 เครื่องพร้อมกัน
   - ระบุปัญหา SQL Injection และ Race Condition
   - เขียนใหม่ด้วย Database Transaction และ Row-level Locking (`SELECT FOR UPDATE`)

### ส่วนที่ 2 — Business Architecture & Safety (30 คะแนน)

4. **Drug Allergy & Safety Design (15 คะแนน)**
   - ออกแบบตาราง `drug_allergies` และ `prescriptions`
   - ระบุ Database Constraint ที่ป้องกันใบสั่งยาสำหรับยาที่ผู้ป่วยแพ้
   - อธิบาย Alert และผู้มีสิทธิ์ Override

5. **System Scalability — Lab Results (15 คะแนน)**
   - ออกแบบการจัดเก็บภาพ X-Ray ความละเอียดสูง และการส่งผล Lab ให้ลื่นบนมือถือ เช่น compression หรือ CDN ภายใน
   - อธิบายมาตรการ PDPA เพื่อไม่ให้ผล Lab รั่วไหลออกนอกองค์กร

### ส่วนที่ 3 — AI Integrity (30 คะแนน)

6. **Symptom to Structured Data (10 คะแนน)**
   - เขียน Prompt เพื่อแปลงข้อความเป็น JSON: _“ปวดท้องบิดๆ มา 2 ชั่วโมง กินส้มตำปูปลาร้ามา”_
   - ป้องกัน AI วินิจฉัยโรคเอง (Hallucination) และบังคับให้ตอบเฉพาะข้อมูลที่ผู้ป่วยให้มา

7. **Smart Drug Interaction Checker (20 คะแนน)**
   - วาด Diagram การเชื่อมต่อระหว่างฐานข้อมูลยากับ AI Model
   - ออกแบบ Human-in-the-loop เมื่อ AI ให้คำแนะนำที่ไม่มั่นใจ

## แผนที่คำตอบใน Repository

| ข้อ | ไฟล์คำตอบ |
|---|---|
| 1. Intelligent Priority Queue | `src/priority_queue.py`, `tests/test_priority_queue.py` — ฟังก์ชัน `get_urgent_patient` |
| 2. Doctor availability SQL | `sql/doctor-availability.sql` |
| 3. Race condition / SQL injection | `src/claim_insurance.py`, `docs/01-03-technical.md` |
| 4–5. Drug safety และ Lab scalability | `docs/04-05-business-safety.md` |
| 6–7. AI integrity | `docs/06-07-ai-integrity.md` |

## วิธีรันตัวอย่างโค้ด

```powershell
python -m unittest discover -s tests -v
```

ชุดทดสอบใช้ Python standard library จึงไม่ต้องติดตั้ง dependency เพิ่ม ครอบคลุมการจัดลำดับ Emergency, การยกระดับผู้ป่วยที่รอนาน, การตรวจ input และการป้องกันค่า ID ที่มีลักษณะเป็น SQL Injection

## สมมติฐานสำคัญในการออกแบบ

- เวลาในฐานข้อมูลเก็บเป็น `timestamptz` แบบ UTC และแสดงผลเป็นเขตเวลา `Asia/Bangkok`
- ช่วงเวลานัดหมายใช้รูปแบบ `[starts_at, ends_at)` จึงอนุญาตให้นัดหนึ่งจบพอดีกับอีกนัดเริ่มได้
- AI ไม่มีสิทธิ์ตัดสินใจทางคลินิกขั้นสุดท้าย ทำหน้าที่ได้เฉพาะสกัดข้อมูล ค้นหลักฐาน และอธิบายผล; บุคลากรที่มีคุณสมบัติต้องเป็นผู้อนุมัติ
- Normal ที่รอเกิน 60 นาทีถูกยกระดับเหนือ Normal ที่เพิ่งมา แต่ไม่แซง Emergency

## การใช้ AI และความรับผิดชอบของมนุษย์

AI ถูกใช้เป็นเครื่องมือช่วยร่างและตรวจทานเท่านั้น คำตอบสุดท้ายกำหนด assumption ชัดเจน ใช้กฎที่คาดเดาได้กับส่วนที่มีความเสี่ยงสูง, parameterized SQL, schema validation, audit trail และ human approval gate ซึ่งสำคัญกว่าการเพิ่ม LLM เข้าระบบเพียงอย่างเดียว
