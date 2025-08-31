#!/bin/bash

# Script quản lý service Giam Sat SSD
SERVICE_NAME="giam_sat_ssd"
SCRIPT_PATH="/mnt/mydisk/giam_sat_ssd/bin/giam_sat_ssd.sh"

case "$1" in
    start)
        echo "🚀 Bắt đầu service $SERVICE_NAME..."
        if pgrep -f "$SCRIPT_PATH" > /dev/null; then
            echo "⚠️  Service đã đang chạy"
            exit 1
        fi
        sudo nohup "$SCRIPT_PATH" start >/dev/null 2>&1 &
        sleep 2
        if pgrep -f "$SCRIPT_PATH" > /dev/null; then
            echo "✅ Service đã khởi động thành công"
        else
            echo "❌ Lỗi khởi động service"
            exit 1
        fi
        ;;
    stop)
        echo "🛑 Dừng service $SERVICE_NAME..."
        sudo pkill -f "$SCRIPT_PATH"
        sleep 2
        if ! pgrep -f "$SCRIPT_PATH" > /dev/null; then
            echo "✅ Service đã dừng"
        else
            echo "⚠️  Service vẫn đang chạy, thử force kill..."
            sudo pkill -9 -f "$SCRIPT_PATH"
        fi
        ;;
    restart)
        $0 stop
        sleep 3
        $0 start
        ;;
    status)
        if pgrep -f "$SCRIPT_PATH" > /dev/null; then
            echo "✅ Service $SERVICE_NAME đang chạy"
            echo "📋 Process:"
            ps aux | grep "$SCRIPT_PATH" | grep -v grep
            echo ""
            echo "📊 Logs mới nhất:"
            tail -5 /mnt/mydisk/giam_sat_ssd/logs/giam_sat_ssd.log
        else
            echo "❌ Service $SERVICE_NAME không chạy"
        fi
        ;;
    logs)
        echo "📋 Logs của service $SERVICE_NAME:"
        tail -20 /mnt/mydisk/giam_sat_ssd/logs/giam_sat_ssd.log
        ;;
    check)
        sudo "$SCRIPT_PATH" check
        ;;
    *)
        echo "Sử dụng: $0 {start|stop|restart|status|logs|check}"
        echo ""
        echo "📋 Các lệnh:"
        echo "   start   - Khởi động service"
        echo "   stop    - Dừng service"
        echo "   restart - Khởi động lại service"
        echo "   status  - Xem trạng thái service"
        echo "   logs    - Xem logs"
        echo "   check   - Kiểm tra nhiệt độ ngay"
        exit 1
        ;;
esac
