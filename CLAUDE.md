# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Development
```bash
# Start development servers
bun run dev                    # All apps in parallel
bun run dev:dashboard          # Dashboard only
bun run dev:website           # Website only
bun run dev:api               # API only (runs on port 3003)
bun run dev:engine            # Engine (Cloudflare Worker)
bun run dev:desktop           # Desktop app

# Testing
bun run test                   # Run all tests
bun test path/to/file.test.ts  # Run a single test file
cd apps/dashboard && bun test  # Run specific app tests
cd apps/dashboard && bun test:watch  # Watch mode

# Code Quality
bun run lint                   # Check linting (uses Biome)
bun run format                 # Auto-format code (uses Biome)
bun run typecheck              # Type checking

# Building
bun run build                  # Build all apps
bun run build:dashboard        # Build specific app

# Maintenance
bun run clean                  # Clean all node_modules
bun run clean:workspaces      # Clean build artifacts
```

### Database Commands
```bash
# In apps/api directory:
bun run db:pull                # Pull schema from database

# In packages/supabase directory:
bun run db:generate            # Generate TypeScript types from database
```

### Background Jobs
```bash
# In root directory:
bun run jobs:dashboard         # Run Trigger.dev dashboard
```

## Architecture Overview

This is a monorepo-based SaaS platform for business management (freelancers, contractors, consultants) built with:
- **Runtime**: Bun (not Node.js)
- **Monorepo**: Turbo
- **Frontend**: Next.js 15 with React 19
- **Database**: Supabase (PostgreSQL) with Drizzle ORM
- **Styling**: TailwindCSS + Shadcn UI components
- **Desktop**: Tauri
- **Mobile**: Expo
- **Cloud Functions**: Cloudflare Workers

### App Structure
- `apps/dashboard` - Main web app (Next.js)
- `apps/website` - Marketing site (Next.js)  
- `apps/api` - REST/tRPC API (Hono + Bun, runs on port 3003)
- `apps/engine` - AI/search worker (Cloudflare)
- `apps/desktop` - Desktop client (Tauri)
- `apps/docs` - Documentation (Mintlify)

### Key Packages
- `packages/ui` - Shared UI components (Shadcn-based)
- `packages/supabase` - Database client, queries, and types
- `packages/jobs` - Background jobs (Trigger.dev)
- `packages/email` - Email templates (React Email)
- `packages/app-store` - Third-party integrations
- `packages/documents` - Document processing (invoices, receipts)
- `packages/invoice` - Invoice generation and templates
- `packages/inbox` - Email inbox integration
- `packages/encryption` - Encryption utilities
- `packages/location` - Country/timezone data

### Service Integration Pattern
The platform integrates multiple external services:
- **Authentication**: Supabase Auth
- **Banking**: GoCardless (EU), Plaid (US/CA), Teller (US)
- **Search**: Typesense
- **AI**: Mistral, OpenAI
- **Background Jobs**: Trigger.dev
- **Email**: Resend
- **Notifications**: Novu
- **Analytics**: OpenPanel
- **Payments**: Polar

### Database Architecture
- Uses Drizzle ORM with PostgreSQL (Supabase)
- Migrations in `apps/api/migrations`
- Schema definitions in `apps/api/src/db/schema.ts`
- Database queries organized in:
  - `apps/api/src/db/queries` - API-specific queries
  - `packages/supabase/src/queries` - Shared queries
- Types generated in `packages/supabase/src/types/db.ts`

### API Architecture
- **tRPC**: Main API protocol for type-safe client-server communication
- **REST API**: Hono-based REST endpoints in `apps/api/src/rest/routers`
- **Middleware**: Auth, database, rate limiting, and scope validation
- **OpenAPI**: Scalar documentation available

### Testing Approach
- Uses Bun's built-in test runner
- Test files: `*.test.ts`, `*.test.tsx`, `*.spec.ts`, `*.spec.tsx`
- Unit tests for utilities and components
- Integration tests for API endpoints
- Run single test: `bun test path/to/file.test.ts`

### State Management
- Client-side stores using Zustand in `apps/dashboard/src/store`
- Server state managed through tRPC queries with React Query

### Development Notes
- Always use `bun` instead of `npm` or `yarn`
- The project uses workspace dependencies (e.g., `@midday/ui`)
- Environment variables are managed through respective services (Vercel, Supabase, etc.)
- Biome is used for linting/formatting (not ESLint/Prettier)
- UTC timezone is enforced in development
- API runs on port 3003 in development
- All timestamps should be handled in UTC
- Use workspace protocol for internal dependencies: `"@midday/package": "workspace:*"`

### Common Patterns
- **File uploads**: Handled through Supabase Storage
- **Background jobs**: Trigger.dev tasks in `packages/jobs/src/tasks`
- **Email sending**: React Email templates with Resend
- **Real-time**: Supabase Realtime for live updates
- **Search**: Typesense integration in the engine app
- **AI features**: Mistral/OpenAI through the engine worker