--Trigger wyliczający sumę zamówienia (TotalDue) w tabeli z zamówieniami (Orders):
CREATE TRIGGER trg_OrderItems_Orders_TotalDue
ON OrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE o
	SET TotalDue = (
		SELECT SUM(oi.UnitPrice * oi.Quantity)
		FROM OrderItems oi
		WHERE oi.OrderID=o.OrderID)
	FROM Orders o
	WHERE o.OrderID IN (
		SELECT i.OrderID FROM inserted i
		UNION
		SELECT d.OrderID FROM deleted d);

END
GO

--Trigger wyliczający ilość wykonaną danego produktu ze szczegołów zamówienia (OrderItems):
CREATE TRIGGER trg_Production_OrderItems_QuantityProduced
ON Production
AFTER UPDATE, INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

	UPDATE oi
	SET oi.QuantityProduced = 
		(SELECT SUM(QuantityToProduce)
	 	 FROM Production p
		 WHERE p.OrderItemID = oi.OrderItemID AND p.Status='Ukończono')
	FROM OrderItems oi
	WHERE oi.OrderItemID IN (
		SELECT i.OrderItemID FROM inserted i
		UNION
		SELECT d.OrderItemID FROM deleted d);
END
GO

--Trigger do aktualizacji stanu konta pracowników (szewc, cholewkarz, krojczy) przy ukończeniu produkcji.
CREATE TRIGGER trg_Production_Employees_CurrentBalance
ON Production
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE e
    SET e.CurrentBalance = e.CurrentBalance + (
        SELECT SUM(ins.QuantityToProduce * pro.SzewcPrice)
        FROM inserted ins
        INNER JOIN deleted de ON ins.ProductionID = de.ProductionID
        INNER JOIN OrderItems oi ON ins.OrderItemID = oi.OrderItemID
        INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
        INNER JOIN Products pro ON pv.ProductID = pro.ProductID
        WHERE ins.SzewcID = e.EmployeeID
          AND ins.Status = 'Ukończono'
          AND de.Status <> 'Ukończono'
    )
    FROM Employees e
    WHERE e.EmployeeID IN (
        SELECT ins.SzewcID 
        FROM inserted ins
        INNER JOIN deleted de ON ins.ProductionID = de.ProductionID
        WHERE ins.Status = 'Ukończono'
          AND de.Status <> 'Ukończono'
    );

    UPDATE e
    SET e.CurrentBalance = e.CurrentBalance + (
        SELECT SUM(ins.QuantityToProduce * pro.CholewkarzPrice)
        FROM inserted ins
        INNER JOIN deleted de ON ins.ProductionID = de.ProductionID
        INNER JOIN OrderItems oi ON ins.OrderItemID = oi.OrderItemID
        INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
        INNER JOIN Products pro ON pv.ProductID = pro.ProductID
        WHERE ins.CholewkarzID = e.EmployeeID
          AND ins.Status = 'Ukończono'
          AND de.Status <> 'Ukończono'
    )
    FROM Employees e
    WHERE e.EmployeeID IN (
        SELECT ins.CholewkarzID 
        FROM inserted ins
        INNER JOIN deleted de ON ins.ProductionID = de.ProductionID
        WHERE ins.Status = 'Ukończono'
          AND de.Status <> 'Ukończono'
    );

    UPDATE e
    SET e.CurrentBalance = e.CurrentBalance + (
        SELECT SUM(ins.QuantityToProduce * pro.KrojczyPrice)
        FROM inserted ins
        INNER JOIN deleted de ON ins.ProductionID = de.ProductionID
        INNER JOIN OrderItems oi ON ins.OrderItemID = oi.OrderItemID
        INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
        INNER JOIN Products pro ON pv.ProductID = pro.ProductID
        WHERE ins.KrojczyID = e.EmployeeID
          AND ins.Status = 'Ukończono'
          AND de.Status <> 'Ukończono'
    )
    FROM Employees e
    WHERE e.EmployeeID IN (
        SELECT ins.KrojczyID 
        FROM inserted ins
        INNER JOIN deleted de ON ins.ProductionID = de.ProductionID
        WHERE ins.Status = 'Ukończono'
          AND de.Status <> 'Ukończono'
    );
END
GO

--Trigger pobierający stan magazynowy przy wydaniu produktu do produkcji oraz zapisujący historię w InventoryTransactions:
CREATE TRIGGER trg_Production_Materials_OnInsert
ON Production
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT 
                vm.MaterialID,
                SUM(vm.QuantityRequired * i.QuantityToProduce) AS UsedQuantity
            FROM inserted i
            INNER JOIN OrderItems oi ON i.OrderItemID = oi.OrderItemID
            INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
            INNER JOIN VariantMaterials vm ON pv.VariantID = vm.VariantID
            GROUP BY vm.MaterialID
        ) calc
        INNER JOIN Materials m ON calc.MaterialID = m.MaterialID
        WHERE m.CurrentStock < calc.UsedQuantity
    )

    BEGIN
        PRINT 'UWAGA: Za niski stan magazynu! Produkcja została utworzona, ale należy uzupełnić materiały.';
    END
    
    UPDATE m
    SET m.CurrentStock = m.CurrentStock - calc.UsedQuantity
    FROM Materials m
    INNER JOIN (
        SELECT 
            vm.MaterialID,
            SUM(vm.QuantityRequired * i.QuantityToProduce) AS UsedQuantity
        FROM inserted i
        INNER JOIN OrderItems oi ON i.OrderItemID = oi.OrderItemID
        INNER JOIN ProductVariants pv ON oi.VariantID = pv.VariantID
        INNER JOIN VariantMaterials vm ON pv.VariantID = vm.VariantID
        GROUP BY vm.MaterialID
    ) calc ON m.MaterialID = calc.MaterialID;


	INSERT INTO InventoryTransactions (MaterialID, ProductionID, Quantity, Notes)
	SELECT
		vm.MaterialID,
		i.ProductionID,
		-(i.QuantityToProduce * vm.QuantityRequired),
		'Przydział prod.' + CAST(i.ProductionID AS NVARCHAR(12))
	FROM inserted i
	INNER JOIN OrderItems oi ON i.OrderItemID=oi.OrderItemID
	INNER JOIN ProductVariants pv ON pv.VariantID=oi.VariantID
	INNER JOIN VariantMaterials vm ON vm.VariantID=pv.VariantID;

END
GO

--Trigger zmieniający stan magazynowy przy update produkcji oraz dodający rekord w InventoryTransactions:
CREATE TRIGGER trg_Production_Materials_OnUpdate
ON Production
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

	IF UPDATE(QuantityToProduce)
	BEGIN
		UPDATE m
		SET m.CurrentStock = m.CurrentStock - calc.new
		FROM Materials m
		INNER JOIN (
		SELECT
			vm.MaterialID,
			SUM(vm.QuantityRequired * (i.QuantityToProduce - d.QuantityToProduce)) as new
		FROM inserted i
		INNER JOIN deleted d ON i.ProductionID=d.ProductionID
		INNER JOIN OrderItems oi ON i.OrderItemID=oi.OrderItemID
		INNER JOIN ProductVariants pv ON pv.VariantID=oi.VariantID
		INNER JOIN VariantMaterials vm ON vm.VariantID=pv.VariantID
		WHERE i.QuantityToProduce <> d.QuantityToProduce
		GROUP BY vm.MaterialID
		) as calc ON m.MaterialID=calc.MaterialID;

	INSERT INTO InventoryTransactions (MaterialID, ProductionID, Quantity, Notes)
	SELECT
		vm.MaterialID,
		i.ProductionID,
		(i.QuantityToProduce - d.QuantityToProduce) * vm.QuantityRequired,
		CASE
			WHEN i.QuantityToProduce>d.QuantityToProduce THEN 'Zwiekszenie prod ' + CAST(i.ProductionID AS NVARCHAR(12))
			ELSE 'Zmniejszenie prod ' + CAST(i.ProductionID AS NVARCHAR(12))
		END
	FROM inserted i
	INNER JOIN deleted d ON i.ProductionID=d.ProductionID
	INNER JOIN OrderItems oi ON i.OrderItemID=oi.OrderItemID
	INNER JOIN ProductVariants pv ON pv.VariantID=oi.VariantID
	INNER JOIN VariantMaterials vm ON vm.VariantID=pv.VariantID
	WHERE i.QuantityToProduce <> d.QuantityToProduce;

	END
END
GO

--Trigger blokujący możliwość usuwania pozycji produkcji (zamiast tworzyć nową tabelę z usuniętymi); zamiast tego zmienia status na ANULOWANO.
CREATE TRIGGER trg_Production_Materials_InsteadOfDelete
ON Production
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE p
	SET p.Status = 'Anulowano'
	FROM Production p
	INNER JOIN deleted d ON d.ProductionID=p.ProductionID;

	PRINT 'Nie można usunąć pozycji. Zmieniono status na ANULOWANO.';

END
GO

--Trigger zwracający pobrane materiały do magagazynu po anulowaniu produkcji oraz dodający o tym informacje w InventoryTransactions:
CREATE TRIGGER trg_Production_Materials_Anulowano
ON Production
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(Status)
	BEGIN
		UPDATE m
		SET m.CurrentStock = m.CurrentStock + calc.new
		FROM Materials m
		INNER JOIN (
		SELECT
			vm.MaterialID,
			SUM(vm.QuantityRequired * i.QuantityToProduce) as new
		FROM inserted i
        INNER JOIN deleted d ON i.ProductionID=d.ProductionID
		INNER JOIN OrderItems oi ON i.OrderItemID=oi.OrderItemID
		INNER JOIN ProductVariants pv ON pv.VariantID=oi.VariantID
		INNER JOIN VariantMaterials vm ON vm.VariantID=pv.VariantID
		WHERE i.Status='Anulowano' AND d.Status <> 'Anulowano'
		GROUP BY vm.MaterialID
		) calc ON m.MaterialID=calc.MaterialID;

	INSERT INTO InventoryTransactions (MaterialID, ProductionID, Quantity, Notes)
	SELECT
		vm.MaterialID,
		i.ProductionID,
		vm.QuantityRequired * i.QuantityToProduce,
		'Anulowanie zamówienia ' + CAST(i.ProductionID AS NVARCHAR(12))
	FROM inserted i
	INNER JOIN deleted d ON i.ProductionID=d.ProductionID
	INNER JOIN OrderItems oi ON i.OrderItemID=oi.OrderItemID
	INNER JOIN ProductVariants pv ON pv.VariantID=oi.VariantID
	INNER JOIN VariantMaterials vm ON vm.VariantID=pv.VariantID
	WHERE i.Status='Anulowano' AND d.Status<> 'Anulowano';	

	END
END
GO

--Trigger blokujący możliwość zlecenia więcej do produkcji, niż jest w zamówieniu:
CREATE TRIGGER trg_Production_QuantityValidation
ON Production
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS(
        SELECT 1
        FROM (
            SELECT 
                oi.OrderItemID,
                oi.Quantity AS OrderedQuantity,
                SUM(p.QuantityToProduce) AS TotalProduced
            FROM inserted i
            INNER JOIN OrderItems oi ON i.OrderItemID = oi.OrderItemID
            INNER JOIN Production p ON oi.OrderItemID = p.OrderItemID
            GROUP BY oi.OrderItemID, oi.Quantity
        ) calc
        WHERE calc.TotalProduced > calc.OrderedQuantity
    )
    BEGIN
        THROW 50001, 'Łączna ilość w produkcji przekracza ilość w zamówieniu!', 1;
        RETURN;
    END
END
GO

--Trigger dodający rekordy do tabeli InventoryTransactions po utworzeniu zamówienia:
CREATE TRIGGER trg_Production_InventoryTransaction_OnInsert
ON Production
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO InventoryTransactions (MaterialID, ProductionID, Quantity)
	SELECT
		vm.MaterialID,
		i.ProductionID,
		i.QuantityToProduce * vm.QuantityRequired as Quantity
	FROM inserted i
	INNER JOIN OrderItems oi ON i.OrderItemID=oi.OrderItemID
	INNER JOIN ProductVariants pv ON pv.VariantID=oi.VariantID
	INNER JOIN VariantMaterials vm ON vm.VariantID=pv.VariantID;
END
GO

--Trigger do śledzenia przepływu pieniędzy (tabela Payments) po dodaniu dostawy do magazynu (aktywuje sie po procedurze sp_AddInventoryDelivery):
CREATE TRIGGER trg_InventoryTransaction_DeliveryMaterials_Insert
ON InventoryTransactions
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO Payments (PaymentName, TotalAmount, TransactionID)
	SELECT
		('Dostawa materiału ' + CAST(i.MaterialID AS NVARCHAR(12))),
		-(i.TotalPrice),
		i.TransactionID
	FROM inserted i;
END
GO

--Trigger do śledzenia zmian ceny dostawy w tabeli Payments:
CREATE TRIGGER trg_InventoryTransaction_DeliveryMaterials_Update
ON InventoryTransactions
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;

	IF UPDATE(TotalPrice)
	BEGIN
		INSERT INTO Payments (PaymentName, TotalAmount, TransactionID)
		SELECT
			('Aktualizacja ceny dostawy ' + CAST(d.TransactionID AS NVARCHAR(12))),
			CASE 
				WHEN i.TotalPrice > d.TotalPrice THEN i.TotalPrice - d.TotalPrice
				ELSE -(i.TotalPrice - d.TotalPrice)
			END,
			i.TransactionID
		FROM inserted i
		INNER JOIN deleted d ON i.TransactionID = d.TransactionID;
	END
END
GO

--Trigger do śledzenia usunięcia dostawy w tabeli Payments:
CREATE TRIGGER trg_InventoryTransaction_DeliveryMaterials_Delete
ON InventoryTransactions
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO Payments (PaymentName, TotalAmount, TransactionID)
	SELECT
		('Usunięcie dostawy materiału ' + CAST(d.MaterialID AS NVARCHAR(12))),
		-d.TotalPrice,
		d.TransactionID
	FROM deleted d;
END
GO

--Trigger wyliczający sumę zamówienia (TotalValue) w tabeli z zamówieniami materiałów(MaterialOrders):
CREATE TRIGGER trg_MaterialOrderItems_MaterialOrders_TotalValue
ON MaterialOrderItems
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE mo
	SET TotalValue = (
		SELECT SUM(moi.UnitPrice * moi.Quantity)
		FROM MaterialOrderItems moi
		WHERE moi.MaterialOrderID=mo.MaterialOrderID)
	FROM MaterialOrders mo
	WHERE mo.MaterialOrderID IN (
		SELECT i.MaterialOrderID FROM inserted i
		UNION
		SELECT d.MaterialOrderID FROM deleted d);
END
GO
