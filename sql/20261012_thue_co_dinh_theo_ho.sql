-- Bổ sung cách thu cố định theo hộ; cấu hình IdKhuVuc = 0 là mức chung cho tất cả.
-- Các cấu hình và sổ bộ hiện có tiếp tục tính theo diện tích.
IF OBJECT_ID(N'dbo.CauHinhThueKhuVuc', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.CauHinhThueKhuVuc', 'ThuTheoHo') IS NULL
        ALTER TABLE dbo.CauHinhThueKhuVuc ADD ThuTheoHo bit NOT NULL CONSTRAINT DF_CauHinhThue_ThuTheoHo DEFAULT (0) WITH VALUES;
    IF COL_LENGTH('dbo.CauHinhThueKhuVuc', 'MucThuMoiHo') IS NULL
        ALTER TABLE dbo.CauHinhThueKhuVuc ADD MucThuMoiHo decimal(18,0) NOT NULL CONSTRAINT DF_CauHinhThue_MucThuMoiHo DEFAULT (0) WITH VALUES;
END;

IF OBJECT_ID(N'dbo.ThuThue', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.ThuThue', 'ThuTheoHo') IS NULL
        ALTER TABLE dbo.ThuThue ADD ThuTheoHo bit NOT NULL CONSTRAINT DF_ThuThue_ThuTheoHo DEFAULT (0) WITH VALUES;
    IF COL_LENGTH('dbo.ThuThue', 'MucThuMoiHo') IS NULL
        ALTER TABLE dbo.ThuThue ADD MucThuMoiHo decimal(18,0) NOT NULL CONSTRAINT DF_ThuThue_MucThuMoiHo DEFAULT (0) WITH VALUES;
END;
