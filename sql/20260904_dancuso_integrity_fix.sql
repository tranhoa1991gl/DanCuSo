SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NULL
       OR OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NULL
       OR OBJECT_ID(N'dbo.LichSuLuuTru', N'U') IS NULL
       OR OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NULL
        THROW 51200, N'Chưa có đủ schema lưu trú. Hãy chạy các migration nền trước bản 20260904.', 1;

    -------------------------------------------------------------------------
    -- 1. Đồng nhất điều kiện "đang lưu trú" giữa C# và SQL.
    -------------------------------------------------------------------------
    IF EXISTS
    (
        SELECT LTRIM(RTRIM(cccd))
        FROM dbo.ThanhVien
        WHERE (ISNULL(laKhachLuuTru, 0) = 1 OR ISNULL(loaiCuTru, N'') = N'Tạm trú')
          AND NULLIF(LTRIM(RTRIM(ISNULL(cccd, ''))), '') IS NOT NULL
        GROUP BY LTRIM(RTRIM(cccd))
        HAVING COUNT(1) > 1
    )
        THROW 51201, N'Có nhiều thành viên đang lưu trú dùng cùng CCCD. Cần xử lý dữ liệu trùng trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.ThanhVien tv
        INNER JOIN dbo.KhachLuuTruCoSo kh
            ON LTRIM(RTRIM(kh.cccd)) = LTRIM(RTRIM(tv.cccd))
        WHERE (ISNULL(tv.laKhachLuuTru, 0) = 1 OR ISNULL(tv.loaiCuTru, N'') = N'Tạm trú')
          AND kh.DaXoa = 0
          AND kh.ngayDiThucTe IS NULL
          AND NULLIF(LTRIM(RTRIM(ISNULL(tv.cccd, ''))), '') IS NOT NULL
    )
        THROW 51202, N'Một CCCD đang lưu trú đồng thời tại hộ dân và cơ sở lưu trú. Cần kết thúc một lượt trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT LTRIM(RTRIM(cccd))
        FROM dbo.KhachLuuTruCoSo
        WHERE DaXoa = 0
          AND ngayDiThucTe IS NULL
          AND NULLIF(LTRIM(RTRIM(ISNULL(cccd, ''))), '') IS NOT NULL
        GROUP BY LTRIM(RTRIM(cccd))
        HAVING COUNT(1) > 1
    )
        THROW 51203, N'Có nhiều khách cơ sở đang lưu trú dùng cùng CCCD. Cần xử lý dữ liệu trùng trước khi cập nhật.', 1;

    -------------------------------------------------------------------------
    -- 2. Registry khóa CCCD đang hoạt động + trigger đồng bộ.
    -------------------------------------------------------------------------
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
    WHERE (ISNULL(tv.laKhachLuuTru, 0) = 1 OR ISNULL(tv.loaiCuTru, N'') = N'Tạm trú')
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
    WHERE (ISNULL(newRow.laKhachLuuTru, 0) = 1 OR ISNULL(newRow.loaiCuTru, N'''') = N''Tạm trú'')
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

    -------------------------------------------------------------------------
    -- 3. Integrity/index trên DB đã nâng cấp từ bản cũ.
    -------------------------------------------------------------------------
    IF EXISTS
    (
        SELECT idThanhVien
        FROM dbo.LichSuLuuTru
        WHERE idThanhVien IS NOT NULL AND ngayDiThucTe IS NULL
        GROUP BY idThanhVien
        HAVING COUNT(1) > 1
    )
        THROW 51204, N'Có nhiều lịch sử lưu trú đang mở cho cùng một thành viên. Cần xử lý trùng trước khi cập nhật.', 1;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.LichSuLuuTru')
          AND name = N'UX_LichSuLuuTru_ThanhVien_DangMo'
    )
        CREATE UNIQUE INDEX UX_LichSuLuuTru_ThanhVien_DangMo
            ON dbo.LichSuLuuTru(idThanhVien)
            WHERE idThanhVien IS NOT NULL AND ngayDiThucTe IS NULL;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.LichSuLuuTru')
          AND name = N'IX_LichSuLuuTru_TrangThai_Ngay'
    )
        CREATE INDEX IX_LichSuLuuTru_TrangThai_Ngay
            ON dbo.LichSuLuuTru(ngayDiThucTe, ngayDiDuKien, ngayDen DESC)
            INCLUDE (idThanhVien, idHoGiaDinh, hoVaTen, cccd);

    IF OBJECT_ID(N'dbo.CK_LichSuLuuTru_ThuTuNgay', N'C') IS NULL
        ALTER TABLE dbo.LichSuLuuTru WITH CHECK ADD CONSTRAINT CK_LichSuLuuTru_ThuTuNgay
            CHECK
            (
                (ngayDiDuKien IS NULL OR ngayDiDuKien >= ngayDen)
                AND (ngayDiThucTe IS NULL OR ngayDiThucTe >= ngayDen)
            );

    IF OBJECT_ID(N'dbo.CK_ThanhVien_ThuTuNgayLuuTru', N'C') IS NULL
        ALTER TABLE dbo.ThanhVien WITH CHECK ADD CONSTRAINT CK_ThanhVien_ThuTuNgayLuuTru
            CHECK (ngayDiDuKien IS NULL OR ngayDenLuuTru IS NULL OR ngayDiDuKien >= ngayDenLuuTru);

    -------------------------------------------------------------------------
    -- 4. Nhật ký điều chỉnh lưu trú nếu DB khách chưa có migration nâng cao.
    -------------------------------------------------------------------------
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

    -------------------------------------------------------------------------
    -- 5. Dọn orphan và thêm FK cascade cho bảng nối thành viên.
    -------------------------------------------------------------------------
    IF OBJECT_ID(N'dbo.ThanhVien_ChinhSach', N'U') IS NOT NULL
    BEGIN
        DELETE cs
        FROM dbo.ThanhVien_ChinhSach cs
        LEFT JOIN dbo.ThanhVien tv ON tv.idThanhVien = cs.idThanhVien
        WHERE tv.idThanhVien IS NULL;

        IF NOT EXISTS
        (
            SELECT 1 FROM sys.foreign_keys
            WHERE parent_object_id = OBJECT_ID(N'dbo.ThanhVien_ChinhSach')
              AND referenced_object_id = OBJECT_ID(N'dbo.ThanhVien')
        )
            ALTER TABLE dbo.ThanhVien_ChinhSach WITH CHECK
            ADD CONSTRAINT FK_ThanhVien_ChinhSach_ThanhVien
                FOREIGN KEY(idThanhVien) REFERENCES dbo.ThanhVien(idThanhVien) ON DELETE CASCADE;
    END;

    IF OBJECT_ID(N'dbo.ThanhVien_DoiTuong', N'U') IS NOT NULL
    BEGIN
        DELETE dt
        FROM dbo.ThanhVien_DoiTuong dt
        LEFT JOIN dbo.ThanhVien tv ON tv.idThanhVien = dt.idThanhVien
        WHERE tv.idThanhVien IS NULL;

        IF NOT EXISTS
        (
            SELECT 1 FROM sys.foreign_keys
            WHERE parent_object_id = OBJECT_ID(N'dbo.ThanhVien_DoiTuong')
              AND referenced_object_id = OBJECT_ID(N'dbo.ThanhVien')
        )
            ALTER TABLE dbo.ThanhVien_DoiTuong WITH CHECK
            ADD CONSTRAINT FK_ThanhVien_DoiTuong_ThanhVien
                FOREIGN KEY(idThanhVien) REFERENCES dbo.ThanhVien(idThanhVien) ON DELETE CASCADE;
    END;

    IF OBJECT_ID(N'dbo.ThanhVien_KhuyetTat', N'U') IS NOT NULL
    BEGIN
        DELETE kt
        FROM dbo.ThanhVien_KhuyetTat kt
        LEFT JOIN dbo.ThanhVien tv ON tv.idThanhVien = kt.idThanhVien
        WHERE tv.idThanhVien IS NULL;

        IF NOT EXISTS
        (
            SELECT 1 FROM sys.foreign_keys
            WHERE parent_object_id = OBJECT_ID(N'dbo.ThanhVien_KhuyetTat')
              AND referenced_object_id = OBJECT_ID(N'dbo.ThanhVien')
        )
            ALTER TABLE dbo.ThanhVien_KhuyetTat WITH CHECK
            ADD CONSTRAINT FK_ThanhVien_KhuyetTat_ThanhVien
                FOREIGN KEY(idThanhVien) REFERENCES dbo.ThanhVien(idThanhVien) ON DELETE CASCADE;
    END;

    -------------------------------------------------------------------------
    -- 6. Xóa hộ an toàn. Giữ nhật ký và thu/chi, chỉ bỏ tham chiếu.
    -- Không SET NOCOUNT ON vì app cũ kiểm tra ExecuteNonQuery() > 0.
    -------------------------------------------------------------------------
    EXEC(N'
CREATE OR ALTER PROCEDURE dbo.HoGiaDinh_Delete
    @idHoGiaDinh INT
AS
BEGIN
    IF OBJECT_ID(N''dbo.NhatKyHoatDong'', N''U'') IS NOT NULL
    BEGIN
        UPDATE dbo.NhatKyHoatDong
        SET IdThanhVien = NULL
        WHERE IdThanhVien IN
              (SELECT idThanhVien FROM dbo.ThanhVien WHERE idHoGiaDinh = @idHoGiaDinh);

        UPDATE dbo.NhatKyHoatDong
        SET IdHoGiaDinh = NULL
        WHERE IdHoGiaDinh = @idHoGiaDinh;
    END;

    IF OBJECT_ID(N''dbo.ThuChi'', N''U'') IS NOT NULL
        UPDATE dbo.ThuChi SET IdHoGiaDinh = NULL WHERE IdHoGiaDinh = @idHoGiaDinh;

    IF OBJECT_ID(N''dbo.PhienLuuTruDangHoatDong'', N''U'') IS NOT NULL
        DELETE FROM dbo.PhienLuuTruDangHoatDong
        WHERE IdThanhVien IN
              (SELECT idThanhVien FROM dbo.ThanhVien WHERE idHoGiaDinh = @idHoGiaDinh);

    IF OBJECT_ID(N''dbo.ThanhVien_ChinhSach'', N''U'') IS NOT NULL
        DELETE cs FROM dbo.ThanhVien_ChinhSach cs
        INNER JOIN dbo.ThanhVien tv ON tv.idThanhVien = cs.idThanhVien
        WHERE tv.idHoGiaDinh = @idHoGiaDinh;

    IF OBJECT_ID(N''dbo.ThanhVien_DoiTuong'', N''U'') IS NOT NULL
        DELETE dt FROM dbo.ThanhVien_DoiTuong dt
        INNER JOIN dbo.ThanhVien tv ON tv.idThanhVien = dt.idThanhVien
        WHERE tv.idHoGiaDinh = @idHoGiaDinh;

    IF OBJECT_ID(N''dbo.ThanhVien_KhuyetTat'', N''U'') IS NOT NULL
        DELETE kt FROM dbo.ThanhVien_KhuyetTat kt
        INNER JOIN dbo.ThanhVien tv ON tv.idThanhVien = kt.idThanhVien
        WHERE tv.idHoGiaDinh = @idHoGiaDinh;

    DELETE FROM dbo.HoGiaDinh
    WHERE idHoGiaDinh = @idHoGiaDinh;
END;');

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
