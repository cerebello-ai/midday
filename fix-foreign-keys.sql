-- This script adds missing foreign key constraints that Drizzle expects
-- Run this after applying schema.sql to complete the database setup

-- Bank accounts foreign keys (already added)
-- ALTER TABLE bank_accounts ADD CONSTRAINT bank_accounts_bank_connection_id_fkey FOREIGN KEY (bank_connection_id) REFERENCES bank_connections(id) ON DELETE CASCADE;
-- ALTER TABLE bank_accounts ADD CONSTRAINT bank_accounts_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;  
-- ALTER TABLE bank_accounts ADD CONSTRAINT public_bank_accounts_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

-- Add other commonly missing foreign keys
-- Note: Only add if they don't already exist

-- Users table
ALTER TABLE users ADD CONSTRAINT IF NOT EXISTS users_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE SET NULL;

-- Transactions table  
ALTER TABLE transactions ADD CONSTRAINT IF NOT EXISTS transactions_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;
ALTER TABLE transactions ADD CONSTRAINT IF NOT EXISTS transactions_bank_account_id_fkey FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE SET NULL;
ALTER TABLE transactions ADD CONSTRAINT IF NOT EXISTS transactions_assigned_id_fkey FOREIGN KEY (assigned_id) REFERENCES users(id) ON DELETE SET NULL;

-- Bank connections
ALTER TABLE bank_connections ADD CONSTRAINT IF NOT EXISTS bank_connections_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

-- Documents
ALTER TABLE documents ADD CONSTRAINT IF NOT EXISTS documents_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;
ALTER TABLE documents ADD CONSTRAINT IF NOT EXISTS documents_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL;

-- Invoices
ALTER TABLE invoices ADD CONSTRAINT IF NOT EXISTS invoices_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;
ALTER TABLE invoices ADD CONSTRAINT IF NOT EXISTS invoices_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL;
ALTER TABLE invoices ADD CONSTRAINT IF NOT EXISTS invoices_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

-- Customers
ALTER TABLE customers ADD CONSTRAINT IF NOT EXISTS customers_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

-- Inbox
ALTER TABLE inbox ADD CONSTRAINT IF NOT EXISTS inbox_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;
ALTER TABLE inbox ADD CONSTRAINT IF NOT EXISTS inbox_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL;

-- Inbox accounts
ALTER TABLE inbox_accounts ADD CONSTRAINT IF NOT EXISTS inbox_accounts_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;