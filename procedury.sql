--Procedura do realizacji wypłaty dla pracownika oraz dodanie wpisu do tabeli Payments oraz wystawiania faktury kosztowej (Invoices):
CREATE PROCEDURE sp_Employees_CurrentBalance_ExecutePayday
(
    @EmployeeID INT,
    @Amount DECIMAL(12,4)
)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @CurrentBalance DECIMAL(12,4);

    IF NOT EXISTS (SELECT 1 FROM Employees WHERE EmployeeID = @EmployeeID)
    BEGIN
        THROW 50001, 'Nie znaleziono pracownika o podanym EmployeeID.', 1;
    END

	SELECT @CurrentBalance = CurrentBalance
	FROM Employees
	WHERE EmployeeID = @EmployeeID;

	IF @Amount > @CurrentBalance
	BEGIN
		THROW 50001, 'Kwota wypłaty przekracza aktualne saldo pracownika.', 1;
	END

    UPDATE e
    SET CurrentBalance = CurrentBalance - @Amount
    FROM Employees e
    WHERE e.EmployeeID = @EmployeeID;

    INSERT INTO Payments (PaymentName, TotalAmount)
    VALUES ('Wypłata dla pracownika '+ CAST(@EmployeeID AS NVARCHAR(12)), -(@Amount));

	INSERT INTO Invoices (InvoiceNumber, InvoiceType, DueDate, NetAmount, VatAmount, TaxAmount, GrossAmount)
	VALUES ('WYP-'+CAST(@EmployeeID AS NVARCHAR(12)), 'Kosztowa', GETDATE(), @Amount, 0, 0, @Amount);
END
GO

--Procedura do dodania dostawy do magazynu oraz dodanie ewentualnej faktury kosztowej do tego zamówienia:
CREATE PROCEDURE sp_AddInventoryDelivery
(
    @MaterialID INT,
    @Quantity DECIMAL(12,4),
    @TotalPrice DECIMAL(12,4),
    @SupplierID INT,
    @Invoice BIT = 0, --0 - brak faktury, 1 - faktura kosztowa dołączona
    @DueDate DATE = NULL, --Termin płatności faktury kosztowej
    @NetAmount DECIMAL(12,4) = NULL, --Wartość netto faktury kosztowej
    @VatAmount DECIMAL(7,4) = NULL, --Wartość stawki VAT faktury kosztowej
    @InvoiceNumber NVARCHAR(50) = NULL --Numer faktury kosztowej
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Materials WHERE MaterialID = @MaterialID)
    BEGIN
        THROW 50001, 'Nie znaleziono materiału o podanym MaterialID.', 1;
    END

    IF @Quantity <= 0
    BEGIN  
        THROW 50001, 'Ilość dostawy musi być większa od 0.', 1;
    END

    UPDATE m
    SET CurrentStock = CurrentStock + @Quantity
    FROM Materials m
    WHERE m.MaterialID = @MaterialID;

    INSERT INTO InventoryTransactions (MaterialID, TotalPrice, Notes, Quantity)
    VALUES (@MaterialID, @TotalPrice, 'Dostawa od' + CAST(@SupplierID AS NVARCHAR(12)), @Quantity);

    IF @Invoice = 1
    BEGIN
        IF @DueDate IS NULL OR @NetAmount IS NULL OR @VatAmount IS NULL OR @SupplierID IS NULL
        BEGIN
            THROW 50001, 'Brak wymaganych danych do wystawienia faktury kosztowej.', 1;
        END
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE SupplierID = @SupplierID)
        BEGIN
            THROW 50001, 'Nie znaleziono dostawcy o podanym SupplierID.', 1;
        END
        INSERT INTO Invoices (InvoiceNumber, InvoiceType, DueDate, NetAmount, VatAmount, TaxAmount, GrossAmount)
        VALUES (@InvoiceNumber, 'Zakupowa', @DueDate, @NetAmount, @VatAmount, (@NetAmount * @VatAmount / 100), @NetAmount + (@NetAmount * @VatAmount / 100));
    END
END
GO

--Procedura do dodawania nowego zamówienia (Orders):
CREATE PROCEDURE sp_AddNewOrder
(
    @CustomerID INT,
    @ShipDate DATE
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Customers WHERE CustomerID = @CustomerID)
    BEGIN
        THROW 50001, 'Nie znaleziono klienta o podanym CustomerID.', 1;
    END

    INSERT INTO Orders (CustomerID, ShipDate)
    VALUES (@CustomerID, @ShipDate);
END
GO

--Procedury do dodawania pozycji do zamówienia nie będzie, gdyż musi być to zaimplementowane bezpośrednio w aplikacji z powodu możliwości wyboru wielu rozmiarów i ilości do rozmiaru (np. 10 par rozmiaru 36, 12 par rozmiaru 35 ale innego produktu)

--Procedura do wystawiania faktury za zamówienie:
CREATE PROCEDURE sp_IssueInvoiceForOrder
(
    @OrderID INT,
    @DueDate DATE, --Termin płatności
    @NetAmount DECIMAL(12,4), --Wartosc Netto zamowienia
    @VatAmount DECIMAL(12,4) --Wartosc stawki VAT
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderID = @OrderID)
    BEGIN
        THROW 50001, 'Nie znaleziono zamówienia o podanym OrderID.', 1;
    END

    INSERT INTO Invoices (OrderID, InvoiceType, DueDate, NetAmount, VatAmount, TaxAmount, GrossAmount)
    VALUES (@OrderID, 'Sprzedażowa', @DueDate, @NetAmount, @VatAmount, (@NetAmount * @VatAmount / 100), @NetAmount + (@NetAmount * @VatAmount / 100));
END
GO

--Procedura do opłacania faktury zakupowej:
CREATE PROCEDURE sp_PayPurchaseInvoice
(
    @InvoiceID INT,
    @PaymentDate DATE,
    @TotalAmount DECIMAL(12,4)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Invoices WHERE InvoiceID = @InvoiceID AND InvoiceType = 'Zakupowa')
    BEGIN
        THROW 50001, 'Nie znaleziono faktury zakupowej o podanym InvoiceID.', 1;
    END

    UPDATE i
    SET PaymentDate = @PaymentDate,
        Status = CASE
                    WHEN @TotalAmount = GrossAmount THEN 'Opłacona'
                    WHEN @TotalAmount < GrossAmount THEN 'Częściowo opłacona'
                    ELSE 'Nadpłata'
                 END
    FROM Invoices i
    WHERE i.InvoiceID = @InvoiceID;

    INSERT INTO Payments (PaymentName, TotalAmount, InvoiceID)
    VALUES ('Płatność faktury zakupowej '+ CAST(@InvoiceID AS NVARCHAR(12)), -(@TotalAmount), @InvoiceID);
END
GO

--Procedura do zmiany statusu faktury sprzedażowej na Opłacona lub Częściowo opłacona (czyli po prostu dodanie płatności do faktury, aby uwzględnić w stanie konta):
CREATE PROCEDURE sp_UpdateSalesInvoicePaymentStatus
(
    @InvoiceID INT,
    @PaymentDate DATE,
    @TotalAmount DECIMAL(12,4)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Invoices WHERE InvoiceID = @InvoiceID AND InvoiceType = 'Sprzedażowa')
    BEGIN
        THROW 50001, 'Nie znaleziono faktury sprzedażowej o podanym InvoiceID.', 1;
    END

	IF @TotalAmount > (SELECT GrossAmount FROM Invoices WHERE InvoiceID = @InvoiceID)
	BEGIN
		THROW 50002, 'Kwota płatności nie może być większa niż kwota brutto faktury.', 1;
	END

	UPDATE i
	SET PaymentDate = @PaymentDate,
		Status = CASE
					WHEN @TotalAmount = GrossAmount THEN 'Opłacona'
					WHEN @TotalAmount < GrossAmount THEN 'Częściowo opłacona'
					ELSE 'Błąd'
				END
	FROM Invoices i
	WHERE i.InvoiceID = @InvoiceID;

    INSERT INTO Payments (PaymentName, TotalAmount, InvoiceID)
    VALUES ('Płatność faktury sprzedażowej '+ CAST(@InvoiceID AS NVARCHAR(12)), @TotalAmount, @InvoiceID);
END
GO

--Raport - Procedura zwracająca raport o produkcji za dany okres czasu:
CREATE PROCEDURE sp_Report_Production
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT 
        pr.Status,
        COUNT(*) AS Ile_zleceń,
        SUM(pr.QuantityToProduce) AS Ile_sztuk
    FROM Production pr
    WHERE pr.CreatedDate BETWEEN @StartDate AND @EndDate
    GROUP BY pr.Status
    ORDER BY SUM(pr.QuantityToProduce) DESC;
    
    SELECT 
        e.FirstName + ' ' + e.LastName AS Pracownik,
        r.RoleName AS Rola,
        COUNT(DISTINCT CASE WHEN pr.SzewcID = e.EmployeeID THEN pr.ProductionID END) AS Jako_szewc,
        COUNT(DISTINCT CASE WHEN pr.CholewkarzID = e.EmployeeID THEN pr.ProductionID END) AS Jako_cholewkarz,
        COUNT(DISTINCT CASE WHEN pr.KrojczyID = e.EmployeeID THEN pr.ProductionID END) AS Jako_krojczy,
        COUNT(DISTINCT pr.ProductionID) AS Razem_zleceń
    FROM Employees e
    LEFT JOIN Production pr ON e.EmployeeID IN (pr.SzewcID, pr.CholewkarzID, pr.KrojczyID)
        AND pr.CreatedDate BETWEEN @StartDate AND @EndDate
    LEFT JOIN Roles r ON e.RoleID = r.RoleID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName, r.RoleName
    HAVING COUNT(DISTINCT pr.ProductionID) > 0
    ORDER BY Razem_zleceń DESC;
END
GO

--Raport - Procedura zwracająca raport sprzedaży za dany okres czasu:
CREATE PROCEDURE sp_Report_Sales
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    -- Sprzedaż wg produktu:
    SELECT 
        p.ProductName AS Produkt,
        pc.CategoryName AS Kategoria,
        SUM(oi.Quantity) AS Sprzedane_sztuki,
        SUM(oi.Quantity * oi.UnitPrice) AS Wartość_sprzedaży,
        AVG(oi.UnitPrice) AS Średnia_cena
    FROM Products p
    INNER JOIN ProductSubcategory psc ON p.ProductSubcategoryID = psc.SubcategoryID
    INNER JOIN ProductCategory pc ON psc.CategoryID = pc.CategoryID
    INNER JOIN ProductVariants pv ON p.ProductID = pv.ProductID
    INNER JOIN OrderItems oi ON pv.VariantID = oi.VariantID
    INNER JOIN Orders o ON oi.OrderID = o.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY p.ProductName, pc.CategoryName
    ORDER BY Wartość_sprzedaży DESC;
    
    -- Klienci i ich zamówienia:
    SELECT 
        c.CustomerName AS Klient,
        COUNT(DISTINCT o.OrderID) AS Ilość_zamówień,
        SUM(o.TotalDue) AS Wydane_łącznie,
        MAX(o.OrderDate) AS Ostatnie_zamówienie
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY c.CustomerID, c.CustomerName
    ORDER BY Wydane_łącznie DESC;
END
GO

--Raport - Procedura zwracająca materiały z niskim stanem magazynowym:
CREATE PROCEDURE sp_Report_LowInventory
AS
BEGIN
	SELECT 
        MaterialName AS Materiał,
        CurrentStock AS Stan,
        UnitOfMeasure AS Jednostka,
        CASE 
            WHEN CurrentStock <= 0 THEN 'BRAK'
            WHEN CurrentStock < 20 THEN 'MAŁO'
            ELSE 'OK'
        END AS Status
    FROM Materials
    WHERE CurrentStock < 20
    ORDER BY CurrentStock;
END
GO

--Raport finansowy:
CREATE PROCEDURE sp_Report_Finance
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    -- Wpływy (dodatnie płatności)
    SELECT 
        'Wpływy' AS Typ,
        COUNT(*) AS Ilość_transakcji,
        SUM(TotalAmount) AS Kwota
    FROM Payments
    WHERE PaymentDate BETWEEN @StartDate AND @EndDate
      AND TotalAmount > 0;
    
    -- Wydatki (ujemne płatności)
    SELECT 
        'Wydatki' AS Typ,
        COUNT(*) AS Ilość_transakcji,
        SUM(ABS(TotalAmount)) AS Kwota
    FROM Payments
    WHERE PaymentDate BETWEEN @StartDate AND @EndDate
      AND TotalAmount < 0;
    
    -- Saldo pracowników
    SELECT 
        FirstName + ' ' + LastName AS Pracownik,
        CurrentBalance AS Saldo,
        CASE 
            WHEN CurrentBalance > 0 THEN 'DO WYPŁATY'
            WHEN CurrentBalance < 0 THEN 'ZADŁUŻENIE'
            ELSE 'ZEROWE'
        END AS Status
    FROM Employees
    WHERE CurrentBalance <> 0
    ORDER BY ABS(CurrentBalance) DESC;
END
GO

--Raport zamówień:
CREATE PROCEDURE sp_Report_Orders
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    -- Zamówienia wg statusu
    SELECT 
        o.Status AS Status_zamówienia,
        COUNT(*) AS Ilość,
        SUM(o.TotalDue) AS Wartość,
        AVG(o.TotalDue) AS Średnia_wartość
    FROM Orders o
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY o.Status
    ORDER BY Wartość DESC;
    
    -- Produkty w zamówieniach
    SELECT 
        p.ProductName AS Produkt,
        s.SizeName AS Rozmiar,
        SUM(oi.Quantity) AS Zamówione_sztuki,
        SUM(oi.QuantityProduced) AS Wyprodukowane_sztuki,
        CASE 
            WHEN SUM(oi.Quantity) > 0 THEN CAST(SUM(oi.QuantityProduced) * 100 / SUM(oi.Quantity) AS DECIMAL(5,1))
            ELSE 0
        END AS Procent_wykonania
    FROM OrderItems oi
    INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
    INNER JOIN Products p ON pv.ProductID = p.ProductID
    INNER JOIN Sizes s ON oi.SizeID = s.SizeID
    INNER JOIN Orders o ON oi.OrderID = o.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY p.ProductName, s.SizeName
    ORDER BY Zamówione_sztuki DESC;
END
GO
