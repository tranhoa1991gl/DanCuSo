SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NULL
       OR OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NULL
       OR OBJECT_ID(N'dbo.LichSuLuuTru', N'U') IS NULL
        THROW 51100, N'Chưa có đủ schema lưu trú để cài đặt kiểm soát nâng cao.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.ThanhVien tv
        INNER JOIN dbo.KhachLuuTruCoSo kh
            ON LTRIM(RTRIM(kh.cccd)) = LTRIM(RTRIM(tv.cccd))
        WHERE ISNULL(tv.laKhachLuuTru, 0) = 1
          AND kh.DaXoa = 0
          AND kh.ngayDiThucTe IS NULL
          AND NULLIF(LTRIM(RTRIM(ISNULL(tv.cccd, ''))), '') IS NOT NULL
    )
        THROW 51101, N'Một CCCD đang lưu trú đồng thời tại hộ dân và cơ sở lưu trú. Cần xử lý trước khi cập nhật.', 1;

    IF OBJECT_ID(N'dbo.PhienLuuTruDangHoatDong', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.PhienLuuTruDangHoatDong
        (
            Cccd VARCHAR(20) NOT NULL CONSTRAINT PK_PhienLuuTruDangHoatDong PRIMARY KEY,
            Nguon NVARCHAR(30) NOT NULL,
            IdThanhVien INT NULL,
            IdKhachLuuTru INT NULL,
            NgayCapNhat DATETIME NOT NULL CONSTRAINT DF_PhienLuuTruDangHoatDong_NgayCapNhat DEFAULT GETDATE(),
            CONSTRAINT CK_PhienLuuTruDangHoatDong_Nguon CHECK (Nguon IN (N'Hộ dân', N'Cơ sở lưu trú')),
            CONSTRAINT CK_PhienLuuTruDangHoatDong_ThamChieu CHECK
            (
                (Nguon = N'Hộ dân' AND IdThanhVien IS NOT NULL AND IdKhachLuuTru IS NULL)
                OR
                (Nguon = N'Cơ sở lưu trú' AND IdThanhVien IS NULL AND IdKhachLuuTru IS NOT NULL)
            )
        );
    END;

    DELETE FROM dbo.PhienLuuTruDangHoatDong;

    INSERT INTO dbo.PhienLuuTruDangHoatDong(Cccd, Nguon, IdThanhVien, IdKhachLuuTru)
    SELECT LTRIM(RTRIM(tv.cccd)), N'Hộ dân', tv.idThanhVien, NULL
    FROM dbo.ThanhVien tv
    WHERE ISNULL(tv.laKhachLuuTru, 0) = 1
      AND NULLIF(LTRIM(RTRIM(ISNULL(tv.cccd, ''))), '') IS NOT NULL;

    INSERT INTO dbo.PhienLuuTruDangHoatDong(Cccd, Nguon, IdThanhVien, IdKhachLuuTru)
    SELECT LTRIM(RTRIM(kh.cccd)), N'Cơ sở lưu trú', NULL, kh.IdKhachLuuTru
    FROM dbo.KhachLuuTruCoSo kh
    WHERE kh.DaXoa = 0
      AND kh.ngayDiThucTe IS NULL
      AND NULLIF(LTRIM(RTRIM(ISNULL(kh.cccd, ''))), '') IS NOT NULL;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.PhienLuuTruDangHoatDong')
          AND name = N'UX_PhienLuuTruDangHoatDong_IdThanhVien'
    )
        CREATE UNIQUE INDEX UX_PhienLuuTruDangHoatDong_IdThanhVien
            ON dbo.PhienLuuTruDangHoatDong(IdThanhVien)
            WHERE IdThanhVien IS NOT NULL;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.PhienLuuTruDangHoatDong')
          AND name = N'UX_PhienLuuTruDangHoatDong_IdKhachLuuTru'
    )
        CREATE UNIQUE INDEX UX_PhienLuuTruDangHoatDong_IdKhachLuuTru
            ON dbo.PhienLuuTruDangHoatDong(IdKhachLuuTru)
            WHERE IdKhachLuuTru IS NOT NULL;

    EXEC(N'
CREATE OR ALTER TRIGGER dbo.TR_ThanhVien_DongBoPhienLuuTru
ON dbo.ThanhVien
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE registry
    FROM dbo.PhienLuuTruDangHoatDong registry
    INNER JOIN deleted oldRow ON oldRow.idThanhVien = registry.IdThanhVien
    WHERE registry.Nguon = N''Hộ dân'';

    INSERT INTO dbo.PhienLuuTruDangHoatDong(Cccd, Nguon, IdThanhVien, IdKhachLuuTru)
    SELECT LTRIM(RTRIM(newRow.cccd)), N''Hộ dân'', newRow.idThanhVien, NULL
    FROM inserted newRow
    WHERE ISNULL(newRow.laKhachLuuTru, 0) = 1
      AND NULLIF(LTRIM(RTRIM(ISNULL(newRow.cccd, ''''))), '''') IS NOT NULL;
END;');

    EXEC(N'
CREATE OR ALTER TRIGGER dbo.TR_KhachLuuTruCoSo_DongBoPhienLuuTru
ON dbo.KhachLuuTruCoSo
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE registry
    FROM dbo.PhienLuuTruDangHoatDong registry
    INNER JOIN deleted oldRow ON oldRow.IdKhachLuuTru = registry.IdKhachLuuTru
    WHERE registry.Nguon = N''Cơ sở lưu trú'';

    INSERT INTO dbo.PhienLuuTruDangHoatDong(Cccd, Nguon, IdThanhVien, IdKhachLuuTru)
    SELECT LTRIM(RTRIM(newRow.cccd)), N''Cơ sở lưu trú'', NULL, newRow.IdKhachLuuTru
    FROM inserted newRow
    WHERE newRow.DaXoa = 0
      AND newRow.ngayDiThucTe IS NULL
      AND NULLIF(LTRIM(RTRIM(ISNULL(newRow.cccd, ''''))), '''') IS NOT NULL;
END;');

    IF OBJECT_ID(N'dbo.NhatKyDieuChinhLuuTru', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.NhatKyDieuChinhLuuTru
        (
            IdNhatKyDieuChinh BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_NhatKyDieuChinhLuuTru PRIMARY KEY,
            Nguon NVARCHAR(30) NOT NULL,
            IdLichSuLuuTru INT NULL,
            IdKhachLuuTru INT NULL,
            HoVaTen NVARCHAR(150) NOT NULL,
            Cccd VARCHAR(20) NULL,
            NgayDenCu DATE NOT NULL,
            NgayDenMoi DATE NOT NULL,
            NgayDiDuKienCu DATE NULL,
            NgayDiDuKienMoi DATE NULL,
            NgayDiThucTeCu DATE NULL,
            NgayDiThucTeMoi DATE NULL,
            GhiChuCu NVARCHAR(500) NULL,
            GhiChuMoi NVARCHAR(500) NULL,
            LyDoDieuChinh NVARCHAR(500) NOT NULL,
            NguoiDieuChinh NVARCHAR(150) NOT NULL,
            NgayDieuChinh DATETIME NOT NULL CONSTRAINT DF_NhatKyDieuChinhLuuTru_NgayDieuChinh DEFAULT GETDATE(),
            CONSTRAINT CK_NhatKyDieuChinhLuuTru_Nguon CHECK (Nguon IN (N'Hộ dân', N'Cơ sở lưu trú')),
            CONSTRAINT CK_NhatKyDieuChinhLuuTru_ThamChieu CHECK
            (
                (Nguon = N'Hộ dân' AND IdLichSuLuuTru IS NOT NULL AND IdKhachLuuTru IS NULL)
                OR
                (Nguon = N'Cơ sở lưu trú' AND IdLichSuLuuTru IS NULL AND IdKhachLuuTru IS NOT NULL)
            ),
            CONSTRAINT CK_NhatKyDieuChinhLuuTru_ThuTuNgay CHECK
            (
                (NgayDiDuKienMoi IS NULL OR NgayDiDuKienMoi >= NgayDenMoi)
                AND (NgayDiThucTeMoi IS NULL OR NgayDiThucTeMoi >= NgayDenMoi)
            )
        );
    END;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.NhatKyDieuChinhLuuTru')
          AND name = N'IX_NhatKyDieuChinhLuuTru_Nguon_ThamChieu_Ngay'
    )
        CREATE INDEX IX_NhatKyDieuChinhLuuTru_Nguon_ThamChieu_Ngay
            ON dbo.NhatKyDieuChinhLuuTru(Nguon, IdLichSuLuuTru, IdKhachLuuTru, NgayDieuChinh DESC);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
