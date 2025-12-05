--Widok aktualnych zamówień:
CREATE VIEW vw_AktualneZamowienia AS
SELECT 
    o.OrderID,
    c.CustomerName AS Klient,
    o.OrderDate AS Data_zamówienia,
    o.ShipDate AS Planowana_wysyłka,
    o.Status AS Status,
    o.TotalDue AS Wartość,
    -- Procent wykonania
    CASE 
        WHEN SUM(oi.Quantity) > 0 
        THEN CAST(SUM(oi.QuantityProduced) * 100.0 / SUM(oi.Quantity) AS DECIMAL(5,1))
        ELSE 0 
    END AS Wykonanie_procent
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
INNER JOIN OrderItems oi ON o.OrderID = oi.OrderID
WHERE o.Status IN ('Nowe', 'W realizacji', 'Gotowe')
GROUP BY o.OrderID, c.CustomerName, o.OrderDate, o.ShipDate, o.Status, o.TotalDue;
GO

--Widok pracowników z aktywnością:
CREATE VIEW vw_PracownicyAktywni AS
SELECT 
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS Pracownik,
    r.RoleName AS Rola,
    e.CurrentBalance AS Saldo,
    e.LastActive AS Ostatnia_aktywność,
    -- Ilość aktualnych zleceń
    (SELECT COUNT(*) 
     FROM Production p 
     WHERE (p.SzewcID = e.EmployeeID OR p.CholewkarzID = e.EmployeeID OR p.KrojczyID = e.EmployeeID)
       AND p.Status IN ('Nowe', 'W trakcie')) AS Aktywne_zlecenia,
    CASE WHEN e.FiredAt IS NOT NULL THEN 'TAK' ELSE 'NIE' END AS Zwolniony
FROM Employees e
LEFT JOIN Roles r ON e.RoleID = r.RoleID;
GO

--Widok stanu magazynowego materiałów:
CREATE VIEW vw_StanMagazynu AS
SELECT 
    m.MaterialID,
    m.MaterialName AS Materiał,
    m.MaterialType AS Typ,
    m.CurrentStock AS Stan,
    m.UnitOfMeasure AS Jednostka,
    -- Ostatnie zużycie
    (SELECT TOP 1 ABS(it.Quantity) 
     FROM InventoryTransactions it 
     WHERE it.MaterialID = m.MaterialID AND it.Quantity < 0
     ORDER BY it.TransactionDate DESC) AS Ostatnie_pobranie,
    -- Status
    CASE 
        WHEN m.CurrentStock <= 0 THEN 'BRAK'
        WHEN m.CurrentStock < 10 THEN 'MAŁO'
        WHEN m.CurrentStock < 50 THEN 'ŚREDNIO'
        ELSE 'OK'
    END AS Status
FROM Materials m;
GO

--Widok faktur do zapłaty:
CREATE VIEW vw_FakturyDoZaplaty AS
SELECT 
    i.InvoiceID,
    i.InvoiceNumber AS Numer_faktury,
    i.InvoiceType AS Typ,
    i.IssueDate AS Data_wystawienia,
    i.DueDate AS Termin_płatności,
    i.GrossAmount AS Kwota_brutto,
    i.Status AS Status,
    DATEDIFF(DAY, GETDATE(), i.DueDate) AS Dni_do_termimu,
    CASE 
        WHEN i.InvoiceType = 'Sprzedażowa' THEN c.CustomerName
        WHEN i.InvoiceType = 'Zakupowa' THEN s.SupplierName
        ELSE 'Inna'
    END AS Kontrahent
FROM Invoices i
LEFT JOIN Orders o ON i.OrderID = o.OrderID
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN Suppliers s ON i.SupplierID = s.SupplierID
WHERE i.Status IN ('Wystawiona', 'Częściowo opłacona')
  AND i.PaymentDate IS NULL;
GO

--Widok produkcji w toku:
CREATE VIEW vw_ProdukcjaWToku AS
SELECT 
    pr.ProductionID,
    p.ProductName AS Produkt,
    s.SizeName AS Rozmiar,
    pr.QuantityToProduce AS Ilość,
    pr.Status AS Status,
    pr.CreatedDate AS Data_utworzenia,
    -- Pracownicy
    szewc.FirstName + ' ' + szewc.LastName AS Szewc,
    krojczy.FirstName + ' ' + krojczy.LastName AS Krojczy,
    cholewkarz.FirstName + ' ' + cholewkarz.LastName AS Cholewkarz,
    -- Zamówienie
    o.OrderID,
    c.CustomerName AS Klient
FROM Production pr
INNER JOIN OrderItems oi ON pr.OrderItemID = oi.OrderItemID
INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
INNER JOIN Products p ON pv.ProductID = p.ProductID
INNER JOIN Sizes s ON oi.SizeID = s.SizeID
INNER JOIN Orders o ON oi.OrderID = o.OrderID
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN Employees szewc ON pr.SzewcID = szewc.EmployeeID
LEFT JOIN Employees krojczy ON pr.KrojczyID = krojczy.EmployeeID
LEFT JOIN Employees cholewkarz ON pr.CholewkarzID = cholewkarz.EmployeeID
WHERE pr.Status IN ('Nowe', 'W trakcie');
GO

--Widok najlepiej sprzedających się produktów w ostatnich 3 miesiącach:
CREATE VIEW vw_NajlepiejSprzedajaceProdukty AS
SELECT TOP 10
    p.ProductName AS Produkt,
    pc.CategoryName AS Kategoria,
    SUM(oi.Quantity) AS Sprzedane_sztuki,
    SUM(oi.Quantity * oi.UnitPrice) AS Przychód,
    COUNT(DISTINCT o.OrderID) AS Ilość_zamówień,
    AVG(oi.UnitPrice) AS Średnia_cena
FROM Products p
INNER JOIN ProductSubcategory psc ON p.ProductSubcategoryID = psc.SubcategoryID
INNER JOIN ProductCategory pc ON psc.CategoryID = pc.CategoryID
INNER JOIN ProductVariants pv ON p.ProductID = pv.ProductID
INNER JOIN OrderItems oi ON pv.VariantID = oi.VariantID
INNER JOIN Orders o ON oi.OrderID = o.OrderID
WHERE o.OrderDate >= DATEADD(MONTH, -3, GETDATE()) -- Ostatnie 3 miesiące
GROUP BY p.ProductName, pc.CategoryName
ORDER BY Sprzedane_sztuki DESC;
GO
