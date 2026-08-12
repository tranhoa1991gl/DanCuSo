/*
MigrationId: 20260811_residency_identity_guest_objects
Purpose:
- Add residence type/origin address for households and members.
- Add identity level catalog.
- Add temporary guest/relative stay tracking and history.
- Add dynamic social/policy object catalog for members.
- Add household classification catalog and party-member schema if missing.

Encoding: UTF-8
*/

SET XACT_ABORT ON
GO

IF OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.HoGiaDinh', N'loaiCuTru') IS NULL
        ALTER TABLE dbo.HoGiaDinh ADD loaiCuTru NVARCHAR(20) NULL;

    IF COL_LENGTH(N'dbo.HoGiaDinh', N'diaChiThuongTruGoc') IS NULL
        ALTER TABLE dbo.HoGiaDinh ADD diaChiThuongTruGoc NVARCHAR(500) NULL;
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NOT NULL
BEGIN
    UPDATE dbo.HoGiaDinh
    SET loaiCuTru = N'Thường trú'
    WHERE loaiCuTru IS NULL OR LTRIM(RTRIM(loaiCuTru)) = N'';
END
GO

IF OBJECT_ID(N'dbo.DanhMucMucDinhDanh', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DanhMucMucDinhDanh
    (
        idMucDinhDanh INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        tenMucDinhDanh NVARCHAR(100) NOT NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucMucDinhDanh WHERE tenMucDinhDanh = N'Mức 1')
    INSERT INTO dbo.DanhMucMucDinhDanh (tenMucDinhDanh) VALUES (N'Mức 1');
IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucMucDinhDanh WHERE tenMucDinhDanh = N'Mức 2')
    INSERT INTO dbo.DanhMucMucDinhDanh (tenMucDinhDanh) VALUES (N'Mức 2');
IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucMucDinhDanh WHERE tenMucDinhDanh = N'Chưa định danh')
    INSERT INTO dbo.DanhMucMucDinhDanh (tenMucDinhDanh) VALUES (N'Chưa định danh');
GO

IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.ThanhVien', N'loaiCuTru') IS NULL
        ALTER TABLE dbo.ThanhVien ADD loaiCuTru NVARCHAR(20) NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'diaChiThuongTruGoc') IS NULL
        ALTER TABLE dbo.ThanhVien ADD diaChiThuongTruGoc NVARCHAR(500) NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'dinhDanh') IS NULL
        ALTER TABLE dbo.ThanhVien ADD dinhDanh NVARCHAR(100) NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'idMucDinhDanh') IS NULL
        ALTER TABLE dbo.ThanhVien ADD idMucDinhDanh INT NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'laKhachLuuTru') IS NULL
        ALTER TABLE dbo.ThanhVien ADD laKhachLuuTru BIT NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'ngayDenLuuTru') IS NULL
        ALTER TABLE dbo.ThanhVien ADD ngayDenLuuTru DATE NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'ngayDiDuKien') IS NULL
        ALTER TABLE dbo.ThanhVien ADD ngayDiDuKien DATE NULL;

    IF COL_LENGTH(N'dbo.ThanhVien', N'lyDoLuuTru') IS NULL
        ALTER TABLE dbo.ThanhVien ADD lyDoLuuTru NVARCHAR(255) NULL;
END
GO

IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NOT NULL
BEGIN
    UPDATE dbo.ThanhVien
    SET loaiCuTru = CASE WHEN ISNULL(laTamTru, 0) = 1 THEN N'Tạm trú' ELSE N'Thường trú' END
    WHERE loaiCuTru IS NULL OR LTRIM(RTRIM(loaiCuTru)) = N'';

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.ThanhVien') AND name = N'IX_ThanhVien_HoGiaDinh')
        CREATE INDEX IX_ThanhVien_HoGiaDinh ON dbo.ThanhVien(idHoGiaDinh, laChuHo DESC, idThanhVien ASC);
END
GO

IF OBJECT_ID(N'dbo.DanhMucDoiTuong', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DanhMucDoiTuong
    (
        idDoiTuong INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        tenDoiTuong NVARCHAR(150) NOT NULL
    );
END
GO

IF OBJECT_ID(N'dbo.ThanhVien_DoiTuong', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ThanhVien_DoiTuong
    (
        idThanhVien INT NOT NULL,
        idDoiTuong INT NOT NULL,
        CONSTRAINT PK_ThanhVien_DoiTuong PRIMARY KEY (idThanhVien, idDoiTuong)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Bảo trợ xã hội')
    INSERT INTO dbo.DanhMucDoiTuong (tenDoiTuong) VALUES (N'Bảo trợ xã hội');
IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Người khuyết tật')
    INSERT INTO dbo.DanhMucDoiTuong (tenDoiTuong) VALUES (N'Người khuyết tật');
IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Thương binh')
    INSERT INTO dbo.DanhMucDoiTuong (tenDoiTuong) VALUES (N'Thương binh');
IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Nạn nhân chất độc da cam')
    INSERT INTO dbo.DanhMucDoiTuong (tenDoiTuong) VALUES (N'Nạn nhân chất độc da cam');
GO

IF OBJECT_ID(N'dbo.LichSuLuuTru', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.LichSuLuuTru
    (
        idLichSuLuuTru INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        idThanhVien INT NULL,
        idHoGiaDinh INT NULL,
        hoVaTen NVARCHAR(100) NOT NULL,
        cccd VARCHAR(20) NULL,
        maHoKhau VARCHAR(50) NULL,
        tenChuHo NVARCHAR(100) NULL,
        diaChiLuuTru NVARCHAR(500) NULL,
        diaChiThuongTruGoc NVARCHAR(500) NULL,
        ngayDen DATE NOT NULL,
        ngayDiDuKien DATE NULL,
        ngayDiThucTe DATE NULL,
        lyDo NVARCHAR(255) NULL,
        ghiChu NVARCHAR(500) NULL,
        ngayTao DATETIME NOT NULL CONSTRAINT DF_LichSuLuuTru_NgayTao DEFAULT(GETDATE()),
        ngayCapNhat DATETIME NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.LichSuLuuTru') AND name = N'IX_LichSuLuuTru_Ho_NgayDen')
    CREATE INDEX IX_LichSuLuuTru_Ho_NgayDen ON dbo.LichSuLuuTru(idHoGiaDinh, ngayDen DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.LichSuLuuTru') AND name = N'IX_LichSuLuuTru_ThanhVien')
    CREATE INDEX IX_LichSuLuuTru_ThanhVien ON dbo.LichSuLuuTru(idThanhVien, ngayDiThucTe);
GO

IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.LichSuLuuTru', N'U') IS NOT NULL
BEGIN
    INSERT INTO dbo.LichSuLuuTru
    (
        idThanhVien, idHoGiaDinh, hoVaTen, cccd, maHoKhau, tenChuHo,
        diaChiLuuTru, diaChiThuongTruGoc, ngayDen, ngayDiDuKien, lyDo
    )
    SELECT
        tv.idThanhVien,
        tv.idHoGiaDinh,
        ISNULL(tv.hoVaTen, N'Chưa rõ'),
        tv.cccd,
        h.maHoKhau,
        h.tenChuHo,
        LTRIM(RTRIM(ISNULL(k.tenKhuVuc, N'') + CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(h.diaChiChiTiet, N''))), N'') IS NULL THEN N'' ELSE N' - ' + LTRIM(RTRIM(h.diaChiChiTiet)) END)),
        tv.diaChiThuongTruGoc,
        ISNULL(tv.ngayDenLuuTru, CAST(GETDATE() AS date)),
        tv.ngayDiDuKien,
        tv.lyDoLuuTru
    FROM dbo.ThanhVien tv
    LEFT JOIN dbo.HoGiaDinh h ON tv.idHoGiaDinh = h.idHoGiaDinh
    LEFT JOIN dbo.DanhMucKhuVuc k ON h.idKhuVuc = k.idKhuVuc
    WHERE ISNULL(tv.laKhachLuuTru, 0) = 1
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.LichSuLuuTru ls
          WHERE ls.idThanhVien = tv.idThanhVien
            AND ls.ngayDiThucTe IS NULL
      );
END
GO

IF OBJECT_ID(N'dbo.DanhMucPhanLoaiHo', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DanhMucPhanLoaiHo
    (
        IdPhanLoaiHo INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DanhMucPhanLoaiHo PRIMARY KEY,
        TenPhanLoaiHo NVARCHAR(100) NOT NULL,
        NgayTao DATETIME NOT NULL CONSTRAINT DF_DanhMucPhanLoaiHo_NgayTao DEFAULT(GETDATE())
    );
END
GO

IF OBJECT_ID(N'dbo.DanhMucPhanLoaiHo', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.DanhMucPhanLoaiHo') AND name = N'UX_DanhMucPhanLoaiHo_Ten')
   AND NOT EXISTS
   (
       SELECT 1
       FROM dbo.DanhMucPhanLoaiHo
       GROUP BY TenPhanLoaiHo
       HAVING COUNT(1) > 1
   )
BEGIN
    CREATE UNIQUE INDEX UX_DanhMucPhanLoaiHo_Ten ON dbo.DanhMucPhanLoaiHo(TenPhanLoaiHo);
END
GO

IF OBJECT_ID(N'dbo.DanhMucPhanLoaiHo', N'U') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM dbo.DanhMucPhanLoaiHo)
BEGIN
    INSERT INTO dbo.DanhMucPhanLoaiHo(TenPhanLoaiHo)
    VALUES (N'Bình thường'), (N'Hộ nghèo'), (N'Hộ cận nghèo');
END
GO

IF OBJECT_ID(N'dbo.DangVien', N'U') IS NULL
   AND OBJECT_ID(N'dbo.ThanhVien', N'U') IS NOT NULL
BEGIN
    CREATE TABLE dbo.DangVien
    (
        IdDangVien INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DangVien PRIMARY KEY,
        IdThanhVien INT NOT NULL,
        NgayKetNap DATE NULL,
        NgayChinhThuc DATE NULL,
        ChucDanh NVARCHAR(100) NULL,
        GhiChu NVARCHAR(500) NULL,
        NgayTao DATETIME NOT NULL CONSTRAINT DF_DangVien_NgayTao DEFAULT(GETDATE()),
        NgayCapNhat DATETIME NULL,
        CONSTRAINT FK_DangVien_ThanhVien FOREIGN KEY(IdThanhVien)
            REFERENCES dbo.ThanhVien(IdThanhVien) ON DELETE CASCADE,
        CONSTRAINT UQ_DangVien_IdThanhVien UNIQUE(IdThanhVien)
    );
END
GO

IF OBJECT_ID(N'dbo.DangVien', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.DangVien', N'GhiChu') IS NULL
BEGIN
    ALTER TABLE dbo.DangVien ADD GhiChu NVARCHAR(500) NULL;
END
GO

IF OBJECT_ID(N'dbo.DangVien', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.DangVien', N'NgayCapNhat') IS NULL
BEGIN
    ALTER TABLE dbo.DangVien ADD NgayCapNhat DATETIME NULL;
END
GO
