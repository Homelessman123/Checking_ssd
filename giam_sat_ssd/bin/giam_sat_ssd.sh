#!/bin/bash

# ==========================================
# Giam Sat SSD - SSD Temperature Monitor
# ==========================================
# Giám sát nhiệt độ SSD và tự động shutdown khi vượt quá ngưỡng
# Author: System Administrator
# Version: 1.0
# ==========================================

# Cấu hình
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/giam_sat_ssd.conf"
LOG_FILE="$PROJECT_DIR/logs/giam_sat_ssd.log"
PID_FILE="/run/giam_sat_ssd.pid"

# Đọc cấu hình
source "$CONFIG_FILE" 2>/dev/null || {
    echo "Không thể đọc file cấu hình: $CONFIG_FILE"
    exit 1
}

# Hàm ghi log
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Hàm lấy nhiệt độ SSD
get_ssd_temperature() {
    local mount_point="$1"
    local device=$(df "$mount_point" 2>/dev/null | tail -1 | awk '{print $1}')
    
    if [[ -z "$device" ]]; then
        log_message "ERROR" "Không thể xác định thiết bị cho mount point: $mount_point"
        return 1
    fi
    
    # Lấy nhiệt độ từ smartctl
    local temp=$(sudo smartctl -A "$device" 2>/dev/null | grep -i "temperature" | head -1 | awk '{print $2}')
    
    if [[ -z "$temp" || ! "$temp" =~ ^[0-9]+$ ]]; then
        log_message "WARN" "Không thể đọc nhiệt độ từ smartctl, thử phương pháp khác..."
        
        # Thử phương pháp khác nếu smartctl không hoạt động
        temp=$(sudo smartctl -A "$device" 2>/dev/null | grep -E "(Temperature|Temp)" | head -1 | grep -o '[0-9]\+' | head -1)
        
        if [[ -z "$temp" || ! "$temp" =~ ^[0-9]+$ ]]; then
            log_message "ERROR" "Không thể đọc nhiệt độ SSD"
            return 1
        fi
    fi
    
    echo "$temp"
}

# Hàm kiểm tra nhiệt độ và thực hiện hành động
check_temperature() {
    local temp=$(get_ssd_temperature "$MONITOR_PATH")
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Lỗi khi đọc nhiệt độ"
        return 1
    fi
    
    log_message "INFO" "Nhiệt độ hiện tại: ${temp}°C (Ngưỡng: ${TEMP_THRESHOLD}°C)"
    
    # Kiểm tra cảnh báo
    if [[ $temp -ge $WARNING_THRESHOLD ]]; then
        log_message "WARN" "CẢNH BÁO: Nhiệt độ cao (${temp}°C) - Gần đạt ngưỡng shutdown!"
        
        # Gửi thông báo nếu có
        if command -v wall >/dev/null 2>&1; then
            echo "CẢNH BÁO SSD: Nhiệt độ ${temp}°C - Gần đạt ngưỡng shutdown ${TEMP_THRESHOLD}°C!" | wall
        fi
    fi
    
    # Kiểm tra ngưỡng shutdown
    if [[ $temp -ge $TEMP_THRESHOLD ]]; then
        log_message "CRITICAL" "NHIỆT ĐỘ VƯỢT NGƯỠNG: ${temp}°C >= ${TEMP_THRESHOLD}°C"
        log_message "CRITICAL" "Bắt đầu quy trình shutdown an toàn..."
        
        # Gửi thông báo khẩn cấp
        if command -v wall >/dev/null 2>&1; then
            echo "KHẨN CẤP: Nhiệt độ SSD ${temp}°C vượt ngưỡng! Hệ thống sẽ shutdown trong $SHUTDOWN_DELAY giây!" | wall
        fi
        
        # Đếm ngược shutdown
        log_message "CRITICAL" "Shutdown sau $SHUTDOWN_DELAY giây..."
        sleep "$SHUTDOWN_DELAY"
        
        log_message "CRITICAL" "Thực hiện shutdown ngay bây giờ!"
        
        # Thực hiện shutdown
        if [[ "$DRY_RUN" == "true" ]]; then
            log_message "INFO" "DRY RUN: Sẽ thực hiện lệnh: shutdown -h now"
        else
            sync  # Đồng bộ filesystem
            shutdown -h now "SSD overheating: ${temp}°C >= ${TEMP_THRESHOLD}°C"
        fi
        
        return 2
    fi
    
    return 0
}

# Hàm kiểm tra quyền root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Script này cần chạy với quyền root!"
        exit 1
    fi
}

# Hàm tạo PID file
create_pid_file() {
    echo $$ > "$PID_FILE"
}

# Hàm xóa PID file
cleanup() {
    rm -f "$PID_FILE"
    log_message "INFO" "Service dừng hoạt động"
    exit 0
}

# Hàm hiển thị trạng thái
show_status() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Service đang chạy (PID: $pid)"
            
            # Hiển thị nhiệt độ hiện tại
            local temp=$(get_ssd_temperature "$MONITOR_PATH")
            if [[ $? -eq 0 ]]; then
                echo "Nhiệt độ hiện tại: ${temp}°C"
                echo "Ngưỡng cảnh báo: ${WARNING_THRESHOLD}°C"
                echo "Ngưỡng shutdown: ${TEMP_THRESHOLD}°C"
            fi
        else
            echo "Service không chạy (PID file cũ)"
            rm -f "$PID_FILE"
        fi
    else
        echo "Service không chạy"
    fi
}

# Hàm start service
start_service() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Service đã đang chạy (PID: $pid)"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    log_message "INFO" "Bắt đầu giám sát nhiệt độ SSD..."
    log_message "INFO" "Đường dẫn giám sát: $MONITOR_PATH"
    log_message "INFO" "Ngưỡng cảnh báo: ${WARNING_THRESHOLD}°C"
    log_message "INFO" "Ngưỡng shutdown: ${TEMP_THRESHOLD}°C"
    log_message "INFO" "Khoảng thời gian kiểm tra: ${CHECK_INTERVAL} giây"
    
    create_pid_file
    
    # Thiết lập signal handlers
    trap cleanup SIGTERM SIGINT
    
    # Vòng lặp giám sát
    while true; do
        check_temperature
        local result=$?
        
        if [[ $result -eq 2 ]]; then
            # Shutdown được kích hoạt
            break
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Hàm stop service
stop_service() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_message "INFO" "Dừng service..."
            kill "$pid"
            
            # Đợi service dừng
            local count=0
            while kill -0 "$pid" 2>/dev/null && [[ $count -lt 30 ]]; do
                sleep 1
                ((count++))
            done
            
            if kill -0 "$pid" 2>/dev/null; then
                log_message "WARN" "Force kill service"
                kill -9 "$pid"
            fi
            
            rm -f "$PID_FILE"
            echo "Service đã dừng"
        else
            echo "Service không chạy"
            rm -f "$PID_FILE"
        fi
    else
        echo "Service không chạy"
    fi
}

# Hàm hiển thị help
show_help() {
    cat << EOF
Giam Sat SSD - SSD Temperature Monitor

Sử dụng:
    $0 {start|stop|restart|status|check|help}

Lệnh:
    start     - Bắt đầu service giám sát
    stop      - Dừng service giám sát  
    restart   - Khởi động lại service
    status    - Hiển thị trạng thái service
    check     - Kiểm tra nhiệt độ một lần
    help      - Hiển thị trợ giúp này

Cấu hình được lưu tại: $CONFIG_FILE
Log được lưu tại: $LOG_FILE
EOF
}

# Main
case "${1:-}" in
    start)
        check_root
        start_service
        ;;
    stop)
        check_root
        stop_service
        ;;
    restart)
        check_root
        stop_service
        sleep 2
        start_service
        ;;
    status)
        show_status
        ;;
    check)
        check_root
        temp=$(get_ssd_temperature "$MONITOR_PATH")
        if [[ $? -eq 0 ]]; then
            echo "Nhiệt độ SSD: ${temp}°C"
            if [[ $temp -ge $TEMP_THRESHOLD ]]; then
                echo "⚠️  CẢNH BÁO: Vượt ngưỡng shutdown (${TEMP_THRESHOLD}°C)!"
            elif [[ $temp -ge $WARNING_THRESHOLD ]]; then
                echo "⚠️  Cảnh báo: Gần đạt ngưỡng (${WARNING_THRESHOLD}°C)"
            else
                echo "✅ Nhiệt độ bình thường"
            fi
        else
            echo "❌ Lỗi: Không thể đọc nhiệt độ"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Sử dụng: $0 {start|stop|restart|status|check|help}"
        exit 1
        ;;
esac
