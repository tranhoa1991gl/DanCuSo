SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NULL
       OR OBJECT_ID(N'dbo.HoGiaDinh', N'U') IS NULL
       OR OBJECT_ID(N'dbo.LichSuLuuTru', N'U') IS NULL
       OR OBJECT_ID(N'dbo.CoSoLuuTru', N'U') IS NULL
       OR OBJECT_ID(N'dbo.KhachLuuTruCoSo', N'U') IS NULL
        THROW 51000, N'Chưa có đủ schema lưu trú. Hãy chạy các migration lưu trú trước bản hardening.', 1;

    IF EXISTS
    (
        SELECT idThanhVien
        FROM dbo.LichSuLuuTru
        WHERE idThanhVien IS NOT NULL AND ngayDiThucTe IS NULL
        GROUP BY idThanhVien
        HAVING COUNT(1) > 1
    )
        THROW 51001, N'Dữ liệu có nhiều lịch sử đang mở cho cùng một thành viên. Cần xử lý trùng trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT LTRIM(RTRIM(cccd))
        FROM dbo.ThanhVien
        WHERE ISNULL(laKhachLuuTru, 0) = 1
          AND NULLIF(LTRIM(RTRIM(ISNULL(cccd, ''))), '') IS NOT NULL
        GROUP BY LTRIM(RTRIM(cccd))
        HAVING COUNT(1) > 1
    )
        THROW 51002, N'Dữ liệu có nhiều thành viên đang lưu trú dùng cùng CCCD. Cần xử lý trùng trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT LTRIM(RTRIM(cccd))
        FROM dbo.KhachLuuTruCoSo
        WHERE DaXoa = 0 AND ngayDiThucTe IS NULL
          AND NULLIF(LTRIM(RTRIM(ISNULL(cccd, ''))), '') IS NOT NULL
        GROUP BY LTRIM(RTRIM(cccd))
        HAVING COUNT(1) > 1
    )
        THROW 51003, N'Dữ liệu có nhiều khách cơ sở đang lưu trú dùng cùng CCCD. Cần xử lý trùng trước khi cập nhật.', 1;

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
        THROW 51004, N'Một CCCD đang lưu trú đồng thời tại hộ dân và cơ sở lưu trú. Cần kết thúc một lượt trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.KhachLuuTruCoSo
        WHERE (ngayDiDuKien IS NOT NULL AND ngayDiDuKien < ngayDen)
           OR (ngayDiThucTe IS NOT NULL AND ngayDiThucTe < ngayDen)
    )
        THROW 51005, N'Khách cơ sở có ngày về nhỏ hơn ngày đến. Cần sửa dữ liệu trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.LichSuLuuTru
        WHERE (ngayDiDuKien IS NOT NULL AND ngayDiDuKien < ngayDen)
           OR (ngayDiThucTe IS NOT NULL AND ngayDiThucTe < ngayDen)
    )
        THROW 51006, N'Lịch sử lưu trú có ngày về nhỏ hơn ngày đến. Cần sửa dữ liệu trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.ThanhVien
        WHERE ngayDiDuKien IS NOT NULL
          AND ngayDenLuuTru IS NOT NULL
          AND ngayDiDuKien < ngayDenLuuTru
    )
        THROW 51007, N'Thành viên có ngày dự kiến về nhỏ hơn ngày đến. Cần sửa dữ liệu trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT 1 FROM dbo.HoGiaDinh
        WHERE ngayHetHanTamTru IS NOT NULL
          AND ngayBatDauTamTru IS NOT NULL
          AND ngayHetHanTamTru < ngayBatDauTamTru
    )
        THROW 51008, N'Hộ tạm trú có ngày hết hạn nhỏ hơn ngày bắt đầu. Cần sửa dữ liệu trước khi cập nhật.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.CoSoLuuTru cs
        LEFT JOIN dbo.DanhMucKhuVuc kv ON kv.idKhuVuc = cs.IdKhuVuc
        WHERE cs.IdKhuVuc IS NOT NULL AND kv.idKhuVuc IS NULL
    )
        THROW 51009, N'Cơ sở lưu trú đang tham chiếu khu vực không tồn tại. Cần sửa dữ liệu trước khi cập nhật.', 1;

    UPDATE dbo.ThanhVien
    SET cccd = NULLIF(LTRIM(RTRIM(cccd)), '')
    WHERE ISNULL(cccd, '') <> ISNULL(NULLIF(LTRIM(RTRIM(cccd)), ''), '');

    UPDATE dbo.KhachLuuTruCoSo
    SET cccd = NULLIF(LTRIM(RTRIM(cccd)), '')
    WHERE ISNULL(cccd, '') <> ISNULL(NULLIF(LTRIM(RTRIM(cccd)), ''), '');

    IF OBJECT_ID(N'dbo.CK_KhachLuuTruCoSo_ThuTuNgay', N'C') IS NULL
        ALTER TABLE dbo.KhachLuuTruCoSo WITH CHECK ADD CONSTRAINT CK_KhachLuuTruCoSo_ThuTuNgay
            CHECK
            (
                (ngayDiDuKien IS NULL OR ngayDiDuKien >= ngayDen)
                AND (ngayDiThucTe IS NULL OR ngayDiThucTe >= ngayDen)
            );
    ALTER TABLE dbo.KhachLuuTruCoSo WITH CHECK CHECK CONSTRAINT CK_KhachLuuTruCoSo_ThuTuNgay;

    IF OBJECT_ID(N'dbo.CK_LichSuLuuTru_ThuTuNgay', N'C') IS NULL
        ALTER TABLE dbo.LichSuLuuTru WITH CHECK ADD CONSTRAINT CK_LichSuLuuTru_ThuTuNgay
            CHECK
            (
                (ngayDiDuKien IS NULL OR ngayDiDuKien >= ngayDen)
                AND (ngayDiThucTe IS NULL OR ngayDiThucTe >= ngayDen)
            );
    ALTER TABLE dbo.LichSuLuuTru WITH CHECK CHECK CONSTRAINT CK_LichSuLuuTru_ThuTuNgay;

    IF OBJECT_ID(N'dbo.CK_ThanhVien_ThuTuNgayLuuTru', N'C') IS NULL
        ALTER TABLE dbo.ThanhVien WITH CHECK ADD CONSTRAINT CK_ThanhVien_ThuTuNgayLuuTru
            CHECK (ngayDiDuKien IS NULL OR ngayDenLuuTru IS NULL OR ngayDiDuKien >= ngayDenLuuTru);
    ALTER TABLE dbo.ThanhVien WITH CHECK CHECK CONSTRAINT CK_ThanhVien_ThuTuNgayLuuTru;

    IF OBJECT_ID(N'dbo.CK_HoGiaDinh_ThuTuNgayTamTru', N'C') IS NULL
        ALTER TABLE dbo.HoGiaDinh WITH CHECK ADD CONSTRAINT CK_HoGiaDinh_ThuTuNgayTamTru
            CHECK (ngayHetHanTamTru IS NULL OR ngayBatDauTamTru IS NULL OR ngayHetHanTamTru >= ngayBatDauTamTru);
    ALTER TABLE dbo.HoGiaDinh WITH CHECK CHECK CONSTRAINT CK_HoGiaDinh_ThuTuNgayTamTru;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.foreign_keys
        WHERE parent_object_id = OBJECT_ID(N'dbo.CoSoLuuTru')
          AND name = N'FK_CoSoLuuTru_DanhMucKhuVuc'
    )
        ALTER TABLE dbo.CoSoLuuTru WITH CHECK ADD CONSTRAINT FK_CoSoLuuTru_DanhMucKhuVuc
            FOREIGN KEY (IdKhuVuc) REFERENCES dbo.DanhMucKhuVuc(idKhuVuc);
    ALTER TABLE dbo.CoSoLuuTru WITH CHECK CHECK CONSTRAINT FK_CoSoLuuTru_DanhMucKhuVuc;

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
        WHERE object_id = OBJECT_ID(N'dbo.ThanhVien')
          AND name = N'UX_ThanhVien_Cccd_KhachDangLuuTru'
    )
        CREATE UNIQUE INDEX UX_ThanhVien_Cccd_KhachDangLuuTru
            ON dbo.ThanhVien(cccd)
            WHERE laKhachLuuTru = 1 AND cccd IS NOT NULL;

    IF NOT EXISTS
    (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.LichSuLuuTru')
          AND name = N'IX_LichSuLuuTru_TrangThai_Ngay'
    )
        CREATE INDEX IX_LichSuLuuTru_TrangThai_Ngay
            ON dbo.LichSuLuuTru(ngayDiThucTe, ngayDiDuKien, ngayDen DESC)
            INCLUDE (idThanhVien, idHoGiaDinh, hoVaTen, cccd);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
