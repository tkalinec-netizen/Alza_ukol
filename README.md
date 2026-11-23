# Sledování účinnosti bannerových kampaní
> Tyto scripty jsou napsány pro **MS SQL Server 2022** / Azure SQL  (fungují od verze 2012 výše) a všechny objekty uvádím explicitně pod výchozím schématem **`dbo`**.


##  a) Datový model

* ER diagram databáze (vytvořeno v draw.io) je přiložen v souboru `er_diagram.png`.

* Vazbu z objednávek (`Order_Banner`) vedu na konkrétní nasazení banneru (`fk_Campaign_Banner`), aby šlo jednoznačně určit kampaň i typ platby (`DAY` / `CLICK`).

*  U tabulky `Campaign_Banner` mám sloupec `isActive` (`BIT`, výchozí `1`), kterým lze konkrétní nasazení banneru kdykoliv vypnout bez mazání historie.  V dotazech (b a c) podle něj ale nefiltruju, protože vypnutí banneru po skončení kampaně by zpětně smazalo jeho minulé náklady a výnosy.

* U velkých transakčních a vazebních tabulek (`Order`, `Order_Banner`, `Banner_Click`, `Campaign_Banner`) používám pro primární a cizí klíče datový typ `BIGINT` – očekávají se u nich miliony až miliardy záznamů, takže klasický `INT` by mohl časem přetéct (což se mi už v praxi stalo). U malých číselníků (`Website`, `Banner_Position`, `Banner`, `Campaign`) nechávám `INT`, protože šetří místo v indexech.

## b) Bilance všech kampaní (výnos mínus náklady)

* Pokud zákazník klikl před nákupem na více bannerů, marži mezi ně dělím rovným dílem, aby se nezapočítala víckrát.
* Náklady počítám podle typu pozice – buď jako počet dnů kampaně krát denní sazba (`DAY`), nebo počet prokliků krát cena za klik (`CLICK`).


## c) Bilance podle dnů v týdnu (platba za den)

* Do výpočtu zahrnuji pouze nasazení na pozicích, které mají nastavený model platby za den (`pricingype = 'DAY'`).
* Používám `SET DATEFIRST 1`, aby týden začínal pondělkem, a výsledek napojuji přes `LEFT JOIN` na číselník 7 dnů – dotaz tak vrátí vždy všech 7 řádků od pondělí do neděle (i když v daný den nic neběželo).
* Platnost kampaně rozbaluji po jednotlivých dnech přes rekurzivní CTE (při milionech řádků v produkci bych místo rekurze použil předpřipravenou kalendářovou tabulku).
* Pokud nastane konec kampaně přesně o půlnoci (`00:00:00` v datetime2 může nastat),  tak se započítá už jen předchozí den.
* Výnosy (poměrnou marži z objednávek v daný den týdne) a denní náklady sčítám v oddělených CTE a spojuji je až na konci, aby se náklady při více objednávkách neduplikovaly.

## d) Indexy

* `IX_Banner_Click_Campaign_Banner` a `IX_Order_Banner_Campaign_Banner` – zrychlí počítání prokliků a dohledání objednávek pro konkrétní nasazený banner (dotazy b a c).
* `IX_Campaign_Banner_Campaign` a `IX_Campaign_Banner_Position` – zrychlí spojování tabulek při filtrování podle kampaně (dotaz b) i podle typu pozice (dotaz c).
* `IX_Banner_Size (Width, Height)` – pro rychlé vyhledání bannerů se stejným rozměrem, jaký má vybraná pozice.
* `IX_Order_Order_Date` – pro filtrování objednávek podle data v reálném provozu.

## e) Constrainty
* `CHECK` na kladné rozměry (`width > 0 AND height > 0`), nezáporné ceny (`unitPrice  >= 0`), povolené typy platby (`DAY`, `CLICK`) a kontrolu data (`validTo > validFrom`).
* `UNIQUE` na název webu (`name`) a na kombinaci `(fk_Campaign, fk_Banner_Position, fk_Banner)`, aby nešel ten samý banner nasadit na stejnou pozici v jedné kampani dvakrát.
* Shodné rozlišení banneru a pozice nelze v MS SQL ohlídat klasickým `CHECK` constraintem (neumí odkazovat do jiné tabulky) – v praxi by se to hlídalo v aplikaci nebo přes `AFTER INSERT, UPDATE` trigger na tabulce `Campaign_Banner`.
