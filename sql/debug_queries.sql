USE recon_25;


#All transactions

SELECT COUNT(*) AS total_transactions,
       SUM(Amount) AS total_amount
FROM all_transactions;

# Count & sum per source (each file/bank)
SELECT Source, COUNT(*) AS transaction_count, SUM(Amount) AS total_amount
FROM all_transactions
GROUP BY Source;


# Interbank transfers

-- Total rows and sum of withdrawals/deposits per match group
SELECT match_group, 
       COUNT(*) AS total_matches,
       SUM(withdrawal_amount) AS total_withdrawals,
       SUM(deposit_amount) AS total_deposits
FROM interbank_transfers
GROUP BY match_group;

-- Count & sum per source (for withdrawals and deposits separately)
SELECT withdrawal_from AS source, COUNT(*) AS withdrawal_count, SUM(withdrawal_amount) AS total_withdrawals
FROM interbank_transfers
GROUP BY withdrawal_from;

SELECT deposit_to AS source, COUNT(*) AS deposit_count, SUM(deposit_amount) AS total_deposits
FROM interbank_transfers
GROUP BY deposit_to;


#Reconciled invoices and expenditures

-- Reconciled invoices & deposits
SELECT COUNT(*) AS reconciled_count,
       SUM(Invoice_Amount) AS total_invoice_amount,
       SUM(Deposit_Amount) AS total_deposit_amount
FROM reconciled;

-- Reconciled expenditures & withdrawals
SELECT COUNT(*) AS reconciled_count,
       SUM(paid_amount) AS total_paid,
       SUM(invoiced_amount) AS total_invoiced
FROM reconciled_expenditures;


#Unmatched

-- Unmatched deposits
SELECT COUNT(*) AS unmatched_deposit_count, SUM(Amount) AS unmatched_deposit_total
FROM unmatched_bank_deposits;

-- Unmatched withdrawals
SELECT COUNT(*) AS unmatched_withdrawal_count, SUM(Amount) AS unmatched_withdrawal_total
FROM unmatched_bank_withdrawals;

-- Unmatched expenditures
SELECT COUNT(*) AS unmatched_expenditure_count, SUM(Total) AS unmatched_expenditure_total
FROM unmatched_expenditures;

-- Unmatched invoices
SELECT COUNT(*) AS unmatched_invoice_count, SUM(Amount) AS unmatched_invoice_total
FROM unmatched_invoices;
