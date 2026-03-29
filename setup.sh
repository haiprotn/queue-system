#!/bin/bash
# ============================================
#  CÀI ĐẶT HỆ THỐNG GỌI SỐ THỨ TỰ
#  Dành cho Raspberry Pi 3
# ============================================
set -e

echo "=========================================="
echo "  CÀI ĐẶT HỆ THỐNG GỌI SỐ THỨ TỰ"
echo "=========================================="

echo "[1/4] Cập nhật hệ thống..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv

echo "[2/4] Tạo môi trường Python..."
cd "$(dirname "$0")"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "[3/4] Tạo service tự khởi động..."
WORK_DIR=$(pwd)
sudo tee /etc/systemd/system/queue-system.service > /dev/null <<EOF
[Unit]
Description=Queue Number System
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/venv/bin/python app.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable queue-system
sudo systemctl start queue-system

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=========================================="
echo "  CÀI ĐẶT THÀNH CÔNG!"
echo "=========================================="
echo ""
echo "  👨‍⚕️ Nhân viên:  http://$IP:5000/staff"
echo "  📺 Màn hình:   http://$IP:5000/display"
echo ""
echo "  Quản lý:"
echo "  - Log:      sudo journalctl -u queue-system -f"
echo "  - Restart:  sudo systemctl restart queue-system"
echo "  - Dừng:     sudo systemctl stop queue-system"
echo "=========================================="
