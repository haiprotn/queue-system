#!/usr/bin/env python3
"""
Hệ thống gọi số thứ tự - Phòng khám
Nhân viên bấm gọi số trực tiếp
Chạy trên Raspberry Pi 3 với Flask + Socket.IO
"""

from flask import Flask, render_template, jsonify, request
from flask_socketio import SocketIO, emit
from datetime import datetime
import json
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = 'phongkham-queue-secret-2024'
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# ===== DỮ LIỆU =====
queue_data = {
    "current_number": 0,
    "history": [],
    "start_date": datetime.now().strftime("%Y-%m-%d"),
}

DATA_FILE = "queue_state.json"

def save_state():
    with open(DATA_FILE, 'w') as f:
        json.dump(queue_data, f, ensure_ascii=False, default=str)

def load_state():
    global queue_data
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            saved = json.load(f)
            if saved.get("start_date") != datetime.now().strftime("%Y-%m-%d"):
                reset_queue()
            else:
                queue_data.update(saved)

def reset_queue():
    queue_data.update({
        "current_number": 0,
        "history": [],
        "start_date": datetime.now().strftime("%Y-%m-%d"),
    })
    save_state()


# ===== ROUTES =====

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/staff')
def staff_page():
    return render_template('staff.html')

@app.route('/display')
def display_page():
    return render_template('display.html')


# ===== API =====

@app.route('/api/call-next', methods=['POST'])
def call_next():
    """Gọi số tiếp theo (tự tăng)"""
    queue_data["current_number"] += 1
    number = queue_data["current_number"]
    queue_data["history"].append({
        "number": number,
        "time": datetime.now().strftime("%H:%M:%S"),
    })
    save_state()

    info = get_info()
    info["action"] = "calling"
    socketio.emit('number_called', info)
    return jsonify({"success": True, "calling": number})

@app.route('/api/call-specific', methods=['POST'])
def call_specific():
    """Gọi một số cụ thể (nhập tay)"""
    data = request.get_json()
    number = data.get("number", 0)
    if number <= 0:
        return jsonify({"success": False, "message": "Số không hợp lệ"})

    if number > queue_data["current_number"]:
        queue_data["current_number"] = number

    queue_data["history"].append({
        "number": number,
        "time": datetime.now().strftime("%H:%M:%S"),
    })
    save_state()

    info = get_info()
    info["calling_number"] = number
    info["action"] = "calling"
    socketio.emit('number_called', info)
    return jsonify({"success": True, "calling": number})

@app.route('/api/recall', methods=['POST'])
def recall():
    """Gọi lại số hiện tại"""
    if queue_data["current_number"] == 0:
        return jsonify({"success": False, "message": "Chưa có số nào"})

    info = get_info()
    info["action"] = "calling"
    socketio.emit('number_called', info)
    return jsonify({"success": True, "calling": queue_data["current_number"]})

@app.route('/api/go-back', methods=['POST'])
def go_back():
    """Lùi lại 1 số"""
    if queue_data["current_number"] > 1:
        queue_data["current_number"] -= 1
        save_state()
        info = get_info()
        info["action"] = "calling"
        socketio.emit('number_called', info)
        return jsonify({"success": True, "calling": queue_data["current_number"]})
    return jsonify({"success": False, "message": "Đã là số đầu tiên"})

@app.route('/api/reset', methods=['POST'])
def reset():
    reset_queue()
    socketio.emit('queue_updated', get_info())
    return jsonify({"success": True})

@app.route('/api/status')
def status():
    return jsonify(get_info())


def get_info():
    return {
        "calling_number": queue_data["current_number"],
        "total_called": len(queue_data["history"]),
        "history": queue_data["history"][-10:][::-1],
    }


@socketio.on('connect')
def handle_connect():
    emit('queue_updated', get_info())


if __name__ == '__main__':
    load_state()
    print("=" * 50)
    print("  HỆ THỐNG GỌI SỐ THỨ TỰ - PHÒNG KHÁM")
    print("=" * 50)
    print(f"  Nhân viên:  http://<IP_PI>:5000/staff")
    print(f"  Màn hình:   http://<IP_PI>:5000/display")
    print("=" * 50)

    socketio.run(
        app,
        host='0.0.0.0',
        port=5000,
        debug=False,
        allow_unsafe_werkzeug=True
    )
