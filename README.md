# Roblox Auto Rejoin — Anime Adventures

## ภาษาไทย

โปรแกรม Windows สำหรับเข้าเกม **Anime Adventures** และเฝ้าดูการทำงานของ Roblox Player กับการเชื่อมต่ออินเทอร์เน็ต เมื่อ Roblox ปิดหรืออินเทอร์เน็ตขาดแล้วกลับมา โปรแกรมจะพยายามเข้าเกมใหม่

### วิธีใช้งาน

1. ติดตั้ง Roblox Player และเข้าสู่ระบบ
2. ดาวน์โหลด ZIP จาก GitHub แล้วแตกไฟล์
3. ดับเบิลคลิก `Start Auto Join.bat`
4. กด **เริ่มเฝ้าดูและเข้าเกม** โปรแกรมจะตรวจ Roblox Player ก่อน หากเกมเปิดอยู่แล้วจะไม่เปิดซ้ำ
5. ใช้ปุ่ม **EN / ไทย** ที่มุมขวาบนเพื่อเปลี่ยนภาษา
6. กด **หยุดเฝ้าดู** เมื่อต้องการหยุด

### สถานะและการเชื่อมต่อ

- ไฟอินเทอร์เน็ตสีเขียว/แดงแสดงผลการตรวจการเชื่อมต่อไปยัง Cloudflare (1.1.1.1:443)
- ไฟ Roblox Player สีเขียวหมายถึงพบโปรเซส Roblox Player ทำงานอยู่ สีแดงหมายถึงไม่พบโปรเซส โปรแกรมไม่สามารถยืนยันสถานะการเชื่อมต่อเซิร์ฟเวอร์จากโปรเซสเพียงอย่างเดียว
- ตรวจทุก 10 วินาที หากเน็ตขาด 3 ครั้งติดกัน จะรอจนกลับมาปกติ 2 ครั้งติดกัน แล้วเริ่มเกมใหม่
- หากเน็ตหลุด โปรแกรมจะปิด Roblox Player ที่ค้างอยู่เมื่อเน็ตกลับมา เพื่อให้เชื่อมต่อใหม่
- หาก Windows ถามว่าจะเปิด Roblox หรือไม่ ให้กดยืนยัน และต้องล็อกอิน Roblox ไว้แล้ว

### ไฟล์ในโปรแกรม

- `AutoJoinRoblox.ps1` — โปรแกรมพร้อมหน้าต่างควบคุม
- `Start Auto Join.bat` — ตัวเปิดโปรแกรม
- `วิธีใช้งาน.txt` — คู่มือภาษาไทย

## English

A Windows utility that launches **Anime Adventures** and monitors Roblox Player and internet connectivity. It attempts to rejoin the experience if Roblox closes or the internet disconnects and comes back.

### How to use

1. Install Roblox Player and sign in.
2. Download the repository ZIP and extract it.
3. Double-click `Start Auto Join.bat`.
4. Click **Start monitoring**. The app checks for an existing Roblox Player first and will not launch a duplicate.
5. Use the **EN / ไทย** button in the top-right corner to switch languages.
6. Click **Stop monitoring** when you want to stop.

### Status and connectivity

- The green/red Internet light shows whether the app can reach Cloudflare (1.1.1.1:443).
- The green Roblox Player light means the Roblox Player process is running; red means it was not found. A running process alone does not confirm that the game server connection is active.
- Checks run every 10 seconds. After 3 consecutive failed internet checks, the app waits for 2 consecutive successful checks, then launches the game again.
- If Roblox is still open after the outage, the app closes that Roblox Player process after the connection returns so it can reconnect.
- If Windows asks to open Roblox, confirm the prompt. Roblox must already be signed in.

### Included files

- `AutoJoinRoblox.ps1` — app and control window
- `Start Auto Join.bat` — app launcher
- `วิธีใช้งาน.txt` — Thai user guide
