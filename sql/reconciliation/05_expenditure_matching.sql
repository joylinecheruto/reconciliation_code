DROP TABLE IF EXISTS reconciled_expenditures;

#Create or replace the reconciled_expenditures view

CREATE OR REPLACE VIEW reconciled_expenditures AS
WITH ranked_matches AS (
    SELECT
    w.ID,
    
        w.Source AS paid_from_acc,
        i.Date AS invoice_duedate,
        w.Transaction_date AS paid_date,
        i.Total AS invoiced_amount,
        w.Amount AS paid_amount,
        i.No AS Invoice_No,
        i.row_no,
        w.transaction_id AS withdrawal_id,
        w.Reference,
        UPPER(TRIM(i.Category)) AS Category,
        i.Payee,
        w.Description,
        w.Transaction_type,
        i.Type,

        ABS(DATEDIFF(w.Transaction_date, i.Date)) AS days_diff,
        ABS(w.Amount - i.Total) AS amount_diff,

        /* Rank per withdrawal */
        ROW_NUMBER() OVER (
            PARTITION BY w.transaction_id
            ORDER BY 
                ABS(DATEDIFF(w.Transaction_date, i.Date)),
                ABS(w.Amount - i.Total),
                i.Date
        ) AS rn_withdrawal,

        /* Rank per invoice/expense */
        ROW_NUMBER() OVER (
            PARTITION BY i.row_no
            ORDER BY 
                ABS(DATEDIFF(w.Transaction_date, i.Date)),
                ABS(w.Amount - i.Total),
                w.Transaction_date
        ) AS rn_invoice

    FROM all_statementswithdrawal w
    INNER JOIN expenditures i
        ON (
            /* PAYABLES */
            (
                i.Type = 'Bill'
                AND ABS(w.Amount - i.Total) <= 1
                AND ABS(DATEDIFF(w.Transaction_date, i.Date)) <= 30
                AND w.Description NOT LIKE '%CUSTOMER TRANSFER%'
            )
            /* DUES & SUBSCRIPTIONS */
            OR (
                UPPER(TRIM(i.Category)) LIKE '%DUES AND SUBSCRIPTIONS%'
                AND ABS(w.Amount - i.Total) <= 1
                AND ABS(DATEDIFF(w.Transaction_date, i.Date)) <= 30
                AND w.Description NOT LIKE '%CUSTOMER TRANSFER%'
            )
            /* CATEGORY EXPENSES */
            OR (
                (
                    UPPER(TRIM(i.Category)) LIKE '%TRAVEL EXPENSES%'
                    OR UPPER(TRIM(i.Category)) LIKE '%MARKETING EXPENSES%'
                    OR UPPER(TRIM(i.Category)) LIKE '%MEALS AND ENTERTAINMENT%'
                )
                AND w.Amount = i.Total
                AND ABS(DATEDIFF(w.Transaction_date, i.Date)) <= 7
            )
            /* GENERAL EXPENSES */
            OR (
                UPPER(TRIM(i.Type)) LIKE '%EXPENSE%'
                AND ABS(w.Amount - i.Total) <= 1
                AND ABS(DATEDIFF(w.Transaction_date, i.Date)) <= 5
            )
        )
)

SELECT *
FROM ranked_matches
WHERE rn_withdrawal = 1
  AND rn_invoice = 1;





drop table if exists unmatched_bank_withdrawals;
CREATE TABLE unmatched_bank_withdrawals AS
SELECT w.*
FROM all_statementswithdrawal w
LEFT JOIN reconciled_expenditures r
ON r.row_no=w.ID
WHERE r.ID IS NULL;
select * from unmatched_bank_withdrawals;

CREATE TABLE unmatched_expenditures AS
SELECT e.*
FROM expenditures e
LEFT JOIN reconciled_expenditures r
ON r.row_no=e.row_no
WHERE r.row_no IS NULL;