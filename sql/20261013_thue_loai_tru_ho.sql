-- Giữ bảng giá hiện tại của hộ được loại trừ khi áp dụng mức thu chung.
IF OBJECT_ID(N'dbo.CauHinhThueHoNgoaiLe', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CauHinhThueHoNgoaiLe (
        IdHoGiaDinh INT NOT NULL,
        NamApDung INT NOT NULL,
        CoCauHinh BIT NOT NULL,
        ThuTheoHo BIT NOT NULL,
        MucThuMoiHo DECIMAL(18,0) NOT NULL,
        DonGiaThueNhaO DECIMAL(18,2) NOT NULL,
        DonGiaThueRuong DECIMAL(18,2) NOT NULL,
        DonViTinhRuong NVARCHAR(20) NOT NULL,
        NgayCapNhat DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_CauHinhThueHoNgoaiLe PRIMARY KEY (NamApDung, IdHoGiaDinh),
        CONSTRAINT FK_CauHinhThueHoNgoaiLe_Ho FOREIGN KEY (IdHoGiaDinh)
            REFERENCES dbo.HoGiaDinh(idHoGiaDinh) ON DELETE CASCADE
    );
END;
