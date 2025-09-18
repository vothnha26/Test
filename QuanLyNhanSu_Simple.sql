-- =============================================
-- Database QuanLyNhanSu - VERSION SIMPLE
-- Chỉ bao gồm: Views, Functions, Procedures, Transactions, Basic Security
-- =============================================

USE [QuanLyNhanSu]
GO

-- =============================================
-- 1. TẠO USERS VÀ ROLES CƠ BẢN
-- =============================================

-- Tạo Users
CREATE USER [hr_manager] FOR LOGIN [hr_manager_login] WITH DEFAULT_SCHEMA=[dbo]
GO
CREATE USER [nhan_vien] FOR LOGIN [nhan_vien_login] WITH DEFAULT_SCHEMA=[dbo]
GO
CREATE USER [sys_admin] FOR LOGIN [sys_admin_login] WITH DEFAULT_SCHEMA=[dbo]
GO

-- Tạo Roles
CREATE ROLE [HRManager_Role]
GO
CREATE ROLE [NhanVien_Role]
GO
CREATE ROLE [SystemAdministrator_Role]
GO

-- Gán Users vào Roles
ALTER ROLE [HRManager_Role] ADD MEMBER [hr_manager]
GO
ALTER ROLE [NhanVien_Role] ADD MEMBER [nhan_vien]
GO
ALTER ROLE [SystemAdministrator_Role] ADD MEMBER [sys_admin]
GO

-- =============================================
-- 2. TẠO BẢNG CHÍNH
-- =============================================

-- Bảng NhanSu
CREATE TABLE [dbo].[NhanSu](
    [MaNV] [int] IDENTITY(1,1) NOT NULL,
    [HoTen] [nvarchar](100) NOT NULL,
    [NgaySinh] [date] NULL,
    [GioiTinh] [nvarchar](10) NULL,
    [Email] [varchar](100) NULL,
    [SoDienThoai] [varchar](20) NULL,
    [ChucDanh] [nvarchar](50) NULL,
    [TrinhDo] [nvarchar](50) NULL,
    [NgayVaoLam] [date] NULL,
    [TrangThai] [nvarchar](50) NOT NULL,
    PRIMARY KEY CLUSTERED ([MaNV] ASC),
    UNIQUE NONCLUSTERED ([Email] ASC)
) ON [PRIMARY]
GO

-- Bảng VaiTro
CREATE TABLE [dbo].[VaiTro](
    [MaVaiTro] [int] IDENTITY(1,1) NOT NULL,
    [TenVaiTro] [nvarchar](50) NOT NULL,
    PRIMARY KEY CLUSTERED ([MaVaiTro] ASC)
) ON [PRIMARY]
GO

-- Bảng TaiKhoan
CREATE TABLE [dbo].[TaiKhoan](
    [MaTK] [int] IDENTITY(1,1) NOT NULL,
    [TenDangNhap] [varchar](50) NOT NULL,
    [MatKhau] [varchar](255) NOT NULL,
    [MaNV] [int] NOT NULL,
    [MaVaiTro] [int] NOT NULL,
    [TrangThai] [nvarchar](20) NOT NULL,
    PRIMARY KEY CLUSTERED ([MaTK] ASC),
    UNIQUE NONCLUSTERED ([TenDangNhap] ASC)
) ON [PRIMARY]
GO

-- Bảng HopDong
CREATE TABLE [dbo].[HopDong](
    [MaHopDong] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [LoaiHopDong] [nvarchar](50) NOT NULL,
    [NgayKy] [date] NULL,
    [NgayKetThuc] [date] NULL,
    [SoHopDong] [varchar](50) NULL,
    [MucLuongCoBan] [decimal](18, 2) NULL,
    [MucLuongTheoGio] [decimal](18, 2) NULL,
    [PhuCapCoDinh] [decimal](18, 2) NULL,
    PRIMARY KEY CLUSTERED ([MaHopDong] ASC),
    CONSTRAINT [UQ_SoHopDong] UNIQUE NONCLUSTERED ([SoHopDong] ASC)
) ON [PRIMARY]
GO

-- Bảng Luong
CREATE TABLE [dbo].[Luong](
    [MaLuong] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [Thang] [int] NOT NULL,
    [Nam] [int] NOT NULL,
    [TongLuong] [decimal](18, 2) NULL,
    [ThucNhan] [decimal](18, 2) NULL,
    PRIMARY KEY CLUSTERED ([MaLuong] ASC)
) ON [PRIMARY]
GO

-- Bảng ChiTietLuong
CREATE TABLE [dbo].[ChiTietLuong](
    [MaChiTiet] [int] IDENTITY(1,1) NOT NULL,
    [MaLuong] [int] NOT NULL,
    [LoaiKhoan] [nvarchar](50) NOT NULL,
    [GiaTri] [decimal](18, 2) NOT NULL,
    [GhiChu] [nvarchar](max) NULL,
    PRIMARY KEY CLUSTERED ([MaChiTiet] ASC)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- Bảng ChamCong
CREATE TABLE [dbo].[ChamCong](
    [MaChamCong] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [Ngay] [date] NOT NULL,
    [GioVao] [time](7) NULL,
    [GioRa] [time](7) NULL,
    PRIMARY KEY CLUSTERED ([MaChamCong] ASC)
) ON [PRIMARY]
GO

-- Bảng DonNghiPhep
CREATE TABLE [dbo].[DonNghiPhep](
    [MaDon] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [LoaiNghi] [nvarchar](50) NOT NULL,
    [NgayBatDau] [date] NOT NULL,
    [NgayKetThuc] [date] NOT NULL,
    [TrangThai] [nvarchar](20) NOT NULL,
    PRIMARY KEY CLUSTERED ([MaDon] ASC)
) ON [PRIMARY]
GO

-- Bảng KhenThuong_KyLuat
CREATE TABLE [dbo].[KhenThuong_KyLuat](
    [MaQD] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [Loai] [nvarchar](20) NOT NULL,
    [NoiDung] [nvarchar](max) NULL,
    [NgayQuyetDinh] [date] NULL,
    PRIMARY KEY CLUSTERED ([MaQD] ASC)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

-- Bảng LopHoc
CREATE TABLE [dbo].[LopHoc](
    [MaLopHoc] [int] IDENTITY(1,1) NOT NULL,
    [TenLopHoc] [nvarchar](100) NOT NULL,
    [MonHoc] [nvarchar](50) NULL,
    [TrinhDo] [nvarchar](50) NULL,
    [SoLuongHocVien] [int] NULL,
    PRIMARY KEY CLUSTERED ([MaLopHoc] ASC)
) ON [PRIMARY]
GO

-- Bảng GioGiangDay
CREATE TABLE [dbo].[GioGiangDay](
    [MaGioDay] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [MaLopHoc] [int] NOT NULL,
    [NgayDay] [date] NOT NULL,
    [SoGio] [float] NOT NULL,
    PRIMARY KEY CLUSTERED ([MaGioDay] ASC)
) ON [PRIMARY]
GO

-- Bảng SoNgayPhep
CREATE TABLE [dbo].[SoNgayPhep](
    [MaSoNgayPhep] [int] IDENTITY(1,1) NOT NULL,
    [MaNV] [int] NOT NULL,
    [Nam] [int] NOT NULL,
    [SoNgayConLai] [decimal](4, 2) NOT NULL,
    PRIMARY KEY CLUSTERED ([MaSoNgayPhep] ASC)
) ON [PRIMARY]
GO

-- =============================================
-- 3. TẠO FOREIGN KEYS
-- =============================================

ALTER TABLE [dbo].[ChamCong] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[ChiTietLuong] ADD FOREIGN KEY([MaLuong]) REFERENCES [dbo].[Luong] ([MaLuong])
GO
ALTER TABLE [dbo].[DonNghiPhep] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[GioGiangDay] ADD FOREIGN KEY([MaLopHoc]) REFERENCES [dbo].[LopHoc] ([MaLopHoc])
GO
ALTER TABLE [dbo].[GioGiangDay] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[HopDong] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[KhenThuong_KyLuat] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[Luong] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[SoNgayPhep] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[TaiKhoan] ADD FOREIGN KEY([MaNV]) REFERENCES [dbo].[NhanSu] ([MaNV])
GO
ALTER TABLE [dbo].[TaiKhoan] ADD FOREIGN KEY([MaVaiTro]) REFERENCES [dbo].[VaiTro] ([MaVaiTro])
GO

-- =============================================
-- 4. TẠO INDEXES CƠ BẢN
-- =============================================

CREATE INDEX IX_HopDong_MaNV_NgayKy ON HopDong (MaNV, NgayKy DESC);
CREATE INDEX IX_ChamCong_MaNV_Ngay ON ChamCong (MaNV, Ngay);
CREATE INDEX IX_ChiTietLuong_MaLuong_LoaiKhoan ON ChiTietLuong (MaLuong, LoaiKhoan);
CREATE INDEX IX_Luong_MaNV_Thang_Nam ON Luong (MaNV, Thang, Nam);
CREATE INDEX IX_TaiKhoan_TenDangNhap ON TaiKhoan (TenDangNhap);

-- =============================================
-- 5. TẠO FUNCTIONS
-- =============================================

-- Function kiểm tra hợp đồng có thể xóa
CREATE FUNCTION [dbo].[FN_KiemTraHopDongCoTheXoa] (@MaHopDong INT)
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM HopDong hd
        INNER JOIN NhanSu ns ON hd.MaNV = ns.MaNV
        WHERE hd.MaHopDong = @MaHopDong 
        AND ns.TrangThai = N'Đang làm việc'
        AND (SELECT COUNT(*) FROM HopDong WHERE MaNV = hd.MaNV) = 1
    )
        RETURN 0; -- Không thể xóa
    RETURN 1; -- Có thể xóa
END;
GO

-- Function kiểm tra số hợp đồng trùng khi cập nhật
CREATE FUNCTION [dbo].[FN_KiemTraSoHopDongTonTai_KhiCapNhat] (@MaHopDongHienTai INT, @SoHopDongMoi VARCHAR(50))
RETURNS BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM HopDong WHERE SoHopDong = @SoHopDongMoi AND MaHopDong <> @MaHopDongHienTai)
        RETURN 1;
    RETURN 0;
END;
GO

-- Function kiểm tra tên đăng nhập tồn tại
CREATE FUNCTION [dbo].[FN_KiemTraTenDangNhapTonTai] (@TenDangNhap VARCHAR(50))
RETURNS BIT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM TaiKhoan WHERE TenDangNhap = @TenDangNhap)
        RETURN 1;
    RETURN 0;
END;
GO

-- Function kiểm tra trùng lịch nghỉ
CREATE FUNCTION [dbo].[FN_KiemTraTrungLichNghi] 
(
    @MaNV INT, 
    @NgayBatDau DATE, 
    @NgayKetThuc DATE
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM DonNghiPhep 
        WHERE MaNV = @MaNV 
        AND TrangThai <> N'Từ chối' 
        AND @NgayBatDau <= NgayKetThuc 
        AND NgayBatDau <= @NgayKetThuc
    )
        RETURN 1; -- Có trùng
    RETURN 0; -- Không trùng
END;
GO

-- Function lấy lương cơ bản hiện hành
CREATE FUNCTION [dbo].[FN_LayLuongCoBanHienHanh] 
(
    @MaNV INT, 
    @NgayTinhLuong DATE
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @LuongCoBan DECIMAL(18, 2);
    
    SELECT TOP 1 @LuongCoBan = MucLuongCoBan 
    FROM HopDong 
    WHERE MaNV = @MaNV 
    AND NgayKy <= @NgayTinhLuong 
    AND (NgayKetThuc IS NULL OR NgayKetThuc >= @NgayTinhLuong)
    ORDER BY NgayKy DESC;
    
    RETURN ISNULL(@LuongCoBan, 0);
END;
GO

-- Function tính số ngày công chuẩn
CREATE FUNCTION [dbo].[FN_SoNgayCongChuan]
(
    @Thang INT,
    @Nam INT,
    @SoNgayLamViecTuan INT = 5 -- Mặc định 5 ngày/tuần
)
RETURNS INT
AS
BEGIN
    DECLARE @NgayDauThang DATE = DATEFROMPARTS(@Nam, @Thang, 1);
    DECLARE @NgayCuoiThang DATE = EOMONTH(@NgayDauThang);
    DECLARE @SoNgayCong INT = 0;

    WHILE @NgayDauThang <= @NgayCuoiThang
    BEGIN
        DECLARE @ThuTrongTuan INT = DATEPART(weekday, @NgayDauThang);
        
        IF @SoNgayLamViecTuan = 5 AND @ThuTrongTuan NOT IN (1, 7) -- 5 ngày: bỏ CN, T7
            SET @SoNgayCong = @SoNgayCong + 1;
        ELSE IF @SoNgayLamViecTuan = 6 AND @ThuTrongTuan NOT IN (1) -- 6 ngày: chỉ bỏ CN
            SET @SoNgayCong = @SoNgayCong + 1;
            
        SET @NgayDauThang = DATEADD(day, 1, @NgayDauThang);
    END;

    RETURN @SoNgayCong;
END;
GO

-- Function thống kê chi phí lương theo tháng
CREATE FUNCTION [dbo].[FN_ThongKe_ChiPhiLuongTheoThang] (@Thang INT, @Nam INT)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    RETURN (SELECT ISNULL(SUM(ThucNhan), 0) FROM Luong WHERE Thang = @Thang AND Nam = @Nam);
END;
GO

-- Function thống kê nhân viên mới trong tháng
CREATE FUNCTION [dbo].[FN_ThongKe_NhanVienMoiTrongThang] (@Thang INT, @Nam INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM NhanSu WHERE MONTH(NgayVaoLam) = @Thang AND YEAR(NgayVaoLam) = @Nam);
END;
GO

-- Function thống kê tổng số nhân viên
CREATE FUNCTION [dbo].[FN_ThongKe_TongSoNhanVien]()
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM NhanSu WHERE TrangThai = N'Đang làm việc');
END;
GO