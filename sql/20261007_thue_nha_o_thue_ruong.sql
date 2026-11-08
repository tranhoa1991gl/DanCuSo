-- CẬP NHẬT PHÂN HỆ QUẢN LÝ THU THUẾ NHÀ Ở VÀ THUẾ RUỘNG THEO TỪNG VÙNG
-- Ngày tạo: 07/10/2026

-- 1. Bảng Cấu hình bảng giá thuế theo từng Vùng / Khu vực và Năm
IF OBJECT_ID(N'[dbo].[CauHinhThueKhuVuc]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[CauHinhThueKhuVuc](
        [IdCauHinh] [int] IDENTITY(1,1) NOT NULL,
        [IdKhuVuc] [int] NOT NULL,
        [NamApDung] [int] NOT NULL,
        [DonGiaThueNhaO] [decimal](18, 2) NOT NULL CONSTRAINT [DF_CauHinhThue_DonGiaNha] DEFAULT ((0)),
        [DonGiaThueRuong] [decimal](18, 2) NOT NULL CONSTRAINT [DF_CauHinhThue_DonGiaRuong] DEFAULT ((0)),
        [DonViTinhRuong] [nvarchar](20) NOT NULL CONSTRAINT [DF_CauHinhThue_DonViRuong] DEFAULT (N'sào'),
        [GhiChu] [nvarchar](500) NULL,
        [NgayCapNhat] [datetime] NOT NULL CONSTRAINT [DF_CauHinhThue_NgayCapNhat] DEFAULT (GETDATE()),
        CONSTRAINT [PK_CauHinhThueKhuVuc] PRIMARY KEY CLUSTERED ([IdCauHinh] ASC),
        CONSTRAINT [UQ_CauHinhThueKhuVuc_KhuVuc_Nam] UNIQUE NONCLUSTERED ([IdKhuVuc] ASC, [NamApDung] ASC)
    );
END;

-- 2. Bảng Quản lý diện tích đất ở, đất ruộng và chính sách miễn giảm của từng hộ gia đình
IF OBJECT_ID(N'[dbo].[ThongTinDatThueHo]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ThongTinDatThueHo](
        [IdHoGiaDinh] [int] NOT NULL,
        [DienTichNhaO] [decimal](18, 2) NOT NULL CONSTRAINT [DF_ThongTinDat_DienTichNha] DEFAULT ((0)),
        [DienTichRuong] [decimal](18, 2) NOT NULL CONSTRAINT [DF_ThongTinDat_DienTichRuong] DEFAULT ((0)),
        [DonViRuong] [nvarchar](20) NOT NULL CONSTRAINT [DF_ThongTinDat_DonViRuong] DEFAULT (N'sào'),
        [MienGiamPhanTram] [decimal](5, 2) NOT NULL CONSTRAINT [DF_ThongTinDat_MienGiam] DEFAULT ((0)),
        [LyDoMienGiam] [nvarchar](255) NULL,
        [ViTriThuaDat] [nvarchar](255) NULL,
        [GhiChu] [nvarchar](500) NULL,
        [NgayCapNhat] [datetime] NOT NULL CONSTRAINT [DF_ThongTinDat_NgayCapNhat] DEFAULT (GETDATE()),
        CONSTRAINT [PK_ThongTinDatThueHo] PRIMARY KEY CLUSTERED ([IdHoGiaDinh] ASC)
    );
END;

-- 3. Bảng Sổ bộ thuế và Quản lý thu thuế
IF OBJECT_ID(N'[dbo].[ThuThue]', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[ThuThue](
        [IdThuThue] [int] IDENTITY(1,1) NOT NULL,
        [MaPhieu] [nvarchar](50) NOT NULL,
        [IdHoGiaDinh] [int] NOT NULL,
        [IdKhuVuc] [int] NULL,
        [NamThue] [int] NOT NULL,
        [KyThu] [nvarchar](50) NOT NULL CONSTRAINT [DF_ThuThue_KyThu] DEFAULT (N'Cả năm'),
        [DienTichNhaO] [decimal](18, 2) NOT NULL CONSTRAINT [DF_ThuThue_DienTichNha] DEFAULT ((0)),
        [DonGiaThueNhaO] [decimal](18, 2) NOT NULL CONSTRAINT [DF_ThuThue_DonGiaNha] DEFAULT ((0)),
        [TienThueNhaO] [decimal](18, 0) NOT NULL CONSTRAINT [DF_ThuThue_TienNha] DEFAULT ((0)),
        [DienTichRuong] [decimal](18, 2) NOT NULL CONSTRAINT [DF_ThuThue_DienTichRuong] DEFAULT ((0)),
        [DonGiaThueRuong] [decimal](18, 2) NOT NULL CONSTRAINT [DF_ThuThue_DonGiaRuong] DEFAULT ((0)),
        [DonViRuong] [nvarchar](20) NOT NULL CONSTRAINT [DF_ThuThue_DonViRuong] DEFAULT (N'sào'),
        [TienThueRuong] [decimal](18, 0) NOT NULL CONSTRAINT [DF_ThuThue_TienRuong] DEFAULT ((0)),
        [PhanTramMienGiam] [decimal](5, 2) NOT NULL CONSTRAINT [DF_ThuThue_PhanTramMienGiam] DEFAULT ((0)),
        [SoTienMienGiam] [decimal](18, 0) NOT NULL CONSTRAINT [DF_ThuThue_SoTienMienGiam] DEFAULT ((0)),
        [TongPhaiNop] [decimal](18, 0) NOT NULL CONSTRAINT [DF_ThuThue_TongPhaiNop] DEFAULT ((0)),
        [SoTienDaNop] [decimal](18, 0) NOT NULL CONSTRAINT [DF_ThuThue_SoTienDaNop] DEFAULT ((0)),
        [ConLai] [decimal](18, 0) NOT NULL CONSTRAINT [DF_ThuThue_ConLai] DEFAULT ((0)),
        [TrangThai] [nvarchar](50) NOT NULL CONSTRAINT [DF_ThuThue_TrangThai] DEFAULT (N'Chưa nộp'),
        [NgayThu] [date] NULL,
        [NguoiNop] [nvarchar](100) NULL,
        [NguoiThu] [nvarchar](100) NULL,
        [IdThuChi] [int] NULL,
        [IdChienDich] [int] NULL,
        [GhiChu] [nvarchar](500) NULL,
        [NgayTao] [datetime] NOT NULL CONSTRAINT [DF_ThuThue_NgayTao] DEFAULT (GETDATE()),
        CONSTRAINT [PK_ThuThue] PRIMARY KEY CLUSTERED ([IdThuThue] ASC)
    );

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ThuThue_Nam_KhuVuc' AND object_id = OBJECT_ID('dbo.ThuThue'))
        CREATE NONCLUSTERED INDEX [IX_ThuThue_Nam_KhuVuc] ON [dbo].[ThuThue] ([NamThue] ASC, [IdKhuVuc] ASC);

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_ThuThue_HoGiaDinh' AND object_id = OBJECT_ID('dbo.ThuThue'))
        CREATE NONCLUSTERED INDEX [IX_ThuThue_HoGiaDinh] ON [dbo].[ThuThue] ([IdHoGiaDinh] ASC);
END;

IF OBJECT_ID(N'[dbo].[ThuThue]', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.ThuThue', 'IdChienDich') IS NULL
    BEGIN
        ALTER TABLE dbo.ThuThue ADD [IdChienDich] [int] NULL;
    END;
END;

