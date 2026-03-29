#!/bin/bash
# ==========================================================
#  Thiết lập tự động khởi động - Hệ thống gọi số thứ tự
#  Chạy script này 1 lần trên Raspberry Pi
#  Lệnh: bash setup_autostart.sh
# ==========================================================

USER_NAME=$(whoami)
HOME_DIR=$HOME
PROJECT_DIR="$HOME_DIR/queue-system/queue-system"
VENV_PYTHON="$HOME_DIR/venv/bin/python3"

echo "=================================================="
echo "  THIẾT LẬP TỰ ĐỘNG KHỞI ĐỘNG"
echo "  User: $USER_NAME"
echo "  Project: $PROJECT_DIR"
echo "=================================================="

# ----------------------------------------------------------
# 1. Tạo systemd service cho Flask server
# ----------------------------------------------------------
echo "[1/3] Tạo systemd service..."

sudo tee /etc/systemd/system/queue-system.service > /dev/null <<EOF
[Unit]
Description=Queue System - He thong goi so thu tu
After=network.target

[Service]
User=$USER_NAME
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_PYTHON app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable queue-system.service
sudo systemctl start queue-system.service
echo "    OK: Flask server se tu dong chay khi khoi dong."

# ----------------------------------------------------------
# 2. Tắt screensaver / chế độ ngủ màn hình
# ----------------------------------------------------------
echo "[2/3] Tat screensaver va ngu man hinh..."

mkdir -p "$HOME_DIR/.config/lxsession/LXDE-pi"
AUTOSTART_FILE="$HOME_DIR/.config/lxsession/LXDE-pi/autostart"

# Giữ lại nội dung cũ nếu có, xóa các dòng cũ của script này
if [ -f "$AUTOSTART_FILE" ]; then
    grep -v "xset\|chromium\|unclutter\|queue" "$AUTOSTART_FILE" > /tmp/autostart_clean
    cp /tmp/autostart_clean "$AUTOSTART_FILE"
else
    echo "@lxpanel --profile LXDE-pi" > "$AUTOSTART_FILE"
    echo "@pcmanfm --desktop --profile LXDE-pi" >> "$AUTOSTART_FILE"
fi

# Tắt screensaver, màn hình không tắt
cat >> "$AUTOSTART_FILE" <<EOF

# --- Queue System ---
@xset s off
@xset -dpms
@xset s noblank
@unclutter -idle 0 -root
EOF

echo "    OK: Man hinh se khong tat."

# ----------------------------------------------------------
# 3. Mở Chromium kiosk full screen sau khi Flask khởi động
# ----------------------------------------------------------
echo "[3/3] Cau hinh Chromium kiosk mode..."

cat >> "$AUTOSTART_FILE" <<EOF
@bash -c 'sleep 5 && chromium-browser --noerrdialogs --disable-infobars --kiosk http://localhost:5000/display'
EOF

# Tắt thông báo "Chromium không tắt đúng cách"
mkdir -p "$HOME_DIR/.config/chromium/Default"
cat > "$HOME_DIR/.config/chromium/Default/Preferences" <<'EOF'
{
   "profile": {
      "exit_type": "Normal",
      "exited_cleanly": true
   }
}
EOF

echo "    OK: Chromium se mo full screen sau 5 giay."

# ----------------------------------------------------------
# Cài unclutter (ẩn chuột)
# ----------------------------------------------------------
if ! command -v unclutter &> /dev/null; then
    echo "Cai unclutter (an chuot)..."
    sudo apt-get install -y unclutter -q
fi

echo ""
echo "=================================================="
echo "  HOAN TAT! Khoi dong lai Pi de kiem tra:"
echo "  sudo reboot"
echo "=================================================="
