DROP TABLE IF EXISTS reconciled;
DROP TABLE IF EXISTS reconciled;
CREATE TABLE reconciled AS
WITH BaseMatches AS (
    SELECT 
        s.Row_no AS Invoice_Row_No,
        d.Source AS Paid_to_account,
        s.Date AS Invoice_Date,
        d.Transaction_date AS Deposit_Date,
        s.Amount AS Invoice_Amount,
        d.Amount AS Deposit_Amount,
        s.Invoice_no,
        d.Reference,
        s.Customer,
        d.Description AS Deposit_Description,
        s.Type AS Invoice_Type,
        s.Status AS Invoice_Status,
        d.transaction_id AS Deposit_id,
        d.Transaction_type,
        ABS(s.Amount - d.Amount) AS Amount_Diff,
        ABS(DATEDIFF(s.Date, d.Transaction_date)) AS Date_Diff,

        /* -------- MATCH PRIORITY -------- */
        CASE
            -- 1. Full word match: all words in Customer exist in Description
            WHEN NOT EXISTS (
                SELECT 1
                FROM (
                    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(s.Customer, ' ', n.n), ' ', -1)) AS word
                    FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
                    WHERE n.n <= LENGTH(s.Customer) - LENGTH(REPLACE(s.Customer, ' ', '')) + 1
                ) words
                WHERE d.Description NOT LIKE CONCAT('%', words.word, '%')
            )
            THEN 1

            -- 2. Partial word match OR invoice/reference match
            WHEN EXISTS (
                SELECT 1
                FROM (
                    SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(s.Customer, ' ', n.n), ' ', -1)) AS word
                    FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
                    WHERE n.n <= LENGTH(s.Customer) - LENGTH(REPLACE(s.Customer, ' ', '')) + 1
                ) words
                WHERE d.Description LIKE CONCAT('%', words.word, '%')
            )
            OR d.Reference LIKE CONCAT('%', s.Invoice_no, '%')
            OR s.Invoice_no LIKE CONCAT('%', d.Reference, '%')
            THEN 2

            -- 3. Fallback
            ELSE 3
        END AS Match_Priority

    FROM sales_invoices s
    INNER JOIN all_statementsdeposit d
       ON (
        -- TILL strict match
        (d.Source LIKE 'TILL143190%' 
         AND s.Invoice_no = d.Reference
         AND ABS(s.Amount - d.Amount) <= 5
         AND ABS(DATEDIFF(s.Date, d.Transaction_date)) <= 30)
        -- Bank deposits flexible match
        OR
        (d.Source NOT LIKE 'TILL43190%' 
         AND ABS(s.Amount - d.Amount) <= 5
         AND ABS(DATEDIFF(s.Date, d.Transaction_date)) <= 30)
    )
    AND d.Source <> 'MPESA0723800949'
),

RankedMatches AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Invoice_Row_No
            ORDER BY Match_Priority ASC, Amount_Diff ASC, Date_Diff ASC
        ) AS rn_invoice,
        ROW_NUMBER() OVER (
            PARTITION BY Deposit_id
            ORDER BY Match_Priority ASC, Amount_Diff ASC, Date_Diff ASC
        ) AS rn_deposit
    FROM BaseMatches
)

SELECT *
FROM RankedMatches
WHERE rn_invoice = 1
  AND rn_deposit = 1;

select* from reconciled;


DROP TABLE IF EXISTS unmatched_bank_deposits;

CREATE TABLE unmatched_bank_deposits AS
SELECT d.*
FROM all_statementsdeposit d
LEFT JOIN reconciled m
ON d.transaction_id=m.Deposit_id
WHERE m.Deposit_id IS NULL;

SELECT * FROM unmatched_bank_deposits;

CREATE OR REPLACE VIEW unmatched_invoices AS
SELECT i.*
FROM sales_invoices i
LEFT JOIN reconciled m
ON i.Row_no=m.Invoice_Row_No
WHERE m.Invoice_Row_No IS NULL;
SELECT* FROM unmatched_invoices;
 
