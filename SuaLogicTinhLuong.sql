-- =============================================
-- SỬA LỖI LOGIC TÍNH LƯƠNG TRONG SP_TinhLuongHangThang
-- =============================================

-- XÓA STORED PROCEDURE CŨ
DROP PROCEDURE IF EXISTS [dbo].[SP_TinhLuongHangThang];
GO

-- TẠO LẠI STORED PROCEDURE VỚI LOGIC ĐÚNG
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
            -- THÊM CÁC TRƯỜNG ĐỂ DEBUG
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
            dbo.FN_SoNgayCongChuan(@Thang, @Nam) -- Tính số ngày công chuẩn
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
                    -- KHÔNG CÓ CHẤM CÔNG: Tính theo lương cơ bản (có thể điều chỉnh)
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

        -- Bước 8: HIỂN THỊ KẾT QUẢ ĐỂ KIỂM TRA (CÓ THỂ XÓA SAU KHI TEST)
        SELECT 
            MaNV,
            ChucDanh,
            MucLuongCoBan,
            SoNgayCongChuan,
            TongNgayCongThucTe,
            LuongCoBan,
            TongGioLamThem,
            LuongLamThem,
            PhuCap,
            Thuong,
            TongLuong,
            BaoHiem,
            ThueTNCN,
            KhauTru,
            ThucNhan
        FROM @BangLuongTam
        ORDER BY MaNV;

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
-- VÍ DỤ MINH HỌA SỰ KHÁC BIỆT
-- =============================================

/*
VÍ DỤ TÍNH LƯƠNG:

Nhân viên A:
- Mức lương cơ bản: 10,000,000 VND/tháng
- Số ngày công chuẩn: 22 ngày
- Số ngày công thực tế: 20 ngày (nghỉ 2 ngày)
- Giờ làm thêm: 4 giờ
- Phụ cấp: 1,000,000 VND
- Thưởng: 500,000 VND

LOGIC CŨ (SAI):
TongLuong = 10,000,000 + (4 * (10,000,000 / 22 / 8) * 1.5) + 1,000,000 + 500,000
          = 10,000,000 + (4 * 56,818 * 1.5) + 1,500,000
          = 10,000,000 + 340,909 + 1,500,000
          = 11,840,909 VND
→ Nhân viên nghỉ 2 ngày vẫn nhận đủ 10 triệu lương cơ bản!

LOGIC MỚI (ĐÚNG):
LuongCoBan = (10,000,000 / 22) * 20 = 454,545 * 20 = 9,090,909 VND
LuongLamThem = 4 * (10,000,000 / 22 / 8) * 1.5 = 4 * 56,818 * 1.5 = 340,909 VND
TongLuong = 9,090,909 + 340,909 + 1,000,000 + 500,000 = 10,931,818 VND
→ Nhân viên nghỉ 2 ngày chỉ nhận lương theo ngày công thực tế!

KHÁC BIỆT: 11,840,909 - 10,931,818 = 909,091 VND (tiết kiệm được gần 1 triệu!)
*/

-- =============================================
-- TEST STORED PROCEDURE
-- =============================================

-- Chạy thử với tháng 12/2024
EXEC SP_TinhLuongHangThang @Thang = 12, @Nam = 2024;

-- Kiểm tra kết quả
SELECT 
    ns.HoTen,
    ns.ChucDanh,
    l.Thang,
    l.Nam,
    l.TongLuong,
    l.ThucNhan,
    ctl.LoaiKhoan,
    ctl.GiaTri,
    ctl.GhiChu
FROM Luong l
JOIN NhanSu ns ON l.MaNV = ns.MaNV
LEFT JOIN ChiTietLuong ctl ON l.MaLuong = ctl.MaLuong
WHERE l.Thang = 12 AND l.Nam = 2024
ORDER BY ns.MaNV, ctl.LoaiKhoan;