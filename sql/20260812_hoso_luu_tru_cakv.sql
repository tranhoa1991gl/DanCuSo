SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.CoSoLuuTru', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CoSoLuuTru
    (
        IdCoSoLuuTru INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_CoSoLuuTru PRIMARY KEY,
        TenCoSo NVARCHAR(150) NOT NULL,
        LoaiCoSo NVARCHAR(50) NOT NULL,
        ChuCoSo NVARCHAR(100) NULL,
        SoDienThoai VARCHAR(20) NULL,
        IdKhuVuc INT NULL,
        DiaChi NVARCHAR(500) NULL,
        GhiChu NVARCHAR(500) NULL,
        DangHoatDong BIT NOT NULL CONSTRAINT DF_CoSoLuuTru_DangHoatDong DEFAULT(1),
        NgayTao DATETIME NOT NULL CONSTRAINT DF_CoSoLuuTru_NgayTao DEFAULT(GETDATE()),
        NgayCapNhat DATETIME NULL
    );
END
GO

IF OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.KhachLuuTruCoSo
    (
        IdKhachLuuTru INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_KhachLuuTruCoSo PRIMARY KEY,
        IdCoSoLuuTru INT NOT NULL,
        HoVaTen NVARCHAR(100) NOT NULL,
        Cccd VARCHAR(20) NULL,
        SoDienThoai VARCHAR(20) NULL,
        DiaChiThuongTru NVARCHAR(500) NULL,
        NgayDen DATE NOT NULL,
        NgayDiDuKien DATE NULL,
        NgayDiThucTe DATE NULL,
        LyDo NVARCHAR(255) NULL,
        GhiChu NVARCHAR(500) NULL,
        NgayTao DATETIME NOT NULL CONSTRAINT DF_KhachLuuTruCoSo_NgayTao DEFAULT(GETDATE()),
        NgayCapNhat DATETIME NULL,
        CONSTRAINT FK_KhachLuuTruCoSo_CoSo FOREIGN KEY(IdCoSoLuuTru)
            REFERENCES dbo.CoSoLuuTru(IdCoSoLuuTru)
    );
END
GO

IF OBJECT_ID(N'dbo.CoSoLuuTru', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.CoSoLuuTru', N'DangHoatDong') IS NULL
BEGIN
    ALTER TABLE dbo.CoSoLuuTru
        ADD DangHoatDong BIT NOT NULL CONSTRAINT DF_CoSoLuuTru_DangHoatDong DEFAULT(1);
END
GO

IF OBJECT_ID(N'dbo.CoSoLuuTru', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.CoSoLuuTru', N'NgayCapNhat') IS NULL
BEGIN
    ALTER TABLE dbo.CoSoLuuTru ADD NgayCapNhat DATETIME NULL;
END
GO

IF OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.KhachLuuTruCoSo', N'NgayCapNhat') IS NULL
BEGIN
    ALTER TABLE dbo.KhachLuuTruCoSo ADD NgayCapNhat DATETIME NULL;
END
GO

IF OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.KhachLuuTruCoSo') AND name = N'IX_KhachLuuTruCoSo_CoSo_NgayDen')
BEGIN
    CREATE INDEX IX_KhachLuuTruCoSo_CoSo_NgayDen
        ON dbo.KhachLuuTruCoSo(IdCoSoLuuTru, NgayDen DESC);
END
GO

IF OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.KhachLuuTruCoSo') AND name = N'IX_KhachLuuTruCoSo_TrangThai')
BEGIN
    CREATE INDEX IX_KhachLuuTruCoSo_TrangThai
        ON dbo.KhachLuuTruCoSo(NgayDiThucTe, NgayDiDuKien);
END
GO

IF OBJECT_ID(N'dbo.CoSoLuuTru', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.CoSoLuuTru') AND name = N'IX_CoSoLuuTru_KhuVuc')
BEGIN
    CREATE INDEX IX_CoSoLuuTru_KhuVuc
        ON dbo.CoSoLuuTru(IdKhuVuc, DangHoatDong);
END
GO

IF OBJECT_ID(N'dbo.DanhMucDoiTuong', N'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Mãn hạn tù về địa phương')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong) VALUES (N'Mãn hạn tù về địa phương');

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Án treo/cải tạo không giam giữ/quản chế')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong) VALUES (N'Án treo/cải tạo không giam giữ/quản chế');

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Người nghiện ma túy')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong) VALUES (N'Người nghiện ma túy');

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Quản lý sau cai nghiện')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong) VALUES (N'Quản lý sau cai nghiện');

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Theo dõi nghi vấn phạm tội')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong) VALUES (N'Theo dõi nghi vấn phạm tội');
END
GO
