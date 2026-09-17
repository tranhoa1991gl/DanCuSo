-- Chay script nay tren SQL Server Management Studio (SSMS)
-- De cap nhat proc NhatKy_TraCuu tra them 2 cot IdHoGiaDinh, IdThanhVien

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
            WHEN nk.PhanLoai = N'Cong dong' THEN N'Toan thon/xa'
            WHEN nk.PhanLoai = N'Ho gia dinh' THEN N'Ho: ' + ISNULL(hg.TenChuHo, N'Khong ro')
            WHEN nk.PhanLoai = N'Ca nhan' THEN N'Ong/Ba: ' + ISNULL(tv.HoVaTen, N'Khong ro')
            ELSE N''
        END AS DoiTuongLienQuan
    FROM dbo.NhatKyHoatDong nk
    LEFT JOIN dbo.HoGiaDinh hg ON nk.IdHoGiaDinh = hg.IdHoGiaDinh
    LEFT JOIN dbo.ThanhVien tv ON nk.IdThanhVien = tv.IdThanhVien
    WHERE nk.NgayGhiNhan >= @TuNgay AND nk.NgayGhiNhan <= @DenNgay
    ORDER BY nk.NgayGhiNhan DESC
END
