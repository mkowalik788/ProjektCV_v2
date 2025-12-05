--Funkcja sprawdzająca dostępność materiału w magazynie:
CREATE FUNCTION fn_SprawdzDostepnoscMaterialu
(
    @MaterialID INT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @Stan DECIMAL(16,4);
    DECLARE @Nazwa NVARCHAR(50);
    DECLARE @Wynik NVARCHAR(100);
    
    SELECT 
        @Stan = CurrentStock,
        @Nazwa = MaterialName
    FROM Materials 
    WHERE MaterialID = @MaterialID;
    
    IF @Nazwa IS NULL
        SET @Wynik = 'Materiał nie istnieje';
    ELSE IF @Stan <= 0
        SET @Wynik = @Nazwa + ': BRAK';
    ELSE IF @Stan < 10
        SET @Wynik = @Nazwa + ': MAŁO (' + CAST(@Stan AS NVARCHAR(20)) + ')';
    ELSE
        SET @Wynik = @Nazwa + ': OK (' + CAST(@Stan AS NVARCHAR(20)) + ')';
    
    RETURN @Wynik;
END
GO

--Funkcja obliczająca wartość zamówienia:
CREATE FUNCTION fn_ObliczWartoscZamowienia
(
    @OrderID INT
)
RETURNS DECIMAL(20,4)
AS
BEGIN
    DECLARE @Wartosc DECIMAL(20,4);
    
    SELECT @Wartosc = SUM(oi.Quantity * oi.UnitPrice)
    FROM OrderItems oi
    WHERE oi.OrderID = @OrderID;
    
    RETURN ISNULL(@Wartosc, 0);
END
GO

--Funkcja pobierająca dane pracownika:
CREATE FUNCTION fn_PobierzDanePracownika
(
    @EmployeeID INT
)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @Dane NVARCHAR(200);
    
    SELECT @Dane = 
        FirstName + ' ' + LastName + 
        ' (' + Login + ') - Saldo: ' + 
        CAST(CurrentBalance AS NVARCHAR(20))
    FROM Employees
    WHERE EmployeeID = @EmployeeID;
    
    RETURN ISNULL(@Dane, 'Pracownik nie istnieje');
END
GO

--Funkcja sprawdzająca czy zamówienie jest gotowe do wysyłki:
CREATE FUNCTION fn_CzyZamowienieGotowe
(
    @OrderID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Wynik BIT = 0;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM OrderItems oi
        WHERE oi.OrderID = @OrderID
          AND oi.Quantity > oi.QuantityProduced
    )
    BEGIN
        SET @Wynik = 1; -- Wszystko wyprodukowane
    END
    
    RETURN @Wynik;
END
GO

--Funkcja obliczająca marżę na produkcie:
CREATE FUNCTION fn_ObliczMarze
(
    @ProductID INT
)
RETURNS DECIMAL(10,4)
AS
BEGIN
    DECLARE @Marza DECIMAL(10,4);
    
    SELECT @Marza = p.ListPrice - (p.SzewcPrice + p.CholewkarzPrice + p.KrojczyPrice)
    FROM Products p
    WHERE p.ProductID = @ProductID;
    
    RETURN ISNULL(@Marza, 0);
END
GO
