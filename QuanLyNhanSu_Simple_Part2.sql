-- =============================================
-- PHẦN 2: STORED PROCEDURES VÀ VIEWS
-- =============================================

-- =============================================
-- 6. STORED PROCEDURE TÍNH LƯƠNG (ĐÃ SỬA LỖI)
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
            ThucNhan DECIMAL(18,2),
            LuongCoBan DECIMAL(18,2),
            LuongLamThem DECIMAL(18,2),
            SoNgayCongChuan INT
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
        INSERT INTO @BangLuongTam (
            MaNV, ChucDanh, MucLuongCoBan, MucLuongTheoGio, PhuCapCoDinh, 
            TongNgayCongThucTe, TongGioLamChuan, TongGioLamThem, 
            PhuCap, Thuong, KhauTru, SoNgayCongChuan
        )
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
            ISNULL(ctld.TongKhauTru, 0),
            dbo.FN_SoNgayCongChuan(@Thang, @Nam)
        FROM NhanSu ns
        LEFT JOIN CongData cd ON ns.MaNV = cd.MaNV
        LEFT JOIN ChiTietLuongData ctld ON ns.MaNV = ctld.MaNV
        JOIN HopDong hd ON ns.MaNV = hd.MaNV AND hd.MaHopDong = (SELECT MAX(MaHopDong) FROM HopDong WHERE MaNV = ns.MaNV)
        WHERE ns.TrangThai = N'Đang làm việc';

        -- Bước 2: TÍNH LƯƠNG CƠ BẢN THEO NGÀY CÔNG THỰC TẾ (ĐÃ SỬA LỖI)
        UPDATE @BangLuongTam
        SET LuongCoBan = 
            CASE 
                WHEN TongNgayCongThucTe > 0 THEN
                    -- CÓ CHẤM CÔNG: Tính theo ngày công thực tế
                    (MucLuongCoBan / SoNgayCongChuan) * TongNgayCongThucTe
                ELSE
                    -- KHÔNG CÓ CHẤM CÔNG: Tính theo lương cơ bản
                    MucLuongCoBan
            END;

        -- Bước 3: TÍNH LƯƠNG LÀM THÊM
        UPDATE @BangLuongTam
        SET LuongLamThem = 
            CASE 
                WHEN TongGioLamThem > 0 THEN
                    TongGioLamThem * (MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5
                ELSE
                    0
            END;

        -- Bước 4: TÍNH TỔNG LƯƠNG (GROSS) - LOGIC KHÁC NHAU CHO TỪNG LOẠI NHÂN VIÊN
        UPDATE @BangLuongTam
        SET TongLuong = 
            CASE ChucDanh
                WHEN N'Giáo viên' THEN 
                    -- GIÁO VIÊN: Tính theo giờ (đã đúng từ trước)
                    (TongGioLamChuan * MucLuongTheoGio) + 
                    (TongGioLamThem * MucLuongTheoGio * 1.5) + 
                    PhuCap + Thuong
                ELSE 
                    -- NHÂN VIÊN THƯỜNG: Tính theo ngày công (ĐÃ SỬA LỖI)
                    LuongCoBan + LuongLamThem + PhuCap + Thuong
            END;
        
        -- Bước 5: Tính các khoản khấu trừ
        UPDATE @BangLuongTam
        SET BaoHiem = TongLuong * 0.08,
            ThueTNCN = CASE WHEN (TongLuong - 11000000) > 0 THEN (TongLuong - 11000000) * 0.1 ELSE 0 END;
        
        -- Bước 6: Cập nhật Tổng Khấu trừ và Lương thực nhận
        UPDATE @BangLuongTam
        SET KhauTru = KhauTru + BaoHiem + ThueTNCN,
            ThucNhan = TongLuong - (KhauTru + BaoHiem + ThueTNCN);
        
        -- Bước 7: Xóa dữ liệu cũ và chèn dữ liệu mới
        DELETE FROM ChiTietLuong WHERE MaLuong IN (SELECT MaLuong FROM Luong WHERE Thang = @Thang AND Nam = @Nam);
        DELETE FROM Luong WHERE Thang = @Thang AND Nam = @Nam;

        DECLARE @MaLuong TABLE (ID INT, MaNV INT);
        
        INSERT INTO Luong (MaNV, Thang, Nam, TongLuong, ThucNhan)
        OUTPUT inserted.MaLuong, inserted.MaNV INTO @MaLuong
        SELECT MaNV, @Thang, @Nam, TongLuong, ThucNhan FROM @BangLuongTam;
        
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

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 7. STORED PROCEDURE XÁC THỰC CƠ BẢN
-- =============================================

CREATE PROCEDURE [dbo].[SP_XacThucNguoiDung]
    @TenDangNhap VARCHAR(50),
    @MatKhau VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MatKhauHash VARCHAR(255) = CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2);
    DECLARE @MaNV INT, @HoTen NVARCHAR(100), @TenVaiTro NVARCHAR(50);
    
    SELECT @MaNV = nv.MaNV, @HoTen = nv.HoTen, @TenVaiTro = vt.TenVaiTro
    FROM TaiKhoan tk
    INNER JOIN NhanSu nv ON tk.MaNV = nv.MaNV
    INNER JOIN VaiTro vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE tk.TenDangNhap = @TenDangNhap 
    AND tk.MatKhau = @MatKhauHash 
    AND tk.TrangThai = N'Hoat dong';
    
    IF @MaNV IS NOT NULL
        SELECT @MaNV AS MaNV, @HoTen AS HoTen, @TenVaiTro AS TenVaiTro;
    ELSE
        THROW 50001, N'Tên đăng nhập hoặc mật khẩu không đúng', 1;
END;
GO

-- =============================================
-- 8. STORED PROCEDURE TẠO TÀI KHOẢN CƠ BẢN
-- =============================================

CREATE PROCEDURE [dbo].[SP_TaoTaiKhoanMoi]
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

        -- Hash mật khẩu
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
GO

-- =============================================
-- 9. CÁC STORED PROCEDURE KHÁC
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
    @NgayKetThuc DATE
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
            
        INSERT INTO DonNghiPhep (MaNV, LoaiNghi, NgayBatDau, NgayKetThuc, TrangThai) 
        VALUES (@MaNV, @LoaiNghi, @NgayBatDau, @NgayKetThuc, N'Chờ duyệt');
        
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
    @TrangThaiMoi NVARCHAR(50)
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
        SET TrangThai = @TrangThaiMoi
        WHERE MaDon = @MaDon;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 10. TẠO VIEWS
-- =============================================

-- View bảng thanh toán lương chi tiết
CREATE VIEW [dbo].[VW_BangThanhToanLuongChiTiet]
AS
WITH HopDongMoiNhat AS (
    SELECT 
        MaNV,
        MaHopDong,
        MucLuongCoBan,
        ROW_NUMBER() OVER (PARTITION BY MaNV ORDER BY NgayKy DESC, MaHopDong DESC) as rn
    FROM HopDong
)
SELECT
    ns.MaNV, 
    ns.HoTen, 
    l.Thang, 
    l.Nam, 
    hd.MucLuongCoBan,
    ISNULL(lt.PhuCap, 0) AS PhuCap, 
    ISNULL(lt.Thuong, 0) AS Thuong,
    ISNULL(lt.KhauTru, 0) AS KhauTruKhac,
    ISNULL(lt.BaoHiem, 0) AS KhauTruBHXH,
    ISNULL(lt.ThueTNCN, 0) AS KhauTruThue,
    l.TongLuong, 
    l.ThucNhan
FROM Luong l
JOIN NhanSu ns ON l.MaNV = ns.MaNV
JOIN HopDongMoiNhat hd ON ns.MaNV = hd.MaNV AND hd.rn = 1
LEFT JOIN (
    SELECT
        l.MaLuong,
        SUM(CASE WHEN ctl.LoaiKhoan = N'Phụ cấp' THEN ctl.GiaTri ELSE 0 END) AS PhuCap,
        SUM(CASE WHEN ctl.LoaiKhoan = N'Thưởng' THEN ctl.GiaTri ELSE 0 END) AS Thuong,
        SUM(CASE WHEN ctl.LoaiKhoan = N'Khấu trừ' THEN ctl.GiaTri ELSE 0 END) AS KhauTru,
        SUM(CASE WHEN ctl.LoaiKhoan = N'BHXH' THEN ctl.GiaTri ELSE 0 END) AS BaoHiem,
        SUM(CASE WHEN ctl.LoaiKhoan = N'Thuế TNCN' THEN ctl.GiaTri ELSE 0 END) AS ThueTNCN
    FROM ChiTietLuong ctl
    JOIN Luong l ON ctl.MaLuong = l.MaLuong
    GROUP BY l.MaLuong
) AS lt ON l.MaLuong = lt.MaLuong;
GO

-- View thông tin nhân sự
CREATE VIEW [dbo].[vw_ThongTinNhanSu]
AS
SELECT 
    ns.MaNV, 
    ns.HoTen, 
    ns.ChucDanh, 
    ns.TrinhDo, 
    ns.NgayVaoLam, 
    tk.TenDangNhap, 
    vt.TenVaiTro,
    ns.TrangThai
FROM NhanSu AS ns
INNER JOIN TaiKhoan AS tk ON ns.MaNV = tk.MaNV
INNER JOIN VaiTro AS vt ON tk.MaVaiTro = vt.MaVaiTro;
GO

-- View báo cáo khen thưởng kỷ luật
CREATE VIEW [dbo].[vw_BaoCaoKhenThuongKyLuat] AS
SELECT
    kt.MaQD, 
    kt.MaNV, 
    ns.HoTen AS TenNhanVien, 
    ns.ChucDanh, 
    kt.Loai AS LoaiQuyetDinh, 
    kt.NoiDung, 
    kt.NgayQuyetDinh
FROM KhenThuong_KyLuat AS kt
JOIN NhanSu AS ns ON kt.MaNV = ns.MaNV;
GO

-- View thống kê chấm công
CREATE VIEW [dbo].[vw_ThongKeChamCong]
AS
SELECT
    cc.MaNV, 
    ns.HoTen, 
    YEAR(cc.Ngay) AS Nam, 
    MONTH(cc.Ngay) AS Thang,
    COUNT(DISTINCT cc.Ngay) AS TongNgayCong,
    SUM(
        CASE 
            WHEN cc.GioVao IS NULL OR cc.GioRa IS NULL THEN 0
            WHEN cc.GioRa < cc.GioVao THEN 
                DATEDIFF(minute, cc.GioVao, '23:59:59') / 60.0 + 
                DATEDIFF(minute, '00:00:00', cc.GioRa) / 60.0
            ELSE 
                DATEDIFF(minute, cc.GioVao, cc.GioRa) / 60.0
        END
    ) AS TongSoGioLam
FROM ChamCong AS cc
JOIN NhanSu AS ns ON cc.MaNV = ns.MaNV
WHERE cc.GioVao IS NOT NULL AND cc.GioRa IS NOT NULL
GROUP BY cc.MaNV, ns.HoTen, YEAR(cc.Ngay), MONTH(cc.Ngay);
GO

-- View thống kê giờ giảng dạy
CREATE VIEW [dbo].[vw_ThongKeGioGiangDay]
AS
SELECT
    gd.MaNV, 
    ns.HoTen, 
    YEAR(gd.NgayDay) AS Nam, 
    MONTH(gd.NgayDay) AS Thang,
    SUM(gd.SoGio) AS TongSoGioGiangDay
FROM GioGiangDay AS gd
JOIN NhanSu AS ns ON gd.MaNV = ns.MaNV
GROUP BY gd.MaNV, ns.HoTen, YEAR(gd.NgayDay), MONTH(gd.NgayDay);
GO