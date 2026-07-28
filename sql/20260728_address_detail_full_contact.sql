/*
MigrationId: 20260728_address_detail_full_contact
Purpose:
- Keep rural area/hamlet (DanhMucKhuVuc/idKhuVuc) separate from detailed address.
- Let old sold installations receive the SQL side of the address-detail update.
- Keep old HoGiaDinh_Insert/Update parameter counts for rollback safety.

Encoding: UTF-8
*/

SET XACT_ABORT ON
GO

IF OBJECT_ID(N'dbo.DanhMucKhuVuc', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DanhMucKhuVuc
    (
        idKhuVuc INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        tenKhuVuc NVARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.HoGiaDinh', N'idKhuVuc') IS NULL
BEGIN
    ALTER TABLE dbo.HoGiaDinh ADD idKhuVuc INT NULL;
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.HoGiaDinh', N'diaChiChiTiet') IS NULL
BEGIN
    ALTER TABLE dbo.HoGiaDinh
        ADD diaChiChiTiet NVARCHAR(255) NOT NULL
            CONSTRAINT DF_HoGiaDinh_diaChiChiTiet DEFAULT N'';
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.DanhMucKhuVuc', N'U') IS NOT NULL
BEGIN
    UPDATE h
    SET h.idKhuVuc = kv.idKhuVuc
    FROM dbo.HoGiaDinh h
    CROSS APPLY
    (
        SELECT TOP 1 idKhuVuc
        FROM dbo.DanhMucKhuVuc
        WHERE tenKhuVuc = h.diaChiChiTiet
        ORDER BY idKhuVuc
    ) kv
    WHERE h.idKhuVuc IS NULL
      AND NULLIF(LTRIM(RTRIM(ISNULL(h.diaChiChiTiet, N''))), N'') IS NOT NULL;
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh_All', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.HoGiaDinh_All AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [dbo].[HoGiaDinh_All]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        h.idHoGiaDinh,
        h.maHoKhau,
        h.tenChuHo,
        COALESCE(k.tenKhuVuc, kText.tenKhuVuc, N'') AS TenKhuVuc,
        CASE
            WHEN COALESCE(k.tenKhuVuc, kText.tenKhuVuc) IS NOT NULL
                 AND LTRIM(RTRIM(ISNULL(h.diaChiChiTiet, N''))) = LTRIM(RTRIM(COALESCE(k.tenKhuVuc, kText.tenKhuVuc)))
                THEN N''
            ELSE ISNULL(h.diaChiChiTiet, N'')
        END AS diaChiChiTiet,
        h.soDienThoai,
        h.phanLoaiHo
    FROM dbo.HoGiaDinh h
    LEFT JOIN dbo.DanhMucKhuVuc k ON h.idKhuVuc = k.idKhuVuc
    OUTER APPLY
    (
        SELECT TOP 1 tenKhuVuc
        FROM dbo.DanhMucKhuVuc
        WHERE h.idKhuVuc IS NULL AND h.diaChiChiTiet = tenKhuVuc
        ORDER BY idKhuVuc
    ) kText
    ORDER BY h.idHoGiaDinh ASC;
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh_SearchForPicker', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.HoGiaDinh_SearchForPicker AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [dbo].[HoGiaDinh_SearchForPicker]
    @Keyword NVARCHAR(200) = NULL,
    @PageIndex INT = 1,
    @PageSize INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    SET @Keyword = NULLIF(LTRIM(RTRIM(@Keyword)), N'');
    IF @PageIndex IS NULL OR @PageIndex < 1 SET @PageIndex = 1;
    IF @PageSize IS NULL OR @PageSize < 1 SET @PageSize = 50;
    IF @PageSize > 200 SET @PageSize = 200;

    ;WITH DataSource AS
    (
        SELECT
            h.idHoGiaDinh AS IdHoGiaDinh,
            h.maHoKhau AS MaHoKhau,
            h.tenChuHo AS TenChuHo,
            COALESCE(k.tenKhuVuc, kText.tenKhuVuc, N'') AS TenKhuVuc,
            CASE
                WHEN COALESCE(k.tenKhuVuc, kText.tenKhuVuc) IS NOT NULL
                     AND LTRIM(RTRIM(ISNULL(h.diaChiChiTiet, N''))) = LTRIM(RTRIM(COALESCE(k.tenKhuVuc, kText.tenKhuVuc)))
                    THEN N''
                ELSE ISNULL(h.diaChiChiTiet, N'')
            END AS DiaChiChiTiet,
            h.soDienThoai AS SoDienThoai,
            h.phanLoaiHo AS PhanLoaiHo,
            ROW_NUMBER() OVER (ORDER BY h.tenChuHo ASC, h.maHoKhau ASC, h.idHoGiaDinh ASC) AS RowNum,
            COUNT(1) OVER () AS TotalRows
        FROM dbo.HoGiaDinh h
        LEFT JOIN dbo.DanhMucKhuVuc k ON h.idKhuVuc = k.idKhuVuc
        OUTER APPLY
        (
            SELECT TOP 1 tenKhuVuc
            FROM dbo.DanhMucKhuVuc
            WHERE h.idKhuVuc IS NULL AND h.diaChiChiTiet = tenKhuVuc
            ORDER BY idKhuVuc
        ) kText
        WHERE
            @Keyword IS NULL
            OR h.maHoKhau LIKE N'%' + @Keyword + N'%'
            OR h.tenChuHo LIKE N'%' + @Keyword + N'%'
            OR COALESCE(k.tenKhuVuc, kText.tenKhuVuc, N'') LIKE N'%' + @Keyword + N'%'
            OR h.diaChiChiTiet LIKE N'%' + @Keyword + N'%'
            OR h.soDienThoai LIKE N'%' + @Keyword + N'%'
    )
    SELECT
        IdHoGiaDinh,
        MaHoKhau,
        TenChuHo,
        TenKhuVuc,
        DiaChiChiTiet,
        SoDienThoai,
        PhanLoaiHo,
        TotalRows
    FROM DataSource
    WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1)
                     AND (@PageIndex * @PageSize)
    ORDER BY RowNum;
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh_Insert', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.HoGiaDinh_Insert AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [dbo].[HoGiaDinh_Insert]
    @maHoKhau NVARCHAR(50),
    @tenChuHo NVARCHAR(100),
    @diaChiChiTiet NVARCHAR(500),
    @soDienThoai NVARCHAR(50),
    @phanLoaiHo NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idKV INT = NULL;
    DECLARE @tenKhuVuc NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@diaChiChiTiet)), N'');

    IF @tenKhuVuc IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.DanhMucKhuVuc WHERE tenKhuVuc = @tenKhuVuc)
    BEGIN
        INSERT INTO dbo.DanhMucKhuVuc (tenKhuVuc) VALUES (@tenKhuVuc);
    END

    SELECT TOP 1 @idKV = idKhuVuc
    FROM dbo.DanhMucKhuVuc
    WHERE tenKhuVuc = @tenKhuVuc
    ORDER BY idKhuVuc;

    INSERT INTO dbo.HoGiaDinh (maHoKhau, tenChuHo, diaChiChiTiet, idKhuVuc, soDienThoai, phanLoaiHo)
    VALUES (@maHoKhau, @tenChuHo, N'', @idKV, @soDienThoai, @phanLoaiHo);
END
GO

IF OBJECT_ID(N'dbo.HoGiaDinh_Update', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.HoGiaDinh_Update AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [dbo].[HoGiaDinh_Update]
    @idHoGiaDinh INT,
    @maHoKhau NVARCHAR(50),
    @tenChuHo NVARCHAR(100),
    @diaChiChiTiet NVARCHAR(500),
    @soDienThoai NVARCHAR(50),
    @phanLoaiHo NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idKV INT = NULL;
    DECLARE @tenKhuVuc NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@diaChiChiTiet)), N'');

    IF @tenKhuVuc IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM dbo.DanhMucKhuVuc WHERE tenKhuVuc = @tenKhuVuc)
    BEGIN
        INSERT INTO dbo.DanhMucKhuVuc (tenKhuVuc) VALUES (@tenKhuVuc);
    END

    SELECT TOP 1 @idKV = idKhuVuc
    FROM dbo.DanhMucKhuVuc
    WHERE tenKhuVuc = @tenKhuVuc
    ORDER BY idKhuVuc;

    UPDATE dbo.HoGiaDinh
    SET maHoKhau = @maHoKhau,
        tenChuHo = @tenChuHo,
        diaChiChiTiet = N'',
        idKhuVuc = @idKV,
        soDienThoai = @soDienThoai,
        phanLoaiHo = @phanLoaiHo
    WHERE idHoGiaDinh = @idHoGiaDinh;
END
GO

IF OBJECT_ID(N'dbo.ThanhVien_All', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.ThanhVien_All AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [dbo].[ThanhVien_All]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        tv.idThanhVien,
        tv.idHoGiaDinh,
        tv.hoVaTen,
        tv.gioiTinh,
        tv.ngaySinh,
        tv.cccd,
        tv.laChuHo,
        tv.laTamTru,
        tv.soDienThoai,
        COALESCE(k.tenKhuVuc, kText.tenKhuVuc, N'') AS TenKhuVuc,
        CASE
            WHEN COALESCE(k.tenKhuVuc, kText.tenKhuVuc) IS NOT NULL
                 AND LTRIM(RTRIM(ISNULL(h.diaChiChiTiet, N''))) = LTRIM(RTRIM(COALESCE(k.tenKhuVuc, kText.tenKhuVuc)))
                THEN N''
            ELSE ISNULL(h.diaChiChiTiet, N'')
        END AS DiaChiChiTiet,
        tv.idDanToc,
        tv.idTonGiao,
        tv.idQuanHe,
        tv.idNgheNghiep,
        tv.idHocVan,
        tv.daMat,
        tv.ngayMat,
        ISNULL(qh.tenQuanHe, N'') AS QuanHeVoiChuHo,
        ISNULL(nn.tenNgheNghiep, N'') AS NgheNghiep,
        ISNULL(tg.tenTonGiao, N'') AS TonGiao,
        ISNULL(dt.tenDanToc, N'') AS DanToc,
        ISNULL(hv.tenHocVan, N'') AS TrinhDoHocVan
    FROM dbo.ThanhVien tv
    LEFT JOIN dbo.HoGiaDinh h ON tv.idHoGiaDinh = h.idHoGiaDinh
    LEFT JOIN dbo.DanhMucKhuVuc k ON h.idKhuVuc = k.idKhuVuc
    OUTER APPLY
    (
        SELECT TOP 1 tenKhuVuc
        FROM dbo.DanhMucKhuVuc
        WHERE h.idKhuVuc IS NULL AND h.diaChiChiTiet = tenKhuVuc
        ORDER BY idKhuVuc
    ) kText
    LEFT JOIN dbo.DanhMucQuanHe qh ON tv.idQuanHe = qh.idQuanHe
    LEFT JOIN dbo.DanhMucNgheNghiep nn ON tv.idNgheNghiep = nn.idNgheNghiep
    LEFT JOIN dbo.DanhMucTonGiao tg ON tv.idTonGiao = tg.idTonGiao
    LEFT JOIN dbo.DanhMucDanToc dt ON tv.idDanToc = dt.idDanToc
    LEFT JOIN dbo.DanhMucHocVan hv ON tv.idHocVan = hv.idHocVan
    ORDER BY tv.idThanhVien DESC;
END
GO

IF OBJECT_ID(N'dbo.ThanhVien_ByHoGiaDinh', N'P') IS NULL
    EXEC(N'CREATE PROCEDURE dbo.ThanhVien_ByHoGiaDinh AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [dbo].[ThanhVien_ByHoGiaDinh]
    @idHoGiaDinh INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        tv.idThanhVien,
        tv.idHoGiaDinh,
        tv.hoVaTen,
        tv.gioiTinh,
        tv.ngaySinh,
        tv.cccd,
        tv.laChuHo,
        tv.laTamTru,
        tv.soDienThoai,
        COALESCE(k.tenKhuVuc, kText.tenKhuVuc, N'') AS TenKhuVuc,
        CASE
            WHEN COALESCE(k.tenKhuVuc, kText.tenKhuVuc) IS NOT NULL
                 AND LTRIM(RTRIM(ISNULL(h.diaChiChiTiet, N''))) = LTRIM(RTRIM(COALESCE(k.tenKhuVuc, kText.tenKhuVuc)))
                THEN N''
            ELSE ISNULL(h.diaChiChiTiet, N'')
        END AS DiaChiChiTiet,
        tv.idDanToc,
        tv.idTonGiao,
        tv.idQuanHe,
        tv.idNgheNghiep,
        tv.idHocVan,
        tv.daMat,
        tv.ngayMat,
        ISNULL(qh.tenQuanHe, N'') AS QuanHeVoiChuHo,
        ISNULL(nn.tenNgheNghiep, N'') AS NgheNghiep,
        ISNULL(tg.tenTonGiao, N'') AS TonGiao,
        ISNULL(dt.tenDanToc, N'') AS DanToc,
        ISNULL(hv.tenHocVan, N'') AS TrinhDoHocVan
    FROM dbo.ThanhVien tv
    LEFT JOIN dbo.HoGiaDinh h ON tv.idHoGiaDinh = h.idHoGiaDinh
    LEFT JOIN dbo.DanhMucKhuVuc k ON h.idKhuVuc = k.idKhuVuc
    OUTER APPLY
    (
        SELECT TOP 1 tenKhuVuc
        FROM dbo.DanhMucKhuVuc
        WHERE h.idKhuVuc IS NULL AND h.diaChiChiTiet = tenKhuVuc
        ORDER BY idKhuVuc
    ) kText
    LEFT JOIN dbo.DanhMucQuanHe qh ON tv.idQuanHe = qh.idQuanHe
    LEFT JOIN dbo.DanhMucNgheNghiep nn ON tv.idNgheNghiep = nn.idNgheNghiep
    LEFT JOIN dbo.DanhMucTonGiao tg ON tv.idTonGiao = tg.idTonGiao
    LEFT JOIN dbo.DanhMucDanToc dt ON tv.idDanToc = dt.idDanToc
    LEFT JOIN dbo.DanhMucHocVan hv ON tv.idHocVan = hv.idHocVan
    WHERE tv.idHoGiaDinh = @idHoGiaDinh
    ORDER BY tv.laChuHo DESC, tv.idThanhVien ASC;
END
GO
