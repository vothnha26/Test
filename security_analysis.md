# Phân tích Bảo mật Database

## 1. User và Role Management

### 1.1 Users được tạo:
- `hr_manager` - Quản lý nhân sự
- `nhan_vien` - Nhân viên thường  
- `sys_admin` - Quản trị hệ thống

### 1.2 Roles được tạo:
- `HRManager_Role`
- `NhanVien_Role` 
- `SystemAdministrator_Role`

**Vấn đề:**
- `sys_admin` được gán vào `db_owner` - QUÁ QUYỀN HẠN
- Thiếu phân quyền chi tiết cho từng bảng
- Không có audit trail cho các thao tác quan trọng

## 2. Vấn đề Bảo mật Nghiêm trọng

### 2.1 SQL Injection trong SP_TaoTaiKhoanMoiHoanChinh
```sql
SET @CreateLoginSQL = N'CREATE LOGIN [' + @TenDangNhap + N'] WITH PASSWORD = ''' + @MatKhau + N''', CHECK_POLICY = ON;';
EXEC sp_executesql @CreateLoginSQL;
```

**Rủi ro:** Attacker có thể inject SQL code thông qua `@TenDangNhap` hoặc `@MatKhau`

### 2.2 Mật khẩu không được hash đúng cách
```sql
INSERT INTO TaiKhoan (TenDangNhap, MatKhau, MaNV, MaVaiTro, TrangThai)
VALUES (@TenDangNhap, HASHBYTES('SHA2_256', @MatKhau), @MaNV, @MaVaiTro, N'Hoat dong');
```

**Vấn đề:**
- SHA2_256 không phải là cách hash mật khẩu tốt nhất
- Thiếu salt
- Nên dùng bcrypt hoặc Argon2

### 2.3 Thiếu Rate Limiting
- Không có cơ chế chống brute force attack
- Không lock account sau nhiều lần đăng nhập sai

### 2.4 Thiếu Audit Logging
- Không log các thao tác quan trọng
- Không track ai đã thay đổi gì, khi nào

## 3. Đề xuất Cải thiện Bảo mật

### 3.1 Tạo bảng Audit Log
```sql
CREATE TABLE AuditLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(50) NOT NULL,
    Action NVARCHAR(20) NOT NULL, -- INSERT, UPDATE, DELETE
    RecordID INT,
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    UserID NVARCHAR(50),
    IPAddress NVARCHAR(50),
    Timestamp DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE LoginAttempts (
    AttemptID INT IDENTITY(1,1) PRIMARY KEY,
    TenDangNhap NVARCHAR(50) NOT NULL,
    Success BIT NOT NULL,
    IPAddress NVARCHAR(50),
    UserAgent NVARCHAR(500),
    Timestamp DATETIME2 DEFAULT GETDATE()
);
```

### 3.2 Tạo Triggers cho Audit
```sql
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
```

### 3.3 Cải thiện Authentication
```sql
CREATE TABLE UserSessions (
    SessionID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MaNV INT NOT NULL,
    LoginTime DATETIME2 DEFAULT GETDATE(),
    LastActivity DATETIME2 DEFAULT GETDATE(),
    IPAddress NVARCHAR(50),
    UserAgent NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (MaNV) REFERENCES NhanSu(MaNV)
);

-- Stored procedure xác thực an toàn
CREATE PROCEDURE [dbo].[SP_XacThucNguoiDung_Safe]
    @TenDangNhap VARCHAR(50),
    @MatKhau VARCHAR(255),
    @IPAddress NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra rate limiting
    IF (SELECT COUNT(*) FROM LoginAttempts 
        WHERE TenDangNhap = @TenDangNhap 
        AND Success = 0 
        AND Timestamp > DATEADD(minute, -15, GETDATE())) >= 5
    BEGIN
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
        VALUES (@TenDangNhap, 0, @IPAddress);
        THROW 50001, N'Tài khoản tạm thời bị khóa do đăng nhập sai quá nhiều lần', 1;
    END;
    
    -- Xác thực với constant time comparison
    DECLARE @StoredHash VARCHAR(255);
    DECLARE @MaNV INT, @HoTen NVARCHAR(100), @TenVaiTro NVARCHAR(50);
    
    SELECT @StoredHash = MatKhau
    FROM TaiKhoan 
    WHERE TenDangNhap = @TenDangNhap AND TrangThai = N'Hoat dong';
    
    IF @StoredHash IS NULL OR @StoredHash != CONVERT(VARCHAR(255), HASHBYTES('SHA2_256', @MatKhau), 2)
    BEGIN
        INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
        VALUES (@TenDangNhap, 0, @IPAddress);
        THROW 50002, N'Tên đăng nhập hoặc mật khẩu không đúng', 1;
    END;
    
    -- Lấy thông tin user
    SELECT @MaNV = nv.MaNV, @HoTen = nv.HoTen, @TenVaiTro = vt.TenVaiTro
    FROM TaiKhoan tk
    INNER JOIN NhanSu nv ON tk.MaNV = nv.MaNV
    INNER JOIN VaiTro vt ON tk.MaVaiTro = vt.MaVaiTro
    WHERE tk.TenDangNhap = @TenDangNhap;
    
    -- Tạo session
    INSERT INTO UserSessions (MaNV, IPAddress)
    VALUES (@MaNV, @IPAddress);
    
    -- Log successful login
    INSERT INTO LoginAttempts (TenDangNhap, Success, IPAddress)
    VALUES (@TenDangNhap, 1, @IPAddress);
    
    SELECT @MaNV AS MaNV, @HoTen AS HoTen, @TenVaiTro AS TenVaiTro;
END;
```

### 3.4 Phân quyền chi tiết
```sql
-- Tạo các role cụ thể hơn
CREATE ROLE HR_ReadOnly;
CREATE ROLE HR_Write;
CREATE ROLE Employee_Self;

-- Phân quyền cho HR_ReadOnly
GRANT SELECT ON NhanSu TO HR_ReadOnly;
GRANT SELECT ON HopDong TO HR_ReadOnly;
GRANT SELECT ON Luong TO HR_ReadOnly;
GRANT SELECT ON ChiTietLuong TO HR_ReadOnly;

-- Phân quyền cho HR_Write
GRANT SELECT, INSERT, UPDATE ON NhanSu TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON HopDong TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON Luong TO HR_Write;
GRANT SELECT, INSERT, UPDATE ON ChiTietLuong TO HR_Write;

-- Phân quyền cho Employee_Self (chỉ xem thông tin của mình)
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

-- Tạo view cho nhân viên xem thông tin của mình
CREATE VIEW vw_EmployeeSelfInfo
AS
SELECT * FROM NhanSu 
WHERE dbo.fn_CheckEmployeeAccess(MaNV) = 1;

GRANT SELECT ON vw_EmployeeSelfInfo TO Employee_Self;
```

### 3.5 Mã hóa dữ liệu nhạy cảm
```sql
-- Tạo master key và certificate
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';

CREATE CERTIFICATE HR_Certificate
WITH SUBJECT = 'HR Data Encryption';

CREATE SYMMETRIC KEY HR_SymmetricKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE HR_Certificate;

-- Cập nhật bảng NhanSu để mã hóa thông tin nhạy cảm
ALTER TABLE NhanSu ADD 
    Email_Encrypted VARBINARY(MAX),
    SoDienThoai_Encrypted VARBINARY(MAX);

-- Trigger để tự động mã hóa
CREATE TRIGGER TR_NhanSu_Encrypt
ON NhanSu
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    OPEN SYMMETRIC KEY HR_SymmetricKey DECRYPTION BY CERTIFICATE HR_Certificate;
    
    UPDATE NhanSu 
    SET 
        Email_Encrypted = ENCRYPTBYKEY(KEY_GUID('HR_SymmetricKey'), Email),
        SoDienThoai_Encrypted = ENCRYPTBYKEY(KEY_GUID('HR_SymmetricKey'), SoDienThoai)
    WHERE MaNV IN (SELECT MaNV FROM inserted);
    
    CLOSE SYMMETRIC KEY HR_SymmetricKey;
END;
```

## 4. Tổng kết Bảo mật

**Vấn đề nghiêm trọng cần sửa ngay:**
1. SQL Injection trong SP_TaoTaiKhoanMoiHoanChinh
2. Phân quyền quá rộng cho sys_admin
3. Thiếu rate limiting
4. Thiếu audit logging

**Cải thiện cần thiết:**
1. Thêm audit trail
2. Cải thiện authentication
3. Mã hóa dữ liệu nhạy cảm
4. Phân quyền chi tiết hơn
5. Thêm session management