SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.ThanhVien', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.ThanhVien', N'queQuan') IS NULL
BEGIN
    ALTER TABLE dbo.ThanhVien
        ADD queQuan NVARCHAR(255) NULL;
END;
GO
