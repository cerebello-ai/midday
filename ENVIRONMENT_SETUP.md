# Environment Setup Guide

## Local vs Cloud Configuration

### Current Configuration
The project is now configured for **local development** using local Supabase instance.

### Environment Files

#### Local Development (Current Active)
- `apps/api/.env` - API local configuration  
- `apps/dashboard/.env` - Dashboard local configuration
- `packages/jobs/.env` - Jobs local configuration

#### Cloud Configuration (Backup)
- `apps/api/.env.cloud` - API cloud configuration backup
- `apps/dashboard/.env.cloud` - Dashboard cloud configuration backup  
- `packages/jobs/.env.cloud` - Jobs cloud configuration backup

## Local Supabase Configuration

### URLs and Keys
- **API URL**: http://127.0.0.1:54321
- **Database URL**: postgresql://postgres:postgres@127.0.0.1:54322/postgres
- **Studio URL**: http://127.0.0.1:54323 (for database management)
- **Anon Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
- **Service Role Key**: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

## Switch Between Environments

### To Use Local Development
```bash
# Make sure local Supabase is running
supabase start

# Current .env files are already set for local
```

### To Switch to Cloud
```bash
# Stop local Supabase
supabase stop

# Replace local .env files with cloud versions
cp apps/api/.env.cloud apps/api/.env
cp apps/dashboard/.env.cloud apps/dashboard/.env
cp packages/jobs/.env.cloud packages/jobs/.env
```

### To Switch Back to Local
```bash
# Start local Supabase
supabase start

# The current .env files are set for local (no action needed)
# Or restore from git if modified:
# git checkout -- apps/api/.env apps/dashboard/.env packages/jobs/.env
```

## Database Setup

### Local Database
- Complete schema applied with 35 tables
- pgvector extension enabled
- Storage policies configured
- TypeScript types generated

### Commands
```bash
# Check Supabase status
supabase status

# Access database directly
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres

# Generate types (if needed)
supabase gen types --lang=typescript --local > packages/supabase/src/types/db.ts
```

## Authentication & Test Data

The local setup includes test data and authentication bypass:

### Test User & Team Created
- **Test User**: `test@midday.ai` (ID: `22222222-2222-2222-2222-222222222222`)
- **Test Team**: `Test Team` (ID: `11111111-1111-1111-1111-111111111111`)
- **User-Team Relationship**: User is linked to team as `owner`

### Sample Data
- **Bank Connection**: Test Bank (Plaid provider)
- **Bank Account**: Test Checking Account ($5,000 balance)
- **Transactions**: 5 sample transactions (2 revenue, 3 expenses)
- **Categories**: Office, Software, Utilities

### Database Functions
All required functions created:
- `get_revenue_v3`, `get_profit_v3`
- `get_team_bank_accounts_balances`, `get_bank_account_currencies`
- `get_burn_rate_v4`, `get_expenses`, `get_spending_v4`, `get_runway_v4`

### Row Level Security (RLS)
**For local development only**: RLS is temporarily disabled on key tables to bypass authentication requirements.

**Important**: In production, RLS should be re-enabled with proper authentication.

## Re-enabling RLS for Production

To re-enable RLS when moving to production:
```sql
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_on_team ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_categories ENABLE ROW LEVEL SECURITY;
```

## Testing the Setup

The application should now work without permission errors:
1. ✅ Team queries will return the test team
2. ✅ User queries will return the test user
3. ✅ Database functions work correctly
4. ✅ All required tables and relationships exist