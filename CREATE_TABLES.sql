SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

GO
/*
DROP TABLE IF EXISTS dbo.[Order_Banner];
DROP TABLE IF EXISTS dbo.[Banner_Click];
DROP TABLE IF EXISTS dbo.[Order];
DROP TABLE IF EXISTS dbo.[Campaign_Banner];
DROP TABLE IF EXISTS dbo.[Campaign];
DROP TABLE IF EXISTS dbo.[Banner];
DROP TABLE IF EXISTS dbo.[Banner_Position];
DROP TABLE IF EXISTS dbo.[Website];
GO*/

CREATE TABLE dbo.[Banner] (
    pk_Banner INT PRIMARY KEY Identity(1,1),
    bannerName NVARCHAR(255) NOT NULL,
    bannerImage VARCHAR(255) NOT NULL,
    width INT NOT NULL,
    height INT NOT NULL,
    urlWeb NVARCHAR(255) NOT NULL
);

CREATE TABLE dbo.[Website](
    pk_Web INT PRIMARY KEY Identity(1,1),
    webName NVARCHAR(255) NOT NULL
);

CREATE TABLE dbo.[Banner_Position] (
    pk_BannerPosition INT PRIMARY KEY IDENTITY(1,1),
    fk_Web INT NOT NULL,
    positionName NVARCHAR(255) NOT NULL,
    width INT NOT NULL,
    height INT NOT NULL,
    pricingType VARCHAR(10) NOT NULL, -- 'DAY' nebo 'CLICK'
    unitPrice DECIMAL(10, 2) NOT NULL, -- X Kč za den nebo za proklik
    CONSTRAINT FK_BannerPosition_Web FOREIGN KEY (fk_Web) REFERENCES dbo.[Website](pk_Web)
);

CREATE TABLE dbo.[Campaign] (
    pk_Campaign INT PRIMARY KEY Identity(1,1),
    campaignName NVARCHAR(255) NOT NULL,
    validFrom DATETIME2 NOT NULL,
    validTo DATETIME2 NOT NULL

);

CREATE TABLE dbo.[Campaign_Banner] (
    pk_Campaign_Banner BIGINT PRIMARY KEY Identity(1,1),
    fk_Campaign INT NOT NULL,
    fk_Banner INT NOT NULL,
    fk_Banner_Position INT NOT NULL,
    isActive BIT NOT NULL DEFAULT 1, -- přidano, protoze na této úrovni dokážu vypnout konkrétní banner na konkrétním webu/pozici
    CONSTRAINT FK_Campaign_Banner_Campaign FOREIGN KEY (fk_Campaign) REFERENCES dbo.[Campaign](pk_Campaign),
    CONSTRAINT FK_Campaign_Banner_Banner FOREIGN KEY (fk_Banner) REFERENCES dbo.[Banner](pk_Banner),
    CONSTRAINT FK_Campaign_Banner_Banner_Position FOREIGN KEY (fk_Banner_Position) REFERENCES dbo.[Banner_Position](pk_BannerPosition)
);

CREATE TABLE dbo.[Banner_Click] (
    pk_Banner_Click      BIGINT PRIMARY KEY IDENTITY(1,1),
    fk_Campaign_Banner   BIGINT    NOT NULL,
    clickedDate          DATETIME2 NOT NULL,
    CONSTRAINT FK_Banner_Click_Campaign_Banner FOREIGN KEY (fk_Campaign_Banner) REFERENCES dbo.[Campaign_Banner](pk_Campaign_Banner)
);


CREATE TABLE dbo.[Order] (
    pk_Order BIGINT PRIMARY KEY Identity(1,1),
    orderDate DATETIME2 NOT NULL,
    totalPrice DECIMAL(12, 2) NOT NULL, -- cena zakázky
    margin DECIMAL(12, 2) NOT NULL     -- marže zakázky
);

CREATE TABLE dbo.[Order_Banner] (
    fk_Order           BIGINT NOT NULL,
    fk_Campaign_Banner BIGINT NOT NULL,
    CONSTRAINT PK_Order_Banner                 PRIMARY KEY (fk_Order, fk_Campaign_Banner),
    CONSTRAINT FK_Order_Banner_Order           FOREIGN KEY (fk_Order)           REFERENCES dbo.[Order](pk_Order),
    CONSTRAINT FK_Order_Banner_Campaign_Banner FOREIGN KEY (fk_Campaign_Banner) REFERENCES dbo.[Campaign_Banner](pk_Campaign_Banner)
);

-- ============================================================================
-- Návrh Indexu (bod d)
-- ============================================================================

CREATE NONCLUSTERED INDEX IX_Banner_Click_Campaign_Banner ON dbo.[Banner_Click] (fk_Campaign_Banner, clickedDate);
CREATE NONCLUSTERED INDEX IX_Order_Banner_Campaign_Banner ON dbo.[Order_Banner] (fk_Campaign_Banner);
CREATE NONCLUSTERED INDEX IX_Campaign_Banner_Campaign     ON dbo.[Campaign_Banner] (fk_Campaign, fk_Banner_Position);
CREATE NONCLUSTERED INDEX IX_Campaign_Banner_Position     ON dbo.[Campaign_Banner] (fk_Banner_Position);
CREATE NONCLUSTERED INDEX IX_Banner_Size                  ON dbo.[Banner] (width, height);
CREATE NONCLUSTERED INDEX IX_Order_Order_Date             ON dbo.[Order] (orderDate);


-- ============================================================================
-- Návrh Constraintu (bod e)
-- ============================================================================

-- kromě primárních kličů a ciziho klíče, které jsou definovány přimo v definici tabulky, přidáme ještě další constrainty pro kontrolu datové integrity
ALTER TABLE dbo.[Website]
    ADD CONSTRAINT UQ_Website_Name UNIQUE ([webName]);

ALTER TABLE dbo.[Banner_Position]
    ADD CONSTRAINT CK_Banner_Position_Size         CHECK (width > 0 AND height > 0),
        CONSTRAINT CK_Banner_Position_Pricing_Type CHECK (pricingType IN ('DAY', 'CLICK')),
        CONSTRAINT CK_Banner_Position_Price        CHECK (unitPrice >= 0);

ALTER TABLE dbo.[Banner]
    ADD CONSTRAINT CK_Banner_Size CHECK (width > 0 AND height > 0);


ALTER TABLE dbo.[Campaign_Banner]
    ADD CONSTRAINT UQ_Campaign_Banner UNIQUE (fk_Campaign, fk_Banner_Position, fk_Banner);

ALTER TABLE dbo.[Order]
    ADD CONSTRAINT CK_Order_Price CHECK (totalPrice >= 0);

ALTER TABLE dbo.[Campaign]
    ADD CONSTRAINT CK_Campaign_Dates CHECK (validTo > validFrom);
GO

