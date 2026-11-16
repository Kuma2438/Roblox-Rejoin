# Roblox Auto Rejoin — Anime Adventures

## ภาษาไทย

โปรแกรม Windows ธีม neon พร้อมแดชบอร์ดสไตล์เว็บ สำหรับเข้าเกม **Anime Adventures** และเฝ้าดูการทำงานของ Roblox Player กับการเชื่อมต่ออินเทอร์เน็ต เมื่อ Roblox ปิดหรืออินเทอร์เน็ตขาดแล้วกลับมา โปรแกรมจะพยายามเข้าเกมใหม่
หน้าโปรแกรมแสดงภาพปกเกม พร้อมแท็บ **AA** ด้านบน

### วิธีใช้งาน

1. ติดตั้ง Roblox Player และเข้าสู่ระบบ
2. ดาวน์โหลด ZIP จาก GitHub แล้วแตกไฟล์
3. ดับเบิลคลิก `RobloxRejoin.exe`
4. กด **เริ่มทำงาน** โปรแกรมจะตรวจ Roblox Player ก่อน หากเกมเปิดอยู่แล้วจะไม่เปิดซ้ำ
5. ใช้ปุ่ม **EN / ไทย** ที่มุมขวาบนเพื่อเปลี่ยนภาษา
6. กด **หยุดทำงาน** เมื่อต้องการหยุด

### สถานะและการเชื่อมต่อ

- ไฟอินเทอร์เน็ตสีเขียว/แดงแสดงผลการตรวจการเชื่อมต่อไปยัง Cloudflare (1.1.1.1:443)
- ไฟ Roblox Player สีเขียวหมายถึงพบโปรเซส Roblox Player ทำงานอยู่ สีแดงหมายถึงไม่พบโปรเซส โปรแกรมไม่สามารถยืนยันสถานะการเชื่อมต่อเซิร์ฟเวอร์จากโปรเซสเพียงอย่างเดียว
- ตรวจทุก 10 วินาที หากเน็ตขาด 3 ครั้งติดกัน จะรอจนกลับมาปกติ 2 ครั้งติดกัน แล้วเริ่มเกมใหม่
- อ่าน Roblox Player logs เพื่อตรวจว่า session เปลี่ยนจากเกมกลับสู่ Roblox app หลังเคยเข้าเกมแล้วหรือไม่ หากยังอยู่หน้าแอปต่อเนื่อง 20 วินาที จะเริ่ม Roblox ใหม่และเข้า Anime Adventures อีกครั้ง
- การตรวจ log อาศัยข้อความ transition ภายใน log ของ Roblox; การเปลี่ยนรูปแบบ log ในการอัปเดต Roblox อาจทำให้ต้องปรับตัวตรวจ
- หากเน็ตหลุด โปรแกรมจะปิด Roblox Player ที่ค้างอยู่เมื่อเน็ตกลับมา เพื่อให้เชื่อมต่อใหม่
- หาก Windows ถามว่าจะเปิด Roblox หรือไม่ ให้กดยืนยัน และต้องล็อกอิน Roblox ไว้แล้ว

### ไฟล์ในโปรแกรม

- `RobloxRejoin.exe` — โปรแกรม Windows x64 แบบไฟล์เดียว รวม runtime ไว้แล้ว
- `Program.cs` และ `RobloxRejoin.csproj` — source code และ project สำหรับ build
- `วิธีใช้งาน.txt` — คู่มือภาษาไทย

## English

A neon-themed, web-style dashboard that launches **Anime Adventures** and monitors Roblox Player and internet connectivity. It attempts to rejoin the experience if Roblox closes or the internet disconnects and comes back.
The dashboard includes the game cover art and an **AA** tab in the header.

### How to use

1. Install Roblox Player and sign in.
2. Download the repository ZIP and extract it.
3. Double-click `RobloxRejoin.exe`.
4. Click **Start**. The app checks for an existing Roblox Player first and will not launch a duplicate.
5. Use the **EN / ไทย** button in the top-right corner to switch languages.
6. Click **Stop** when you want to stop.

### Status and connectivity

- The green/red Internet light shows whether the app can reach Cloudflare (1.1.1.1:443).
- The green Roblox Player light means the Roblox Player process is running; red means it was not found. A running process alone does not confirm that the game server connection is active.
- Checks run every 10 seconds. After 3 consecutive failed internet checks, the app waits for 2 consecutive successful checks, then launches the game again.
- The app reads Roblox Player logs to detect a transition from a play session back to the Roblox app after gameplay has started. If it remains on the app screen for 20 seconds, the app restarts Roblox and rejoins Anime Adventures.
- This log-based detection depends on Roblox session transition messages; Roblox updates may change those messages and require an adjustment.
- If Roblox is still open after the outage, the app closes that Roblox Player process after the connection returns so it can reconnect.
- If Windows asks to open Roblox, confirm the prompt. Roblox must already be signed in.

### Included files

- `RobloxRejoin.exe` — standalone Windows x64 app; the .NET runtime is included
- `Assets/aa-cover.png` — Anime Adventures game cover shown in the dashboard
- `Program.cs` and `RobloxRejoin.csproj` — source code and build project
- `วิธีใช้งาน.txt` — Thai user guide
