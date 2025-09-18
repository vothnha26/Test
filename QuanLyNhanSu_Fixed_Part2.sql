-- =============================================
-- PHẦN 2: STORED PROCEDURES (ĐÃ SỬA LỖI)
-- =============================================

-- =============================================
-- 7. STORED PROCEDURE TÍNH LƯƠNG (ĐÃ SỬA LỖI NGHIÊM TRỌNG)
-- =============================================

CREATE PROCEDURE [dbo].[SP_TinhLuongHangThang]
    @Thang INT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation đầu vào
    IF @Thang < 1 OR @Thang > 12
        THROW 50001, N'Tháng không hợp lệ (1-12)', 1;

    IF @Nam < 2000 OR @Nam > 2100
        THROW 50002, N'Năm không hợp lệ', 1;

    IF NOT EXISTS (SELECT 1 FROM NhanSu WHERE TrangThai = N'Đang làm việc')
        THROW 50003, N'Không có nhân viên đang làm việc', 1;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @BangLuongTam TABLE (
            MaNV INT, 
            ChucDanh NVARCHAR(50), 
            MucLuongCoBan DECIMAL(18, 2), 
            MucLuongTheoGio DECIMAL(18, 2),
            PhuCapCoDinh DECIMAL(18, 2), 
            TongNgayCongThucTe INT, 
            TongGioLamChuan FLOAT, 
            TongGioLamThem FLOAT,
            PhuCap DECIMAL(18,2), 
            Thuong DECIMAL(18,2), 
            KhauTru DECIMAL(18,2),
            ThueTNCN DECIMAL(18,2), 
            BaoHiem DECIMAL(18,2),
            TongLuong DECIMAL(18,2), 
            ThucNhan DECIMAL(18,2)
        );

        -- Bước 1: Thu thập dữ liệu
        WITH ChiTietLuongData AS (
            SELECT
                l.MaNV,
                SUM(CASE WHEN ctl.LoaiKhoan = N'Phụ cấp' THEN ctl.GiaTri ELSE 0 END) AS TongPhuCap,
                SUM(CASE WHEN ctl.LoaiKhoan = N'Thưởng' THEN ctl.GiaTri ELSE 0 END) AS TongThuong,
                SUM(CASE WHEN ctl.LoaiKhoan IN (N'Khấu trừ', N'Điều chỉnh lương thâm niên') THEN ctl.GiaTri ELSE 0 END) AS TongKhauTru
            FROM ChiTietLuong ctl
            JOIN Luong l ON ctl.MaLuong = l.MaLuong
            WHERE l.Thang = @Thang AND l.Nam = @Nam
            GROUP BY l.MaNV
        ),
        CongData AS (
            SELECT 
                MaNV, 
                COUNT(DISTINCT Ngay) AS TongSoNgayCong, 
                SUM(DATEDIFF(minute, GioVao, GioRa) / 60.0) AS TongGioLam,
                SUM(CASE WHEN DATEDIFF(minute, GioVao, GioRa) / 60.0 > 8 THEN (DATEDIFF(minute, GioVao, GioRa) / 60.0) - 8 ELSE 0 END) AS TongGioLamThem
            FROM ChamCong 
            WHERE MONTH(Ngay) = @Thang AND YEAR(Ngay) = @Nam 
            AND GioVao IS NOT NULL AND GioRa IS NOT NULL
            GROUP BY MaNV
        )
        INSERT INTO @BangLuongTam (MaNV, ChucDanh, MucLuongCoBan, MucLuongTheoGio, PhuCapCoDinh, TongNgayCongThucTe, TongGioLamChuan, TongGioLamThem, PhuCap, Thuong, KhauTru)
        SELECT 
            ns.MaNV, 
            ns.ChucDanh, 
            hd.MucLuongCoBan, 
            hd.MucLuongTheoGio, 
            hd.PhuCapCoDinh,
            ISNULL(cd.TongSoNgayCong, 0), 
            ISNULL(cd.TongGioLam, 0) - ISNULL(cd.TongGioLamThem, 0), 
            ISNULL(cd.TongGioLamThem, 0),
            ISNULL(ctld.TongPhuCap, 0) + ISNULL(hd.PhuCapCoDinh, 0),
            ISNULL(ctld.TongThuong, 0),
            ISNULL(ctld.TongKhauTru, 0)
        FROM NhanSu ns
        LEFT JOIN CongData cd ON ns.MaNV = cd.MaNV
        LEFT JOIN ChiTietLuongData ctld ON ns.MaNV = ctld.MaNV
        JOIN HopDong hd ON ns.MaNV = hd.MaNV AND hd.MaHopDong = (SELECT MAX(MaHopDong) FROM HopDong WHERE MaNV = ns.MaNV)
        WHERE ns.TrangThai = N'Đang làm việc';

        -- Bước 2: Tính toán Tổng Lương (ĐÃ SỬA LỖI NGHIÊM TRỌNG)
        UPDATE @BangLuongTam
        SET TongLuong = 
            CASE ChucDanh
                WHEN N'Giáo viên' THEN 
                    -- Giáo viên: tính theo giờ (đã đúng)
                    (TongGioLamChuan * MucLuongTheoGio) + 
                    (TongGioLamThem * MucLuongTheoGio * 1.5) + 
                    PhuCap + Thuong
                ELSE 
                    -- Nhân viên thường: tính theo ngày công (ĐÃ SỬA LỖI)
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
        
        -- Bước 3: Tính các khoản khấu trừ
        UPDATE @BangLuongTam
        SET BaoHiem = TongLuong * 0.08,
            ThueTNCN = CASE WHEN (TongLuong - 11000000) > 0 THEN (TongLuong - 11000000) * 0.1 ELSE 0 END;
        
        -- Bước 4: Cập nhật Tổng Khấu trừ và Lương thực nhận
        UPDATE @BangLuongTam
        SET KhauTru = KhauTru + BaoHiem + ThueTNCN,
            ThucNhan = TongLuong - (KhauTru + BaoHiem + ThueTNCN);
        
        -- Bước 5: Xóa dữ liệu cũ và chèn dữ liệu mới
        DELETE FROM ChiTietLuong WHERE MaLuong IN (SELECT MaLuong FROM Luong WHERE Thang = @Thang AND Nam = @Nam);
        DELETE FROM Luong WHERE Thang = @Thang AND Nam = @Nam;

        DECLARE @MaLuong TABLE (ID INT, MaNV INT);
        
        INSERT INTO Luong (MaNV, Thang, Nam, TongLuong, ThucNhan, TrangThai, NgayTinh)
        OUTPUT inserted.MaLuong, inserted.MaNV INTO @MaLuong
        SELECT MaNV, @Thang, @Nam, TongLuong, ThucNhan, N'Đã tính', GETDATE() FROM @BangLuongTam;
        
        -- Chèn chi tiết khấu trừ
        INSERT INTO ChiTietLuong (MaLuong, LoaiKhoan, GiaTri, GhiChu)
        SELECT T2.ID, N'BHXH', T1.BaoHiem, N'Khấu trừ BHXH 8%' 
        FROM @BangLuongTam T1 
        INNER JOIN @MaLuong T2 ON T1.MaNV = T2.MaNV 
        WHERE T1.BaoHiem > 0;
        
        INSERT INTO ChiTietLuong (MaLuong, LoaiKhoan, GiaTri, GhiChu)
        SELECT T2.ID, N'Thuế TNCN', T1.ThueTNCN, N'Khấu trừ Thuế TNCN 10%' 
        FROM @BangLuongTam T1 
        INNER JOIN @MaLuong T2 ON T1.MaNV = T2.MaNV 
        WHERE T1.ThueTNCN > 0;

        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('Luong', 'CALCULATE', @Thang * 100 + @Nam, 
                N'{"Thang":' + CAST(@Thang AS NVARCHAR(2)) + ',"Nam":' + CAST(@Nam AS NVARCHAR(4)) + '}', 
                SYSTEM_USER);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 8. STORED PROCEDURE XÁC THỰC AN TOÀN
-- =============================================

CREATE PROCEDURE [dbo].[SP_XacThucNguoiDung_Safe]
    @TenDangNhap VARCHAR(50),
    @MatKhau VARCHAR(255),
    @IPAddress NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra rate limiting
    IF (SELECT COUNT(*) FROM LoginAttempts 
        WHERE TenDangNhap = @TenDangNhap 
        AND Success = 0 
        AND Timestamp > DATEADD(minute, -15, GETDATE())) >= 5
    BEGIN
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
        VALUES (@TenDangNhap, 0, @IPAddress);
        THROW 50001, N'Tài khoản tạm thời bị khóa do đăng nhập sai quá nhiều lần', 1;
    END;
    
    -- Kiểm tra tài khoản bị khóa
    IF EXISTS (
        SELECT 1 FROM TaiKhoan 
        WHERE TenDangNhap = @TenDangNhap 
        AND (TrangThai = N'Vô hiệu hóa' OR (LockedUntil IS NOT NULL AND LockedUntil > GETDATE()))
    )
    BEGIN
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
        VALUES (@TenDangNhap, 0, @IPAddress);
        THROW 50002, N'Tài khoản đã bị khóa', 1;
    END;
    
    -- Xác thực
    DECLARE @StoredHash VARCHAR(255);
    DECLARE @MaNV INT, @HoTen NVARCHAR(100), @TenVaiTro NVARCHAR(50);
    
    SELECT @StoredHash = MatKhau
    FROM TaiKhoan 
    WHERE TenDangNhap = @TenDangNhap AND TrangThai = N'Hoat dong';
    
    IF @StoredHash IS NULL OR @StoredHash != CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2)
    BEGIN
        -- Tăng số lần đăng nhập sai
        UPDATE TaiKhoan 
        SET FailedAttempts = FailedAttempts + 1,
            LockedUntil = CASE WHEN FailedAttempts >= 4 THEN DATEADD(minute, 15, GETDATE()) ELSE LockedUntil END
        WHERE TenDangNhap = @TenDangNhap;
        
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
        VALUES (@TenDangNhap, 0, @IPAddress);
        THROW 50003, N'Tên đăng nhập hoặc mật khẩu không đúng', 1;
    END;
    
    -- Lấy thông tin user
    SELECT @MaNV = nv.MaNV, @HoTen = nv.HoTen, @TenVaiTro = vt.TenVaiTro
    FROM TaiKhoan tk
    INNER JOIN NhanSu nv ON tk.MaNV = nv.MaNV
    INNER JOIN VaiTro vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE tk.TenDangNhap = @TenDangNhap;
    
    -- Reset failed attempts và cập nhật last login
    UPDATE TaiKhoan 
    SET FailedAttempts = 0, 
        LockedUntil = NULL,
        LastLogin = GETDATE()
    WHERE TenDangNhap = @TenDangNhap;
    
    -- Tạo session
    INSERT INTO UserSessions (MaNV, IPAddress)
    VALUES (@MaNV, @IPAddress);
    
    -- Log successful login
    INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
    VALUES (@TenDangNhap, 1, @IPAddress);
    
    SELECT @MaNV AS MaNV, @HoTen AS HoTen, @TenVaiTro AS TenVaiTro;
END;
GO

-- =============================================
-- 9. STORED PROCEDURE TẠO TÀI KHOẢN AN TOÀN
-- =============================================

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

        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('TaiKhoan', 'CREATE', @MaNV, 
                N'{"TenDangNhap":"' + @TenDangNhap + '","VaiTro":"' + @TenVaiTro + '"}', 
                SYSTEM_USER);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =============================================
-- 10. STORED PROCEDURE TĂNG LƯƠNG THEO THÂM NIÊN (ĐÃ TỐI ƯU)
-- =============================================

CREATE PROCEDURE [dbo].[SP_TangLuongTheoThamNien_Safe]
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
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        SELECT 
            'HopDong', 
            'SALARY_INCREASE', 
            MaNV, 
            N'{"PhanTramTang":' + CAST(@PhanTramTang AS NVARCHAR(10)) + ',"LyDo":"' + @LyDo + '"}', 
            SYSTEM_USER
        FROM NhanVienCanTangLuong;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =============================================
-- 11. CÁC STORED PROCEDURE KHÁC (ĐÃ CẢI THIỆN)
-- =============================================

-- SP thêm nhân sự
CREATE PROCEDURE [dbo].[SP_ThemNhanSu] 
    @HoTen NVARCHAR(100), 
    @NgaySinh DATE, 
    @GioiTinh NVARCHAR(10), 
    @Email VARCHAR(100), 
    @SoDienThoai VARCHAR(20), 
    @ChucDanh NVARCHAR(50), 
    @TrinhDo NVARCHAR(50), 
    @NgayVaoLam DATE
AS 
BEGIN 
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validation
        IF @NgayVaoLam > GETDATE()
            THROW 50001, N'Ngày vào làm không được lớn hơn ngày hiện tại', 1;
            
        INSERT INTO NhanSu (HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, ChucDanh, TrinhDo, NgayVaoLam, TrangThai) 
        VALUES (@HoTen, @NgaySinh, @GioiTinh, @Email, @SoDienThoai, @ChucDanh, @TrinhDo, @NgayVaoLam, N'Đang làm việc');
        
        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('NhanSu', 'CREATE', SCOPE_IDENTITY(), 
                N'{"HoTen":"' + @HoTen + '","ChucDanh":"' + @ChucDanh + '"}', 
                SYSTEM_USER);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- SP thêm hợp đồng
CREATE PROCEDURE [dbo].[SP_ThemHopDongMoi] 
    @MaNV INT, 
    @SoHopDong VARCHAR(50), 
    @LoaiHopDong NVARCHAR(50), 
    @NgayKy DATE, 
    @NgayKetThuc DATE, 
    @MucLuongCoBan DECIMAL(18, 2), 
    @MucLuongTheoGio DECIMAL(18, 2) = NULL, 
    @PhuCapCoDinh DECIMAL(18, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validation
        IF NOT EXISTS (SELECT 1 FROM NhanSu WHERE MaNV = @MaNV)
            THROW 50001, N'Nhân viên không tồn tại', 1;
            
        IF @NgayKetThuc IS NOT NULL AND @NgayKetThuc <= @NgayKy
            THROW 50002, N'Ngày kết thúc phải sau ngày ký', 1;
            
        IF dbo.FN_KiemTraSoHopDongTonTai_KhiCapNhat(0, @SoHopDong) = 1
            THROW 50003, N'Số hợp đồng đã tồn tại', 1;
            
        INSERT INTO HopDong (MaNV, SoHopDong, LoaiHopDong, NgayKy, NgayKetThuc, MucLuongCoBan, MucLuongTheoGio, PhuCapCoDinh)
        VALUES (@MaNV, @SoHopDong, @LoaiHopDong, @NgayKy, @NgayKetThuc, @MucLuongCoBan, @MucLuongTheoGio, @PhuCapCoDinh);
        
        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('HopDong', 'CREATE', SCOPE_IDENTITY(), 
                N'{"MaNV":' + CAST(@MaNV AS NVARCHAR(10)) + ',"SoHopDong":"' + @SoHopDong + '"}', 
                SYSTEM_USER);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- SP nhập chấm công
CREATE PROCEDURE [dbo].[SP_NhapChamCong] 
    @MaNV INT, 
    @Ngay DATE, 
    @GioVao TIME, 
    @GioRa TIME
AS
BEGIN
    SET NOCOUNT ON; 
    BEGIN TRANSACTION; 
    BEGIN TRY
        -- Validation
        IF NOT EXISTS (SELECT 1 FROM NhanSu WHERE MaNV = @MaNV)
            THROW 50001, N'Mã nhân sự không tồn tại.', 1;
            
        IF EXISTS (SELECT 1 FROM ChamCong WHERE MaNV = @MaNV AND Ngay = @Ngay)
            THROW 50002, N'Đã có bản ghi chấm công cho nhân sự này trong ngày.', 1;
            
        IF @GioRa <= @GioVao
            THROW 50003, N'Giờ ra phải sau giờ vào.', 1;
            
        INSERT INTO ChamCong (MaNV, Ngay, GioVao, GioRa) 
        VALUES (@MaNV, @Ngay, @GioVao, @GioRa);
        
        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('ChamCong', 'CREATE', SCOPE_IDENTITY(), 
                N'{"MaNV":' + CAST(@MaNV AS NVARCHAR(10)) + ',"Ngay":"' + CAST(@Ngay AS NVARCHAR(10)) + '"}', 
                SYSTEM_USER);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
        THROW; 
    END CATCH;
END;
GO

-- SP nộp đơn xin nghỉ
CREATE PROCEDURE [dbo].[SP_NopDonXinNghi] 
    @MaNV INT, 
    @LoaiNghi NVARCHAR(50), 
    @NgayBatDau DATE, 
    @NgayKetThuc DATE,
    @LyDo NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON; 
    BEGIN TRANSACTION; 
    BEGIN TRY
        -- Validation
        IF NOT EXISTS (SELECT 1 FROM NhanSu WHERE MaNV = @MaNV)
            THROW 50001, N'Mã nhân sự không tồn tại.', 1;
            
        IF @NgayKetThuc < @NgayBatDau
            THROW 50002, N'Ngày kết thúc phải sau ngày bắt đầu.', 1;
            
        IF dbo.FN_KiemTraTrungLichNghi(@MaNV, @NgayBatDau, @NgayKetThuc) = 1 
            THROW 50003, N'Khoảng thời gian nghỉ bạn chọn bị trùng với một đơn nghỉ phép đã có.', 1;
            
        INSERT INTO DonNghiPhep (MaNV, LoaiNghi, NgayBatDau, NgayKetThuc, TrangThai, LyDo) 
        VALUES (@MaNV, @LoaiNghi, @NgayBatDau, @NgayKetThuc, N'Chờ duyệt', @LyDo);
        
        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('DonNghiPhep', 'CREATE', SCOPE_IDENTITY(), 
                N'{"MaNV":' + CAST(@MaNV AS NVARCHAR(10)) + ',"LoaiNghi":"' + @LoaiNghi + '"}', 
                SYSTEM_USER);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH 
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
        THROW; 
    END CATCH;
END;
GO

-- SP duyệt đơn nghỉ phép
CREATE PROCEDURE [dbo].[SP_DuyetDonNghiPhep]
    @MaDon INT, 
    @TrangThaiMoi NVARCHAR(50), 
    @NguoiDuyetID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validation
        IF @TrangThaiMoi NOT IN (N'Đã duyệt', N'Từ chối') 
            THROW 51000, N'Trạng thái duyệt không hợp lệ.', 1;
            
        IF NOT EXISTS (SELECT 1 FROM DonNghiPhep WHERE MaDon = @MaDon)
            THROW 51001, N'Đơn nghỉ phép không tồn tại.', 1;
            
        UPDATE dbo.DonNghiPhep
        SET TrangThai = @TrangThaiMoi,
            NguoiDuyet = @NguoiDuyetID,
            NgayDuyet = GETDATE()
        WHERE MaDon = @MaDon;
        
        -- Ghi log
        INSERT INTO AuditLog (TableName, Action, RecordID, NewValues, UserID)
        VALUES ('DonNghiPhep', 'APPROVE', @MaDon, 
                N'{"TrangThai":"' + @TrangThaiMoi + '","NguoiDuyet":' + CAST(@NguoiDuyetID AS NVARCHAR(10)) + '}', 
                SYSTEM_USER);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO