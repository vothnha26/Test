-- =============================================
-- SỬA LỖI NHỎ TRONG SP_TinhLuongHangThang
-- Xử lý trường hợp không có chấm công
-- =============================================

ALTER PROCEDURE [dbo].[SP_TinhLuongHangThang]
    @Thang INT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @BangLuongTam TABLE (
            MaNV INT, ChucDanh NVARCHAR(50), MucLuongCoBan DECIMAL(18, 2), MucLuongTheoGio DECIMAL(18, 2),
            PhuCapCoDinh DECIMAL(18, 2), TongNgayCongThucTe INT, TongGioLamChuan FLOAT, TongGioLamThem FLOAT,
            PhuCap DECIMAL(18,2), Thuong DECIMAL(18,2), KhauTru DECIMAL(18,2),
            ThueTNCN DECIMAL(18,2), BaoHiem DECIMAL(18,2),
            TongLuong DECIMAL(18,2), ThucNhan DECIMAL(18,2)
        );

        -- Bước 1: Thu thập tất cả dữ liệu vào bảng tạm
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
            SELECT MaNV, COUNT(DISTINCT Ngay) AS TongSoNgayCong, SUM(DATEDIFF(minute, GioVao, GioRa) / 60.0) AS TongGioLam,
                SUM(CASE WHEN DATEDIFF(minute, GioVao, GioRa) / 60.0 > 8 THEN (DATEDIFF(minute, GioVao, GioRa) / 60.0) - 8 ELSE 0 END) AS TongGioLamThem
            FROM ChamCong WHERE MONTH(Ngay) = @Thang AND YEAR(Ngay) = @Nam GROUP BY MaNV
        )
        INSERT INTO @BangLuongTam (MaNV, ChucDanh, MucLuongCoBan, MucLuongTheoGio, PhuCapCoDinh, TongNgayCongThucTe, TongGioLamChuan, TongGioLamThem, PhuCap, Thuong, KhauTru)
        SELECT 
            ns.MaNV, ns.ChucDanh, hd.MucLuongCoBan, hd.MucLuongTheoGio, hd.PhuCapCoDinh,
            ISNULL(cd.TongSoNgayCong, 0), ISNULL(cd.TongGioLam, 0) - ISNULL(cd.TongGioLamThem, 0), ISNULL(cd.TongGioLamThem, 0),
            ISNULL(ctld.TongPhuCap, 0) + ISNULL(hd.PhuCapCoDinh, 0),
            ISNULL(ctld.TongThuong, 0),
            ISNULL(ctld.TongKhauTru, 0)
        FROM NhanSu ns
        LEFT JOIN CongData cd ON ns.MaNV = cd.MaNV
        LEFT JOIN ChiTietLuongData ctld ON ns.MaNV = ctld.MaNV
        JOIN HopDong hd ON ns.MaNV = hd.MaNV AND hd.MaHopDong = (SELECT MAX(MaHopDong) FROM HopDong WHERE MaNV = ns.MaNV)
        WHERE ns.TrangThai = N'Đang làm việc';

        -- Bước 2: Tính toán Tổng Lương (Gross) - ĐÃ SỬA XỬ LÝ TRƯỜNG HỢP KHÔNG CÓ CHẤM CÔNG
        UPDATE @BangLuongTam
        SET TongLuong = 
            (CASE 
                -- Logic cho Giáo viên (tính theo giờ) không đổi
                WHEN ChucDanh = N'Giáo viên' THEN 
                    (TongGioLamChuan * MucLuongTheoGio) + (TongGioLamThem * MucLuongTheoGio * 1.5)
                -- Logic mới cho các nhân viên khác (tính lương theo ngày công thực tế)
                ELSE 
                    CASE 
                        -- CÓ CHẤM CÔNG: Tính theo ngày công thực tế
                        WHEN TongNgayCongThucTe > 0 THEN
                            ( (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam)) * TongNgayCongThucTe ) +
                            ( TongGioLamThem * (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam) / 8.0) * 1.5 )
                        -- KHÔNG CÓ CHẤM CÔNG: Tính theo lương cơ bản (có thể điều chỉnh theo quy định)
                        ELSE
                            MucLuongCoBan + 
                            ( TongGioLamThem * (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam) / 8.0) * 1.5 )
                    END
            END) 
            + PhuCap + Thuong; -- Cộng các khoản phụ cấp và thưởng
        
        -- Bước 3: Tính các khoản khấu trừ dựa trên Tổng Lương
        UPDATE @BangLuongTam
        SET BaoHiem = TongLuong * 0.08,
            ThueTNCN = CASE WHEN (TongLuong - 11000000) > 0 THEN (TongLuong - 11000000) * 0.1 ELSE 0 END;
        
        -- Bước 4: Cập nhật Tổng Khấu trừ
        UPDATE @BangLuongTam
        SET KhauTru = KhauTru + BaoHiem + ThueTNCN;

        -- Bước 5: Tính Lương thực nhận
        UPDATE @BangLuongTam
        SET ThucNhan = TongLuong - KhauTru;
        
        -- Bước 6: Xóa dữ liệu cũ và chèn dữ liệu mới
        DELETE FROM ChiTietLuong WHERE MaLuong IN (SELECT MaLuong FROM Luong WHERE Thang = @Thang AND Nam = @Nam);
        DELETE FROM Luong WHERE Thang = @Thang AND Nam = @Nam;

        DECLARE @MaLuong TABLE (ID INT, MaNV INT);
        
        INSERT INTO Luong (MaNV, Thang, Nam, TongLuong, ThucNhan)
        OUTPUT inserted.MaLuong, inserted.MaNV INTO @MaLuong
        SELECT MaNV, @Thang, @Nam, TongLuong, ThucNhan FROM @BangLuongTam;
        
        INSERT INTO ChiTietLuong (MaLuong, LoaiKhoan, GiaTri, GhiChu)
        SELECT T2.ID, N'BHXH', T1.BaoHiem, N'Khấu trừ BHXH' FROM @BangLuongTam T1 INNER JOIN @MaLuong T2 ON T1.MaNV = T2.MaNV WHERE T1.BaoHiem > 0;
        
        INSERT INTO ChiTietLuong (MaLuong, LoaiKhoan, GiaTri, GhiChu)
        SELECT T2.ID, N'Thuế TNCN', T1.ThueTNCN, N'Khấu trừ Thuế TNCN' FROM @BangLuongTam T1 INNER JOIN @MaLuong T2 ON T1.MaNV = T2.MaNV WHERE T1.ThueTNCN > 0;

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

TRƯỜNG HỢP 1: CÓ CHẤM CÔNG (TongNgayCongThucTe = 20)
LuongCoBan = (10,000,000 / 22) * 20 = 454,545 * 20 = 9,090,909 VND
LuongLamThem = 4 * (10,000,000 / 22 / 8) * 1.5 = 4 * 56,818 * 1.5 = 340,909 VND
TongLuong = 9,090,909 + 340,909 + 1,000,000 + 500,000 = 10,931,818 VND

TRƯỜNG HỢP 2: KHÔNG CÓ CHẤM CÔNG (TongNgayCongThucTe = 0)
LuongCoBan = 10,000,000 VND (lương cơ bản)
LuongLamThem = 4 * (10,000,000 / 22 / 8) * 1.5 = 340,909 VND
TongLuong = 10,000,000 + 340,909 + 1,000,000 + 500,000 = 11,840,909 VND

KHÁC BIỆT: 11,840,909 - 10,931,818 = 909,091 VND
→ Nhân viên nghỉ 2 ngày tiết kiệm được gần 1 triệu VND!
*/