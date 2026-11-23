SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

INSERT INTO dbo.[Website] (webName) VALUES 
    (N'seznam.cz'),
    (N'heureka.cz');

-- Pozice
INSERT INTO dbo.[Banner_Position] (fk_Web, positionName, width, height, pricingType, unitPrice) VALUES 
    (1, N'Homepage Top',        970, 210, 'DAY',   1000.00),
    (1, N'Pravy sloupec',       300, 300, 'CLICK',    5.00),
    (2, N'Kategorie horni box', 970, 210, 'DAY',    800.00);

-- Bannery
INSERT INTO dbo.[Banner] (bannerName, bannerImage, width, height, urlWeb) VALUES 
    (N'Podzimni vyprodej NB', 'vyprodej_nb.png', 970, 210, N'https://muj-eshop.cz'),
    (N'Akce mobily',          'akce_tel.png',    300, 300, N'https://muj-eshop.cz');

-- Kampaně (konec o půlnoci 00:00:00 = končí předchozí den)
INSERT INTO dbo.[Campaign] (campaignName, validFrom, validTo) VALUES 
    (N'Listopadova akce', '2026-11-16 00:00:00', '2026-11-19 00:00:00'),
    (N'Predvanocni slevy', '2026-11-19 00:00:00', '2026-11-23 00:00:00');

-- Nasazení banneru do kampaní
INSERT INTO dbo.[Campaign_Banner] (fk_Campaign, fk_Banner, fk_Banner_Position, isActive) VALUES 
    (1, 1, 1, 1),
    (1, 2, 2, 1),
    (2, 1, 3, 1);

-- Prokliky
INSERT INTO dbo.[Banner_Click] (fk_Campaign_Banner, clickedDate) VALUES 
    (1, '2026-11-16 10:14:22'),
    (1, '2026-11-17 14:21:05'),
    (2, '2026-11-16 11:02:11'),
    (2, '2026-11-16 11:07:49'),
    (2, '2026-11-16 12:13:02'),
    (2, '2026-11-17 09:34:18'),
    (2, '2026-11-17 15:46:55'),
    (2, '2026-11-18 08:22:30'),
    (2, '2026-11-18 13:11:44'),
    (2, '2026-11-18 16:04:19'),
    (2, '2026-11-18 18:33:08'),
    (2, '2026-11-18 20:17:51'),
    (3, '2026-11-20 17:05:12');

-- Objednávky
INSERT INTO dbo.[Order] (orderDate, totalPrice, margin) VALUES 
    ('2026-11-16 10:48:10', 21990.00, 4000.00),
    ('2026-11-18 21:04:35', 11490.00, 2000.00),
    ('2026-11-20 17:32:40',  8990.00, 1500.00);

-- Vazba objednávek na bannery (objednávka 2 přišla přes dva bannery)
INSERT INTO dbo.[Order_Banner] (fk_Order, fk_Campaign_Banner) VALUES 
    (1, 1),
    (2, 1),
    (2, 2),
    (3, 3);