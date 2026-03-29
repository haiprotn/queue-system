# 🏥 Hệ Thống Gọi Số Thứ Tự - Phòng Khám
### Raspberry Pi 3 • Flask • Phát âm thanh tiếng Việt

---

## Cách hoạt động

Nhân viên bấm **"Gọi số tiếp theo"** → Số tự tăng → Màn hình TV hiển thị + phát âm thanh gọi bệnh nhân.

| Trang | URL | Dùng cho |
|-------|-----|----------|
| **Nhân viên** | `/staff` | Bấm gọi số, gọi lại, nhập số cụ thể |
| **Màn hình** | `/display` | Nối TV hiển thị số + phát tiếng chuông + đọc giọng nói |

---

## Cài đặt trên Raspberry Pi

```bash
# 1. Copy thư mục queue-system vào Pi
# 2. Chạy:
cd ~/queue-system
chmod +x setup.sh
./setup.sh
```

Xong! Hệ thống tự chạy và tự khởi động cùng Pi.

---

## Sử dụng

### Nhân viên (trên điện thoại hoặc máy tính):
1. Mở `http://<IP_Pi>:5000/staff`
2. Bấm **"GỌI SỐ TIẾP THEO"** → số tự tăng 1
3. Hoặc **nhập số cụ thể** rồi bấm Gọi
4. Bấm **"Gọi lại"** nếu bệnh nhân chưa nghe
5. Bấm **"Lùi 1 số"** nếu bấm nhầm

### Màn hình TV:
1. Nối Pi với TV qua HDMI, cắm loa
2. Mở Chromium full-screen: `http://localhost:5000/display`
3. **Nhấn 1 lần** vào nút "Nhấn để bật âm thanh"
4. Khi gọi số → chuông kêu → giọng đọc: *"Mời bệnh nhân số... vui lòng đến phòng khám"*

---

## Cấu hình âm thanh Pi

```bash
# Output qua jack 3.5mm
sudo raspi-config → System Options → Audio → Headphones

# Tăng âm lượng
amixer set PCM 100%

# Test loa
speaker-test -t wav -c 2
```

---

## Tùy chỉnh

**Đổi tên phòng khám:** sửa `templates/display.html` dòng `<h1>PHÒNG KHÁM</h1>`

**Đổi câu gọi:** sửa `templates/display.html` hàm `speakNumber`, dòng `const text = ...`

**Đổi port:** sửa `app.py` dòng cuối `port=5000`

---

## Quản lý service

```bash
sudo systemctl status queue-system     # Trạng thái
sudo journalctl -u queue-system -f     # Xem log
sudo systemctl restart queue-system    # Khởi động lại
sudo systemctl stop queue-system       # Dừng
```
