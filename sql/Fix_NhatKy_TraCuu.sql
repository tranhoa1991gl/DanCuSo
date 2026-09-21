-- UTF-8 WITHOUT BOM: compatible with the existing online updater.
-- Keep ALTER PROCEDURE first in this batch (comments are allowed).

ALTER PROCEDURE [dbo].[NhatKy_TraCuu]
    @TuNgay DATETIME,
    @DenNgay DATETIME
AS
BEGIN
    SELECT 
        nk.Id,
        nk.NgayGhiNhan,
        nk.PhanLoai,
        nk.TieuDe,
        nk.NoiDung,
        nk.TinhTrang,
        nk.IdHoGiaDinh,
        nk.IdThanhVien,
        CASE 
            WHEN nk.PhanLoai IN (N'Cộng đồng', N'Cong dong') THEN N'Toàn thôn/xã'
            WHEN nk.PhanLoai IN (N'Hộ gia đình', N'Ho gia dinh') THEN
                CASE WHEN nk.IdHoGiaDinh IS NULL THEN N'Chưa chọn hộ gia đình'
                     ELSE N'Hộ: ' + COALESCE(NULLIF(hg.TenChuHo, N''), N'Không rõ') END
            WHEN nk.PhanLoai IN (N'Cá nhân', N'Ca nhan') THEN
                CASE WHEN nk.IdThanhVien IS NULL THEN N'Chưa chọn cá nhân'
                     ELSE N'Ông/Bà: ' + COALESCE(NULLIF(tv.HoVaTen, N''), N'Không rõ') END
            ELSE N''
        END AS DoiTuongLienQuan
    FROM dbo.NhatKyHoatDong nk
    LEFT JOIN dbo.HoGiaDinh hg ON nk.IdHoGiaDinh = hg.IdHoGiaDinh
    LEFT JOIN dbo.ThanhVien tv ON nk.IdThanhVien = tv.IdThanhVien
    WHERE nk.NgayGhiNhan >= @TuNgay AND nk.NgayGhiNhan <= @DenNgay
    ORDER BY nk.NgayGhiNhan DESC
END
