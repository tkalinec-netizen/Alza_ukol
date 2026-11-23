SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- ============================================================================
-- b) Výpis všech kampaní a jejich bilanci (výnos mínus náklady)
-- ============================================================================
;WITH ClickCounts AS (
    SELECT fk_Campaign_Banner, COUNT(*) AS clicks
    FROM dbo.[Banner_Click]
    GROUP BY fk_Campaign_Banner
),
CampaignCosts AS (
    SELECT 
        c.pk_Campaign,
        SUM(
            CASE bp.pricingType
                WHEN 'DAY' THEN 
                    (DATEDIFF(DAY, CAST(c.validFrom AS DATE), 
                        CASE 
                            WHEN CAST(c.validTo AS TIME) = '00:00:00' THEN DATEADD(DAY, -1, CAST(c.validTo AS DATE))
                            ELSE CAST(c.validTo AS DATE)
                        END
                    ) + 1) * bp.unitPrice
                WHEN 'CLICK' THEN 
                    ISNULL(cc.clicks, 0) * bp.unitPrice
                ELSE 0
            END
        ) AS totalCost
    FROM dbo.[Campaign] c
    LEFT JOIN dbo.[Campaign_Banner] cb ON cb.fk_Campaign = c.pk_Campaign
    LEFT JOIN dbo.[Banner_Position] bp ON bp.pk_BannerPosition = cb.fk_Banner_Position
    LEFT JOIN ClickCounts cc ON cc.fk_Campaign_Banner = cb.pk_Campaign_Banner
    GROUP BY c.pk_Campaign
),
OrderBannerCounts AS (
    SELECT fk_Order, COUNT(*) AS bannerCount
    FROM dbo.[Order_Banner]
    GROUP BY fk_Order
),
CampaignRevenues AS (
    -- Marzi zakazky delime rovnomerne mezi vsechny bannery, ze kterych zakaznik prisel
    SELECT 
        cb.fk_Campaign,
        SUM(o.margin / CAST(obc.bannerCount AS DECIMAL(18, 4))) AS totalRevenue
    FROM dbo.[Order] o
    JOIN dbo.[Order_Banner] ob ON ob.fk_Order = o.pk_Order
    JOIN OrderBannerCounts obc ON obc.fk_Order = o.pk_Order
    JOIN dbo.[Campaign_Banner] cb ON cb.pk_Campaign_Banner = ob.fk_Campaign_Banner
    GROUP BY cb.fk_Campaign
)
SELECT 
    c.pk_Campaign,
    c.campaignName,
    CAST(ISNULL(r.totalRevenue, 0) AS DECIMAL(12, 2)) AS revenue,
    CAST(ISNULL(cost.totalCost, 0) AS DECIMAL(12, 2)) AS cost,
    CAST(ISNULL(r.totalRevenue, 0) - ISNULL(cost.totalCost, 0) AS DECIMAL(12, 2)) AS balance
FROM dbo.[Campaign] c
LEFT JOIN CampaignRevenues r ON r.fk_Campaign = c.pk_Campaign
LEFT JOIN CampaignCosts cost ON cost.pk_Campaign = c.pk_Campaign
ORDER BY balance DESC;


-- ============================================================================
-- c) Celková bilance bannerů placených za den podle dnu v týdnu (Po - Ne)
-- ============================================================================
SET DATEFIRST 1;

;WITH DaysOfWeek (dayNum, dayName) AS (
    SELECT * FROM (VALUES 
        (1, N'Po'),
        (2, N'Út'),
        (3, N'St'),
        (4, N'Čt'),
        (5, N'Pá'),
        (6, N'So'),
        (7, N'Ne')
    ) AS t(dayNum, dayName)
),
CampaignDays AS (
    SELECT 
        cb.pk_Campaign_Banner,
        bp.unitPrice AS dailyCost,
        CAST(c.validFrom AS DATE) AS activeDate,
        CASE 
            WHEN CAST(c.validTo AS TIME) = '00:00:00' THEN DATEADD(DAY, -1, CAST(c.validTo AS DATE))
            ELSE CAST(c.validTo AS DATE)
        END AS endDate -- Když je čas konce půlnoc 00:00:00, vezmi předchozí den
    FROM dbo.[Campaign] c
    JOIN dbo.[Campaign_Banner] cb ON cb.fk_Campaign = c.pk_Campaign
    JOIN dbo.[Banner_Position] bp ON bp.pk_BannerPosition = cb.fk_Banner_Position
    WHERE bp.pricingType = 'DAY'

    UNION ALL

    SELECT 
        pk_Campaign_Banner,
        dailyCost,
        DATEADD(DAY, 1, activeDate),
        endDate
    FROM CampaignDays
    WHERE activeDate < endDate
),
DailyCosts AS (
    SELECT 
        DATEPART(WEEKDAY, activeDate) AS dayNum,
        SUM(dailyCost) AS totalCost
    FROM CampaignDays
    GROUP BY DATEPART(WEEKDAY, activeDate)
),
OrderBannerCounts AS (
    SELECT fk_Order, COUNT(*) AS bannerCount
    FROM dbo.[Order_Banner]
    GROUP BY fk_Order
),
DailyRevenues AS (
    SELECT 
        DATEPART(WEEKDAY, o.orderDate) AS dayNum,
        SUM(o.margin / CAST(obc.bannerCount AS DECIMAL(18, 4))) AS totalRevenue
    FROM dbo.[Order] o
    JOIN dbo.[Order_Banner] ob ON ob.fk_Order = o.pk_Order
    JOIN OrderBannerCounts obc ON obc.fk_Order = o.pk_Order
    JOIN dbo.[Campaign_Banner] cb ON cb.pk_Campaign_Banner = ob.fk_Campaign_Banner
    JOIN dbo.[Banner_Position] bp ON bp.pk_BannerPosition = cb.fk_Banner_Position
    WHERE bp.pricingType = 'DAY'
    GROUP BY DATEPART(WEEKDAY, o.orderDate)
)
SELECT 
    d.dayNum,
    d.dayName,
    CAST(ISNULL(r.totalRevenue, 0) AS DECIMAL(12, 2)) AS revenue,
    CAST(ISNULL(c.totalCost, 0)    AS DECIMAL(12, 2)) AS cost,
    CAST(ISNULL(r.totalRevenue, 0) - ISNULL(c.totalCost, 0) AS DECIMAL(12, 2)) AS balance
FROM DaysOfWeek d
LEFT JOIN DailyRevenues r ON r.dayNum = d.dayNum
LEFT JOIN DailyCosts c    ON c.dayNum = d.dayNum
ORDER BY d.dayNum
OPTION (MAXRECURSION 1000);-- Může být potřeba zvýšit, pokud by kampan byla delší než 1000 dní