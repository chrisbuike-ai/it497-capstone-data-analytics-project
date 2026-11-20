-- =====================================================================
-- PROJECT: Cloud-Hosted Consumer Spending Analytics Pipeline 
-- AUTHOR: Christian Umunnabuike
-- COURSE: IT 335 / Database Administration & IT 497 Capstone
-- DESCRIPTION: 
-- This script demonstrates the refined version of a cloud-hosted 
-- relational database designed to analyze consumer spending patterns.
-- It includes technical optimizations (indexing) and ethical integrations
-- (PII hashing, automated data retention) to ensure data stewardship.
-- =====================================================================

-- 1. SCHEMA CREATION & ETHICAL DATA MASKING (PII Protection)
-- Refinement: Instead of storing raw PII, we use SHA-256 hashing to 
-- anonymize customer identities. This allows analysts to track unique 
-- spending patterns without ever exposing a user's actual identity.
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    EmailHash VARCHAR(64) NOT NULL, 
    PhoneHash VARCHAR(64) NOT NULL,
    Region VARCHAR(50),
    SignupDate DATE
);

CREATE TABLE Transactions (
    TransactionID INT PRIMARY KEY,
    CustomerID INT,
    TransactionDate DATE,
    Amount DECIMAL(10, 2),
    Category VARCHAR(50),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- 2. TECHNICAL ENHANCEMENT: Indexing for Performance Optimization
-- Challenge Addressed: As the dataset grew, complex JOINs and aggregations 
-- became slow. Added composite indexes to speed up queries without 
-- scanning the entire table.
CREATE INDEX idx_transaction_date ON Transactions(TransactionDate);
CREATE INDEX idx_customer_category ON Transactions(CustomerID, Category);

-- 3. ETHICAL INTEGRATION: Data Minimization & Retention Policy
-- Refinement: This stored procedure enforces a strict 24-month data 
-- retention policy. It automatically purges old transaction logs to 
-- minimize data hoarding and reduce the risk of historical data breaches.
DELIMITER //
CREATE PROCEDURE EnforceDataRetention()
BEGIN
    DECLARE retention_months INT DEFAULT 24;
    
    DELETE FROM Transactions 
    WHERE TransactionDate < DATE_SUB(CURDATE(), INTERVAL retention_months MONTH);
    
    -- Log the cleanup action for audit transparency
    INSERT INTO AuditLog (Action, Timestamp) 
    VALUES ('Data Retention Purge Executed', NOW());
END //
DELIMITER ;

-- 4. ANALYTICAL QUERY: Extracting Insights Safely
-- This query joins the tables to find top spending categories by region.
-- Because of our ethical design, the output contains NO PII, only 
-- aggregated, anonymized business insights.
SELECT 
    c.Region,
    t.Category,
    COUNT(t.TransactionID) AS TotalTransactions,
    SUM(t.Amount) AS TotalRevenue
FROM Customers c
JOIN Transactions t ON c.CustomerID = t.CustomerID
WHERE t.TransactionDate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY c.Region, t.Category
ORDER BY TotalRevenue DESC;

-- 5. EXECUTE RETENTION POLICY
CALL EnforceDataRetention();