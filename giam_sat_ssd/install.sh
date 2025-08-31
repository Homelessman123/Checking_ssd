#!/bin/bash

# ==========================================
# Giam Sat SSD - Script Cài Đặt
# ==========================================

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TARGET_DIR="/mnt/mydisk/giam_sat_ssd"
SERVICE_NAME="giam_sat_ssd"

echo "🚀 Bắt đầu cài đặt Giam Sat SSD..."

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Script này cần chạy với quyền root!"
    echo "Sử dụng: sudo $0"
    exit 1
fi

# Kiểm tra mount point tồn tại
if [[ ! -d "/mnt/mydisk" ]]; then
    echo "❌ Mount point /mnt/mydrive không tồn tại!"
    echo "Vui lòng mount thiết bị trước khi cài đặt."
    exit 1
fi

# Set permissions
echo "🔒 Thiết lập quyền..."
chmod +x "$TARGET_DIR/bin/giam_sat_ssd.sh"
chmod 644 "$TARGET_DIR/config/giam_sat_ssd.conf"
chmod 755 "$TARGET_DIR/logs"

# Install systemd service
echo "⚙️  Cài đặt systemd service..."
cp "$TARGET_DIR/giam_sat_ssd.service" "/etc/systemd/system/"
systemctl daemon-reload

# Tạo symbolic link để dễ sử dụng
echo "🔗 Tạo symbolic link..."
ln -sf "$TARGET_DIR/bin/giam_sat_ssd.sh" "/usr/local/bin/giam_sat_ssd"

# Kiểm tra smartmontools
if ! command -v smartctl >/dev/null 2>&1; then
    echo "📦 Cài đặt smartmontools..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y smartmontools
    elif command -v yum >/dev/null 2>&1; then
        yum install -y smartmontools
    else
        echo "⚠️  Vui lòng cài đặt smartmontools thủ công"
    fi
fi

echo "✅ Cài đặt hoàn tất!"
echo ""
echo "📋 Cách sử dụng:"
echo "   sudo giam_sat_ssd check       # Kiểm tra nhiệt độ"
echo "   sudo giam_sat_ssd start       # Bắt đầu giám sát"
echo "   sudo giam_sat_ssd status      # Xem trạng thái"
echo "   sudo giam_sat_ssd stop        # Dừng giám sát"
echo ""
echo "📋 Systemd service:"
echo "   sudo systemctl enable $SERVICE_NAME    # Bật tự động khởi động"
echo "   sudo systemctl start $SERVICE_NAME     # Bắt đầu service"
echo "   sudo systemctl status $SERVICE_NAME    # Xem trạng thái service"
echo ""
echo "📁 Thư mục cấu hình: $TARGET_DIR/config/giam_sat_ssd.conf"
echo "📁 Thư mục log: $TARGET_DIR/logs/"

# Test installation
echo ""
echo "🧪 Test installation..."
if giam_sat_ssd check; then
    echo "✅ Test thành công!"
else
    echo "⚠️  Test không thành công, vui lòng kiểm tra cấu hình"
fi
