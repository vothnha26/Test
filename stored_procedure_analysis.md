# Phân tích Stored Procedures

## 1. SP_TinhLuongHangThang - VẤN ĐỀ NGHIÊM TRỌNG

**Vấn đề chính đã phân tích ở phần trước:**
- Logic tính lương cho nhân viên thường SAI
- Thiếu xử lý trường hợp không có chấm công
- Performance kém do quá phức tạp

**Đề xuất:** Tách thành nhiều SP nhỏ hơn

## 2. SP_TaoTaiKhoanMoiHoanChinh - VẤN ĐỀ BẢO MẬT

**Vấn đề nghiêm trọng:**
```sql
SET @CreateLoginSQL = N'CREATE LOGIN [' + @TenDangNhap + N'] WITH PASSWORD = ''' + @MatKhau + N''', CHECK_POLICY = ON;';
EXEC sp_executesql @CreateLoginSQL;
```

**Vấn đề:**
- SQL Injection vulnerability
- Mật khẩu được truyền dạng plain text
- Cần quyền sysadmin để tạo login

**Code an toàn:**
```sql
CREATE PROCEDURE [dbo].[SP_TaoTaiKhoanMoiHoanChinh]
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

        -- Hash mật khẩu trước khi lưu
        DECLARE @MatKhauHash VARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2);
        
        -- Thêm tài khoản
        INSERT INTO TaiKhoan (TenDangNhap, MatKhau, MaNV, MaVaiTro, TrangThai)
        VALUES (@TenDangNhap, @MatKhauHash, @MaNV, @MaVaiTro, N'Hoat dong');

        -- Ghi log
        INSERT INTO AuditLog (Action, TableName, RecordID, UserID, Timestamp)
        VALUES ('CREATE', 'TaiKhoan', @MaNV, SYSTEM_USER, GETDATE());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

## 3. SP_XacThucNguoiDung - VẤN ĐỀ BẢO MẬT

**Vấn đề:**
```sql
WHERE tk.TenDangNhap = @TenDangNhap AND tk.MatKhau = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2)
```

**Vấn đề:**
- So sánh hash trực tiếp, dễ bị timing attack
- Không có rate limiting
- Không log failed attempts

**Code an toàn:**
```sql
CREATE PROCEDURE [dbo].[SP_XacThucNguoiDung] 
(
    @TenDangNhap VARCHAR(50), 
    @MatKhau VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MatKhauHash VARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2);
    DECLARE @MaNV INT, @HoTen NVARCHAR(100), @TenVaiTro NVARCHAR(50);
    
    -- Kiểm tra tài khoản bị khóa
    IF EXISTS (
        SELECT 1 FROM TaiKhoan 
        WHERE TenDangNhap = @TenDangNhap 
        AND TrangThai = N'Vô hiệu hóa'
    )
    BEGIN
        -- Log failed attempt
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress, Timestamp)
        VALUES (@TenDangNhap, 0, 'Unknown', GETDATE());
        
        THROW 50001, N'Tài khoản đã bị khóa', 1;
    END;
    
    -- Xác thực
    SELECT @MaNV = nv.MaNV, @HoTen = nv.HoTen, @TenVaiTro = vt.TenVaiTro
    FROM TaiKhoan tk
    INNER JOIN NhanSu nv ON tk.MaNV = nv.MaNV
    INNER JOIN VaiTro vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE tk.TenDangNhap = @TenDangNhap 
    AND tk.MatKhau = @MatKhauHash 
    AND tk.TrangThai = N'Hoat dong';
    
    IF @MaNV IS NOT NULL
    BEGIN
        -- Log successful attempt
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress, Timestamp)
        VALUES (@TenDangNhap, 1, 'Unknown', GETDATE());
        
        SELECT @MaNV AS MaNV, @HoTen AS HoTen, @TenVaiTro AS TenVaiTro;
    END
    ELSE
    BEGIN
        -- Log failed attempt
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress, Timestamp)
        VALUES (@TenDangNhap, 0, 'Unknown', GETDATE());
        
        THROW 50002, N'Tên đăng nhập hoặc mật khẩu không đúng', 1;
    END;
END;
```

## 4. SP_TangLuongTheoThamNien - VẤN ĐỀ PERFORMANCE

**Vấn đề:**
- Sử dụng CURSOR (chậm)
- Không có batch processing
- Có thể gây deadlock

**Code cải thiện:**
```sql
CREATE PROCEDURE [dbo].[SP_TangLuongTheoThamNien]
    @SoNamThamNienToiThieu INT,
    @PhanTramTang DECIMAL(5, 2),
    @LyDo NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validation
        IF @PhanTramTang <= 0 OR @PhanTramTang > 100
            THROW 50001, N'Phần trăm tăng lương phải > 0 và <= 100', 1;
            
        -- Batch update thay vì cursor
        WITH NhanVienCanTangLuong AS (
            SELECT 
                ns.MaNV,
                hd.MaHopDong,
                hd.MucLuongCoBan,
                hd.MucLuongCoBan * (1 + @PhanTramTang / 100.0) AS MucLuongMoi
            FROM NhanSu ns
            INNER JOIN HopDong hd ON ns.MaNV = hd.MaNV 
                AND hd.MaHopDong = (SELECT MAX(MaHopDong) FROM HopDong WHERE MaNV = ns.MaNV)
            WHERE ns.TrangThai = N'Đang làm việc' 
            AND DATEDIFF(year, ns.NgayVaoLam, GETDATE()) >= @SoNamThamNienToiThieu
        )
        UPDATE hd
        SET MucLuongCoBan = nv.MucLuongMoi
        FROM HopDong hd
        INNER JOIN NhanVienCanTangLuong nv ON hd.MaHopDong = nv.MaHopDong;
        
        -- Ghi log batch
        INSERT INTO SalaryAdjustmentLog (MaNV, MucLuongCu, MucLuongMoi, LyDo, NgayDieuChinh)
        SELECT 
            MaNV, 
            MucLuongCoBan, 
            MucLuongMoi, 
            @LyDo, 
            GETDATE()
        FROM NhanVienCanTangLuong;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

## 5. Các SP khác - Đánh giá tổng quan

**SP tốt:**
- SP_BaoCaoKhenThuongKyLuat
- SP_BaoCaoThamNienNhanSu  
- SP_NopDonXinNghi
- SP_DuyetDonNghiPhep

**SP cần cải thiện:**
- SP_CapNhatMatKhau (thiếu validation mật khẩu mạnh)
- SP_ThemHopDongMoi (thiếu validation ngày)
- SP_NhapChamCong (thiếu validation giờ)

**SP có vấn đề:**
- SP_TinhLuongHangThang (logic sai)
- SP_TaoTaiKhoanMoiHoanChinh (SQL injection)
- SP_XacThucNguoiDung (bảo mật kém)
- SP_TangLuongTheoThamNien (performance kém)

## 6. Đề xuất cải thiện chung

1. **Thêm validation đầu vào cho tất cả SP**
2. **Sử dụng parameterized queries**
3. **Thêm audit logging**
4. **Cải thiện error handling**
5. **Tối ưu performance (tránh cursor)**
6. **Thêm rate limiting cho authentication**