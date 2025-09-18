# Phân tích chi tiết Logic Tính Lương

## 1. Vấn đề chính trong SP_TinhLuongHangThang

### Vấn đề 1: Logic tính lương cho nhân viên thường SAI

**Code hiện tại:**
```sql
TongLuong = MucLuongCoBan + TongGioLamThem * (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam) / 8.0) * 1.5
```

**Vấn đề:**
- Chỉ tính lương cơ bản + giờ làm thêm
- KHÔNG tính lương theo số ngày công thực tế
- Nhân viên nghỉ 1 ngày vẫn nhận đủ lương cơ bản

**Logic ĐÚNG phải là:**
```sql
-- Lương cơ bản theo ngày công thực tế
LuongCoBan = (MucLuongCoBan / SoNgayCongChuan) * TongNgayCongThucTe

-- Giờ làm thêm
LuongLamThem = TongGioLamThem * (MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5

-- Tổng lương
TongLuong = LuongCoBan + LuongLamThem + PhuCap + Thuong
```

### Vấn đề 2: Công thức tính giờ làm thêm SAI

**Code hiện tại:**
```sql
TongGioLamThem * (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam) / 8.0) * 1.5
```

**Vấn đề:**
- Thiếu nhân với `TongGioLamThem` trong phần tính lương cơ bản
- Công thức này chỉ tính được lương 1 giờ làm thêm

### Vấn đề 3: Xử lý trường hợp không có chấm công

**Vấn đề:**
- Nếu nhân viên không có dữ liệu chấm công → `TongNgayCongThucTe = 0`
- Lương sẽ = 0, không hợp lý

**Giải pháp:**
- Cần có cơ chế fallback (ví dụ: tính theo lương cơ bản nếu không có chấm công)
- Hoặc báo lỗi rõ ràng

## 2. Vấn đề trong hàm FN_SoNgayCongChuan

**Code hiện tại:**
```sql
IF DATEPART(weekday, @NgayDauThang) NOT IN (1, 7) -- 1 = Chủ nhật, 7 = Thứ bảy
```

**Vấn đề:**
- Giả định tuần làm việc 5 ngày (bỏ qua thứ 7)
- Nhiều công ty Việt Nam làm việc 6 ngày/tuần
- Cần có tham số configurable

## 3. Vấn đề Performance và Logic

### Vấn đề 1: Stored Procedure quá phức tạp
- 1 SP làm quá nhiều việc
- Khó debug và maintain
- Có thể gây deadlock

### Vấn đề 2: Thiếu validation
- Không kiểm tra dữ liệu đầu vào
- Không xử lý edge cases
- Thiếu error handling chi tiết

## 4. Code sửa lỗi đề xuất

### 4.1 Sửa logic tính lương chính:

```sql
-- Bước 2: Tính toán Tổng Lương (Gross) - SỬA LẠI
UPDATE @BangLuongTam
SET TongLuong = 
    CASE ChucDanh
        WHEN N'Giáo viên' THEN 
            -- Giáo viên: tính theo giờ
            (TongGioLamChuan * MucLuongTheoGio) + 
            (TongGioLamThem * MucLuongTheoGio * 1.5) + 
            PhuCap + Thuong
        ELSE 
            -- Nhân viên thường: tính theo ngày công
            CASE 
                WHEN TongNgayCongThucTe > 0 THEN
                    -- Có chấm công: tính theo ngày công thực tế
                    ((MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam)) * TongNgayCongThucTe) +
                    (TongGioLamThem * (MucLuongCoBan / dbo.FN_SoNgayCongChuan(@Thang, @Nam) / 8.0) * 1.5) +
                    PhuCap + Thuong
                ELSE
                    -- Không có chấm công: tính theo lương cơ bản (có thể cần điều chỉnh)
                    MucLuongCoBan + PhuCap + Thuong
            END
    END;
```

### 4.2 Thêm validation:

```sql
-- Kiểm tra dữ liệu đầu vào
IF @Thang < 1 OR @Thang > 12
    THROW 50001, N'Tháng không hợp lệ (1-12)', 1;

IF @Nam < 2000 OR @Nam > 2100
    THROW 50002, N'Năm không hợp lệ', 1;

-- Kiểm tra có nhân viên nào không
IF NOT EXISTS (SELECT 1 FROM NhanSu WHERE TrangThai = N'Đang làm việc')
    THROW 50003, N'Không có nhân viên đang làm việc', 1;
```

### 4.3 Cải thiện hàm FN_SoNgayCongChuan:

```sql
CREATE FUNCTION [dbo].[FN_SoNgayCongChuan]
(
    @Thang INT,
    @Nam INT,
    @SoNgayLamViecTuan INT = 5 -- Mặc định 5 ngày/tuần, có thể điều chỉnh
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
        
        -- Logic linh hoạt theo số ngày làm việc/tuần
        IF @SoNgayLamViecTuan = 5 AND @ThuTrongTuan NOT IN (1, 7) -- 5 ngày: bỏ CN, T7
            SET @SoNgayCong = @SoNgayCong + 1;
        ELSE IF @SoNgayLamViecTuan = 6 AND @ThuTrongTuan NOT IN (1) -- 6 ngày: chỉ bỏ CN
            SET @SoNgayCong = @SoNgayCong + 1;
            
        SET @NgayDauThang = DATEADD(day, 1, @NgayDauThang);
    END;

    RETURN @SoNgayCong;
END;
```