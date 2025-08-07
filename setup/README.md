# Midday Setup & Troubleshooting Documentation

This directory contains comprehensive setup and troubleshooting documentation based on real issues encountered during Midday development setup.

## 📚 Documentation Overview

### [01-supabase-configuration.md](./01-supabase-configuration.md)
**Supabase Configuration Guide**
- Fixed Supabase client configuration for background jobs
- Environment variable setup and fallbacks
- Client parameter handling improvements

**Key Fixes**:
- ✅ `supabaseUrl is required` error in jobs
- ✅ Environment variable fallback chain
- ✅ Backward compatibility maintained

---

### [02-database-schema-troubleshooting.md](./02-database-schema-troubleshooting.md)
**Database Schema Troubleshooting Guide**
- Teams table insert constraint violations
- Database schema validation and debugging
- Drizzle ORM best practices

**Key Fixes**:
- ✅ Teams table `plan` field not-null constraint
- ✅ Missing required fields in INSERT statements
- ✅ Database defaults vs ORM behavior

---

### [03-engine-service-setup.md](./03-engine-service-setup.md)
**Engine Service Setup Guide**
- Cloudflare Worker local development setup
- Engine client configuration and authentication
- Connection troubleshooting and debugging

**Key Fixes**:
- ✅ "Unable to connect" engine errors
- ✅ Engine service startup and port configuration
- ✅ Environment variable setup for engine API

---

### [04-background-jobs-troubleshooting.md](./04-background-jobs-troubleshooting.md)
**Background Jobs Troubleshooting Guide**
- Trigger.dev job configuration and debugging
- Document processing pipeline setup
- Job monitoring and error handling

**Key Fixes**:
- ✅ Document processing job failures
- ✅ Supabase connection in background jobs
- ✅ Job timeout and retry configuration

---

## 🚀 Quick Start

If you're setting up Midday for the first time and encounter issues, follow this checklist:

### 1. Environment Setup
```bash
# Copy environment templates
cp apps/api/.env-template apps/api/.env
cp packages/jobs/.env-template packages/jobs/.env

# Configure required variables
# See individual guides for specific variables needed
```

### 2. Database Setup

> **Important**: This project uses Drizzle ORM for database management. Choose the appropriate setup method based on your situation.

#### Option A: Fresh Supabase Project (Recommended for new contributors)
If you're setting up a brand new Supabase project:

```sql
-- In Supabase SQL Editor, run in this order:
-- 1. Run schema.sql (complete database snapshot with all tables, functions, and policies)
-- 2. Run setup/database-setup.sql (storage policies for file uploads - NOT included in schema.sql)
```

This gives you the complete, up-to-date database structure immediately.

#### Option B: Existing Project with Drizzle Migrations
If you're working on an existing project or want to use Drizzle's migration system:

```bash
# Apply Drizzle migrations incrementally
cd apps/api
bun run db:push  # Applies all pending migrations from migrations/ folder

# Then apply storage policies (still required!)
# Run setup/database-setup.sql in Supabase SQL Editor

# Generate TypeScript types after database is ready
cd packages/supabase
bun run db:generate
```

#### Understanding the Database Files
- **`schema.sql`**: Complete database export (35 tables, all functions, basic policies)
- **`apps/api/migrations/`**: Drizzle ORM incremental migrations
- **`setup/database-setup.sql`**: Storage policies for file uploads (required for both options)

#### Available Database Commands
```bash
# In apps/api directory:
bun run db:generate  # Create new migration from schema changes
bun run db:push      # Apply migrations to database
bun run db:pull      # Pull current database schema (overwrites local schema)
```

### 3. Start Services
```bash
# Start all services
bun run dev

# Or start individually:
bun run dev:dashboard   # Dashboard (port 3001)
bun run dev:api        # API (port 3003)
bun run dev:engine     # Engine (port 3002)
bun run jobs:dashboard # Background jobs
```

### 4. Verify Everything Works
- ✅ Dashboard loads at http://localhost:3001
- ✅ API responds at http://localhost:3003
- ✅ Engine responds at http://localhost:3002
- ✅ Jobs dashboard shows active workers
- ✅ Can create teams and upload documents

---

## 🔧 Common Issues & Quick Fixes

| Issue | Quick Fix | Guide |
|-------|-----------|-------|
| `supabaseUrl is required` in jobs | Check job client config | [01-supabase-configuration.md](./01-supabase-configuration.md) |
| Team creation fails with DB error | Add missing `plan` field | [02-database-schema-troubleshooting.md](./02-database-schema-troubleshooting.md) |
| "Unable to connect" to institutions | Start engine service | [03-engine-service-setup.md](./03-engine-service-setup.md) |
| Document processing jobs fail | Check Supabase client in jobs | [04-background-jobs-troubleshooting.md](./04-background-jobs-troubleshooting.md) |

---

## 🛠 Development Tools & Commands

### Essential Commands
```bash
# Development
bun run dev                    # Start all services
bun run lint                   # Check code quality
bun run typecheck             # Type checking

# Database
bun run db:generate           # Generate migrations
bun run db:push              # Apply migrations
bun run db:pull              # Pull schema from DB

# Testing
bun run test                  # Run tests
bun test path/to/file.test.ts # Run specific test
```

### Debugging Tools
```bash
# Check running services
lsof -i :3001  # Dashboard
lsof -i :3002  # Engine  
lsof -i :3003  # API

# View logs
tail -f logs/api.log
tail -f logs/jobs.log

# Database queries
psql $DATABASE_URL
```

---

## 📋 Environment Variables Checklist

### Core Services
- [ ] `SUPABASE_URL` - Database connection
- [ ] `SUPABASE_SERVICE_KEY` - Service authentication
- [ ] `ENGINE_API_URL=http://localhost:3002` - Engine connection
- [ ] `ENGINE_API_KEY=secret` - Engine authentication

### Background Jobs
- [ ] `TRIGGER_PROJECT_ID` - Trigger.dev project
- [ ] `TRIGGER_SECRET_KEY` - Trigger.dev authentication

### Optional Services
- [ ] `OPENAI_API_KEY` - AI features
- [ ] `RESEND_API_KEY` - Email service

---

## 🐛 Reporting Issues

When reporting new issues, please include:

1. **Environment details**:
   - Operating system
   - Bun version (`bun --version`)
   - Node version (if applicable)

2. **Error details**:
   - Full error message
   - Stack trace
   - Relevant logs

3. **Reproduction steps**:
   - What you were trying to do
   - Steps to reproduce
   - Expected vs actual behavior

4. **Configuration**:
   - Environment variables (sanitized)
   - Service status
   - Recent changes

---

## 📝 Contributing to Documentation

When you encounter and fix new issues:

1. **Document the problem** clearly
2. **Explain the root cause** 
3. **Provide the solution** with code examples
4. **Add testing steps** to verify the fix
5. **Update this README** with quick reference

This documentation is maintained to help the next developer avoid the same issues!

---

## 🔗 Related Resources

- [Main README](../README.md) - Project overview
- [CLAUDE.md](../CLAUDE.md) - Development commands and architecture
- [Apps Documentation](../apps/) - Individual app documentation
- [Packages Documentation](../packages/) - Package-specific guides