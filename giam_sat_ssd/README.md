# Giam Sat SSD - SSD Temperature Monitor

Chương trình giám sát nhiệt độ SSD và tự động shutdown khi nhiệt độ vượt ngưỡng an toàn.

## 🎯 Tính năng

- ✅ Giám sát nhiệt độ SSD theo thời gian thực
- ✅ Cảnh báo khi nhiệt độ gần đạt ngưỡng
- ✅ Tự động shutdown an toàn khi vượt ngưỡng
- ✅ Hoạt động như systemd service
- ✅ Ghi log chi tiết
- ✅ Thông báo qua wall message
- ✅ Cấu hình linh hoạt

## 📦 Cài đặt

```bash
# 1. Clone/copy dự án
sudo cp -r giam_sat_ssd /mnt/mydrive/

# 2. Chạy script cài đặt
cd /mnt/mydrive/giam_sat_ssd
sudo ./install.sh
```

## ⚙️ Cấu hình

Chỉnh sửa file cấu hình tại `/mnt/mydisk/giam_sat_ssd/config/giam_sat_ssd.conf`:

```bash
# Đường dẫn cần giám sát
MONITOR_PATH="/mnt/mydisk"

# Ngưỡng nhiệt độ (độ C)
TEMP_THRESHOLD=65          # Ngưỡng shutdown
WARNING_THRESHOLD=60       # Ngưỡng cảnh báo

# Khoảng thời gian kiểm tra (giây)
CHECK_INTERVAL=30

# Thời gian chờ trước khi shutdown (giây)
SHUTDOWN_DELAY=10

# Chế độ test (true = không thực sự shutdown)
DRY_RUN=false
```

## 🚀 Sử dụng

### Sử dụng trực tiếp:

```bash
# Kiểm tra nhiệt độ một lần
sudo giam_sat_ssd check

# Bắt đầu giám sát
sudo giam_sat_ssd start

# Xem trạng thái
sudo giam_sat_ssd status

# Dừng giám sát
sudo giam_sat_ssd stop

# Khởi động lại
sudo giam_sat_ssd restart

# Hiển thị trợ giúp
giam_sat_ssd help
```

### Sử dụng systemd service:

```bash
# Bật tự động khởi động
sudo systemctl enable giam_sat_ssd

# Bắt đầu service
sudo systemctl start giam_sat_ssd

# Xem trạng thái service
sudo systemctl status giam_sat_ssd

# Xem log
sudo journalctl -u giam_sat_ssd -f

# Dừng service
sudo systemctl stop giam_sat_ssd

# Vô hiệu hóa tự động khởi động
sudo systemctl disable giam_sat_ssd
```

## 📊 Giám sát Log

```bash
# Xem log realtime
tail -f /mnt/mydrive/giam_sat_ssd/logs/giam_sat_ssd.log

# Xem log systemd
sudo journalctl -u giam_sat_ssd -f

# Xem log hôm nay
sudo journalctl -u giam_sat_ssd --since today
```

## 🔧 Troubleshooting

### Lỗi không đọc được nhiệt độ:

```bash
# Kiểm tra thiết bị
df /mnt/mydrive

# Kiểm tra smartctl
sudo smartctl -A /dev/sdX

# Kiểm tra quyền
ls -la /mnt/mydrive/giam_sat_ssd/
```

### Test mode:

Để test mà không thực sự shutdown:

```bash
# Chỉnh sửa cấu hình
sudo nano /mnt/mydrive/giam_sat_ssd/config/giam_sat_ssd.conf

# Đặt DRY_RUN=true
DRY_RUN=true

# Khởi động lại service
sudo systemctl restart giam_sat_ssd
```

## 📁 Cấu trúc thư mục

```
/mnt/mydrive/giam_sat_ssd/
├── bin/
│   └── giam_sat_ssd.sh        # Script chính
├── config/
│   └── giam_sat_ssd.conf      # File cấu hình
├── logs/
│   └── giam_sat_ssd.log       # Log file
├── giam_sat_ssd.service       # Systemd service
├── install.sh                 # Script cài đặt
└── README.md                  # Tài liệu này
```

## 🔒 Bảo mật

- Service chạy với quyền root (cần thiết để shutdown)
- Sử dụng các security settings trong systemd
- PID file để tránh chạy multiple instances
- Validation input và error handling

## 📈 Monitoring

Service ghi log các sự kiện quan trọng:

- `INFO`: Nhiệt độ bình thường
- `WARN`: Nhiệt độ gần đạt ngưỡng
- `CRITICAL`: Nhiệt độ vượt ngưỡng, bắt đầu shutdown
- `ERROR`: Lỗi đọc nhiệt độ hoặc hệ thống

## ⚠️ Lưu ý quan trọng

1. **Backup dữ liệu**: Luôn backup dữ liệu quan trọng
2. **Test trước**: Sử dụng `DRY_RUN=true` để test
3. **Điều chỉnh ngưỡng**: Điều chỉnh ngưỡng phù hợp với SSD của bạn
4. **Monitor**: Theo dõi log thường xuyên
5. **Quyền root**: Service cần quyền root để shutdown

## 📞 Hỗ trợ

Nếu gặp vấn đề:

1. Kiểm tra log: `sudo journalctl -u giam_sat_ssd`
2. Test thủ công: `sudo giam_sat_ssd check`
3. Kiểm tra cấu hình
4. Kiểm tra quyền file
