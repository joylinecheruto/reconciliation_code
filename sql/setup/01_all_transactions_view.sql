DROP VIEW IF EXISTS all_transactions;
CREATE OR REPLACE VIEW all_transactions AS
SELECT
    ID,
    Source,
    Type,
    Transaction_date,
    Reference,
    Transaction_type,
    Amount,
    Description,
    ROW_NUMBER() OVER (ORDER BY Source, Transaction_date, Amount, ID) AS transaction_id
FROM
(
    -- ABSA4731 Deposits
    SELECT 
        ID,
        'ABSA4731' AS Source,
        'Deposit' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Credit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM absa4731deposits

    UNION ALL

    -- ABSA4731 Withdrawals
    SELECT 
        ID,
        'ABSA4731' AS Source,
        'Withdrawal' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Debit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM absa4731withdrawals

    UNION ALL

    -- COOP1191 Deposits
    SELECT 
        ID,
        'COOP1191' AS Source,
        'Deposit' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Credit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM coop1191deposits

    UNION ALL

    -- COOP1191 Withdrawals
    SELECT 
        ID,
        'COOP1191' AS Source,
        'Withdrawal' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Debit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM coop1191withdrawals

    UNION ALL

    -- COOP1192 Deposits
    SELECT 
        ID,
        'COOP1192' AS Source,
        'Deposit' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Credit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM coop1192deposits

    UNION ALL

    -- COOP1192 Withdrawals
    SELECT 
        ID,
        'COOP1192' AS Source,
        'Withdrawal' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Debit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM coop1192withdrawals

    UNION ALL

    -- DTB3001 Deposits
    SELECT 
        ID,
        'DTB3001' AS Source,
        'Deposit' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Credit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM dtb3001deposits

    UNION ALL

    -- DTB3001 Withdrawals
    SELECT 
        ID,
        'DTB3001' AS Source,
        'Withdrawal' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Debit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM dtb3001withdrawals

    UNION ALL

    -- TLLL143190 Deposits
    SELECT 
        ID,
        'TLLL143190' AS Source,
        'Deposit' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Credit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM tlll143190deposits

    UNION ALL

    -- TLLL143190 Withdrawals
    SELECT 
        ID,
        'TLLL143190' AS Source,
        'Withdrawal' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        Reference,
        Transaction_type,
        CAST(REPLACE(Debit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM tlll143190withdrawals

    UNION ALL

    -- MPESA Deposits
    SELECT 
        ID,
        'MPESA0723800949' AS Source,
        'Deposit' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        TRIM(Reference) AS Reference,
        Transaction_type,
        CAST(REPLACE(Credit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM mpesa0723800949deposits

    UNION ALL

    -- MPESA Withdrawals
    SELECT 
        ID,
        'MPESA0723800949' AS Source,
        'Withdrawal' AS Type,
        STR_TO_DATE(Transaction_date,'%m/%d/%Y') AS Transaction_date,
        TRIM(Reference) AS Reference,
        Transaction_type,
        CAST(REPLACE(Debit,',','') AS DECIMAL(18,2)) AS Amount,
        TRIM(Description) AS Description
    FROM mpesa0723800949withdrawals

) AS combined;


SELECT * FROM all_transactions;
