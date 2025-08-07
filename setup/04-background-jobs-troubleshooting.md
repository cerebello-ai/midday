# Background Jobs Troubleshooting Guide

This document covers background job issues and their solutions.

## Issues Fixed

### 1. Document Processing Job Failure

**Problem**: The `process-document` job was failing with multiple errors:
```
Error: supabaseUrl is required.
at new SupabaseClient
at createSupabaseClient
at createClient (packages/supabase/src/client/job.ts:5:3)
at run (packages/jobs/src/tasks/document/process-document.ts:19:22)
```

**Root Cause**: Supabase client configuration in jobs wasn't properly set up (covered in detail in `01-supabase-configuration.md`).

**Solution**: Updated the Supabase client to accept parameters and environment variable fallbacks.

## Background Jobs Architecture

Midday uses **Trigger.dev** for background jobs processing:

### Key Components
- **Jobs Package**: `packages/jobs/` - Contains all background tasks
- **Trigger.dev**: External service for job orchestration
- **Tasks Location**: `packages/jobs/src/tasks/`
- **Configuration**: `packages/jobs/trigger.config.ts`

### Job Types
1. **Document Processing**: `process-document` - Processes uploaded documents and images
2. **Image Classification**: `classify-image` - AI-powered image classification
3. **Document Classification**: `classify-document` - AI-powered document classification
4. **HEIC Conversion**: `convert-heic` - Converts HEIC images to JPG

## Setting Up Background Jobs

### 1. Environment Configuration

**Required Environment Variables** (in `packages/jobs/.env`):
```bash
# Trigger.dev Configuration
TRIGGER_PROJECT_ID=your-project-id
TRIGGER_SECRET_KEY=your-secret-key

# Supabase Configuration (for job database access)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-key

# Optional: OpenAI for AI tasks
OPENAI_API_KEY=your-openai-key
```

### 2. Starting the Jobs Service

**Development Mode**:
```bash
# Start Trigger.dev dashboard
bun run jobs:dashboard

# Or run specific jobs
cd packages/jobs
bun run dev
```

**Expected Output**:
```
○ Aug 04, 12:24:43.632 ->  20250804.4 | process-document | run_xxx
✓ Job completed successfully
```

### 3. Trigger.dev Configuration

Located in `packages/jobs/trigger.config.ts`:
```typescript
import { defineConfig } from "@trigger.dev/sdk/v3";

export default defineConfig({
  project: "proj_zfhegaqlpfenezykfvur", // Your project ID
  // ... other configuration
});
```

## Document Processing Workflow

### Process Flow
1. **File Upload** → User uploads document to vault
2. **Job Trigger** → `process-document` job is triggered
3. **File Type Check** → Determines processing method:
   - HEIC images → Convert to JPG first
   - Regular images → Direct to image classification
   - Documents → Extract content and classify
4. **Classification** → AI determines document type
5. **Database Update** → Results stored in database

### Code Structure

**Main Processing Task** (`packages/jobs/src/tasks/document/process-document.ts`):
```typescript
export const processDocument = schemaTask({
  id: "process-document",
  schema: processDocumentSchema,
  maxDuration: 60,
  queue: {
    concurrencyLimit: 100,
  },
  run: async ({ mimetype, filePath, teamId }) => {
    // Create Supabase client with proper configuration
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_KEY!,
    );

    // Processing logic...
  },
});
```

## Common Job Issues

### 1. Supabase Connection Errors

**Symptoms**:
- "supabaseUrl is required" errors
- Database connection failures in jobs

**Solutions**:
1. Verify environment variables in `packages/jobs/.env`
2. Check Supabase client configuration (see `01-supabase-configuration.md`)
3. Ensure service key has proper permissions

**Debug Steps**:
```bash
# Check environment variables
cd packages/jobs
echo $SUPABASE_URL
echo $SUPABASE_SERVICE_KEY

# Test Supabase connection
bun run test-connection.js  # Create a simple test script
```

### 2. Trigger.dev Authentication Issues

**Symptoms**:
- Jobs not appearing in dashboard
- Authentication failures
- Project ID errors

**Solutions**:
```bash
# Verify Trigger.dev credentials
cd packages/jobs
echo $TRIGGER_PROJECT_ID
echo $TRIGGER_SECRET_KEY

# Check trigger configuration
cat trigger.config.ts

# Login to Trigger.dev CLI
bunx @trigger.dev/cli@latest login
```

### 3. Job Timeout Issues

**Symptoms**:
- Jobs hanging or timing out
- "Maximum duration exceeded" errors

**Solutions**:
1. Increase `maxDuration` in job configuration
2. Optimize processing logic
3. Add proper error handling and retries

**Configuration Example**:
```typescript
export const processDocument = schemaTask({
  id: "process-document",
  maxDuration: 120, // Increase from 60 to 120 seconds
  retry: {
    maxAttempts: 3,
    factor: 2,
    minTimeoutInMs: 1000,
    maxTimeoutInMs: 10000,
  },
  // ... rest of configuration
});
```

### 4. File Processing Errors

**Symptoms**:
- "File not found" errors
- Corrupted file processing
- HEIC conversion failures

**Debug Steps**:
1. Check file exists in Supabase Storage
2. Verify file permissions
3. Test file download manually
4. Check HEIC conversion dependencies

## Monitoring and Debugging

### 1. Job Logs

**Viewing Logs**:
```bash
# Local development logs
bun run jobs:dashboard

# Check specific job logs
tail -f logs/jobs.log
```

### 2. Database Monitoring

**Check Document Processing Status**:
```sql
-- Check documents processing status
SELECT id, name, processing_status, created_at 
FROM documents 
WHERE processing_status IN ('processing', 'failed')
ORDER BY created_at DESC;

-- Check recent job executions
SELECT * FROM job_executions 
ORDER BY created_at DESC 
LIMIT 10;
```

### 3. Error Handling

**Best Practices**:
```typescript
export const processDocument = schemaTask({
  // ... configuration
  run: async ({ mimetype, filePath, teamId }) => {
    const supabase = createClient(/* ... */);
    
    try {
      // Main processing logic
      
    } catch (error) {
      console.error('Document processing failed:', error);
      
      // Update document status to failed
      await supabase
        .from("documents")
        .update({ processing_status: "failed" })
        .eq("id", filePath.join("/"));
        
      // Re-throw for Trigger.dev retry logic
      throw error;
    }
  },
});
```

## Testing Background Jobs

### 1. Local Testing

**Test Document Upload**:
1. Start all services: `bun run dev`
2. Upload a document through the UI
3. Monitor job execution in Trigger.dev dashboard
4. Check document processing status

### 2. Manual Job Triggering

**Trigger Jobs Manually**:
```typescript
// In your test script
import { processDocument } from './src/tasks/document/process-document';

await processDocument.trigger({
  mimetype: 'application/pdf',
  filePath: ['test-document.pdf'],
  teamId: 'test-team-id'
});
```

## Related Files

- `packages/jobs/` - Main jobs package
- `packages/jobs/src/tasks/` - All background tasks
- `packages/jobs/trigger.config.ts` - Trigger.dev configuration
- `packages/supabase/src/client/job.ts` - Supabase client for jobs
- `apps/dashboard/src/components/vault/` - File upload UI components

## Best Practices

1. **Always handle errors gracefully** in job functions
2. **Use appropriate timeouts** for different job types
3. **Monitor job performance** and optimize as needed
4. **Test jobs locally** before deploying
5. **Keep job functions focused** and single-purpose
6. **Use proper retry strategies** for transient failures
7. **Log important events** for debugging and monitoring