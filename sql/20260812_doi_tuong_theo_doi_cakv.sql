SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.DanhMucDoiTuong', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.DanhMucDoiTuong', N'theoDoiCakv') IS NULL
BEGIN
    ALTER TABLE dbo.DanhMucDoiTuong
        ADD theoDoiCakv BIT NOT NULL
            CONSTRAINT DF_DanhMucDoiTuong_TheoDoiCakv DEFAULT(0) WITH VALUES;
END
GO

IF OBJECT_ID(N'dbo.DanhMucDoiTuong', N'U') IS NOT NULL
   AND COL_LENGTH(N'dbo.DanhMucDoiTuong', N'theoDoiCakv') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Mãn hạn tù về địa phương')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong, theoDoiCakv) VALUES (N'Mãn hạn tù về địa phương', 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Án treo/cải tạo không giam giữ/quản chế')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong, theoDoiCakv) VALUES (N'Án treo/cải tạo không giam giữ/quản chế', 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Người nghiện ma túy')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong, theoDoiCakv) VALUES (N'Người nghiện ma túy', 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Quản lý sau cai nghiện')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong, theoDoiCakv) VALUES (N'Quản lý sau cai nghiện', 1);

    IF NOT EXISTS (SELECT 1 FROM dbo.DanhMucDoiTuong WHERE LTRIM(RTRIM(tenDoiTuong)) = N'Theo dõi nghi vấn phạm tội')
        INSERT INTO dbo.DanhMucDoiTuong(tenDoiTuong, theoDoiCakv) VALUES (N'Theo dõi nghi vấn phạm tội', 1);

    UPDATE dbo.DanhMucDoiTuong
    SET theoDoiCakv = 1
    WHERE LTRIM(RTRIM(tenDoiTuong)) IN
    (
        N'Mãn hạn tù về địa phương',
        N'Án treo/cải tạo không giam giữ/quản chế',
        N'Người nghiện ma túy',
        N'Quản lý sau cai nghiện',
        N'Theo dõi nghi vấn phạm tội'
    )
       OR tenDoiTuong LIKE N'%mãn hạn tù%'
       OR tenDoiTuong LIKE N'%ra tù%'
       OR tenDoiTuong LIKE N'%án treo%'
       OR tenDoiTuong LIKE N'%cải tạo không giam giữ%'
       OR tenDoiTuong LIKE N'%quản chế%'
       OR tenDoiTuong LIKE N'%ma túy%'
       OR tenDoiTuong LIKE N'%sau cai%'
       OR tenDoiTuong LIKE N'%nghi vấn%'
       OR tenDoiTuong LIKE N'%phạm tội%';

    UPDATE dbo.DanhMucDoiTuong
    SET theoDoiCakv = 0
    WHERE LTRIM(RTRIM(tenDoiTuong)) IN
    (
        N'Bảo trợ xã hội',
        N'Người khuyết tật',
        N'Thương binh',
        N'Nạn nhân chất độc da cam'
    );
END
GO
