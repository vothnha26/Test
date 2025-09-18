# Phân tích Database Quản lý Nhân sự

## 1. Cấu trúc Database

### Bảng chính:
- **NhanSu**: Thông tin nhân viên
- **HopDong**: Hợp đồng lao động
- **Luong**: Bảng lương hàng tháng
- **ChiTietLuong**: Chi tiết các khoản lương
- **ChamCong**: Chấm công
- **TaiKhoan**: Tài khoản đăng nhập
- **VaiTro**: Vai trò người dùng

### Bảng phụ trợ:
- **DonNghiPhep**: Đơn xin nghỉ phép
- **KhenThuong_KyLuat**: Khen thưởng/kỷ luật
- **GioGiangDay**: Giờ giảng dạy (cho giáo viên)
- **LopHoc**: Lớp học
- **SoNgayPhep**: Số ngày phép còn lại

## 2. Phân tích Logic Tính Lương

### Stored Procedure: SP_TinhLuongHangThang

**Logic tính lương cho 2 loại nhân viên:**

#### A. Giáo viên (ChucDanh = 'Giáo viên'):
```sql
TongLuong = TongGioLamChuan * MucLuongTheoGio + TongGioLamThem * MucLuongTheoGio * 1.5
```

#### B. Nhân viên khác:
```sql
TongLuong = MucLuongCoBan + TongGioLamThem * (MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5
```

### Các khoản khấu trừ:
1. **BHXH**: 8% tổng lương
2. **Thuế TNCN**: 10% trên phần vượt 11,000,000 VND
3. **Các khoản khấu trừ khác**: Từ bảng ChiTietLuong

## 3. Vấn đề phát hiện

### 3.1 Logic tính lương có vấn đề:

**Vấn đề 1: Tính lương cơ bản cho nhân viên**
- Nhân viên thường được tính lương theo ngày công thực tế, nhưng logic hiện tại chỉ cộng thêm giờ làm thêm
- Thiếu tính lương cơ bản theo số ngày công thực tế

**Vấn đề 2: Công thức tính giờ làm thêm**
- Công thức: `(MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5` có thể không chính xác
- Nên là: `(MucLuongCoBan / SoNgayCongChuan / 8.0) * TongGioLamThem * 1.5`

**Vấn đề 3: Thiếu xử lý trường hợp không có chấm công**
- Nếu nhân viên không có dữ liệu chấm công, lương sẽ = 0

### 3.2 Hàm FN_SoNgayCongChuan có vấn đề:
- Tính theo tuần làm việc 5 ngày (bỏ qua thứ 7, chủ nhật)
- Nhưng nhiều công ty làm việc 6 ngày/tuần

### 3.3 Stored Procedure SP_TinhLuongHangThang:
- Logic phức tạp, khó maintain
- Thiếu xử lý edge cases
- Có thể gây deadlock khi xử lý nhiều nhân viên

## 4. Đề xuất cải thiện

### 4.1 Sửa logic tính lương:

```sql
-- Cho nhân viên thường:
TongLuong = (MucLuongCoBan / SoNgayCongChuan) * TongNgayCongThucTe 
           + TongGioLamThem * (MucLuongCoBan / SoNgayCongChuan / 8.0) * 1.5
           + PhuCap + Thuong

-- Cho giáo viên:
TongLuong = TongGioLamChuan * MucLuongTheoGio 
           + TongGioLamThem * MucLuongTheoGio * 1.5
           + PhuCap + Thuong
```

### 4.2 Cải thiện xử lý lỗi:
- Thêm validation cho dữ liệu đầu vào
- Xử lý trường hợp dữ liệu null
- Thêm logging cho audit trail

### 4.3 Tối ưu performance:
- Sử dụng batch processing
- Thêm indexes phù hợp
- Tách logic phức tạp thành các function nhỏ hơn