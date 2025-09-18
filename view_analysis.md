# Phân tích Views

## 1. VW_BangThanhToanLuongChiTiet

**Mục đích:** Hiển thị bảng lương chi tiết với các khoản phụ cấp, thưởng, khấu trừ

**Vấn đề:**
```sql
JOIN HopDong hd ON ns.MaNV = hd.MaNV AND hd.MaHopDong = (SELECT MAX(MaHopDong) FROM HopDong WHERE MaNV = ns.MaNV)
```

**Vấn đề:**
- Subquery trong JOIN có thể chậm
- Không có index optimization
- Logic lấy hợp đồng mới nhất có thể sai nếu có nhiều hợp đồng cùng ngày

**Code cải thiện:**
```sql
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
```

## 2. vw_ThongTinNhanSu

**Đánh giá:** ✅ Logic đúng, performance tốt

**Gợi ý:** Có thể thêm index trên (MaNV, MaVaiTro) để tối ưu

## 3. vw_BaoCaoKhenThuongKyLuat

**Đánh giá:** ✅ Logic đúng, đơn giản

## 4. vw_ThongKeChamCong

**Vấn đề:**
```sql
SUM(DATEDIFF(minute, cc.GioVao, cc.GioRa) / 60.0) AS TongSoGioLam
```

**Vấn đề:**
- Không xử lý trường hợp GioVao hoặc GioRa = NULL
- Có thể tính sai nếu làm việc qua ngày (GioRa < GioVao)

**Code cải thiện:**
```sql
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
```

## 5. vw_ThongKeGioGiangDay

**Đánh giá:** ✅ Logic đúng, đơn giản

## 6. Tổng kết Views

**Views tốt:**
- vw_ThongTinNhanSu
- vw_BaoCaoKhenThuongKyLuat  
- vw_ThongKeGioGiangDay

**Views cần cải thiện:**
- VW_BangThanhToanLuongChiTiet (performance)
- vw_ThongKeChamCong (xử lý edge cases)

## 7. Đề xuất cải thiện chung

### 7.1 Thêm Indexes
```sql
-- Index cho VW_BangThanhToanLuongChiTiet
CREATE INDEX IX_HopDong_MaNV_NgayKy ON HopDong (MaNV, NgayKy DESC);

-- Index cho vw_ThongKeChamCong  
CREATE INDEX IX_ChamCong_MaNV_Ngay ON ChamCong (MaNV, Ngay);

-- Index cho ChiTietLuong
CREATE INDEX IX_ChiTietLuong_MaLuong_LoaiKhoan ON ChiTietLuong (MaLuong, LoaiKhoan);
```

### 7.2 Thêm Materialized Views (nếu cần)
```sql
-- Tạo bảng tạm cho báo cáo thường xuyên
CREATE TABLE ThongKeChamCongThang (
    MaNV INT,
    HoTen NVARCHAR(100),
    Nam INT,
    Thang INT,
    TongNgayCong INT,
    TongSoGioLam FLOAT,
    LastUpdated DATETIME,
    PRIMARY KEY (MaNV, Nam, Thang)
);
```

### 7.3 Cải thiện Error Handling
```sql
-- Thêm validation trong views
CREATE VIEW [dbo].[VW_BangThanhToanLuongChiTiet_Safe]
AS
SELECT
    ns.MaNV, 
    ns.HoTen, 
    l.Thang, 
    l.Nam, 
    ISNULL(hd.MucLuongCoBan, 0) AS MucLuongCoBan,
    ISNULL(lt.PhuCap, 0) AS PhuCap, 
    ISNULL(lt.Thuong, 0) AS Thuong,
    ISNULL(lt.KhauTru, 0) AS KhauTruKhac,
    ISNULL(lt.BaoHiem, 0) AS KhauTruBHXH,
    ISNULL(lt.ThueTNCN, 0) AS KhauTruThue,
    ISNULL(l.TongLuong, 0) AS TongLuong, 
    ISNULL(l.ThucNhan, 0) AS ThucNhan
FROM Luong l
JOIN NhanSu ns ON l.MaNV = ns.MaNV
LEFT JOIN HopDongMoiNhat hd ON ns.MaNV = hd.MaNV AND hd.rn = 1
LEFT JOIN (
    -- Chi tiết lương logic
) AS lt ON l.MaLuong = lt.MaLuong
WHERE ns.TrangThai = N'Đang làm việc'; -- Chỉ hiển thị nhân viên đang làm việc
```