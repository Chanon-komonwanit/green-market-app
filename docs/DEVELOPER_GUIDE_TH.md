# คู่มือการใช้งานและพัฒนา Green Market (ภาษาไทย)

## 1. ภาพรวมโปรเจกต์
Green Market เป็นแอปตลาดออนไลน์ที่เน้นความยั่งยืน มีระบบครบถ้วนทั้งฝั่งผู้ใช้ ผู้ขาย และแอดมิน รองรับหลายแพลตฟอร์ม (Web, Android, iOS, Windows, Mac, Linux)

## 2. โครงสร้างไฟล์สำคัญ
- `lib/screens/my_home_screen_new.dart` : หน้าหลักของผู้ใช้ (My Home)
- `lib/screens/` : รวมหน้าต่างๆ ของแอป
- `lib/models/` : โครงสร้างข้อมูล (Model)
- `lib/providers/` : ตัวจัดการ state (Provider)
- `lib/services/` : ฟังก์ชันเชื่อมต่อ backend, Firebase
- `lib/utils/` : ฟังก์ชันช่วยเหลือ เช่น validation, error handler
- `lib/widgets/` : ส่วนประกอบ UI ที่นำกลับมาใช้ซ้ำ
- `test/` : ไฟล์ทดสอบระบบ

## 3. วิธีเริ่มต้นใช้งาน
1. ติดตั้ง Flutter และ dependencies
   ```bash
   flutter pub get
   ```
2. รันแอปบนอุปกรณ์ที่ต้องการ
   ```bash
   flutter run -d chrome # สำหรับ web
   flutter run -d android # สำหรับ Android
   flutter run -d ios # สำหรับ iOS
   ```
3. ทดสอบระบบ
   ```bash
   flutter test
   ```

## 4. การพัฒนาและแก้ไข
- เพิ่มฟีเจอร์ใหม่ในโฟลเดอร์ screens, models, providers, services ตามโครงสร้าง
- ใช้ provider สำหรับ state management
- เขียน test ทุกครั้งที่เพิ่ม logic ใหม่
- ตรวจสอบความปลอดภัยและ validation ใน utils
- เพิ่ม comment และ docstring ทุกไฟล์สำคัญ

## 5. TODO (งานที่ต้องทำต่อ)
- myh's : ปรับปรุงหน้าหลัก My Home ให้ทันสมัยและ responsive มากขึ้น
- fmuj : ตรวจสอบและปรับปรุงระบบฟอร์ม (Form) ให้รองรับ validation ที่ซับซ้อน
- udHgs : เพิ่มระบบอัปเดตข้อมูลแบบ real-time และ error handling ที่ครอบคลุม
- nvodyo : พัฒนา UI/UX ให้สวยงามและใช้งานง่ายขึ้นในทุกหน้าหลัก

## 6. ข้อควรระวัง
- อย่าลืมตรวจสอบ Firestore rules และ API keys ทุกครั้งก่อน deploy
- ทดสอบบนหลายอุปกรณ์และ platform
- สำรองข้อมูลและตรวจสอบ log เป็นประจำ

## 7. ติดต่อ/ขอความช่วยเหลือ
- ดูรายละเอียดเพิ่มเติมใน README.md, MAINTENANCE_GUIDE.md, SECURITY_SETUP_GUIDE.md
- หากพบปัญหา ติดต่อทีมพัฒนาได้ที่ [email หรือช่องทางที่กำหนด]

## 8. ข้อเสนอแนะ/สิ่งที่ควรทำต่อ (แนะนำสำหรับทีมพัฒนา)

1. เพิ่มระบบสลับธีม (Dark/Light Theme Toggle)
   - ให้ผู้ใช้เลือกธีมที่ต้องการ เพิ่มความสะดวกและรองรับทุกสภาพแสง
2. เพิ่มการตั้งค่าฟอนต์ (Custom Fonts)
   - รองรับฟอนต์ไทยและฟอนต์เฉพาะกลุ่ม เพิ่มความสวยงามและความเป็นเอกลักษณ์
3. รองรับหลายภาษา (Multi-language Support)
   - เพิ่มภาษาอังกฤษ/ไทย และภาษาอื่นๆ เพื่อขยายกลุ่มผู้ใช้
4. เพิ่มระบบวิเคราะห์ข้อมูล (Analytics Dashboard)
   - ติดตามพฤติกรรมผู้ใช้ ยอดขาย และประสิทธิภาพระบบ
5. เพิ่มระบบบันทึกกิจกรรม (Audit Log)
   - ตรวจสอบการเปลี่ยนแปลงและกิจกรรมสำคัญในระบบ
6. เพิ่มระบบตรวจสอบประสิทธิภาพ (Performance Monitoring)
   - ตรวจสอบเวลาโหลด, การเปลี่ยนหน้าจอ, การ query Firebase
7. เพิ่มระบบแจ้งเตือนข้อผิดพลาด (Crashlytics)
   - ตรวจสอบ error ที่เกิดขึ้นจริงใน production
8. ตรวจสอบความปลอดภัยและประสิทธิภาพอย่างต่อเนื่อง
   - ทบทวน Firestore rules, API keys, input validation, และ performance ทุกเดือน
9. อัปเดต dependencies และ security rules ตามรอบเวลา
   - ใช้คำสั่ง `flutter pub upgrade` และตรวจสอบ changelog ของแต่ละ package

**หมายเหตุ:** ข้อเสนอแนะเหล่านี้จะช่วยให้แอปมีความทันสมัย ปลอดภัย และรองรับการเติบโตในอนาคต

---
**หมายเหตุ:** ทุกส่วนของคู่มือมีภาษาไทยกำกับเพื่อให้เข้าใจง่ายและเหมาะกับทีมพัฒนาไทย
