-- SQL Script to Generate Data Sync Errors
-- Run this script on the MEMBER database to cause a sync failure
--
-- IMPORTANT: Run ONLY on the Member database, NOT the Hub

-- ============================================================================
-- SCENARIO: Schema Mismatch - Drop a synced column
-- Dropping a column that is part of the sync schema causes sync to fail
-- ============================================================================

-- Run on MEMBER database to cause sync error:
ALTER TABLE Customers DROP COLUMN Email;
GO

PRINT 'Email column dropped from Customers table.';
PRINT 'Trigger sync to see the error in sync group logs.';
PRINT '';
PRINT 'To restore sync, run this on the Member database:';
PRINT '  ALTER TABLE Customers ADD Email NVARCHAR(100) NULL;';
GO
