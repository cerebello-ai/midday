-- Add inbox_account_id column to inbox table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='inbox' AND column_name='inbox_account_id') THEN
        ALTER TABLE "inbox" ADD COLUMN "inbox_account_id" uuid;
    END IF;
END $$;

-- Add index for inbox_account_id if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace 
                   WHERE c.relname = 'inbox_inbox_account_id_idx' AND n.nspname = 'public') THEN
        CREATE INDEX "inbox_inbox_account_id_idx" ON "inbox" USING btree ("inbox_account_id");
    END IF;
END $$;

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'inbox_inbox_account_id_fkey') THEN
        ALTER TABLE "inbox" ADD CONSTRAINT "inbox_inbox_account_id_fkey" 
        FOREIGN KEY ("inbox_account_id") REFERENCES "inbox_accounts"("id") ON DELETE no action ON UPDATE no action;
    END IF;
END $$;