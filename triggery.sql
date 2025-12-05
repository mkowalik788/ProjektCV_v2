CREATE TABLE Roles (
	RoleID INT IDENTITY(1,1) PRIMARY KEY,
	RoleName NVARCHAR(25) NOT NULL
	);
GO

CREATE TABLE Employees (
	EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
	FirstName NVARCHAR(25) NOT NULL,
	LastName NVARCHAR(25) NOT NULL,
	Login NVARCHAR(30) UNIQUE NOT NULL,
	PasswordHash VARBINARY(64),
	PasswordSalt VARBINARY(16),
	RoleID INT,
	CurrentBalance DECIMAL(12,4) DEFAULT 0,
	LastActive DATETIME,
	CreatedAt DATE DEFAULT GETDATE(),
	FiredAt DATE,
	FiredReason NVARCHAR(200)
	);
GO

CREATE TABLE EmployeeRoles (
	EmployeeID INT NOT NULL,
	RoleID INT NOT NULL,
	CONSTRAINT FK_EmployeeID_Employees_EmployeeID FOREIGN KEY(EmployeeID) REFERENCES Employees(EmployeeID),
	CONSTRAINT FK_RoleID_Roles_RoleID FOREIGN KEY(RoleID) REFERENCES Roles(RoleID)
	);
GO

CREATE TABLE Customers (
	CustomerID INT IDENTITY(1,1) PRIMARY KEY,
	Login NVARCHAR(30) UNIQUE NOT NULL,
	PasswordHash VARBINARY(64),
	PasswordSalt VARBINARY(16),
	CustomerName NVARCHAR(30) NOT NULL,
	PhoneNumber VARCHAR(20),
	Email NVARCHAR(50),
	LastActive DATETIME,
	CreatedAt DATE DEFAULT GETDATE()
	);
GO

CREATE TABLE BankAccounts (
    BankAccountID INT IDENTITY(1,1) PRIMARY KEY,
    AccountNumber NVARCHAR(34) NOT NULL,
    BankName NVARCHAR(100),
    IsActive BIT DEFAULT 1
);

CREATE TABLE ProductionStages (
	StageID INT IDENTITY(1,1) PRIMARY KEY,
	StageName NVARCHAR(25) NOT NULL,
	OrderIndex INT
	);
GO

CREATE TABLE RoleStages (
	RoleStageID INT IDENTITY(1,1) PRIMARY KEY,
	RoleID INT,
	StageID INT,
	CONSTRAINT FK_Roles_RoleID FOREIGN KEY(RoleID) REFERENCES Roles(RoleID),
	CONSTRAINT FK_StgeID_ProdictionStages_StageID FOREIGN KEY(StageID) REFERENCES ProductionStages(StageID)
	);
GO

CREATE TABLE ProductCategory (
	CategoryID INT IDENTITY(1,1) PRIMARY KEY,
	CategoryName NVARCHAR(40) NOT NULL
	);
GO

CREATE TABLE ProductSubcategory (
	SubcategoryID INT IDENTITY(1,1) PRIMARY KEY,
	SubcategoryName NVARCHAR(40) NOT NULL,
	CategoryID INT NOT NULL,
	CONSTRAINT FK_CategoryID_ProductCategory_CategoryID FOREIGN KEY(CategoryID) REFERENCES ProductCategory(CategoryID)
	);
GO

CREATE TABLE Products (
	ProductID INT IDENTITY(1,1) PRIMARY KEY,
	ProductName NVARCHAR(50) NOT NULL,
	ProductSubcategoryID INT NOT NULL,
	ListPrice DECIMAL(10,4) NOT NULL,
	SzewcPrice DECIMAL(10,4) NOT NULL,
	KrojczyPrice DECIMAL(10,4) NOT NULL,
	CholewkarzPrice DECIMAL(10,4) NOT NULL,
	CreatedDate DATE DEFAULT GETDATE()
	);
GO

CREATE TABLE ProductVariants (
	VariantID INT IDENTITY(1,1) PRIMARY KEY,
	ProductID INT,
	VariantName NVARCHAR(50) NOT NULL,
	VariantSKU NVARCHAR(50) UNIQUE,
	CONSTRAINT FK_ProductID_Products_ProductID FOREIGN KEY(ProductID) REFERENCES Products(ProductID)
	);
GO

CREATE TABLE Sizes (
	SizeID INT IDENTITY(1,1) PRIMARY KEY,
	SizeName NVARCHAR(20) NOT NULL, --np. EU38
	OrderIndex INT --kolejność wyświetlania
	);
GO

CREATE TABLE Materials (
	MaterialID INT IDENTITY(1,1) PRIMARY KEY,
	MaterialName NVARCHAR(50) NOT NULL,
	MaterialType NVARCHAR(50) NOT NULL,
	CurrentStock DECIMAL(16,4) DEFAULT '0',
	UnitOfMeasure NVARCHAR(10) NOT NULL --np. m2, szt, par, cm, m
	);
GO

CREATE TABLE VariantMaterials (
	VariantMaterialID INT IDENTITY(1,1) PRIMARY KEY,
	VariantID INT,
	MaterialID INT,
	QuantityRequired DECIMAL(10,4) NOT NULL, --Ilość na sztukę
	CONSTRAINT FK_VariantID_ProductVariants_VariantID FOREIGN KEY(VariantID) REFERENCES ProductVariants(VariantID),
	CONSTRAINT FK_MaterialID_Materials_MaterialID FOREIGN KEY(MaterialID) REFERENCES Materials(MaterialID)
	);
GO

CREATE TABLE Suppliers (
	SupplierID INT IDENTITY(1,1) PRIMARY KEY,
	SupplierName NVARCHAR(200) NOT NULL,
	Phone NVARCHAR(20),
	Email NVARCHAR(50)
	);
GO

CREATE TABLE Orders (
	OrderID INT IDENTITY(1,1) PRIMARY KEY,
	CustomerID INT,
	OrderDate DATETIME DEFAULT GETDATE(),
	ShipDate DATE,
	Status NVARCHAR(50) DEFAULT 'Nowe',
	TotalDue DECIMAL(20,4),
	CONSTRAINT FK_CustomerID_Customers_CustomerID FOREIGN KEY(CustomerID) REFERENCES Customers(CustomerID)
	);
GO

CREATE TABLE OrderItems (
	OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
	OrderID INT NOT NULL,
	VariantID INT NOT NULL,
	SizeID INT NOT NULL,
	Quantity INT NOT NULL,
	UnitPrice DECIMAL(10,4) NOT NULL,
	QuantityProduced INT DEFAULT '0',
	CONSTRAINT FK_Orders_OrderID FOREIGN KEY(OrderID) REFERENCES Orders(OrderID),
	CONSTRAINT FK_ProductVariants_VariantID FOREIGN KEY(VariantID) REFERENCES ProductVariants(VariantID),
	CONSTRAINT FK_Sizes_SizeID FOREIGN KEY(SizeID) REFERENCES Sizes(SizeID)
	);
GO

CREATE TABLE Production (
	ProductionID INT IDENTITY(1,1) PRIMARY KEY,
	OrderItemID INT NOT NULL,
	QuantityToProduce INT NOT NULL, --ilość przydzielona
	Status NVARCHAR(30) DEFAULT 'Nowe',
	CreatedDate DATETIME DEFAULT GETDATE(),
	SzewcID INT,
	CholewkarzID INT,
	KrojczyID INT,
	Notes NVARCHAR(500),
	CompletedDate DATETIME,
	CONSTRAINT FK_OrderItemID_OrderItems_OrderItemID FOREIGN KEY(OrderItemID) REFERENCES OrderItems(OrderItemID),
	CONSTRAINT FK_SzewcID_Employees_EmployeeID FOREIGN KEY(SzewcID) REFERENCES Employees(EmployeeID),
	CONSTRAINT FK_CholewkarzID_Employees_EmployeeID FOREIGN KEY(CholewkarzID) REFERENCES Employees(EmployeeID),
	CONSTRAINT FK_KrojczyID_Employees_EmployeeID FOREIGN KEY(KrojczyID) REFERENCES Employees(EmployeeID)
	);
GO

CREATE TABLE InventoryTransactions (
	TransactionID INT IDENTITY(1,1) PRIMARY KEY,
	MaterialID INT NOT NULL,
	ProductionID INT NULL,
	Quantity DECIMAL(16,4),
	TransactionDate DATE DEFAULT GETDATE(),
	TotalPrice DECIMAL(12,4) DEFAULT 0,
	SupplierID INT NULL,
	Notes NVARCHAR(200),
	CONSTRAINT FK_Materials_MaterialID FOREIGN KEY(MaterialID) REFERENCES Materials(MaterialID),
	CONSTRAINT FK_ProductionID_Production_ProductionID FOREIGN KEY(ProductionID) REFERENCES Production(ProductionID),
	CONSTRAINT FK_SupplierID_Suppliers_SupplierID FOREIGN KEY(SupplierID) REFERENCES Suppliers(SupplierID)
	);
GO

CREATE TABLE Invoices (
    InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
	InvoiceType NVARCHAR(20) NOT NULL, 
    InvoiceNumber NVARCHAR(50) UNIQUE NOT NULL, -- np. FV/2024/0001
    OrderID INT NOT NULL,
    IssueDate DATE DEFAULT GETDATE(),
    DueDate DATE NOT NULL,
    PaymentDate DATE NULL,
    NetAmount DECIMAL(20,4),
	VatAmount DECIMAL(7,4),
    TaxAmount DECIMAL(20,4),
    GrossAmount DECIMAL(20,4),
	SupplierID INT NULL,
    Status NVARCHAR(20) DEFAULT 'Wystawiona',
    CONSTRAINT FK_OrderID_Invoices_OrderID FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
	CONSTRAINT CHK_InvoiceType CHECK (InvoiceType IN ('Sprzedażowa', 'Zakupowa', 'Proforma', 'Korygująca', 'Kosztowa')),
	CONSTRAINT FK_Invoices_Suppliers_SupplierID FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

CREATE TABLE Payments (
	PaymentID INT IDENTITY(1,1) PRIMARY KEY,
	PaymentName NVARCHAR(50),
	TotalAmount DECIMAL(16,4) NOT NULL,
	PaymentDate DATETIME DEFAULT GETDATE(),
	PaymentType NVARCHAR(30),
	InvoiceID INT NULL,
	TransactionID INT NULL,
	BankAccountID INT NULL,
	CONSTRAINT FK_Invoices_InvoiceID FOREIGN KEY(InvoiceID) REFERENCES Invoices(InvoiceID),
	CONSTRAINT FK_TransactionID_InventoryTransactions_TransactionID FOREIGN KEY(TransactionID) REFERENCES InventoryTransactions(TransactionID),
	CONSTRAINT FK_BankAccountID_BankAccounts_BankAccountID FOREIGN KEY(BankAccountID) REFERENCES BankAccounts(BankAccountID),
	CONSTRAINT CHK_PaymentType CHECK (PaymentType IN ('Przelew', 'Gotówka', 'Karta'))
	);
GO

CREATE TABLE MaterialOrders (
    MaterialOrderID INT IDENTITY(1,1) PRIMARY KEY,
    SupplierID INT NOT NULL,
    OrderDate DATE DEFAULT GETDATE(),
    ExpectedDeliveryDate DATE,
    Status NVARCHAR(30) DEFAULT 'Nowe',
    TotalValue DECIMAL(16,4),
    Notes NVARCHAR(500),
    CONSTRAINT FK_MaterialOrders_Suppliers_SupplierID FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

CREATE TABLE MaterialOrderItems (
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    MaterialOrderID INT NOT NULL,
    MaterialID INT NOT NULL,
    Quantity DECIMAL(16,4) NOT NULL,
    UnitPrice DECIMAL(12,4) NOT NULL,
    FOREIGN KEY (MaterialOrderID) REFERENCES MaterialOrders(MaterialOrderID),
    FOREIGN KEY (MaterialID) REFERENCES Materials(MaterialID)
);
GO
