SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -------------------------------------------------------------------------
    -- 1. Cập nhật Stored Procedure ThongKe_DoanThe:
    --    Loại bỏ người đã mất (daMat = 1) và khách lưu trú (laKhachLuuTru = 1)
    -------------------------------------------------------------------------
    IF OBJECT_ID(N'[dbo].[ThongKe_DoanThe]', N'P') IS NOT NULL
        DROP PROCEDURE [dbo].[ThongKe_DoanThe];
    
    EXEC(N'
    CREATE PROCEDURE [dbo].[ThongKe_DoanThe]
        @IdDoanThe INT
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT 
            tv.IdThanhVien,
            tv.HoVaTen,
            tv.NgaySinh,
            tv.GioiTinh,
            dt.TenDoanThe,
            tvdt.NgayThamGia,
            ISNULL(tvdt.ChucVu, '''''''') AS ChucVu
        FROM dbo.ThanhVien tv
        INNER JOIN dbo.ThanhVien_DoanThe tvdt ON tv.IdThanhVien = tvdt.IdThanhVien
        INNER JOIN dbo.DanhMucDoanThe dt ON tvdt.IdDoanThe = dt.IdDoanThe
        WHERE (@IdDoanThe = 0 OR tvdt.IdDoanThe = @IdDoanThe)
          AND ISNULL(tv.daMat, 0) = 0
          AND ISNULL(tv.laKhachLuuTru, 0) = 0
        ORDER BY dt.TenDoanThe, tv.HoVaTen;
    END');

    COMMIT TRANSACTION;
    PRINT N'Cập nhật thành công migration 20260913_fix_thong_ke_dan_so.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrMsg, 16, 1);
END CATCH;