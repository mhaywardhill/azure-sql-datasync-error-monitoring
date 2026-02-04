-- Sample Schema for SQL Data Sync Demo
-- Run this script on BOTH the Hub and Member databases

-- Create a sample Customers table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customers')
BEGIN
    CREATE TABLE Customers (
        CustomerId INT PRIMARY KEY,
        FirstName NVARCHAR(50) NOT NULL,
        LastName NVARCHAR(50) NOT NULL,
        Email NVARCHAR(100),
        Phone NVARCHAR(20),
        City NVARCHAR(50),
        Country NVARCHAR(50),
        CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 DEFAULT GETUTCDATE()
    );
    PRINT 'Customers table created successfully';
END
ELSE
BEGIN
    PRINT 'Customers table already exists';
END
GO

-- Create a sample Products table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Products')
BEGIN
    CREATE TABLE Products (
        ProductId INT PRIMARY KEY,
        ProductName NVARCHAR(100) NOT NULL,
        Category NVARCHAR(50),
        Price DECIMAL(10, 2),
        StockQuantity INT,
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 DEFAULT GETUTCDATE()
    );
    PRINT 'Products table created successfully';
END
ELSE
BEGIN
    PRINT 'Products table already exists';
END
GO

-- Create a sample Orders table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Orders')
BEGIN
    CREATE TABLE Orders (
        OrderId INT PRIMARY KEY,
        CustomerId INT NOT NULL,
        OrderDate DATETIME2 DEFAULT GETUTCDATE(),
        TotalAmount DECIMAL(10, 2),
        Status NVARCHAR(20) DEFAULT 'Pending',
        ShippingAddress NVARCHAR(200),
        CreatedDate DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedDate DATETIME2 DEFAULT GETUTCDATE()
    );
    PRINT 'Orders table created successfully';
END
ELSE
BEGIN
    PRINT 'Orders table already exists';
END
GO

-- Insert sample data (only on Hub database initially)
-- Customers
IF NOT EXISTS (SELECT 1 FROM Customers)
BEGIN
    INSERT INTO Customers (CustomerId, FirstName, LastName, Email, Phone, City, Country)
    VALUES 
        (1, 'John', 'Doe', 'john.doe@email.com', '+1-555-0101', 'New York', 'USA'),
        (2, 'Jane', 'Smith', 'jane.smith@email.com', '+1-555-0102', 'Los Angeles', 'USA'),
        (3, 'Bob', 'Johnson', 'bob.johnson@email.com', '+44-20-1234', 'London', 'UK'),
        (4, 'Alice', 'Williams', 'alice.w@email.com', '+49-30-5678', 'Berlin', 'Germany'),
        (5, 'Charlie', 'Brown', 'charlie.b@email.com', '+33-1-9012', 'Paris', 'France');
    PRINT 'Sample customers inserted';
END
GO

-- Products
IF NOT EXISTS (SELECT 1 FROM Products)
BEGIN
    INSERT INTO Products (ProductId, ProductName, Category, Price, StockQuantity)
    VALUES 
        (1, 'Laptop Pro', 'Electronics', 1299.99, 50),
        (2, 'Wireless Mouse', 'Electronics', 29.99, 200),
        (3, 'USB-C Hub', 'Accessories', 49.99, 150),
        (4, 'Mechanical Keyboard', 'Electronics', 149.99, 75),
        (5, 'Monitor Stand', 'Accessories', 79.99, 100);
    PRINT 'Sample products inserted';
END
GO

-- Orders
IF NOT EXISTS (SELECT 1 FROM Orders)
BEGIN
    INSERT INTO Orders (OrderId, CustomerId, TotalAmount, Status, ShippingAddress)
    VALUES 
        (1, 1, 1349.98, 'Shipped', '123 Main St, New York, NY 10001'),
        (2, 2, 79.98, 'Delivered', '456 Oak Ave, Los Angeles, CA 90001'),
        (3, 3, 149.99, 'Processing', '789 High St, London, UK'),
        (4, 1, 49.99, 'Pending', '123 Main St, New York, NY 10001'),
        (5, 4, 229.98, 'Shipped', '321 Berlin Str, Berlin, Germany');
    PRINT 'Sample orders inserted';
END
GO

PRINT 'Schema and sample data setup complete!';
GO
