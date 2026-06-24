# ข้อ 1–3 — Technical & High-Stakes Logic

เอกสารนี้เป็น technical reference ของคำตอบใน [README](../README.md) โดยยึด source code และ SQL ใน repository เป็นแหล่งข้อมูลเดียว (single source of truth)

## ข้อ 1 — Intelligent Priority Queue

โค้ดอยู่ที่ [`src/priority_queue.py`](../src/priority_queue.py) และ test อยู่ที่ [`tests/test_priority_queue.py`](../tests/test_priority_queue.py)

- แบ่งเป็น 2 tier: `EMERGENCY` มาก่อน `NORMAL` เสมอ
- ภายใน tier เดียวกันใช้ `severity` 1–10 จากมากไปน้อย
- Normal ที่รออย่างน้อย 60 นาทีได้รับคะแนน boost 10 เพื่อป้องกัน starvation แต่ไม่แซง Emergency จริง
- คะแนนเท่ากันใช้เวลามาถึงก่อนเป็น tie-breaker

`get_urgent_patient(queue, current_time)` เรียก `order_patients()` แล้วคืนคนแรก หรือ `None` เมื่อคิวว่าง โค้ดที่เรียงทั้งคิวมี complexity `O(n log n)` และ memory `O(n)` จึงเหมาะกับ triage board ที่มี 10,000 คน หากต้องการเพียงคนถัดไปในระบบขนาดใหญ่มาก สามารถใช้ one-pass scan `O(n)` หรือ priority queue/heap ได้

## ข้อ 2 — Doctor's Availability

SQL อยู่ที่ [`sql/doctor-availability.sql`](../sql/doctor-availability.sql) และใช้ CTE 4 ชุด:

1. `request` สร้างช่วงเวลา 19 มีนาคม 2026, 10:00–11:00
2. `working_doctors` หาแพทย์ที่กะ `WORK` ครอบคลุมทั้งช่วง
3. `break_doctors` หาแพทย์ที่กะ `BREAK` ทับช่วง
4. `booked_doctors` หาแพทย์ที่มีนัด `confirmed` ทับช่วง

Query สุดท้าย `JOIN working_doctors` และ `LEFT JOIN` อีกสองกลุ่ม จากนั้นเลือกเฉพาะ `break_doctors` และ `booked_doctors` ที่เป็น `NULL`

เงื่อนไข overlap ใช้ interval แบบ half-open `[start, end)`:

```sql
existing.starts_at < request.ends_at
AND existing.ends_at > request.starts_at
```

จึงตรวจได้แม้นัดเดิมเริ่ม 09:30 และสิ้นสุด 10:30 ซึ่งทับกับช่วงค้นหา 10:00–11:00

ควรมี index ที่ `appointments(doctor_id, starts_at, ends_at)` สำหรับ `status = 'confirmed'` และ `doctor_shifts(doctor_id, starts_at, ends_at)` เพื่อรองรับข้อมูลนัดหมายจำนวนมาก

## ข้อ 3 — Insurance Claim: Injection และ Race Condition

โค้ดอยู่ที่ [`src/claim_insurance.py`](../src/claim_insurance.py) และ test อยู่ที่ [`tests/test_claim_insurance.py`](../tests/test_claim_insurance.py)

ปัญหาเดิมมี 2 ส่วน:

- **SQL Injection:** การต่อ `patientId` หรือ `treatmentCost` เข้า SQL string เปิดโอกาสให้ input เปลี่ยนความหมาย query
- **Race Condition:** สอง request อ่านวงเงินเดียวกันก่อน update จึงอาจอนุมัติยอดรวมเกินวงเงินจริง

แนวทางแก้คือเริ่ม transaction แล้ว lock แถวผู้ป่วยก่อนอ่านวงเงิน:

```sql
SELECT insurance_limit
FROM patients
WHERE id = %s
FOR UPDATE;
```

หลัง lock แล้วจึงตรวจวงเงินและ update ด้วย bound parameters:

```sql
UPDATE patients
SET insurance_limit = insurance_limit - %s
WHERE id = %s;
```

request ที่สองของผู้ป่วยคนเดิมต้องรอ lock และจะอ่านวงเงินล่าสุดหลัง request แรก commit จึงไม่เกิด lost update หรือ overspend ต้องเพิ่ม idempotency key และ audit log ใน production เพื่อป้องกัน retry ซ้ำและรองรับการตรวจสอบย้อนหลัง
