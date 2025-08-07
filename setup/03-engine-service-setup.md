# Engine Service Setup Guide

This document covers setting up and troubleshooting the Midday Engine service.

## Issues Fixed

### 1. Engine Connection Error

**Problem**: API calls to institutions were failing with:
```
Unable to connect. Is the computer able to access the url?
TRPCError: Unable to connect. Is the computer able to access the url?
```

**Root Cause**: The engine service wasn't running, causing the API to fail when trying to connect to `http://localhost:3002`.

**Solution**: Start the engine service and verify environment configuration.

## Engine Service Overview

The Midday Engine is a Cloudflare Worker that handles:
- Bank institution data
- Account information
- AI/search functionality
- External API integrations

### Architecture
- **Runtime**: Cloudflare Workers (using Wrangler for local development)
- **Local Port**: 3002
- **API Client**: `@midday/engine-client` package
- **Location**: `apps/engine/`

## Setting Up the Engine Service

### 1. Environment Configuration

**Required Environment Variables** (in `apps/api/.env`):
```bash
ENGINE_API_URL=http://localhost:3002
ENGINE_API_KEY=secret
```

### 2. Starting the Engine Service

**Option 1: Start engine only**
```bash
bun run dev:engine
```

**Option 2: Start all services**
```bash
bun run dev  # Starts all apps including engine
```

**Option 3: Start from engine directory**
```bash
cd apps/engine
bun run dev
```

Expected output:
```
⛅️ wrangler 4.20.0
─────────────────────────────────────────────
[wrangler:info] Ready on http://localhost:3002
⎔ Starting local server...
```

### 3. Verifying Engine is Running

**Check if port is in use**:
```bash
lsof -i :3002
```

**Check process list**:
```bash
ps aux | grep wrangler
```

## Engine Client Configuration

The engine client is configured in `packages/engine-client/src/index.ts`:

```typescript
import type { AppType } from "@midday/engine";
import { hc } from "hono/client";

export const client = hc<AppType>(`${process.env.ENGINE_API_URL}/`, {
  headers: {
    Authorization: `Bearer ${process.env.ENGINE_API_KEY}`,
  },
});
```

### Key Points:
- Uses Hono client for type-safe API calls
- Requires `ENGINE_API_URL` environment variable
- Requires `ENGINE_API_KEY` for authentication
- Imports types from `@midday/engine` for full type safety

## Common Engine Issues

### 1. Engine Not Starting

**Symptoms**:
- Connection refused errors
- "Unable to connect" messages
- Port 3002 not in use

**Solutions**:
```bash
# Check if wrangler is installed
bunx wrangler --version

# Start engine with verbose logging
cd apps/engine
NODE_ENV=development bun run dev

# Check for port conflicts
lsof -i :3002
```

### 2. Environment Variables Not Set

**Symptoms**:
- Authentication errors
- Undefined URL errors

**Solutions**:
```bash
# Verify environment variables
echo $ENGINE_API_URL
echo $ENGINE_API_KEY

# Check .env file exists
ls -la apps/api/.env

# Source environment variables
source apps/api/.env
```

### 3. Wrangler Issues

**Common Wrangler Problems**:
- Outdated version
- Missing configuration
- Port conflicts

**Solutions**:
```bash
# Update wrangler
bun install -g wrangler@latest

# Check wrangler configuration
cd apps/engine
cat wrangler.toml

# Use different port if conflict
wrangler dev src/index.ts --port 3003
# Then update ENGINE_API_URL=http://localhost:3003
```

### 4. API Authentication Errors

**Symptoms**:
- 401 Unauthorized responses
- "Invalid token" errors

**Verification**:
- Check `ENGINE_API_KEY` matches between client and server
- Verify Authorization header format: `Bearer ${token}`
- Ensure environment variables are loaded in API process

## Testing the Engine

### 1. Health Check
The engine should expose endpoints for testing connectivity.

### 2. Institution Endpoint Test
Try accessing institutions through the API:
```bash
# This should work after engine is running
curl -H "Authorization: Bearer secret" \
     http://localhost:3002/institutions
```

### 3. Integration Test
Test through the main application:
1. Start all services: `bun run dev`
2. Access the dashboard
3. Try connecting a bank account
4. Check for institution listings

## Engine Development

### File Structure
```
apps/engine/
├── src/
│   ├── index.ts          # Main entry point
│   ├── middleware.ts     # Auth and request middleware
│   ├── routes/           # API route handlers
│   ├── providers/        # Bank provider integrations
│   └── utils/           # Utility functions
├── wrangler.toml        # Cloudflare Worker configuration
└── package.json
```

### Adding New Features
1. Define routes in `src/routes/`
2. Add middleware if needed
3. Update type definitions
4. Test locally with `bun run dev`

## Related Files

- `apps/engine/` - Engine service source code
- `packages/engine-client/` - TypeScript client library
- `apps/api/src/trpc/routers/institutions.ts` - API endpoints using engine
- `apps/api/.env` - Environment configuration

## Best Practices

1. **Always start engine before API** when developing locally
2. **Use consistent environment variables** across all services
3. **Monitor engine logs** for debugging connection issues
4. **Keep engine client types in sync** with engine API
5. **Test engine endpoints independently** before integration testing
6. **Use proper error handling** for engine connectivity issues