# HƯỚNG DẪN CÀI ĐẶT DATABASE QUẢN LÝ NHÂN SỰ - VERSION SIMPLE

## 📋 TỔNG QUAN

Database này là phiên bản **đơn giản hóa** của hệ thống quản lý nhân sự, tập trung vào các tính năng cốt lõi:

### ✅ BAO GỒM:
- **Views**: 5 views chính cho báo cáo và hiển thị dữ liệu
- **Functions**: 8 functions hỗ trợ tính toán và validation
- **Stored Procedures**: Tính lương, xác thực, CRUD operations, báo cáo
- **Transactions**: Tất cả operations đều có transaction handling
- **Basic Security**: Users, Roles, và phân quyền cơ bản
- **Authentication**: Xác thực với hash password

### ❌ KHÔNG BAO GỒM:
- Audit logging
- Rate limiting
- Session management
- Data encryption
- Advanced security features

## 🚀 CÁCH CÀI ĐẶT

### Bước 1: Tạo Database
```sql
CREATE DATABASE [QuanLyNhanSu];
```

### Bước 2: Chạy Scripts theo thứ tự
1. **Chạy file đầu tiên:** `QuanLyNhanSu_Simple.sql`
2. **Chạy file thứ hai:** `QuanLyNhanSu_Simple_Part2.sql`  
3. **Chạy file thứ ba:** `QuanLyNhanSu_Simple_Part3.sql`

### Bước 3: Kiểm tra cài đặt
```sql
-- Kiểm tra các bảng
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- Kiểm tra các stored procedures
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE';

-- Kiểm tra các functions
SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION';

-- Kiểm tra các views
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS;
```

## 🔐 TÀI KHOẢN MẪU

| Tài khoản | Mật khẩu | Vai trò | Quyền hạn |
|-----------|----------|---------|-----------|
| admin | admin123 | Quản lý nhân sự | Đầy đủ quyền HR |
| teacher1 | teacher123 | Giáo viên | Xem thông tin cá nhân |
| employee1 | employee123 | Nhân viên | Xem thông tin cá nhân |

## 📊 CÁC VIEWS CHÍNH

### 1. **VW_BangThanhToanLuongChiTiet**
Hiển thị bảng lương chi tiết với các khoản phụ cấp, thưởng, khấu trừ
```sql
SELECT * FROM VW_BangThanhToanLuongChiTiet WHERE Thang = 12 AND Nam = 2024;
```

### 2. **vw_ThongTinNhanSu**
Thông tin nhân sự kèm tài khoản và vai trò
```sql
SELECT * FROM vw_ThongTinNhanSu;
```

### 3. **vw_BaoCaoKhenThuongKyLuat**
Báo cáo khen thưởng kỷ luật
```sql
SELECT * FROM vw_BaoCaoKhenThuongKyLuat;
```

### 4. **vw_ThongKeChamCong**
Thống kê chấm công theo tháng
```sql
SELECT * FROM vw_ThongKeChamCong WHERE Thang = 12 AND Nam = 2024;
```

### 5. **vw_ThongKeGioGiangDay**
Thống kê giờ giảng dạy
```sql
SELECT * FROM vw_ThongKeGioGiangDay WHERE Thang = 12 AND Nam = 2024;
```

## 🔧 CÁC FUNCTIONS CHÍNH

### 1. **FN_KiemTraHopDongCoTheXoa**
Kiểm tra xem có thể xóa hợp đồng không
```sql
SELECT dbo.FN_KiemTraHopDongCoTheXoa(1);
```

### 2. **FN_KiemTraTenDangNhapTonTai**
Kiểm tra tên đăng nhập đã tồn tại
```sql
SELECT dbo.FN_KiemTraTenDangNhapTonTai('admin');
```

### 3. **FN_KiemTraTrungLichNghi**
Kiểm tra trùng lịch nghỉ phép
```sql
SELECT dbo.FN_KiemTraTrungLichNghi(1, '2024-12-10', '2024-12-12');
```

### 4. **FN_LayLuongCoBanHienHanh**
Lấy lương cơ bản hiện hành
```sql
SELECT dbo.FN_LayLuongCoBanHienHanh(1, GETDATE());
```

### 5. **FN_SoNgayCongChuan**
Tính số ngày công chuẩn trong tháng
```sql
SELECT dbo.FN_SoNgayCongChuan(12, 2024, 5); -- 5 ngày/tuần
```

### 6. **FN_ThongKe_ChiPhiLuongTheoThang**
Thống kê chi phí lương theo tháng
```sql
SELECT dbo.FN_ThongKe_ChiPhiLuongTheoThang(12, 2024);
```

### 7. **FN_ThongKe_NhanVienMoiTrongThang**
Thống kê nhân viên mới trong tháng
```sql
SELECT dbo.FN_ThongKe_NhanVienMoiTrongThang(12, 2024);
```

### 8. **FN_ThongKe_TongSoNhanVien**
Thống kê tổng số nhân viên
```sql
SELECT dbo.FN_ThongKe_TongSoNhanVien();
```

## 📝 CÁC STORED PROCEDURES CHÍNH

### 1. **SP_TinhLuongHangThang** (ĐÃ SỬA LỖI LOGIC)
Tính lương hàng tháng với logic đúng cho nhân viên thường và giáo viên
```sql
EXEC SP_TinhLuongHangThang @Thang = 12, @Nam = 2024;
```

### 2. **SP_XacThucNguoiDung**
Xác thực đăng nhập
```sql
EXEC SP_XacThucNguoiDung @TenDangNhap = 'admin', @MatKhau = 'admin123';
```

### 3. **SP_TaoTaiKhoanMoi**
Tạo tài khoản mới (an toàn, không có SQL injection)
```sql
EXEC SP_TaoTaiKhoanMoi 
    @HoTen = N'Nguyễn Văn F',
    @NgaySinh = '1990-01-01',
    @GioiTinh = N'Nam',
    @Email = 'nguyenvanf@company.com',
    @SoDienThoai = '0123456789',
    @ChucDanh = N'Nhân viên',
    @TrinhDo = N'Đại học',
    @NgayVaoLam = '2024-01-01',
    @TenDangNhap = 'employee3',
    @MatKhau = 'password123',
    @TenVaiTro = N'Nhân viên';
```

### 4. **SP_ThemNhanSu**
Thêm nhân sự mới
```sql
EXEC SP_ThemNhanSu 
    @HoTen = N'Trần Thị G',
    @NgaySinh = '1992-05-15',
    @GioiTinh = N'Nữ',
    @Email = 'tranthig@company.com',
    @SoDienThoai = '0987654321',
    @ChucDanh = N'Giáo viên',
    @TrinhDo = N'Thạc sĩ',
    @NgayVaoLam = '2024-02-01';
```

### 5. **SP_ThemHopDongMoi**
Thêm hợp đồng mới
```sql
EXEC SP_ThemHopDongMoi 
    @MaNV = 6,
    @SoHopDong = 'HD006',
    @LoaiHopDong = N'Hợp đồng xác định thời hạn',
    @NgayKy = '2024-02-01',
    @NgayKetThuc = '2027-02-01',
    @MucLuongCoBan = 12000000,
    @MucLuongTheoGio = 150000,
    @PhuCapCoDinh = 1000000;
```

### 6. **SP_NhapChamCong**
Nhập chấm công
```sql
EXEC SP_NhapChamCong 
    @MaNV = 1,
    @Ngay = '2024-12-04',
    @GioVao = '08:00:00',
    @GioRa = '17:00:00';
```

### 7. **SP_NopDonXinNghi**
Nộp đơn xin nghỉ
```sql
EXEC SP_NopDonXinNghi 
    @MaNV = 3,
    @LoaiNghi = N'Nghỉ phép',
    @NgayBatDau = '2024-12-15',
    @NgayKetThuc = '2024-12-17';
```

### 8. **SP_DuyetDonNghiPhep**
Duyệt đơn nghỉ phép
```sql
EXEC SP_DuyetDonNghiPhep @MaDon = 1, @TrangThaiMoi = N'Đã duyệt';
```

## 📊 CÁC STORED PROCEDURES BÁO CÁO

### 1. **SP_BaoCaoKhenThuongKyLuat**
```sql
EXEC SP_BaoCaoKhenThuongKyLuat @Nam = 2024;
EXEC SP_BaoCaoKhenThuongKyLuat @Nam = 2024, @Loai = N'Khen thưởng';
```

### 2. **SP_BaoCaoThamNienNhanSu**
```sql
EXEC SP_BaoCaoThamNienNhanSu;
```

### 3. **SP_BaoCaoGioLamThem**
```sql
EXEC SP_BaoCaoGioLamThem @Thang = 12, @Nam = 2024;
```

### 4. **SP_BaoCaoNhanSuThucTe**
```sql
EXEC SP_BaoCaoNhanSuThucTe;
```

## 🔒 PHÂN QUYỀN

### HRManager_Role:
- Đầy đủ quyền SELECT, INSERT, UPDATE, DELETE trên tất cả bảng
- Có thể xem tất cả views

### NhanVien_Role:
- Chỉ SELECT trên các bảng liên quan đến bản thân
- Có thể INSERT đơn nghỉ phép

### SystemAdministrator_Role:
- Đầy đủ quyền trên tất cả objects

## ⚠️ LƯU Ý QUAN TRỌNG

### 1. Logic tính lương đã được sửa:
- **Nhân viên thường**: Tính theo ngày công thực tế
- **Giáo viên**: Tính theo giờ giảng dạy
- **Giờ làm thêm**: Hệ số 1.5

### 2. Bảo mật cơ bản:
- Mật khẩu được hash bằng SHA2_256
- Phân quyền theo vai trò
- Validation đầu vào

### 3. Transaction handling:
- Tất cả operations đều có BEGIN TRANSACTION
- ROLLBACK khi có lỗi
- COMMIT khi thành công

## 🎯 KẾT QUẢ MONG ĐỢI

Sau khi cài đặt thành công:
- ✅ Logic tính lương chính xác
- ✅ Views hoạt động tốt
- ✅ Functions hỗ trợ đầy đủ
- ✅ Stored procedures an toàn
- ✅ Transaction handling đúng
- ✅ Phân quyền cơ bản
- ✅ Authentication hoạt động

Database này phù hợp cho các ứng dụng quản lý nhân sự vừa và nhỏ, tập trung vào tính năng cốt lõi mà không phức tạp hóa bảo mật.