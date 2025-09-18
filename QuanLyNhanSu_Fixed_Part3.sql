-- =============================================
-- PHẦN 3: VIEWS, TRIGGERS VÀ PHÂN QUYỀN
-- =============================================

-- =============================================
-- 12. TẠO VIEWS (ĐÃ TỐI ƯU)
-- =============================================

-- View bảng thanh toán lương chi tiết (đã tối ưu)
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
    l.ThucNhan,
    l.TrangThai,
    l.NgayTinh
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
    kt.NgayQuyetDinh,
    kt.SoTien
FROM KhenThuong_KyLuat AS kt
JOIN NhanSu AS ns ON kt.MaNV = ns.MaNV;
GO

-- View thống kê chấm công (đã sửa lỗi)
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
                -- Xử lý trường hợp làm việc qua ngày
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

-- View cho nhân viên xem thông tin của mình
CREATE VIEW [dbo].[vw_EmployeeSelfInfo]
AS
SELECT 
    ns.MaNV,
    ns.HoTen,
    ns.ChucDanh,
    ns.TrinhDo,
    ns.NgayVaoLam,
    ns.TrangThai,
    tk.TenDangNhap,
    vt.TenVaiTro
FROM NhanSu ns
INNER JOIN TaiKhoan tk ON ns.MaNV = tk.MaNV
INNER JOIN VaiTro vt ON tk.MaVaiTro = vt.MaVaiTro
WHERE tk.TenDangNhap = SYSTEM_USER;
GO

-- =============================================
-- 13. TẠO TRIGGERS CHO AUDIT
-- =============================================

-- Trigger cho bảng NhanSu
CREATE TRIGGER TR_NhanSu_Audit
ON NhanSu
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(20);
    DECLARE @RecordID INT;
    
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Action = 'INSERT';
    ELSE
        SET @Action = 'DELETE';
    
    IF @Action IN ('INSERT', 'UPDATE')
        SELECT @RecordID = MaNV FROM inserted;
    ELSE
        SELECT @RecordID = MaNV FROM deleted;
    
    INSERT INTO AuditLog (TableName, Action, RecordID, OldValues, NewValues, UserID)
    SELECT 
        'NhanSu',
        @Action,
        @RecordID,
        (SELECT * FROM deleted FOR JSON AUTO),
        (SELECT * FROM inserted FOR JSON AUTO),
        SYSTEM_USER;
END;
GO

-- Trigger cho bảng HopDong
CREATE TRIGGER TR_HopDong_Audit
ON HopDong
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(20);
    DECLARE @RecordID INT;
    
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Action = 'INSERT';
    ELSE
        SET @Action = 'DELETE';
    
    IF @Action IN ('INSERT', 'UPDATE')
        SELECT @RecordID = MaHopDong FROM inserted;
    ELSE
        SELECT @RecordID = MaHopDong FROM deleted;
    
    INSERT INTO AuditLog (TableName, Action, RecordID, OldValues, NewValues, UserID)
    SELECT 
        'HopDong',
        @Action,
        @RecordID,
        (SELECT * FROM deleted FOR JSON AUTO),
        (SELECT * FROM inserted FOR JSON AUTO),
        SYSTEM_USER;
END;
GO

-- Trigger cho bảng Luong
CREATE TRIGGER TR_Luong_Audit
ON Luong
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Action NVARCHAR(20);
    DECLARE @RecordID INT;
    
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @Action = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @Action = 'INSERT';
    ELSE
        SET @Action = 'DELETE';
    
    IF @Action IN ('INSERT', 'UPDATE')
        SELECT @RecordID = MaLuong FROM inserted;
    ELSE
        SELECT @RecordID = MaLuong FROM deleted;
    
    INSERT INTO AuditLog (TableName, Action, RecordID, OldValues, NewValues, UserID)
    SELECT 
        'Luong',
        @Action,
        @RecordID,
        (SELECT * FROM deleted FOR JSON AUTO),
        (SELECT * FROM inserted FOR JSON AUTO),
        SYSTEM_USER;
END;
GO

-- =============================================
-- 14. PHÂN QUYỀN CHI TIẾT
-- =============================================

-- Phân quyền cho HR_ReadOnly
GRANT SELECT ON NhanSu TO HR_ReadOnly;
GRANT SELECT ON HopDong TO HR_ReadOnly;
GRANT SELECT ON Luong TO HR_ReadOnly;
GRANT SELECT ON ChiTietLuong TO HR_ReadOnly;
GRANT SELECT ON ChamCong TO HR_ReadOnly;
GRANT SELECT ON DonNghiPhep TO HR_ReadOnly;
GRANT SELECT ON KhenThuong_KyLuat TO HR_ReadOnly;
GRANT SELECT ON VW_BangThanhToanLuongChiTiet TO HR_ReadOnly;
GRANT SELECT ON vw_ThongTinNhanSu TO HR_ReadOnly;
GRANT SELECT ON vw_BaoCaoKhenThuongKyLuat TO HR_ReadOnly;
GRANT SELECT ON vw_ThongKeChamCong TO HR_ReadOnly;
GRANT SELECT ON vw_ThongKeGioGiangDay TO HR_ReadOnly;

-- Phân quyền cho HR_Write
GRANT SELECT, INSERT, UPDATE ON NhanSu TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON HopDong TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON Luong TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON ChiTietLuong TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON ChamCong TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON DonNghiPhep TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON KhenThuong_KyLuat TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON GioGiangDay TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON LopHoc TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON SoNgayPhep TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON VaiTro TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON TaiKhoan TO HR_Write;

-- Phân quyền cho Employee_Self
GRANT SELECT ON vw_EmployeeSelfInfo TO Employee_Self;
GRANT SELECT ON Luong TO Employee_Self;
GRANT SELECT ON ChiTietLuong TO Employee_Self;
GRANT SELECT ON ChamCong TO Employee_Self;
GRANT SELECT ON DonNghiPhep TO Employee_Self;

-- Phân quyền cho HRManager_Role
ALTER ROLE [HR_ReadOnly] ADD MEMBER [HRManager_Role];
ALTER ROLE [HR_Write] ADD MEMBER [HRManager_Role];

-- Phân quyền cho NhanVien_Role
ALTER ROLE [Employee_Self] ADD MEMBER [NhanVien_Role];

-- Phân quyền cho SystemAdministrator_Role (hạn chế hơn db_owner)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES TO SystemAdministrator_Role;
GRANT EXECUTE ON ALL STORED PROCEDURES TO SystemAdministrator_Role;
GRANT SELECT ON ALL VIEWS TO SystemAdministrator_Role;

-- =============================================
-- 15. TẠO DỮ LIỆU MẪU
-- =============================================

-- Thêm vai trò mẫu
INSERT INTO VaiTro (TenVaiTro) VALUES 
(N'Quản lý nhân sự'),
(N'Nhân viên'),
(N'Giáo viên'),
(N'Quản trị hệ thống');

-- Thêm nhân viên mẫu
INSERT INTO NhanSu (HoTen, NgaySinh, GioiTinh, Email, SoDienThoai, ChucDanh, TrinhDo, NgayVaoLam, TrangThai) VALUES
(N'Nguyễn Văn A', '1990-01-15', N'Nam', 'nguyenvana@company.com', '0123456789', N'Quản lý nhân sự', N'Đại học', '2020-01-01', N'Đang làm việc'),
(N'Trần Thị B', '1985-05-20', N'Nữ', 'tranthib@company.com', '0987654321', N'Giáo viên', N'Thạc sĩ', '2019-03-15', N'Đang làm việc'),
(N'Lê Văn C', '1992-08-10', N'Nam', 'levanc@company.com', '0369258147', N'Nhân viên', N'Đại học', '2021-06-01', N'Đang làm việc');

-- Thêm hợp đồng mẫu
INSERT INTO HopDong (MaNV, SoHopDong, LoaiHopDong, NgayKy, NgayKetThuc, MucLuongCoBan, MucLuongTheoGio, PhuCapCoDinh) VALUES
(1, 'HD001', N'Hợp đồng không xác định thời hạn', '2020-01-01', NULL, 15000000, NULL, 2000000),
(2, 'HD002', N'Hợp đồng xác định thời hạn', '2019-03-15', '2024-03-15', 12000000, 150000, 1000000),
(3, 'HD003', N'Hợp đồng thử việc', '2021-06-01', '2021-12-01', 8000000, NULL, 500000);

-- Thêm tài khoản mẫu
INSERT INTO TaiKhoan (TenDangNhap, MatKhau, MaNV, MaVaiTro, TrangThai) VALUES
('admin', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'admin123'), 2), 1, 1, N'Hoat dong'),
('teacher', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'teacher123'), 2, 3, N'Hoat dong'),
('employee', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'employee123'), 3, 2, N'Hoat dong');

-- =============================================
-- 16. TẠO CÁC STORED PROCEDURE BÁO CÁO
-- =============================================

-- SP báo cáo khen thưởng kỷ luật
CREATE PROCEDURE [dbo].[SP_BaoCaoKhenThuongKyLuat]
    @Nam INT = NULL,
    @Loai NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ns.MaNV,
        ns.HoTen,
        ns.ChucDanh,
        kt.Loai AS LoaiQuyetDinh,
        COUNT(kt.MaQD) AS SoLan,
        SUM(ISNULL(kt.SoTien, 0)) AS TongTien
    FROM
        KhenThuong_KyLuat AS kt
    JOIN
        NhanSu AS ns ON kt.MaNV = ns.MaNV
    WHERE
        (@Nam IS NULL OR YEAR(kt.NgayQuyetDinh) = @Nam)
        AND (@Loai IS NULL OR kt.Loai = @Loai)
    GROUP BY
        ns.MaNV,
        ns.HoTen,
        ns.ChucDanh,
        kt.Loai
    ORDER BY
        ns.HoTen, kt.Loai;
END;
GO

-- SP báo cáo thâm niên nhân sự
CREATE PROCEDURE [dbo].[SP_BaoCaoThamNienNhanSu]
AS
BEGIN
    SET NOCOUNT ON;

    WITH ThamNienData AS (
        SELECT
            MaNV,
            DATEDIFF(year, NgayVaoLam, GETDATE()) AS SoNamThamNien
        FROM NhanSu
        WHERE TrangThai = N'Đang làm việc'
    )
    SELECT
        CASE
            WHEN SoNamThamNien < 1 THEN N'Dưới 1 năm'
            WHEN SoNamThamNien BETWEEN 1 AND 3 THEN N'1 - 3 năm'
            WHEN SoNamThamNien BETWEEN 4 AND 5 THEN N'4 - 5 năm'
            WHEN SoNamThamNien >= 6 THEN N'Trên 5 năm'
            ELSE N'Không xác định'
        END AS KhoangThamNien,
        COUNT(*) AS SoLuongNhanSu
    FROM ThamNienData
    GROUP BY
        CASE
            WHEN SoNamThamNien < 1 THEN N'Dưới 1 năm'
            WHEN SoNamThamNien BETWEEN 1 AND 3 THEN N'1 - 3 năm'
            WHEN SoNamThamNien BETWEEN 4 AND 5 THEN N'4 - 5 năm'
            WHEN SoNamThamNien >= 6 THEN N'Trên 5 năm'
            ELSE N'Không xác định'
        END
    ORDER BY SoLuongNhanSu DESC;
END;
GO

-- SP báo cáo giờ làm thêm
CREATE PROCEDURE [dbo].[SP_BaoCaoGioLamThem]
    @Thang INT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @BangGioCong TABLE (
        MaNV INT,
        HoTen NVARCHAR(100),
        TongGioLamViec FLOAT,
        TongGioLamThem FLOAT
    );

    INSERT INTO @BangGioCong (MaNV, HoTen, TongGioLamViec, TongGioLamThem)
    SELECT
        ns.MaNV,
        ns.HoTen,
        SUM(DATEDIFF(minute, cc.GioVao, cc.GioRa) / 60.0) AS TongGioLamViec,
        SUM(
            CASE
                WHEN DATEDIFF(minute, cc.GioVao, cc.GioRa) / 60.0 > 8 THEN
                    (DATEDIFF(minute, cc.GioVao, cc.GioRa) / 60.0) - 8
                ELSE
                    0
            END
        ) AS TongGioLamThem
    FROM NhanSu ns
    JOIN ChamCong cc ON ns.MaNV = cc.MaNV
    WHERE MONTH(cc.Ngay) = @Thang AND YEAR(cc.Ngay) = @Nam
    AND cc.GioVao IS NOT NULL AND cc.GioRa IS NOT NULL
    GROUP BY ns.MaNV, ns.HoTen;

    SELECT
        MaNV,
        HoTen,
        TongGioLamViec,
        TongGioLamThem
    FROM @BangGioCong
    WHERE TongGioLamThem > 0
    ORDER BY TongGioLamThem DESC;
END;
GO

-- =============================================
-- 17. TẠO FUNCTION KIỂM TRA QUYỀN TRUY CẬP
-- =============================================

CREATE FUNCTION dbo.fn_CheckEmployeeAccess(@MaNV INT)
RETURNS BIT
AS
BEGIN
    DECLARE @CurrentUser INT;
    SELECT @CurrentUser = MaNV FROM TaiKhoan WHERE TenDangNhap = SYSTEM_USER;
    
    IF @CurrentUser = @MaNV
        RETURN 1;
    RETURN 0;
END;
GO

-- =============================================
-- 18. TẠO JOB CLEANUP (Nếu cần)
-- =============================================

-- Stored procedure dọn dẹp session cũ
CREATE PROCEDURE [dbo].[SP_CleanupOldSessions]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xóa session cũ hơn 24 giờ
    DELETE FROM UserSessions 
    WHERE LastActivity < DATEADD(hour, -24, GETDATE());
    
    -- Xóa login attempts cũ hơn 30 ngày
    DELETE FROM LoginAttempts 
    WHERE Timestamp < DATEADD(day, -30, GETDATE());
    
    -- Xóa audit log cũ hơn 1 năm
    DELETE FROM AuditLog 
    WHERE Timestamp < DATEADD(year, -1, GETDATE());
END;
GO

-- =============================================
-- KẾT THÚC SCRIPT
-- =============================================

PRINT 'Database QuanLyNhanSu đã được tạo thành công với tất cả các cải thiện!';
PRINT 'Các vấn đề đã được sửa:';
PRINT '1. Logic tính lương cho nhân viên thường';
PRINT '2. SQL Injection vulnerability';
PRINT '3. Phân quyền chi tiết';
PRINT '4. Audit logging';
PRINT '5. Rate limiting cho authentication';
PRINT '6. Performance optimization';
PRINT '7. Error handling cải thiện';
PRINT '8. Data validation đầy đủ';