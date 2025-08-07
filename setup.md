# Midday Setup Guide

## OTP Authentication Configuration

### Issue: Email Link Expiration Error

If you encounter the error "Email link is invalid or has expired" when using OTP authentication, this is likely due to a mismatch between your UI expecting 6-digit OTP codes and Supabase sending magic links by default.

**Error URL Pattern:**
```
http://localhost:3001/login#error=access_denied&error_code=otp_expired&error_description=Email+link+is+invalid+or+has+expired
```

### Root Cause

Your application's `OTPSignIn` component displays a 6-digit code input field, but Supabase's `signInWithOtp()` method sends **magic links** by default, not OTP codes.

**Flow Mismatch:**
1. **UI expects**: 6-digit OTP codes (`InputOTP` component)
2. **Supabase sends**: Magic link in email (default behavior)
3. **User clicks**: Expired magic link → Error

### Solution: Configure Supabase for OTP Codes

#### Step 1: Access Email Templates

1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Navigate to **Authentication** → **Email Templates**
3. You'll need to modify **two templates**:
   - **Magic Link** (for login)
   - **Confirm Your Signup** (for registration)

#### Step 2: Modify Magic Link Template

Replace the default magic link template with an OTP-focused template:

**Before (Magic Link):**
```html
<h2>Magic Link</h2>
<p>Follow this link to login:</p>
<p><a href="{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email">Log In</a></p>
```

**After (OTP Code):**
```html
<h2>Your Login Code</h2>
<p>Please enter this 6-digit code to complete your login:</p>
<h1 style="font-size: 32px; font-weight: bold; text-align: center; letter-spacing: 8px; margin: 20px 0; color: #1a1a1a;">{{ .Token }}</h1>
<p style="text-align: center; color: #666; font-size: 14px;">This code will expire in 1 hour.</p>
<p style="text-align: center; color: #666; font-size: 12px;">If you didn't request this, please ignore this email.</p>
```

#### Step 3: Modify Confirm Your Signup Template

Replace the default signup confirmation template:

**Before (Confirmation Link):**
```html
<h2>Confirm your signup</h2>
<p>Follow this link to confirm your user:</p>
<p><a href="{{ .SiteURL }}/auth/confirm?token_hash={{ .TokenHash }}&type=email">Confirm your mail</a></p>
```

**After (OTP Code):**
```html
<h2>Confirm Your Signup</h2>
<p>Welcome! Please enter this 6-digit code to complete your account registration:</p>
<h1 style="font-size: 32px; font-weight: bold; text-align: center; letter-spacing: 8px; margin: 20px 0; color: #1a1a1a;">{{ .Token }}</h1>
<p style="text-align: center; color: #666; font-size: 14px;">This code will expire in 1 hour.</p>
<p style="text-align: center; color: #666; font-size: 12px;">If you didn't sign up for this account, please ignore this email.</p>
```

#### Step 4: Configure OTP Expiration (Optional)

1. Go to **Authentication** → **Providers** → **Email**
2. Set **Email OTP Expiration** (default: 3600 seconds = 1 hour)
3. Maximum allowed: 86400 seconds (24 hours)

#### Step 5: Test Authentication Flow

1. Start the development server: `TZ=UTC next dev -p 3001 --turbopack`
2. **Test Login Flow:**
   - Navigate to login page
   - Enter email address
   - Check email for 6-digit login code
   - Enter code in the app's OTP input field
3. **Test Signup Flow:**
   - Navigate to signup page  
   - Enter email and password
   - Check email for 6-digit confirmation code
   - Enter code to complete registration

### Development Environment

The application runs with `TZ=UTC` to ensure consistent timezone handling:

```json
{
  "scripts": {
    "dev": "TZ=UTC next dev -p 3001 --turbopack"
  }
}
```

### Alternative Approaches

#### Option A: Hybrid Approach
Modify your UI to support both OTP codes and magic links:

```typescript
// Add to your OTP component
<div className="text-center mt-4">
  <p className="text-sm text-gray-600">
    Or check your email for a magic link to sign in directly
  </p>
</div>
```

#### Option B: Magic Link Only
If you prefer magic links, update your UI to remove the OTP input and instruct users to check their email for a clickable link.

### Technical Details

**Login Authentication Flow:**
1. User submits email via `supabase.auth.signInWithOtp({ email })`
2. Supabase sends email with OTP code (using Magic Link template)
3. User enters code in `InputOTP` component
4. Code verified via `supabase.auth.verifyOtp({ email, token, type: "email" })`

**Signup Authentication Flow:**
1. User submits email via `supabase.auth.signUp({ email, password })`
2. Supabase sends email with OTP code (using Confirm Your Signup template)
3. User enters code in `InputOTP` component
4. Code verified via `supabase.auth.verifyOtp({ email, token, type: "email" })`

**Key Files:**
- `apps/dashboard/src/components/otp-sign-in.tsx` - OTP UI component
- `apps/dashboard/src/actions/verify-otp-action.ts` - Server-side verification
- Supabase Email Templates:
  - **Magic Link** template (for login OTP codes)
  - **Confirm Your Signup** template (for registration OTP codes)

### Troubleshooting

**Common Issues:**
- **"OTP expired"**: Check if you're clicking a magic link instead of entering the 6-digit code
- **Template not updating**: Clear browser cache and verify both email templates are updated in Supabase dashboard
- **Different email formats**: Ensure both "Magic Link" and "Confirm Your Signup" templates use the `{{ .Token }}` variable
- **Emails not arriving**: Verify SMTP configuration and rate limits (2 emails/hour for default Supabase email service)

**Rate Limits:**
- Default: 1 OTP request per 60 seconds per email
- Production: Configure custom SMTP for higher limits

### Production Considerations

1. **Custom SMTP**: Configure custom SMTP server for production email delivery
2. **Rate Limiting**: Monitor and adjust OTP request limits
3. **Security**: Consider implementing additional verification steps for sensitive operations
4. **User Experience**: Provide clear instructions about checking email for codes vs links

---

## Supabase Database Webhook Configuration

### Registration Webhook Setup

The application includes a webhook at `/api/webhook/registered/route.ts` that needs to be triggered after user signup to handle analytics tracking and onboarding flow.

#### What the Webhook Does

- Tracks user registration analytics events
- Triggers an "onboard-team" background job with 5-minute delay
- Sends welcome emails and sets up team onboarding

#### Configuration Steps

**Step 1: Prepare Your Webhook Secret**

1. Your webhook secret is already configured in `.env`: `sb_secret_DI_Ar4hU6NtXn3rxHKjCGQ_CfCNpA_k`
2. Go to [SHA256 Online Tool](https://emn178.github.io/online-tools/sha256.html)
3. Enter your webhook secret and generate the SHA256 hash
4. Copy the generated hash (you'll need it for the webhook configuration)

**Step 2: Access Supabase Database Webhooks**

1. Navigate to **Database** → **Webhooks**
2. Click **Create a new hook**

**Step 3: Configure the Webhook**

Configure the webhook with these settings:

- **Name**: `User Registration Webhook`
- **Table**: `users`
- **Events**: `Insert` (check only Insert)
- **Type**: `HTTP Request`
- **HTTP Method**: `POST`
- **URL**: `https://your-domain.com/api/webhook/registered`
  - For development: `https://your-ngrok-url.ngrok.io/api/webhook/registered`
  - For production: `https://your-production-domain.com/api/webhook/registered`

**Step 4: Configure Authentication**

1. **HTTP Headers**: Add the following headers:
   ```
   Content-Type: application/json
   x-webhook-secret: sb_secret_DI_Ar4hU6NtXn3rxHKjCGQ_CfCNpA_k
   ```

**Important**: The current webhook code expects HMAC-SHA256 signatures that change with each request body. Static headers won't work for signature verification.

### **Alternative Approach: Simplified Verification**

If Supabase doesn't auto-generate HMAC signatures, you may need to modify the webhook verification to use a simpler approach:

```typescript
// Instead of HMAC verification, use simple secret comparison
const webhookSecret = (await headers()).get("x-webhook-secret");
if (webhookSecret !== process.env.WEBHOOK_SECRET_KEY) {
  return NextResponse.json({ message: "Not Authorized" }, { status: 401 });
}
```

**Step 5: Test the Webhook**

1. Start your development server with ngrok:
   ```bash
   ngrok http 3001
   ```
2. Create a test user registration
3. **Check your application logs** for the header output:
   ```
   === ALL WEBHOOK HEADERS ===
   content-type: application/json
   user-agent: ...
   x-supabase-signature found: false
   === END HEADERS ===
   ```
4. **Analyze the headers** to see what authentication headers Supabase actually sends
5. Check Supabase webhook logs for delivery status
6. If no `x-supabase-signature` is found, use the simplified verification approach

#### Webhook Payload Format

The webhook receives this payload format:

```json
{
  "type": "INSERT",
  "table": "users",
  "schema": "public",
  "record": {
    "id": "user-uuid-here",
    "full_name": "John Doe",
    "email": "john@example.com",
    "created_at": "2025-08-02T...",
    "team_id": "team-uuid-here"
  },
  "old_record": null
}
```

#### Environment Variables Required

Ensure these environment variables are set:

```bash
# Webhook secret for signature verification (use original secret, not SHA256 hash)
WEBHOOK_SECRET_KEY=sb_secret_DI_Ar4hU6NtXn3rxHKjCGQ_CfCNpA_k

# Trigger.dev configuration (for onboarding jobs)
TRIGGER_SECRET_KEY=your-trigger-secret
TRIGGER_PROJECT_ID=your-trigger-project-id

# Resend configuration (for welcome emails)
RESEND_API_KEY=your-resend-key
RESEND_AUDIENCE_ID=your-audience-id
```

#### Development Setup with ngrok

For local development, you'll need to expose your local server:

```bash
# Install ngrok (if not already installed)
npm install -g ngrok

# Expose your local development server
ngrok http 3001

# Use the ngrok URL in your Supabase webhook configuration
# Example: https://abc123.ngrok.io/api/webhook/registered
```

#### Troubleshooting

**Common Issues:**

- **Signature verification fails**: 
  - **Current Issue**: The webhook expects HMAC-SHA256 signatures, but static headers don't work
  - **Solution**: Either find if Supabase auto-generates signatures or use the simplified verification approach
  - **Check**: Look at incoming webhook headers to see if `x-supabase-signature` is automatically included
- **Webhook not triggering**: Verify the webhook is enabled and the table/events are correctly configured  
- **Missing user data**: Check that the `users` table has `id` and `full_name` columns populated
- **Onboarding job not running**: Verify Trigger.dev configuration and that the project is properly connected
- **"Missing signature" error**: Consider using the simplified verification approach with `x-webhook-secret` header instead

**Webhook Logs:**

- **Application Logs**: Check your console for detailed header logging:
  ```
  === ALL WEBHOOK HEADERS ===
  [All headers from Supabase will be listed here]
  === END HEADERS ===
  ```
- **Supabase Logs**: Check **Database** → **Webhooks** → **Logs** for delivery status
- **Trigger.dev**: Monitor dashboard for job execution
- **Console Output**: Look for the webhook request headers to understand what Supabase actually sends

#### Security Considerations

1. **Signature Verification**: The webhook verifies requests using HMAC-SHA256 signatures
2. **HTTPS Only**: Use HTTPS URLs in production for webhook endpoints
3. **Secret Management**: Keep `WEBHOOK_SECRET_KEY` secure and rotate periodically
4. **Rate Limiting**: Consider implementing rate limiting on webhook endpoints if needed

---

## Database Trigger for User Profile Creation

### Issue: Missing public.users Record Creation

The application expects a record in the `public.users` table for each authenticated user, but this is not automatically created when users sign up through Supabase Auth.

### Solution: Add Database Trigger

You need to create a PostgreSQL trigger that automatically creates a `public.users` record when a new user signs up. 

**Important**: The user registration flow is:
1. User registers → Trigger creates profile in `public.users` (without team)
2. User is redirected to `/setup` → Updates their name and avatar
3. User is redirected to `/teams/create` → Creates their first team

#### Step 1: Access Supabase SQL Editor

1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Navigate to **SQL Editor**
3. Click **New Query**

#### Step 2: Create the Trigger Function

Run the following SQL to create the function and trigger:

```sql
-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Insert the new user into public.users table (without team_id)
  INSERT INTO public.users (
    id,
    email,
    full_name,
    created_at,
    locale,
    week_starts_on_monday,
    timezone,
    timezone_auto_sync,
    time_format,
    date_format,
    team_id
  )
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', null),
    now(),
    COALESCE(new.raw_user_meta_data->>'locale', 'en'),
    COALESCE((new.raw_user_meta_data->>'week_starts_on_monday')::boolean, false),
    COALESCE(new.raw_user_meta_data->>'timezone', 'UTC'),
    COALESCE((new.raw_user_meta_data->>'timezone_auto_sync')::boolean, true),
    COALESCE((new.raw_user_meta_data->>'time_format')::numeric, 24),
    new.raw_user_meta_data->>'date_format',
    null -- No team initially, user will create one after setup
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists (for re-running)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

#### Step 3: Verify the Trigger

After creating the trigger, verify it's working:

```sql
-- Check if the trigger exists
SELECT tgname, tgrelid::regclass, tgfoid::regproc 
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';

-- Check if the function exists
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'handle_new_user';
```

#### Step 4: Test the User Creation Flow

1. Sign up a new user through your application
2. Check if the user record is created in both tables:

```sql
-- Check auth.users table
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Check public.users table
SELECT id, email, full_name, created_at, team_id 
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5;
```

### How It Works

1. **User signs up** via Supabase Auth (OTP, OAuth, etc.)
2. **Supabase creates** a record in `auth.users`
3. **Trigger fires** automatically after the insert
4. **Function executes** and creates a corresponding record in `public.users`
5. **User profile** is now available for the application to use

### Schema Relationships

- `public.users.id` references `auth.users.id` (1:1 relationship)
- The trigger ensures data consistency between the two tables
- User metadata from auth is copied to the public profile

### Troubleshooting

**Common Issues:**

- **Duplicate key error**: User already exists in public.users
  - Solution: Add `ON CONFLICT (id) DO NOTHING` to the INSERT statement if needed
- **Missing columns**: Schema mismatch between function and table
  - Solution: Verify column names match your current schema
- **Permission denied**: Function needs proper permissions
  - Solution: Ensure `SECURITY DEFINER` is set on the function

**To handle existing users** (if you have users in auth.users but not in public.users):

```sql
-- Migrate existing auth users to public.users
INSERT INTO public.users (id, email, full_name, created_at)
SELECT 
  id,
  email,
  COALESCE(raw_user_meta_data->>'full_name', email),
  created_at
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users);
```

#### Step 5: Configure Row Level Security (RLS) Policies

After creating the trigger, you need to set up RLS policies to allow access to the users table. Run this SQL:

```sql
-- Allow service role to access all users (for server-side queries)
CREATE POLICY "Service role can access all users" ON public.users
FOR ALL USING (auth.role() = 'service_role');

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile" ON public.users
FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile  
CREATE POLICY "Users can update own profile" ON public.users
FOR UPDATE USING (auth.uid() = id);

-- Allow users to insert their own profile (for registration)
CREATE POLICY "Users can insert own profile" ON public.users
FOR INSERT WITH CHECK (auth.uid() = id);
```

### Security Considerations

1. The function runs with `SECURITY DEFINER` to ensure it has permission to insert
2. The trigger only fires on INSERT, not UPDATE or DELETE
3. User data is sanitized using COALESCE to handle null values
4. The function doesn't expose sensitive auth data to the public schema
5. RLS policies ensure users can only access their own data, while service role can access all users for server operations

### Common RLS Issues

**"User not authenticated" or "Failed query" errors:**

This typically happens when RLS is enabled but no policies exist, blocking all access to the table.

**Solution:** Run the RLS policies above to allow:
- Service role (server-side) access to all users
- Individual users access to their own profile
- New users to create their profile during registration

---

## Additional Setup Information

Add other setup instructions here as needed...