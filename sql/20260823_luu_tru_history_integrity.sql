SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH(N'dbo.HoGiaDinh', N'ngayBatDauTamTru') IS NULL
        ALTER TABLE dbo.HoGiaDinh ADD ngayBatDauTamTru DATE NULL;

    IF COL_LENGTH(N'dbo.HoGiaDinh', N'ngayHetHanTamTru') IS NULL
        ALTER TABLE dbo.HoGiaDinh ADD ngayHetHanTamTru DATE NULL;

    IF COL_LENGTH(N'dbo.CoSoLuuTru', N'DaXoa') IS NULL
        ALTER TABLE dbo.CoSoLuuTru ADD DaXoa BIT NOT NULL
            CONSTRAINT DF_CoSoLuuTru_DaXoa DEFAULT (0) WITH VALUES;

    IF COL_LENGTH(N'dbo.CoSoLuuTru', N'NgayXoa') IS NULL
        ALTER TABLE dbo.CoSoLuuTru ADD NgayXoa DATETIME NULL;

    IF COL_LENGTH(N'dbo.KhachLuuTruCoSo', N'DaXoa') IS NULL
        ALTER TABLE dbo.KhachLuuTruCoSo ADD DaXoa BIT NOT NULL
            CONSTRAINT DF_KhachLuuTruCoSo_DaXoa DEFAULT (0) WITH VALUES;

    IF COL_LENGTH(N'dbo.KhachLuuTruCoSo', N'NgayXoa') IS NULL
        ALTER TABLE dbo.KhachLuuTruCoSo ADD NgayXoa DATETIME NULL;

    -- SQL động để SQL Server biên dịch sau khi các cột mới đã được tạo.
    EXEC sys.sp_executesql N'
        ;WITH MocTamTru AS
        (
            SELECT
                tv.idHoGiaDinh,
                MIN(tv.ngayDenLuuTru) AS NgayBatDau,
                MAX(tv.ngayDiDuKien) AS NgayHetHan
            FROM dbo.ThanhVien tv
            WHERE ISNULL(tv.loaiCuTru, N'''') = N''Tạm trú''
               OR ISNULL(tv.laTamTru, 0) = 1
            GROUP BY tv.idHoGiaDinh
        )
        UPDATE h
        SET h.ngayBatDauTamTru = COALESCE(h.ngayBatDauTamTru, m.NgayBatDau),
            h.ngayHetHanTamTru = COALESCE(h.ngayHetHanTamTru, m.NgayHetHan)
        FROM dbo.HoGiaDinh h
        INNER JOIN MocTamTru m ON m.idHoGiaDinh = h.idHoGiaDinh
        WHERE ISNULL(h.loaiCuTru, N'''') = N''Tạm trú'';';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.CoSoLuuTru')
          AND name = N'IX_CoSoLuuTru_DaXoa_HoatDong'
    )
        EXEC sys.sp_executesql N'
            CREATE INDEX IX_CoSoLuuTru_DaXoa_HoatDong
                ON dbo.CoSoLuuTru (DaXoa, DangHoatDong, TenCoSo);';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.KhachLuuTruCoSo')
          AND name = N'IX_KhachLuuTruCoSo_HienTai'
    )
        EXEC sys.sp_executesql N'
            CREATE INDEX IX_KhachLuuTruCoSo_HienTai
                ON dbo.KhachLuuTruCoSo (DaXoa, IdCoSoLuuTru, NgayDiThucTe, NgayDiDuKien)
                INCLUDE (HoVaTen, Cccd, NgayDen);';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.KhachLuuTruCoSo')
          AND name = N'UX_KhachLuuTruCoSo_Cccd_DangLuuTru'
    )
        EXEC sys.sp_executesql N'
            IF NOT EXISTS
            (
                SELECT Cccd
                FROM dbo.KhachLuuTruCoSo
                WHERE DaXoa = 0 AND NgayDiThucTe IS NULL AND Cccd IS NOT NULL
                GROUP BY Cccd
                HAVING COUNT(1) > 1
            )
                CREATE UNIQUE INDEX UX_KhachLuuTruCoSo_Cccd_DangLuuTru
                    ON dbo.KhachLuuTruCoSo (Cccd)
                    WHERE DaXoa = 0 AND NgayDiThucTe IS NULL AND Cccd IS NOT NULL;';

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.HoGiaDinh')
          AND name = N'IX_HoGiaDinh_TamTru_HetHan'
    )
        EXEC sys.sp_executesql N'
            CREATE INDEX IX_HoGiaDinh_TamTru_HetHan
                ON dbo.HoGiaDinh (loaiCuTru, ngayHetHanTamTru)
                INCLUDE (tenChuHo, idKhuVuc, diaChiChiTiet);';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
