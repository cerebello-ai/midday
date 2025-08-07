# Supabase Configuration Guide

This document covers the Supabase configuration issues we encountered and how to resolve them.

## Issues Fixed

### 1. Supabase Client Configuration for Background Jobs

**Problem**: The `process-document` job was failing with `supabaseUrl is required` error.

**Root Cause**: The Supabase client in `packages/supabase/src/client/job.ts` wasn't properly configured to accept parameters or fallback to appropriate environment variables.

**Solution**: Updated the `createClient` function to accept optional parameters:

```typescript
// Before (packages/supabase/src/client/job.ts)
export const createClient = () =>
  createSupabaseClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_KEY!,
  );

// After
export const createClient = (
  supabaseUrl?: string,
  supabaseServiceKey?: string,
) =>
  createSupabaseClient<Database>(
    supabaseUrl || process.env.NEXT_PUBLIC_SUPABASE_URL || process.env.SUPABASE_URL!,
    supabaseServiceKey || process.env.SUPABASE_SERVICE_KEY!,
  );
```

**Key Changes**:
- Added optional `supabaseUrl` and `supabaseServiceKey` parameters
- Added fallback to both `NEXT_PUBLIC_SUPABASE_URL` and `SUPABASE_URL` environment variables
- Maintained backward compatibility with existing code

### 2. Environment Variables for Supabase

**Required Environment Variables**:
```bash
# In apps/api/.env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key
SUPABASE_JWT_SECRET=your-jwt-secret

# For Next.js apps, also include:
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
```

**Environment Variable Priority**:
1. Parameters passed to `createClient()` function
2. `NEXT_PUBLIC_SUPABASE_URL` (for Next.js compatibility)
3. `SUPABASE_URL` (for server-side/jobs)

## Testing the Fix

After applying the fix, verify it works:

1. **Start the jobs service**:
   ```bash
   bun run jobs:dashboard
   ```

2. **Check job logs** for the `process-document` task - it should no longer show Supabase URL errors.

3. **Test document processing** by uploading a document to the vault.

## Related Files

- `packages/supabase/src/client/job.ts` - Main Supabase client for jobs
- `packages/jobs/src/tasks/document/process-document.ts` - Document processing job
- `apps/api/.env` - Environment configuration

## Best Practices

1. **Always provide fallbacks** for environment variables in client configurations
2. **Use appropriate environment variables** for different contexts:
   - `NEXT_PUBLIC_*` for client-side Next.js code
   - Non-prefixed variables for server-side code
3. **Test both parameter passing and environment variable fallbacks**
4. **Maintain backward compatibility** when updating client configurations