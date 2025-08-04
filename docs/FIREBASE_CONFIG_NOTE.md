# Firebase Config Note

หากเกิดปัญหาเชื่อมต่อ Firebase บน Android หรือ Linux:
- ตรวจสอบค่า apiKey, appId, messagingSenderId, projectId, storageBucket ในไฟล์ lib/firebase_options.dart
- ค่าทั้งหมดควรตรงกับที่ตั้งค่าใน Firebase Console ของโปรเจกต์ green-market-32046
- หากไม่ตรง ให้คัดลอกค่าจากหน้า Firebase Console มาใส่ใหม่
- หลังแก้ไขแล้วให้ build/deploy ใหม่

หมายเหตุ: ค่านี้ถูกตั้งตามข้อมูลล่าสุดที่มีในวันที่ 22 ก.ค. 2025

หากยังมีปัญหา ให้ตรวจสอบสิทธิ์ Firebase, network, และ error log เพิ่มเติม
