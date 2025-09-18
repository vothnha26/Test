# BÁO CÁO TỔNG HỢP PHÂN TÍCH DATABASE QUẢN LÝ NHÂN SỰ

## TÓM TẮT EXECUTIVE

Sau khi phân tích toàn diện database QuanLyNhanSu, tôi phát hiện **một số vấn đề nghiêm trọng** cần được khắc phục ngay lập tức, đặc biệt là:

1. **Logic tính lương SAI** - ảnh hưởng trực tiếp đến tài chính
2. **Lỗ hổng bảo mật nghiêm trọng** - SQL Injection
3. **Phân quyền không phù hợp** - quá rộng rãi

## 1. VẤN ĐỀ NGHIÊM TRỌNG CẦN SỬA NGAY

### 1.1 Logic Tính Lương SAI (CRITICAL)

**Vấn đề:** Trong `SP_TinhLuongHangThang`, logic tính lương cho nhân viên thường hoàn toàn SAI:

```sql
-- CODE HIỆN TẠI (SAI):
TongLuong = MucLuongCoBan + TongGioLamThem * (MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5
```

**Tại sao SAI:**
- Nhân viên nghỉ 1 ngày vẫn nhận đủ lương cơ bản
- Không tính lương theo số ngày công thực tế
- Chỉ cộng thêm giờ làm thêm

**CODE ĐÚNG phải là:**
```sql
-- Cho nhân viên thường:
LuongCoBan = (MucLuongCoBan / SoNgayCongChuan) * TongNgayCongThucTe
LuongLamThem = TongGioLamThem * (MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5
TongLuong = LuongCoBan + LuongLamThem + PhuCap + Thuong

-- Cho giáo viên (đã đúng):
TongLuong = TongGioLamChuan * MucLuongTheoGio + TongGioLamThem * MucLuongTheoGio * 1.5
```

### 1.2 Lỗ hổng SQL Injection (CRITICAL)

**Vấn đề:** Trong `SP_TaoTaiKhoanMoiHoanChinh`:

```sql
SET @CreateLoginSQL = N'CREATE LOGIN [' + @TenDangNhap + N'] WITH PASSWORD = ''' + @MatKhau + N''', CHECK_POLICY = ON;';
EXEC sp_executesql @CreateLoginSQL;
```

**Rủi ro:** Attacker có thể inject SQL code thông qua `@TenDangNhap` hoặc `@MatKhau`

### 1.3 Phân quyền quá rộng (HIGH)

**Vấn đề:** `sys_admin` được gán vào `db_owner` - có quyền làm mọi thứ trong database

## 2. VẤN ĐỀ KHÁC CẦN CẢI THIỆN

### 2.1 Performance Issues
- `SP_TangLuongTheoThamNien` sử dụng CURSOR (chậm)
- Views có subquery không tối ưu
- Thiếu indexes phù hợp

### 2.2 Bảo mật
- Thiếu rate limiting cho authentication
- Thiếu audit logging
- Mật khẩu không được hash đúng cách
- Thiếu session management

### 2.3 Logic Business
- Hàm `FN_SoNgayCongChuan` giả định tuần làm việc 5 ngày
- Thiếu xử lý edge cases trong chấm công
- Validation đầu vào không đầy đủ

## 3. ĐÁNH GIÁ TỔNG QUAN

### 3.1 Điểm mạnh:
- Cấu trúc database hợp lý
- Có đầy đủ các chức năng cơ bản
- Sử dụng stored procedures và functions
- Có views để báo cáo

### 3.2 Điểm yếu:
- Logic tính lương sai
- Bảo mật kém
- Performance chưa tối ưu
- Thiếu error handling chi tiết

## 4. KHUYẾN NGHỊ ƯU TIÊN

### 4.1 Sửa ngay lập tức (CRITICAL):
1. **Sửa logic tính lương** trong `SP_TinhLuongHangThang`
2. **Khắc phục SQL Injection** trong `SP_TaoTaiKhoanMoiHoanChinh`
3. **Điều chỉnh phân quyền** cho `sys_admin`

### 4.2 Sửa trong tuần tới (HIGH):
1. Thêm audit logging
2. Cải thiện authentication với rate limiting
3. Tối ưu performance các stored procedures
4. Thêm validation đầu vào đầy đủ

### 4.3 Cải thiện dài hạn (MEDIUM):
1. Mã hóa dữ liệu nhạy cảm
2. Thêm session management
3. Tối ưu indexes
4. Cải thiện error handling

## 5. CODE SỬA LỖI QUAN TRỌNG

### 5.1 Sửa SP_TinhLuongHangThang:

```sql
-- Bước 2: Tính toán Tổng Lương (Gross) - SỬA LẠI
UPDATE @BangLuongTam
SET TongLuong = 
    CASE ChucDanh
        WHEN N'Giáo viên' THEN 
            -- Giáo viên: tính theo giờ (đã đúng)
            (TongGioLamChuan * MucLuongTheoGio) + 
            (TongGioLamThem * MucLuongTheoGio * 1.5) + 
            PhuCap + Thuong
        ELSE 
            -- Nhân viên thường: tính theo ngày công (SỬA LẠI)
            CASE 
                WHEN TongNgayCongThucTe > 0 THEN
                    -- Có chấm công: tính theo ngày công thực tế
                    ((MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam)) * TongNgayCongThucTe) +
                    (TongGioLamThem * (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam) / 8.0) * 1.5) +
                    PhuCap + Thuong
                ELSE
                    -- Không có chấm công: tính theo lương cơ bản
                    MucLuongCoBan + PhuCap + Thuong
            END
    END;
```

### 5.2 Sửa SP_TaoTaiKhoanMoiHoanChinh:

```sql
-- Bỏ phần tạo login (cần quyền sysadmin)
-- Chỉ tạo user trong database và tài khoản
CREATE PROCEDURE [dbo].[SP_TaoTaiKhoanMoiHoanChinh_Safe]
    @HoTen NVARCHAR(100),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(10),
    @Email VARCHAR(100),
    @SoDienThoai VARCHAR(20),
    @ChucDanh NVARCHAR(50),
    @TrinhDo NVARCHAR(50),
    @NgayVaoLam DATE,
    @TenDangNhap VARCHAR(50),
    @MatKhau VARCHAR(255),
    @TenVaiTro NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validation đầu vào
        IF LEN(@TenDangNhap) < 3 OR LEN(@MatKhau) < 6
            THROW 50001, N'Tên đăng nhập phải >= 3 ký tự, mật khẩu >= 6 ký tự', 1;
            
        IF dbo.FN_KiemTraTenDangNhapTonTai(@TenDangNhap) = 1
            THROW 50002, N'Tên đăng nhập đã tồn tại', 1;

        -- Thêm nhân sự
        INSERT INTO NhanSu (HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, ChucDanh, TrinhDo, NgayVaoLam, TrangThai)
        VALUES (@HoTen, @NgaySinh, @GioiTinh, @Email, @SoDienThoai, @ChucDanh, @TrinhDo, @NgayVaoLam, N'Đang làm việc');

        DECLARE @MaNV INT = SCOPE_IDENTITY();
        DECLARE @MaVaiTro INT;
        SELECT @MaVaiTro = MaVaiTro FROM VaiTro WHERE TenVaiTro = @TenVaiTro;
        
        IF @MaVaiTro IS NULL
            THROW 50003, N'Vai trò không tồn tại', 1;

        -- Hash mật khẩu an toàn
        DECLARE @MatKhauHash VARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2);
        
        -- Thêm tài khoản
        INSERT INTO TaiKhoan (TenDangNhap, MatKhau, MaNV, MaVaiTro, TrangThai)
        VALUES (@TenDangNhap, @MatKhauHash, @MaNV, @MaVaiTro, N'Hoat dong');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

## 6. KẾT LUẬN

Database có **cấu trúc tốt** nhưng có **3 vấn đề nghiêm trọng** cần sửa ngay:

1. **Logic tính lương sai** - ảnh hưởng tài chính
2. **SQL Injection** - rủi ro bảo mật cao  
3. **Phân quyền quá rộng** - vi phạm nguyên tắc least privilege

Sau khi sửa các vấn đề này, database sẽ hoạt động ổn định và an toàn hơn nhiều.

**Ưu tiên:** Sửa logic tính lương trước tiên vì ảnh hưởng trực tiếp đến tài chính của công ty.