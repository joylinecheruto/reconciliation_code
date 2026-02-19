
CREATE OR REPLACE VIEW all_statementswithdrawal AS
SELECT w.*
FROM all_transactions w
LEFT JOIN interbank_transfers t
ON w.transaction_id=t.withdrawal_transaction_id
WHERE w.Type='Withdrawal'
AND t.withdrawal_transaction_id IS NULL;

SELECT * FROM all_statementswithdrawal;

CREATE OR REPLACE VIEW all_statementsdeposit AS
SELECT d.*
FROM all_transactions d
LEFT JOIN interbank_transfers t
ON d.transaction_id=t.deposit_transaction_id
WHERE d.Type='Deposit'
AND t.deposit_transaction_id IS NULL;

SELECT * FROM all_statementsdeposit;

