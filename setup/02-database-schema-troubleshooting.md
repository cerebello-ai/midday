# Database Schema Troubleshooting Guide

This document covers database schema issues encountered during setup and their solutions.

## Issues Fixed

### 1. Teams Table Insert Failure

**Problem**: Team creation was failing with a database constraint error:
```
Failed query: insert into "teams" (id, created_at, name, logo_url, inbox_id, email, inbox_email, inbox_forwarding, base_currency, country_code, document_classification, flags, canceled_at, plan) values (default, default, $1, default, default, $2, default, default, $3, $4, default, default, default, default) returning "id"
```

**Root Cause**: The `plan` field in the teams table has a `notNull()` constraint but wasn't being included in the insert statement.

**Schema Definition**:
```typescript
// apps/api/src/db/schema.ts
export const teams = pgTable(
  "teams",
  {
    // ... other fields
    plan: plansEnum().default("trial").notNull(),
    // ... other fields
  }
);
```

**Solution**: Added the missing `plan` field to the team creation query:

```typescript
// Before (apps/api/src/db/queries/teams.ts)
const [newTeam] = await tx
  .insert(teams)
  .values({
    name: params.name,
    baseCurrency: params.baseCurrency,
    countryCode: params.countryCode,
    logoUrl: params.logoUrl,
    email: params.email,
    // plan field was missing!
  })
  .returning({ id: teams.id });

// After
const [newTeam] = await tx
  .insert(teams)
  .values({
    name: params.name,
    baseCurrency: params.baseCurrency,
    countryCode: params.countryCode,
    logoUrl: params.logoUrl,
    email: params.email,
    plan: "trial", // ✅ Added missing field
  })
  .returning({ id: teams.id });
```

## Understanding the Schema Structure

### Teams Table Schema
Located in `apps/api/src/db/schema.ts`:

```typescript
export const plansEnum = pgEnum("plans", ["trial", "starter", "pro"]);

export const teams = pgTable(
  "teams",
  {
    id: uuid().defaultRandom().primaryKey().notNull(),
    createdAt: timestamp("created_at", { withTimezone: true, mode: "string" })
      .defaultNow()
      .notNull(),
    name: text(),
    logoUrl: text("logo_url"),
    inboxId: text("inbox_id").default("generate_inbox(10)"),
    email: text(),
    inboxEmail: text("inbox_email"),
    inboxForwarding: boolean("inbox_forwarding").default(true),
    baseCurrency: text("base_currency"),
    countryCode: text("country_code"),
    documentClassification: boolean("document_classification").default(false),
    flags: text().array(),
    canceledAt: timestamp("canceled_at", {
      withTimezone: true,
      mode: "string",
    }),
    plan: plansEnum().default("trial").notNull(), // ⚠️ This field is required!
  }
);
```

### Key Points:
- The `plan` field uses `plansEnum()` with values: `["trial", "starter", "pro"]`
- It has `.default("trial")` for database-level default
- It has `.notNull()` constraint, making it required
- When using Drizzle ORM, **database defaults don't automatically apply** in INSERT statements - you must explicitly provide the value

## Troubleshooting Database Schema Issues

### 1. Identifying Missing Required Fields

**Symptoms**:
- Insert operations failing with constraint violations
- Error messages mentioning "not null constraint"

**Debugging Steps**:
1. Check the database schema definition in `apps/api/src/db/schema.ts`
2. Look for fields with `.notNull()` constraints
3. Verify all required fields are included in INSERT statements
4. Check query files in `apps/api/src/db/queries/`

### 2. Validating Schema Changes

**After making schema changes**:

1. **Run database migrations**:
   ```bash
   cd apps/api
   bun run db:generate  # Generate new migration
   bun run db:push      # Apply to database
   ```

2. **Update TypeScript types**:
   ```bash
   cd packages/supabase
   bun run db:generate  # Generate new types
   ```

3. **Test with sample data**:
   ```bash
   bun run test        # Run database tests
   ```

### 3. Common Schema Pitfalls

1. **Database defaults vs ORM defaults**: Database `.default()` values don't automatically apply in ORM INSERT statements
2. **Enum validation**: Ensure enum values match exactly (case-sensitive)
3. **Foreign key constraints**: Verify referenced records exist before inserting
4. **Timestamp handling**: Use appropriate timezone settings (`withTimezone: true`)

## Related Files

- `apps/api/src/db/schema.ts` - Main database schema definitions
- `apps/api/src/db/queries/teams.ts` - Team-related database operations
- `apps/api/migrations/` - Database migration files
- `packages/supabase/src/types/db.ts` - Generated TypeScript types

## Best Practices

1. **Always include required fields** in INSERT statements, even if they have database defaults
2. **Use enum values explicitly** rather than relying on defaults
3. **Test database operations** after schema changes
4. **Keep migrations and schema in sync**
5. **Validate constraints** at both database and application levels
6. **Use TypeScript types** to catch missing fields at compile time