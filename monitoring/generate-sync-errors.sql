-- SQL Script to Generate Data Sync Errors
-- Run these scripts to create various sync error scenarios for testing
-- 
-- IMPORTANT: Run on either Hub or Member database (not both) to create conflicts

-- ============================================================================
-- SCENARIO 1: Primary Key Conflict
-- Insert the same primary key on both databases to cause a sync conflict
-- ============================================================================

-- Run this on HUB database:
-- INSERT INTO Customers (CustomerId, FirstName, LastName, Email, City, Country)
-- VALUES (100, 'Hub', 'User', 'hub@test.com', 'London', 'UK');

-- Run this on MEMBER database:
-- INSERT INTO Customers (CustomerId, FirstName, LastName, Email, City, Country)
-- VALUES (100, 'Member', 'User', 'member@test.com', 'Paris', 'France');

-- ============================================================================
-- SCENARIO 2: Data Truncation Error
-- Insert data that exceeds column size on one side
-- ============================================================================

-- Run on HUB database (FirstName is NVARCHAR(50), this has 60 chars):
INSERT INTO Customers (CustomerId, FirstName, LastName, Email, City, Country)
VALUES (101, 'ThisIsAVeryLongFirstNameThatExceedsFiftyCharactersLimit123', 'Test', 'truncate@test.com', 'Berlin', 'Germany');

-- ============================================================================
-- SCENARIO 3: Concurrent Update Conflict  
-- Update the same row on both databases before sync completes
-- ============================================================================

-- First, ensure a row exists (run on both):
-- INSERT INTO Products (ProductId, ProductName, Category, Price, StockQuantity)
-- VALUES (200, 'Conflict Test Product', 'Test', 99.99, 100);

-- Then run on HUB:
UPDATE Products SET Price = 149.99, StockQuantity = 50 WHERE ProductId = 200;

-- And run on MEMBER:
-- UPDATE Products SET Price = 199.99, StockQuantity = 25 WHERE ProductId = 200;

-- ============================================================================
-- SCENARIO 4: Delete-Update Conflict
-- Delete on one side, update on the other
-- ============================================================================

-- First ensure row exists (run on both):
IF NOT EXISTS (SELECT 1 FROM Orders WHERE OrderId = 300)
BEGIN
    INSERT INTO Orders (OrderId, CustomerId, TotalAmount, Status, ShippingAddress)
    VALUES (300, 1, 500.00, 'Pending', 'Test Address');
END
GO

-- Run on HUB:
DELETE FROM Orders WHERE OrderId = 300;

-- Run on MEMBER (after hub delete, before sync):
-- UPDATE Orders SET Status = 'Shipped' WHERE OrderId = 300;

-- ============================================================================
-- SCENARIO 5: Foreign Key Violation (if constraints exist)
-- Insert order with non-existent customer
-- ============================================================================

-- This will fail if FK constraint exists
INSERT INTO Orders (OrderId, CustomerId, TotalAmount, Status, ShippingAddress)
VALUES (301, 99999, 100.00, 'Pending', 'Invalid Customer Order');

-- ============================================================================
-- SCENARIO 6: NULL Constraint Violation
-- Insert NULL into NOT NULL column
-- ============================================================================

-- This will cause an error (FirstName is NOT NULL)
-- INSERT INTO Customers (CustomerId, FirstName, LastName, Email, City, Country)
-- VALUES (102, NULL, 'NullTest', 'null@test.com', 'Rome', 'Italy');

-- ============================================================================
-- SCENARIO 7: Schema Mismatch - Add column on one side only
-- This causes sync to fail as schemas don't match
-- ============================================================================

-- Run ONLY on HUB database:
-- ALTER TABLE Customers ADD NewColumn NVARCHAR(50) NULL;

-- Then insert data with the new column:
-- UPDATE Customers SET NewColumn = 'Test Value' WHERE CustomerId = 1;

-- ============================================================================
-- QUICK TEST: Run this block to create multiple error scenarios at once
-- ============================================================================

PRINT 'Creating error scenarios for Data Sync testing...';

-- Insert row that will be updated/deleted for conflict testing
IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductId = 500)
BEGIN
    INSERT INTO Products (ProductId, ProductName, Category, Price, StockQuantity)
    VALUES (500, 'Sync Error Test Product', 'ErrorTest', 50.00, 100);
    PRINT 'Created test product (ProductId = 500)';
END

-- Create a row and immediately delete it (orphan scenario)
INSERT INTO Customers (CustomerId, FirstName, LastName, Email, City, Country)
VALUES (501, 'Orphan', 'Record', 'orphan@test.com', 'Nowhere', 'Unknown');
DELETE FROM Customers WHERE CustomerId = 501;
PRINT 'Created and deleted orphan record';

-- Insert duplicate attempt (will fail but generates log entry)
BEGIN TRY
    INSERT INTO Customers (CustomerId, FirstName, LastName, Email, City, Country)
    VALUES (1, 'Duplicate', 'Key', 'dup@test.com', 'DupCity', 'DupCountry');
END TRY
BEGIN CATCH
    PRINT 'Duplicate key error generated: ' + ERROR_MESSAGE();
END CATCH

PRINT 'Error scenarios created. Trigger sync to see errors in logs.';
GO
