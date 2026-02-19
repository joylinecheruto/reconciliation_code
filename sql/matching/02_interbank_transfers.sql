DROP TABLE IF EXISTS interbank_transfers;

create table  interbank_transfers AS

WITH potential_matches AS (
    SELECT
        w.transaction_id      AS withdrawal_transaction_id,
        d.transaction_id      AS deposit_transaction_id,

        w.Source              AS withdrawal_from,
        d.Source              AS deposit_to,

        w.Transaction_date    AS withdrawal_date,
        d.Transaction_date    AS deposit_date,

        w.Reference           AS withdrawal_reference,
        d.Reference           AS deposit_reference,

        w.Amount              AS withdrawal_amount,
        d.Amount              AS deposit_amount,

        w.Description         AS withdrawal_description,
        d.Description         AS deposit_description,

        w.Transaction_type    AS withdrawal_transaction_type,
        d.Transaction_type    AS deposit_transaction_type,

        ABS(ABS(w.Amount) - d.Amount)                    AS amount_diff,
        ABS(DATEDIFF(w.Transaction_date, d.Transaction_date)) AS date_diff,

        CASE
            WHEN ABS(ABS(w.Amount) - d.Amount) = 0
             AND w.Transaction_date = d.Transaction_date
            THEN 'Exact Match'
            ELSE 'Approximate Match'
        END AS match_type,

        CASE
            WHEN w.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
             AND d.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
            THEN 'Bank→Bank'

            WHEN w.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
             AND d.Source = 'MPESA0723800949'
            THEN 'Bank→Mpesa'

            WHEN w.Source = 'MPESA0723800949'
             AND d.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
            THEN 'Mpesa→Bank'

            WHEN w.Source = 'TLLL143190'
             AND d.Source = 'DTB3001'
            THEN 'Till→Bank'
        END AS match_group

    FROM all_transactions w
    JOIN all_transactions d
        ON w.Type = 'Withdrawal'
       AND d.Type = 'Deposit'
       AND w.Source <> d.Source
       AND ABS(ABS(w.Amount) - d.Amount) <= 1
       AND ABS(DATEDIFF(w.Transaction_date, d.Transaction_date)) <= 1
       AND (
            (w.Source = 'MPESA0723800949' AND d.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
             AND d.Description LIKE CONCAT('%', w.Reference, '%'))
            OR
            
            (w.Source = 'TLLL143190' AND d.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
      
             ) 
            OR
            (w.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192') AND d.Source = 'MPESA0723800949'
             AND (d.Description LIKE '%DEPOSIT OF FUNDS%' OR d.Description LIKE '%BUSINESS PAYMENT%')
             AND (w.Description LIKE '%254723800949%' OR w.Description LIKE '%0723800949%' or w.Transaction_type like'%WITHDRAWAL%')
            AND (w.Description NOT LIKE '%POS%')
          
            
         )
            OR
		(w.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192') AND 
        d.Source IN ('ABSA4731','DTB3001','COOP1191','COOP1192')
          
                      AND (d.Description NOT LIKE '%07%') and (d.Description not like '%2547%'))
                   and (d.Description not like '%CHQ NO%')
  )     
),

-- Rank both withdrawals and deposits in one CTE
ranked_matches AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY withdrawal_transaction_id
               ORDER BY amount_diff, date_diff
           ) AS withdrawal_rank,
           ROW_NUMBER() OVER (
               PARTITION BY deposit_transaction_id
               ORDER BY amount_diff, date_diff
           ) AS deposit_rank
    FROM potential_matches
)

-- Pick only matches that are best for both withdrawal and deposit
SELECT 
withdrawal_from,
		deposit_to,
        withdrawal_date,
        deposit_date,
        withdrawal_reference,
        deposit_reference,
        withdrawal_amount,
        deposit_amount,
        withdrawal_description,
        deposit_description,
        withdrawal_transaction_type,
        deposit_transaction_type,
        Match_Group,
        Match_Type,
        withdrawal_transaction_id,
        deposit_transaction_id
FROM ranked_matches
WHERE withdrawal_rank = 1
  AND deposit_rank = 1;
SELECT* from interbank_transfers;
