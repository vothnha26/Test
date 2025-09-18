# Phân tích User-Defined Functions

## 1. FN_KiemTraHopDongCoTheXoa

**Mục đích:** Kiểm tra xem có thể xóa hợp đồng không

**Logic hiện tại:**
```sql
IF @TrangThaiNhanSu = N'Đang làm việc' AND @SoHopDong = 1
    RETURN 0; -- Không thể xóa
RETURN 1; -- Có thể xóa
```

**Vấn đề:**
- Logic đúng nhưng có thể cải thiện performance
- Nên sử dụng EXISTS thay vì COUNT

**Code cải thiện:**
```sql
CREATE FUNCTION [dbo].[FN_KiemTraHopDongCoTheXoa] (@MaHopDong INT)
RETURNS BIT
AS
BEGIN
    -- Kiểm tra nhân viên có đang làm việc và chỉ có 1 hợp đồng không
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
```

## 2. FN_KiemTraSoHopDongTonTai_KhiCapNhat

**Logic:** Kiểm tra số hợp đồng trùng khi cập nhật

**Đánh giá:** ✅ Logic đúng, code tốt

## 3. FN_KiemTraTenDangNhapTonTai

**Logic:** Kiểm tra tên đăng nhập đã tồn tại

**Đánh giá:** ✅ Logic đúng, code tốt

## 4. FN_KiemTraTrungLichNghi

**Logic:** Kiểm tra trùng lịch nghỉ phép

**Vấn đề:**
- Logic đúng nhưng có thể tối ưu
- Điều kiện `@NgayBatDau <= NgayKetThuc AND @NgayKetThuc >= NgayBatDau` có thể viết gọn hơn

**Code cải thiện:**
```sql
CREATE FUNCTION [dbo].[FN_KiemTraTrungLichNghi] 
(
    @MaNV INT, 
    @NgayBatDau DATE, 
    @NgayKetThuc DATE
)
RETURNS BIT
AS
BEGIN
    -- Kiểm tra overlap: (Start1 <= End2) AND (Start2 <= End1)
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
```

## 5. FN_LayLuongCoBanHienHanh

**Logic:** Lấy lương cơ bản hiện hành của nhân viên

**Vấn đề:**
- Logic đúng nhưng có thể cải thiện
- Nên kiểm tra hợp đồng còn hiệu lực

**Code cải thiện:**
```sql
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
    AND (NgayKetThuc IS NULL OR NgayKetThuc >= @NgayTinhLuong) -- Kiểm tra hợp đồng còn hiệu lực
    ORDER BY NgayKy DESC;
    
    RETURN ISNULL(@LuongCoBan, 0);
END;
```

## 6. FN_SoNgayCongChuan

**Vấn đề đã phân tích ở phần trước:**
- Giả định tuần làm việc 5 ngày
- Cần linh hoạt hơn

## 7. Các hàm thống kê

### FN_ThongKe_ChiPhiLuongTheoThang
**Đánh giá:** ✅ Logic đúng

### FN_ThongKe_NhanVienMoiTrongThang  
**Đánh giá:** ✅ Logic đúng

### FN_ThongKe_TongSoNhanVien
**Đánh giá:** ✅ Logic đúng

## 8. Tổng kết Functions

**Functions tốt:**
- FN_KiemTraSoHopDongTonTai_KhiCapNhat
- FN_KiemTraTenDangNhapTonTai  
- FN_ThongKe_ChiPhiLuongTheoThang
- FN_ThongKe_NhanVienMoiTrongThang
- FN_ThongKe_TongSoNhanVien

**Functions cần cải thiện:**
- FN_KiemTraHopDongCoTheXoa (performance)
- FN_KiemTraTrungLichNghi (tối ưu logic)
- FN_LayLuongCoBanHienHanh (kiểm tra hiệu lực hợp đồng)
- FN_SoNgayCongChuan (linh hoạt số ngày làm việc)

**Functions có vấn đề nghiêm trọng:**
- Không có (tất cả đều hoạt động được, chỉ cần tối ưu)