-- =============================================
-- PHẦN 3: PHÂN QUYỀN VÀ DỮ LIỆU MẪU
-- =============================================

-- =============================================
-- 11. PHÂN QUYỀN CƠ BẢN
-- =============================================

-- Phân quyền cho HRManager_Role
GRANT SELECT, INSERT, UPDATE, DELETE ON NhanSu TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON HopDong TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON Luong TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ChiTietLuong TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ChamCong TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON DonNghiPhep TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON KhenThuong_KyLuat TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON GioGiangDay TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON LopHoc TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON SoNgayPhep TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON VaiTro TO HRManager_Role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TaiKhoan TO HRManager_Role;

-- Phân quyền cho NhanVien_Role
GRANT SELECT ON NhanSu TO NhanVien_Role;
GRANT SELECT ON Luong TO NhanVien_Role;
GRANT SELECT ON ChiTietLuong TO NhanVien_Role;
GRANT SELECT ON ChamCong TO NhanVien_Role;
GRANT SELECT ON DonNghiPhep TO NhanVien_Role;
GRANT INSERT ON DonNghiPhep TO NhanVien_Role; -- Cho phép nộp đơn nghỉ phép

-- Phân quyền cho SystemAdministrator_Role
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES TO SystemAdministrator_Role;
GRANT EXECUTE ON ALL STORED PROCEDURES TO SystemAdministrator_Role;
GRANT SELECT ON ALL VIEWS TO SystemAdministrator_Role;

-- Phân quyền cho Views
GRANT SELECT ON VW_BangThanhToanLuongChiTiet TO HRManager_Role;
GRANT SELECT ON vw_ThongTinNhanSu TO HRManager_Role;
GRANT SELECT ON vw_BaoCaoKhenThuongKyLuat TO HRManager_Role;
GRANT SELECT ON vw_ThongKeChamCong TO HRManager_Role;
GRANT SELECT ON vw_ThongKeGioGiangDay TO HRManager_Role;

GRANT SELECT ON vw_ThongTinNhanSu TO NhanVien_Role;

-- =============================================
-- 12. TẠO DỮ LIỆU MẪU
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
(N'Lê Văn C', '1992-08-10', N'Nam', 'levanc@company.com', '0369258147', N'Nhân viên', N'Đại học', '2021-06-01', N'Đang làm việc'),
(N'Phạm Thị D', '1988-12-05', N'Nữ', 'phamthid@company.com', '0147258369', N'Giáo viên', N'Tiến sĩ', '2018-09-01', N'Đang làm việc'),
(N'Hoàng Văn E', '1995-03-25', N'Nam', 'hoangvane@company.com', '0258147369', N'Nhân viên', N'Cao đẳng', '2022-01-15', N'Đang làm việc');

-- Thêm hợp đồng mẫu
INSERT INTO HopDong (MaNV, SoHopDong, LoaiHopDong, NgayKy, NgayKetThuc, MucLuongCoBan, MucLuongTheoGio, PhuCapCoDinh) VALUES
(1, 'HD001', N'Hợp đồng không xác định thời hạn', '2020-01-01', NULL, 15000000, NULL, 2000000),
(2, 'HD002', N'Hợp đồng xác định thời hạn', '2019-03-15', '2024-03-15', 12000000, 150000, 1000000),
(3, 'HD003', N'Hợp đồng thử việc', '2021-06-01', '2021-12-01', 8000000, NULL, 500000),
(4, 'HD004', N'Hợp đồng không xác định thời hạn', '2018-09-01', NULL, 18000000, 200000, 2500000),
(5, 'HD005', N'Hợp đồng xác định thời hạn', '2022-01-15', '2025-01-15', 9000000, NULL, 800000);

-- Thêm tài khoản mẫu
INSERT INTO TaiKhoan (TenDangNhap, MatKhau, MaNV, MaVaiTro, TrangThai) VALUES
('admin', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'admin123'), 2), 1, 1, N'Hoat dong'),
('teacher1', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'teacher123'), 2, 3, N'Hoat dong'),
('employee1', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'employee123'), 3, 2, N'Hoat dong'),
('teacher2', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'teacher456'), 4, 3, N'Hoat dong'),
('employee2', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', 'employee456'), 5, 2, N'Hoat dong');

-- Thêm lớp học mẫu
INSERT INTO LopHoc (TenLopHoc, MonHoc, TrinhDo, SoLuongHocVien) VALUES
(N'Lớp Toán 10A1', N'Toán học', N'Lớp 10', 35),
(N'Lớp Văn 11B2', N'Ngữ văn', N'Lớp 11', 32),
(N'Lớp Anh 12C1', N'Tiếng Anh', N'Lớp 12', 28),
(N'Lớp Lý 10A2', N'Vật lý', N'Lớp 10', 30);

-- Thêm giờ giảng dạy mẫu
INSERT INTO GioGiangDay (MaNV, MaLopHoc, NgayDay, SoGio) VALUES
(2, 1, '2024-12-01', 2.0),
(2, 1, '2024-12-03', 2.0),
(2, 1, '2024-12-05', 2.0),
(4, 2, '2024-12-02', 1.5),
(4, 2, '2024-12-04', 1.5),
(4, 3, '2024-12-01', 2.0);

-- Thêm chấm công mẫu
INSERT INTO ChamCong (MaNV, Ngay, GioVao, GioRa) VALUES
(1, '2024-12-01', '08:00:00', '17:00:00'),
(1, '2024-12-02', '08:15:00', '17:30:00'),
(1, '2024-12-03', '08:00:00', '18:00:00'),
(3, '2024-12-01', '08:30:00', '17:00:00'),
(3, '2024-12-02', '08:00:00', '17:00:00'),
(3, '2024-12-03', '08:15:00', '17:15:00'),
(5, '2024-12-01', '08:00:00', '17:00:00'),
(5, '2024-12-02', '08:00:00', '17:00:00');

-- Thêm đơn nghỉ phép mẫu
INSERT INTO DonNghiPhep (MaNV, LoaiNghi, NgayBatDau, NgayKetThuc, TrangThai) VALUES
(3, N'Nghỉ phép', '2024-12-10', '2024-12-12', N'Chờ duyệt'),
(5, N'Nghỉ ốm', '2024-12-05', '2024-12-06', N'Đã duyệt');

-- Thêm khen thưởng kỷ luật mẫu
INSERT INTO KhenThuong_KyLuat (MaNV, Loai, NoiDung, NgayQuyetDinh) VALUES
(2, N'Khen thưởng', N'Hoàn thành xuất sắc nhiệm vụ giảng dạy', '2024-11-15'),
(4, N'Khen thưởng', N'Đạt giải nhất cuộc thi giáo viên dạy giỏi', '2024-11-20'),
(1, N'Khen thưởng', N'Quản lý nhân sự hiệu quả', '2024-11-25');

-- =============================================
-- 13. CÁC STORED PROCEDURE BÁO CÁO
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
        COUNT(kt.MaQD) AS SoLan
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

-- SP báo cáo nhân sự thực tế
CREATE PROCEDURE [dbo].[SP_BaoCaoNhanSuThucTe]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ns.MaNV,
        ns.HoTen,
        ns.ChucDanh,
        ns.NgayVaoLam,
        DATEDIFF(year, ns.NgayVaoLam, GETDATE()) AS SoNamThamNien,
        hd.SoHopDong,
        hd.LoaiHopDong,
        hd.MucLuongCoBan,
        hd.MucLuongTheoGio,
        ns.Email,
        ns.SoDienThoai,
        ns.TrangThai
    FROM
        NhanSu AS ns
    LEFT JOIN
        HopDong AS hd ON ns.MaNV = hd.MaNV AND hd.MaHopDong = (SELECT MAX(MaHopDong) FROM HopDong WHERE MaNV = ns.MaNV)
    ORDER BY
        ns.NgayVaoLam;
END;
GO

-- =============================================
-- 14. TEST CÁC CHỨC NĂNG
-- =============================================

-- Test tính lương
PRINT 'Testing salary calculation...';
EXEC SP_TinhLuongHangThang @Thang = 12, @Nam = 2024;

-- Test xác thực
PRINT 'Testing authentication...';
EXEC SP_XacThucNguoiDung @TenDangNhap = 'admin', @MatKhau = 'admin123';

-- Test báo cáo
PRINT 'Testing reports...';
EXEC SP_BaoCaoThamNienNhanSu;
EXEC SP_BaoCaoKhenThuongKyLuat @Nam = 2024;

-- =============================================
-- KẾT THÚC SCRIPT
-- =============================================

PRINT 'Database QuanLyNhanSu Simple đã được tạo thành công!';
PRINT 'Các tính năng chính:';
PRINT '1. Views: VW_BangThanhToanLuongChiTiet, vw_ThongTinNhanSu, vw_BaoCaoKhenThuongKyLuat, vw_ThongKeChamCong, vw_ThongKeGioGiangDay';
PRINT '2. Functions: 8 functions hỗ trợ tính toán và validation';
PRINT '3. Stored Procedures: Tính lương, xác thực, CRUD operations, báo cáo';
PRINT '4. Transactions: Tất cả operations đều có transaction handling';
PRINT '5. Security: Users, Roles, và phân quyền cơ bản';
PRINT '6. Authentication: SP_XacThucNguoiDung với hash password';
PRINT '';
PRINT 'Tài khoản mẫu:';
PRINT 'admin/admin123 - Quản lý nhân sự';
PRINT 'teacher1/teacher123 - Giáo viên';
PRINT 'employee1/employee123 - Nhân viên';