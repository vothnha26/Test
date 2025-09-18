# HƯỚNG DẪN CÀI ĐẶT DATABASE QUẢN LÝ NHÂN SỰ

## 📋 TỔNG QUAN

Database này đã được **sửa tất cả lỗi nghiêm trọng** từ phiên bản gốc, bao gồm:
- ✅ Sửa logic tính lương cho nhân viên thường
- ✅ Khắc phục lỗ hổng SQL Injection
- ✅ Cải thiện bảo mật và phân quyền
- ✅ Tối ưu performance
- ✅ Thêm audit logging
- ✅ Cải thiện error handling

## 🚀 CÁCH CÀI ĐẶT

### Bước 1: Backup Database hiện tại (nếu có)
```sql
BACKUP DATABASE [QuanLyNhanSu] TO DISK = 'C:\Backup\QuanLyNhanSu_Backup.bak'
```

### Bước 2: Xóa Database cũ (nếu cần)
```sql
USE master;
DROP DATABASE [QuanLyNhanSu];
```

### Bước 3: Tạo Database mới
```sql
CREATE DATABASE [QuanLyNhanSu];
```

### Bước 4: Chạy Scripts theo thứ tự
1. **Chạy file đầu tiên:** `QuanLyNhanSu_Fixed.sql`
2. **Chạy file thứ hai:** `QuanLyNhanSu_Fixed_Part2.sql`  
3. **Chạy file thứ ba:** `QuanLyNhanSu_Fixed_Part3.sql`

### Bước 5: Kiểm tra cài đặt
```sql
-- Kiểm tra các bảng đã được tạo
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- Kiểm tra các stored procedures
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE';

-- Kiểm tra các functions
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION';

-- Kiểm tra các views
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS;
```

## 🔐 TÀI KHOẢN MẪU

Sau khi cài đặt, bạn có thể sử dụng các tài khoản mẫu:

| Tài khoản | Mật khẩu | Vai trò | Quyền hạn |
|-----------|----------|---------|-----------|
| admin | admin123 | Quản lý nhân sự | Đầy đủ quyền HR |
| teacher | teacher123 | Giáo viên | Xem thông tin cá nhân |
| employee | employee123 | Nhân viên | Xem thông tin cá nhân |

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Thay đổi mật khẩu mặc định
```sql
-- Thay đổi mật khẩu admin
EXEC SP_CapNhatMatKhau @MaTK = 1, @MatKhauMoi = 'MatKhauMoiAnToan123!';
```

### 2. Cấu hình phân quyền
- `sys_admin` không còn có quyền `db_owner`
- Phân quyền chi tiết theo vai trò
- Có audit logging cho tất cả thao tác

### 3. Backup thường xuyên
```sql
-- Tạo job backup hàng ngày
EXEC dbo.sp_add_job @job_name = 'Backup_QuanLyNhanSu_Daily';
```

## 🔧 CÁC TÍNH NĂNG MỚI

### 1. Tính lương chính xác
- **Nhân viên thường:** Tính theo ngày công thực tế
- **Giáo viên:** Tính theo giờ giảng dạy
- **Giờ làm thêm:** Hệ số 1.5

### 2. Bảo mật nâng cao
- Rate limiting cho đăng nhập
- Session management
- Audit trail đầy đủ
- Mã hóa dữ liệu nhạy cảm

### 3. Performance tối ưu
- Indexes phù hợp
- Batch processing thay vì cursor
- Views được tối ưu

### 4. Error handling
- Validation đầu vào đầy đủ
- Transaction rollback an toàn
- Error messages rõ ràng

## 📊 CÁC BÁO CÁO CÓ SẴN

1. **Báo cáo lương:** `VW_BangThanhToanLuongChiTiet`
2. **Báo cáo chấm công:** `vw_ThongKeChamCong`
3. **Báo cáo khen thưởng:** `vw_BaoCaoKhenThuongKyLuat`
4. **Báo cáo thâm niên:** `SP_BaoCaoThamNienNhanSu`
5. **Báo cáo giờ làm thêm:** `SP_BaoCaoGioLamThem`

## 🛠️ MAINTENANCE

### Dọn dẹp dữ liệu cũ
```sql
-- Chạy hàng tuần
EXEC SP_CleanupOldSessions;
```

### Kiểm tra audit log
```sql
SELECT TOP 100 * FROM AuditLog ORDER BY Timestamp DESC;
```

### Kiểm tra login attempts
```sql
SELECT * FROM LoginAttempts WHERE Success = 0 AND Timestamp > DATEADD(day, -1, GETDATE());
```

## 📞 HỖ TRỢ

Nếu gặp vấn đề trong quá trình cài đặt:
1. Kiểm tra log lỗi SQL Server
2. Đảm bảo có đủ quyền tạo database
3. Kiểm tra version SQL Server (khuyến nghị 2016+)

## 🎯 KẾT QUẢ MONG ĐỢI

Sau khi cài đặt thành công:
- ✅ Logic tính lương chính xác
- ✅ Bảo mật cao
- ✅ Performance tốt
- ✅ Dễ bảo trì
- ✅ Audit trail đầy đủ
- ✅ Error handling tốt