

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."account_type" AS ENUM (
    'depository',
    'credit',
    'other_asset',
    'loan',
    'other_liability'
);


ALTER TYPE "public"."account_type" OWNER TO "postgres";


CREATE TYPE "public"."bank_providers" AS ENUM (
    'gocardless',
    'plaid',
    'teller',
    'enablebanking'
);


ALTER TYPE "public"."bank_providers" OWNER TO "postgres";


CREATE TYPE "public"."connection_status" AS ENUM (
    'disconnected',
    'connected',
    'unknown'
);


ALTER TYPE "public"."connection_status" OWNER TO "postgres";


CREATE TYPE "public"."document_processing_status" AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed'
);


ALTER TYPE "public"."document_processing_status" OWNER TO "postgres";


CREATE TYPE "public"."inbox_account_providers" AS ENUM (
    'gmail',
    'outlook'
);


ALTER TYPE "public"."inbox_account_providers" OWNER TO "postgres";


CREATE TYPE "public"."inbox_status" AS ENUM (
    'processing',
    'pending',
    'archived',
    'new',
    'deleted',
    'done'
);


ALTER TYPE "public"."inbox_status" OWNER TO "postgres";


CREATE TYPE "public"."inbox_type" AS ENUM (
    'invoice',
    'expense'
);


ALTER TYPE "public"."inbox_type" OWNER TO "postgres";


CREATE TYPE "public"."invoice_delivery_type" AS ENUM (
    'create',
    'create_and_send',
    'scheduled'
);


ALTER TYPE "public"."invoice_delivery_type" OWNER TO "postgres";


CREATE TYPE "public"."invoice_size" AS ENUM (
    'a4',
    'letter'
);


ALTER TYPE "public"."invoice_size" OWNER TO "postgres";


CREATE TYPE "public"."invoice_status" AS ENUM (
    'draft',
    'overdue',
    'paid',
    'unpaid',
    'canceled',
    'scheduled'
);


ALTER TYPE "public"."invoice_status" OWNER TO "postgres";


CREATE TYPE "public"."plans" AS ENUM (
    'trial',
    'starter',
    'pro'
);


ALTER TYPE "public"."plans" OWNER TO "postgres";


CREATE TYPE "public"."reportTypes" AS ENUM (
    'profit',
    'revenue',
    'burn_rate',
    'expense'
);


ALTER TYPE "public"."reportTypes" OWNER TO "postgres";


CREATE TYPE "public"."teamRoles" AS ENUM (
    'owner',
    'member'
);


ALTER TYPE "public"."teamRoles" OWNER TO "postgres";


CREATE TYPE "public"."trackerStatus" AS ENUM (
    'in_progress',
    'completed'
);


ALTER TYPE "public"."trackerStatus" OWNER TO "postgres";


CREATE TYPE "public"."transactionCategories" AS ENUM (
    'travel',
    'office_supplies',
    'meals',
    'software',
    'rent',
    'income',
    'equipment',
    'transfer',
    'internet_and_telephone',
    'facilities_expenses',
    'activity',
    'uncategorized',
    'taxes',
    'other',
    'salary',
    'fees'
);


ALTER TYPE "public"."transactionCategories" OWNER TO "postgres";


CREATE TYPE "public"."transactionMethods" AS ENUM (
    'payment',
    'card_purchase',
    'card_atm',
    'transfer',
    'other',
    'unknown',
    'ach',
    'interest',
    'deposit',
    'wire',
    'fee'
);


ALTER TYPE "public"."transactionMethods" OWNER TO "postgres";


CREATE TYPE "public"."transactionStatus" AS ENUM (
    'posted',
    'pending',
    'excluded',
    'completed',
    'archived'
);


ALTER TYPE "public"."transactionStatus" OWNER TO "postgres";


CREATE TYPE "public"."transaction_frequency" AS ENUM (
    'weekly',
    'biweekly',
    'monthly',
    'semi_monthly',
    'annually',
    'irregular',
    'unknown'
);


ALTER TYPE "public"."transaction_frequency" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."extract_product_names"("products_json" json) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
  -- If products_json is null or not an array, return empty string
  IF products_json IS NULL OR json_typeof(products_json) != 'array' THEN
    RETURN '';
  END IF;
  
  -- Extract name fields from JSON array and concatenate with spaces
  RETURN COALESCE(
    (
      SELECT string_agg(
        COALESCE(product->>'name', product->>'title', product->>'description', ''),
        ' '
      )
      FROM json_array_elements(products_json) AS product
      WHERE COALESCE(product->>'name', product->>'title', product->>'description', '') != ''
    ),
    ''
  );
END;
$$;


ALTER FUNCTION "public"."extract_product_names"("products_json" json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_inbox"("count_limit" integer DEFAULT 10) RETURNS TABLE("id" "uuid", "display_name" "text", "amount" numeric, "currency" "text", "date" "date", "type" "text", "status" "text", "file_path" "text", "file_name" "text", "inbox_id" "uuid", "forwarded_to" "text", "due_date" "date", "created_at" timestamp with time zone, "updated_at" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
  SELECT 
    gen_random_uuid() as id,
    'Sample Invoice ' || generate_series as display_name,
    (random() * 1000 + 100)::numeric(10,2) as amount,
    'USD' as currency,
    (CURRENT_DATE - (random() * 30)::int) as date,
    CASE WHEN random() < 0.7 THEN 'invoice' ELSE 'expense' END as type,
    CASE 
      WHEN random() < 0.5 THEN 'pending'
      WHEN random() < 0.8 THEN 'new' 
      ELSE 'processed'
    END as status,
    '/storage/inbox/sample_' || generate_series || '.pdf' as file_path,
    'sample_' || generate_series || '.pdf' as file_name,
    gen_random_uuid() as inbox_id,
    NULL::text as forwarded_to,
    (CURRENT_DATE + (random() * 30)::int) as due_date,
    (CURRENT_TIMESTAMP - (random() * interval '30 days')) as created_at,
    CURRENT_TIMESTAMP as updated_at
  FROM generate_series(1, count_limit);
$$;


ALTER FUNCTION "public"."generate_inbox"("count_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_inbox_fts"("display_name" "text", "product_names" "text") RETURNS "tsvector"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
  -- Combine display_name and product_names, handle nulls
  RETURN to_tsvector(
    'english',
    COALESCE(display_name, '') || ' ' || COALESCE(product_names, '')
  );
END;
$$;


ALTER FUNCTION "public"."generate_inbox_fts"("display_name" "text", "product_names" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_bank_account_currencies"("team_id" "uuid") RETURNS TABLE("currency" "text")
    LANGUAGE "sql"
    AS $_$
  SELECT DISTINCT ba.currency
  FROM bank_accounts ba
  WHERE ba.team_id = $1 
  AND ba.currency IS NOT NULL
  AND ba.enabled = true
  ORDER BY ba.currency;
$_$;


ALTER FUNCTION "public"."get_bank_account_currencies"("team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_burn_rate_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text" DEFAULT ''::"text") RETURNS TABLE("date" "date", "value" numeric, "recurring_value" numeric, "percentage" numeric)
    LANGUAGE "sql"
    AS $$
  WITH date_series AS (
    SELECT generate_series(
      date_from::date,
      date_to::date,
      '1 month'::interval
    )::date as date
  )
  SELECT 
    ds.date,
    0::numeric as value,
    0::numeric as recurring_value,
    0::numeric as percentage
  FROM date_series ds
  ORDER BY ds.date;
$$;


ALTER FUNCTION "public"."get_burn_rate_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_expenses"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text" DEFAULT ''::"text") RETURNS TABLE("date" "date", "value" numeric, "recurring_value" numeric, "percentage" numeric)
    LANGUAGE "sql"
    AS $$
  WITH date_series AS (
    SELECT generate_series(
      date_from::date,
      date_to::date,
      '1 month'::interval
    )::date as date
  )
  SELECT 
    ds.date,
    0::numeric as value,
    0::numeric as recurring_value,
    0::numeric as percentage
  FROM date_series ds
  ORDER BY ds.date;
$$;


ALTER FUNCTION "public"."get_expenses"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_next_invoice_number"("team_id" "uuid") RETURNS integer
    LANGUAGE "sql"
    AS $_$
  SELECT COALESCE(
    (SELECT MAX(CAST(invoice_number AS integer)) + 1 
     FROM invoices 
     WHERE team_id = $1 
     AND invoice_number ~ '^[0-9]+$'),
    1
  );
$_$;


ALTER FUNCTION "public"."get_next_invoice_number"("team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_payment_score"("team_id" "uuid") RETURNS TABLE("score" integer)
    LANGUAGE "sql"
    AS $$
  SELECT 0 as score;
$$;


ALTER FUNCTION "public"."get_payment_score"("team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_profit_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text" DEFAULT ''::"text") RETURNS TABLE("date" "date", "value" numeric, "recurring_value" numeric, "percentage" numeric)
    LANGUAGE "sql"
    AS $$
  WITH date_series AS (
    SELECT generate_series(
      date_from::date,
      date_to::date,
      '1 month'::interval
    )::date as date
  )
  SELECT 
    ds.date,
    0::numeric as value,
    0::numeric as recurring_value,
    0::numeric as percentage
  FROM date_series ds
  ORDER BY ds.date;
$$;


ALTER FUNCTION "public"."get_profit_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_revenue_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text" DEFAULT ''::"text") RETURNS TABLE("date" "date", "value" numeric, "recurring_value" numeric, "percentage" numeric)
    LANGUAGE "sql"
    AS $$
  WITH date_series AS (
    SELECT generate_series(
      date_from::date,
      date_to::date,
      '1 month'::interval
    )::date as date
  )
  SELECT 
    ds.date,
    0::numeric as value,
    0::numeric as recurring_value,
    0::numeric as percentage
  FROM date_series ds
  ORDER BY ds.date;
$$;


ALTER FUNCTION "public"."get_revenue_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_runway_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text" DEFAULT ''::"text") RETURNS TABLE("date" "date", "value" numeric, "recurring_value" numeric, "percentage" numeric)
    LANGUAGE "sql"
    AS $$
  WITH date_series AS (
    SELECT generate_series(
      date_from::date,
      date_to::date,
      '1 month'::interval
    )::date as date
  )
  SELECT 
    ds.date,
    0::numeric as value,
    0::numeric as recurring_value,
    0::numeric as percentage
  FROM date_series ds
  ORDER BY ds.date;
$$;


ALTER FUNCTION "public"."get_runway_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_spending_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text" DEFAULT ''::"text") RETURNS TABLE("date" "date", "value" numeric, "recurring_value" numeric, "percentage" numeric)
    LANGUAGE "sql"
    AS $$
  WITH date_series AS (
    SELECT generate_series(
      date_from::date,
      date_to::date,
      '1 month'::interval
    )::date as date
  )
  SELECT 
    ds.date,
    0::numeric as value,
    0::numeric as recurring_value, 
    0::numeric as percentage
  FROM date_series ds
  ORDER BY ds.date;
$$;


ALTER FUNCTION "public"."get_spending_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_team_bank_accounts_balances"("team_id" "uuid") RETURNS TABLE("balance" numeric, "currency" "text")
    LANGUAGE "sql"
    AS $$
  SELECT 0::numeric as balance, 'USD'::text as currency;
$$;


ALTER FUNCTION "public"."get_team_bank_accounts_balances"("team_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."api_keys" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key_encrypted" "text" NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "key_hash" "text",
    "scopes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "last_used_at" timestamp with time zone
);


ALTER TABLE "public"."api_keys" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."apps" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" DEFAULT "gen_random_uuid"(),
    "config" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "app_id" "text" NOT NULL,
    "created_by" "uuid" DEFAULT "gen_random_uuid"(),
    "settings" "jsonb"
);


ALTER TABLE "public"."apps" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bank_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "name" "text",
    "currency" "text",
    "bank_connection_id" "uuid",
    "enabled" boolean DEFAULT true NOT NULL,
    "account_id" "text" NOT NULL,
    "balance" numeric(10,2) DEFAULT 0,
    "manual" boolean DEFAULT false,
    "type" "public"."account_type",
    "base_currency" "text",
    "base_balance" numeric(10,2),
    "error_details" "text",
    "error_retries" smallint,
    "account_reference" "text"
);


ALTER TABLE "public"."bank_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bank_connections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "institution_id" "text" NOT NULL,
    "expires_at" timestamp with time zone,
    "team_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "logo_url" "text",
    "access_token" "text",
    "enrollment_id" "text",
    "provider" "public"."bank_providers" NOT NULL,
    "last_accessed" timestamp with time zone,
    "reference_id" "text",
    "status" "public"."connection_status" DEFAULT 'connected'::"public"."connection_status",
    "error_details" "text",
    "error_retries" smallint DEFAULT '0'::smallint
);


ALTER TABLE "public"."bank_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."customer_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "customer_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL
);


ALTER TABLE "public"."customer_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."customers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "billingEmail" "text",
    "country" "text",
    "address_line_1" "text",
    "address_line_2" "text",
    "city" "text",
    "state" "text",
    "zip" "text",
    "note" "text",
    "team_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "website" "text",
    "phone" "text",
    "vat_number" "text",
    "country_code" "text",
    "token" "text" DEFAULT ''::"text" NOT NULL,
    "contact" "text",
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"english"'::"regconfig", ((((((((((((((((((COALESCE("name", ''::"text") || ' '::"text") || COALESCE("contact", ''::"text")) || ' '::"text") || COALESCE("phone", ''::"text")) || ' '::"text") || COALESCE("email", ''::"text")) || ' '::"text") || COALESCE("address_line_1", ''::"text")) || ' '::"text") || COALESCE("address_line_2", ''::"text")) || ' '::"text") || COALESCE("city", ''::"text")) || ' '::"text") || COALESCE("state", ''::"text")) || ' '::"text") || COALESCE("zip", ''::"text")) || ' '::"text") || COALESCE("country", ''::"text")))) STORED NOT NULL
);


ALTER TABLE "public"."customers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."document_tag_assignments" (
    "document_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL
);


ALTER TABLE "public"."document_tag_assignments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."document_tag_embeddings" (
    "slug" "text" NOT NULL,
    "embedding" "public"."vector"(1024),
    "name" "text" NOT NULL
);


ALTER TABLE "public"."document_tag_embeddings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."document_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "team_id" "uuid" NOT NULL
);


ALTER TABLE "public"."document_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "metadata" "jsonb",
    "path_tokens" "text"[],
    "team_id" "uuid",
    "parent_id" "text",
    "object_id" "uuid",
    "owner_id" "uuid",
    "tag" "text",
    "title" "text",
    "body" "text",
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"english"'::"regconfig", (("title" || ' '::"text") || "body"))) STORED NOT NULL,
    "summary" "text",
    "content" "text",
    "date" "date",
    "language" "text",
    "processing_status" "public"."document_processing_status" DEFAULT 'pending'::"public"."document_processing_status",
    "fts_simple" "tsvector",
    "fts_english" "tsvector",
    "fts_language" "tsvector"
);


ALTER TABLE "public"."documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exchange_rates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "base" "text",
    "rate" numeric(10,2),
    "target" "text",
    "updated_at" timestamp with time zone
);


ALTER TABLE "public"."exchange_rates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inbox" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid",
    "file_path" "text"[],
    "file_name" "text",
    "transaction_id" "uuid",
    "amount" numeric(10,2),
    "currency" "text",
    "content_type" "text",
    "size" bigint,
    "attachment_id" "uuid",
    "date" "date",
    "forwarded_to" "text",
    "reference_id" "text",
    "meta" json,
    "status" "public"."inbox_status" DEFAULT 'new'::"public"."inbox_status",
    "website" "text",
    "display_name" "text",
    "fts" "tsvector" GENERATED ALWAYS AS ("public"."generate_inbox_fts"("display_name", "public"."extract_product_names"(("meta" -> 'products'::"text")))) STORED NOT NULL,
    "type" "public"."inbox_type",
    "description" "text",
    "base_amount" numeric(10,2),
    "base_currency" "text",
    "tax_amount" numeric(10,2),
    "tax_rate" numeric(10,2),
    "tax_type" "text"
);


ALTER TABLE "public"."inbox" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."inbox_accounts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "access_token" "text" NOT NULL,
    "refresh_token" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "last_accessed" timestamp with time zone NOT NULL,
    "provider" "public"."inbox_account_providers" NOT NULL,
    "external_id" "text" NOT NULL,
    "expiry_date" timestamp with time zone NOT NULL,
    "schedule_id" "text"
);


ALTER TABLE "public"."inbox_accounts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoice_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."invoice_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoice_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "customer_label" "text",
    "from_label" "text",
    "invoice_no_label" "text",
    "issue_date_label" "text",
    "due_date_label" "text",
    "description_label" "text",
    "price_label" "text",
    "quantity_label" "text",
    "total_label" "text",
    "vat_label" "text",
    "tax_label" "text",
    "payment_label" "text",
    "note_label" "text",
    "logo_url" "text",
    "currency" "text",
    "payment_details" "jsonb",
    "from_details" "jsonb",
    "size" "public"."invoice_size" DEFAULT 'a4'::"public"."invoice_size",
    "date_format" "text",
    "include_vat" boolean,
    "include_tax" boolean,
    "tax_rate" numeric(10,2),
    "delivery_type" "public"."invoice_delivery_type" DEFAULT 'create'::"public"."invoice_delivery_type" NOT NULL,
    "discount_label" "text",
    "include_discount" boolean,
    "include_decimals" boolean,
    "include_qr" boolean,
    "total_summary_label" "text",
    "title" "text",
    "vat_rate" numeric(10,2),
    "include_units" boolean,
    "subtotal_label" "text",
    "include_pdf" boolean,
    "send_copy" boolean
);


ALTER TABLE "public"."invoice_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."invoices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "due_date" timestamp with time zone,
    "invoice_number" "text",
    "customer_id" "uuid",
    "amount" numeric(10,2),
    "currency" "text",
    "line_items" "jsonb",
    "payment_details" "jsonb",
    "customer_details" "jsonb",
    "company_datails" "jsonb",
    "note" "text",
    "internal_note" "text",
    "team_id" "uuid" NOT NULL,
    "paid_at" timestamp with time zone,
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"english"'::"regconfig", ((COALESCE(("amount")::"text", ''::"text") || ' '::"text") || COALESCE("invoice_number", ''::"text")))) STORED NOT NULL,
    "vat" numeric(10,2),
    "tax" numeric(10,2),
    "url" "text",
    "file_path" "text"[],
    "status" "public"."invoice_status" DEFAULT 'draft'::"public"."invoice_status" NOT NULL,
    "viewed_at" timestamp with time zone,
    "from_details" "jsonb",
    "issue_date" timestamp with time zone,
    "template" "jsonb",
    "note_details" "jsonb",
    "customer_name" "text",
    "token" "text" DEFAULT ''::"text" NOT NULL,
    "sent_to" "text",
    "reminder_sent_at" timestamp with time zone,
    "discount" numeric(10,2),
    "file_size" bigint,
    "user_id" "uuid",
    "subtotal" numeric(10,2),
    "top_block" "jsonb",
    "bottom_block" "jsonb",
    "sent_at" timestamp with time zone,
    "scheduled_at" timestamp with time zone,
    "scheduled_job_id" "text"
);


ALTER TABLE "public"."invoices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oauth_access_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token" "text" NOT NULL,
    "refresh_token" "text",
    "application_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "scopes" "text"[] NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "refresh_token_expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_used_at" timestamp with time zone,
    "revoked" boolean DEFAULT false,
    "revoked_at" timestamp with time zone
);


ALTER TABLE "public"."oauth_access_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oauth_applications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "description" "text",
    "overview" "text",
    "developer_name" "text",
    "logo_url" "text",
    "website" "text",
    "install_url" "text",
    "screenshots" "text"[] DEFAULT '{}'::"text"[],
    "redirect_uris" "text"[] NOT NULL,
    "client_id" "text" NOT NULL,
    "client_secret" "text" NOT NULL,
    "scopes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "team_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_public" boolean DEFAULT false,
    "active" boolean DEFAULT true,
    "status" "text" DEFAULT 'draft'::"text"
);


ALTER TABLE "public"."oauth_applications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."oauth_authorization_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "application_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "scopes" "text"[] NOT NULL,
    "redirect_uri" "text" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "used" boolean DEFAULT false,
    "code_challenge" "text",
    "code_challenge_method" "text"
);


ALTER TABLE "public"."oauth_authorization_codes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "link_id" "text",
    "team_id" "uuid",
    "short_link" "text",
    "from" timestamp with time zone,
    "to" timestamp with time zone,
    "type" "public"."reportTypes",
    "expire_at" timestamp with time zone,
    "currency" "text",
    "created_by" "uuid"
);


ALTER TABLE "public"."reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."short_links" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "short_id" "text" NOT NULL,
    "url" "text" NOT NULL,
    "type" "text",
    "size" numeric(10,2),
    "mime_type" "text",
    "file_name" "text",
    "team_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."short_links" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "name" "text" NOT NULL
);


ALTER TABLE "public"."tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "logo_url" "text",
    "inbox_id" "text" DEFAULT 'generate_inbox(10)'::"text",
    "email" "text",
    "inbox_email" "text",
    "inbox_forwarding" boolean DEFAULT true,
    "base_currency" "text",
    "country_code" "text",
    "document_classification" boolean DEFAULT false,
    "flags" "text"[],
    "canceled_at" timestamp with time zone,
    "plan" "public"."plans" DEFAULT 'trial'::"public"."plans" NOT NULL
);


ALTER TABLE "public"."teams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tracker_entries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "duration" bigint,
    "project_id" "uuid",
    "start" timestamp with time zone,
    "stop" timestamp with time zone,
    "assigned_id" "uuid",
    "team_id" "uuid",
    "description" "text",
    "rate" numeric(10,2),
    "currency" "text",
    "billed" boolean DEFAULT false,
    "date" "date" DEFAULT "now"()
);


ALTER TABLE "public"."tracker_entries" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tracker_project_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "tracker_project_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL
);


ALTER TABLE "public"."tracker_project_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tracker_projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid",
    "rate" numeric(10,2),
    "currency" "text",
    "status" "public"."trackerStatus" DEFAULT 'in_progress'::"public"."trackerStatus" NOT NULL,
    "description" "text",
    "name" "text" NOT NULL,
    "billable" boolean DEFAULT false,
    "estimate" bigint,
    "customer_id" "uuid",
    "fts" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"english"'::"regconfig", ((COALESCE("name", ''::"text") || ' '::"text") || COALESCE("description", ''::"text")))) STORED NOT NULL
);


ALTER TABLE "public"."tracker_projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tracker_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "link_id" "text",
    "short_link" "text",
    "team_id" "uuid" DEFAULT "gen_random_uuid"(),
    "project_id" "uuid" DEFAULT "gen_random_uuid"(),
    "created_by" "uuid"
);


ALTER TABLE "public"."tracker_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transaction_attachments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "type" "text",
    "transaction_id" "uuid",
    "team_id" "uuid",
    "size" bigint,
    "name" "text",
    "path" "text"[]
);


ALTER TABLE "public"."transaction_attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transaction_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "color" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "system" boolean DEFAULT false,
    "slug" "text" NOT NULL,
    "tax_rate" numeric(10,2),
    "tax_type" "text",
    "description" "text",
    "embedding" "public"."vector"(384),
    "parent_id" "uuid"
);


ALTER TABLE "public"."transaction_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transaction_enrichments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "team_id" "uuid",
    "category_slug" "text",
    "system" boolean DEFAULT false
);


ALTER TABLE "public"."transaction_enrichments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transaction_tags" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL,
    "transaction_id" "uuid" NOT NULL
);


ALTER TABLE "public"."transaction_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."transactions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "date" "date" NOT NULL,
    "name" "text" NOT NULL,
    "method" "public"."transactionMethods" NOT NULL,
    "amount" numeric(10,2) NOT NULL,
    "currency" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "assigned_id" "uuid",
    "note" character varying,
    "bank_account_id" "uuid",
    "internal_id" "text" NOT NULL,
    "status" "public"."transactionStatus" DEFAULT 'posted'::"public"."transactionStatus",
    "category" "public"."transactionCategories",
    "balance" numeric(10,2),
    "manual" boolean DEFAULT false,
    "notified" boolean DEFAULT false,
    "internal" boolean DEFAULT false,
    "description" "text",
    "category_slug" "text",
    "baseAmount" numeric(10,2),
    "counterparty_name" "text",
    "base_currency" "text",
    "taxRate" numeric(10,2),
    "tax_type" "text",
    "recurring" boolean,
    "frequency" "public"."transaction_frequency",
    "fts_vector" "tsvector" GENERATED ALWAYS AS ("to_tsvector"('"english"'::"regconfig", ((COALESCE("name", ''::"text") || ' '::"text") || COALESCE("description", ''::"text")))) STORED NOT NULL,
    "tax_rate" numeric,
    "base_amount" numeric
);


ALTER TABLE "public"."transactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid",
    "email" "text",
    "role" "public"."teamRoles",
    "code" "text" DEFAULT 'nanoid(24)'::"text",
    "invited_by" "uuid"
);


ALTER TABLE "public"."user_invites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "avatar_url" "text",
    "email" "text",
    "team_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "locale" "text" DEFAULT 'en'::"text",
    "week_starts_on_monday" boolean DEFAULT false,
    "timezone" "text",
    "timezone_auto_sync" boolean DEFAULT true,
    "time_format" numeric DEFAULT 24,
    "date_format" "text"
);


ALTER TABLE "public"."users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users_on_team" (
    "user_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "role" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."users_on_team" OWNER TO "postgres";


ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_key_unique" UNIQUE ("key_hash");



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."apps"
    ADD CONSTRAINT "apps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bank_accounts"
    ADD CONSTRAINT "bank_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bank_connections"
    ADD CONSTRAINT "bank_connections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customer_tags"
    ADD CONSTRAINT "customer_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."document_tag_assignments"
    ADD CONSTRAINT "document_tag_assignments_pkey" PRIMARY KEY ("document_id", "tag_id");



ALTER TABLE ONLY "public"."document_tag_embeddings"
    ADD CONSTRAINT "document_tag_embeddings_pkey" PRIMARY KEY ("slug");



ALTER TABLE ONLY "public"."document_tags"
    ADD CONSTRAINT "document_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exchange_rates"
    ADD CONSTRAINT "exchange_rates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inbox_accounts"
    ADD CONSTRAINT "inbox_accounts_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."inbox_accounts"
    ADD CONSTRAINT "inbox_accounts_external_id_key" UNIQUE ("external_id");



ALTER TABLE ONLY "public"."inbox_accounts"
    ADD CONSTRAINT "inbox_accounts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inbox"
    ADD CONSTRAINT "inbox_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."inbox"
    ADD CONSTRAINT "inbox_reference_id_key" UNIQUE ("reference_id");



ALTER TABLE ONLY "public"."invoice_comments"
    ADD CONSTRAINT "invoice_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoice_templates"
    ADD CONSTRAINT "invoice_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoice_templates"
    ADD CONSTRAINT "invoice_templates_team_id_key" UNIQUE ("team_id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_scheduled_job_id_key" UNIQUE ("scheduled_job_id");



ALTER TABLE ONLY "public"."oauth_access_tokens"
    ADD CONSTRAINT "oauth_access_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oauth_access_tokens"
    ADD CONSTRAINT "oauth_access_tokens_refresh_token_unique" UNIQUE ("refresh_token");



ALTER TABLE ONLY "public"."oauth_access_tokens"
    ADD CONSTRAINT "oauth_access_tokens_token_unique" UNIQUE ("token");



ALTER TABLE ONLY "public"."oauth_applications"
    ADD CONSTRAINT "oauth_applications_client_id_unique" UNIQUE ("client_id");



ALTER TABLE ONLY "public"."oauth_applications"
    ADD CONSTRAINT "oauth_applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."oauth_applications"
    ADD CONSTRAINT "oauth_applications_slug_unique" UNIQUE ("slug");



ALTER TABLE ONLY "public"."oauth_authorization_codes"
    ADD CONSTRAINT "oauth_authorization_codes_code_unique" UNIQUE ("code");



ALTER TABLE ONLY "public"."oauth_authorization_codes"
    ADD CONSTRAINT "oauth_authorization_codes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reports"
    ADD CONSTRAINT "reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."short_links"
    ADD CONSTRAINT "short_links_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."short_links"
    ADD CONSTRAINT "short_links_short_id_unique" UNIQUE ("short_id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_inbox_id_key" UNIQUE ("inbox_id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tracker_entries"
    ADD CONSTRAINT "tracker_entries_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tracker_project_tags"
    ADD CONSTRAINT "tracker_project_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tracker_projects"
    ADD CONSTRAINT "tracker_projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tracker_reports"
    ADD CONSTRAINT "tracker_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transaction_attachments"
    ADD CONSTRAINT "transaction_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transaction_categories"
    ADD CONSTRAINT "transaction_categories_pkey" PRIMARY KEY ("team_id", "slug");



ALTER TABLE ONLY "public"."transaction_enrichments"
    ADD CONSTRAINT "transaction_enrichments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transaction_tags"
    ADD CONSTRAINT "transaction_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_internal_id_key" UNIQUE ("internal_id");



ALTER TABLE ONLY "public"."transactions"
    ADD CONSTRAINT "transactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."apps"
    ADD CONSTRAINT "unique_app_id_team_id" UNIQUE ("team_id", "app_id");



ALTER TABLE ONLY "public"."bank_connections"
    ADD CONSTRAINT "unique_bank_connections" UNIQUE ("institution_id", "team_id");



ALTER TABLE ONLY "public"."customer_tags"
    ADD CONSTRAINT "unique_customer_tag" UNIQUE ("customer_id", "tag_id");



ALTER TABLE ONLY "public"."tracker_project_tags"
    ADD CONSTRAINT "unique_project_tag" UNIQUE ("tracker_project_id", "tag_id");



ALTER TABLE ONLY "public"."exchange_rates"
    ADD CONSTRAINT "unique_rate" UNIQUE ("base", "target");



ALTER TABLE ONLY "public"."document_tags"
    ADD CONSTRAINT "unique_slug_per_team" UNIQUE ("slug", "team_id");



ALTER TABLE ONLY "public"."transaction_tags"
    ADD CONSTRAINT "unique_tag" UNIQUE ("tag_id", "transaction_id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "unique_tag_name" UNIQUE ("team_id", "name");



ALTER TABLE ONLY "public"."user_invites"
    ADD CONSTRAINT "unique_team_invite" UNIQUE ("team_id", "email");



ALTER TABLE ONLY "public"."transaction_enrichments"
    ADD CONSTRAINT "unique_team_name" UNIQUE ("name", "team_id");



ALTER TABLE ONLY "public"."user_invites"
    ADD CONSTRAINT "user_invites_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."user_invites"
    ADD CONSTRAINT "user_invites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."users_on_team"
    ADD CONSTRAINT "users_on_team_pkey" PRIMARY KEY ("user_id", "team_id", "id");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "users_on_team_team_id_idx" ON "public"."users_on_team" USING "btree" ("team_id");



CREATE INDEX "users_on_team_user_id_idx" ON "public"."users_on_team" USING "btree" ("user_id");



ALTER TABLE ONLY "public"."users_on_team"
    ADD CONSTRAINT "users_on_team_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."users_on_team"
    ADD CONSTRAINT "users_on_team_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow file uploads" ON "public"."documents" FOR INSERT WITH CHECK (true);



CREATE POLICY "Service role can access all users" ON "public"."users" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Users can insert own profile" ON "public"."users" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own profile" ON "public"."users" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Users can view own profile" ON "public"."users" FOR SELECT USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."apps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bank_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bank_connections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."customer_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."document_tag_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."document_tag_embeddings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."document_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."exchange_rates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inbox" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."inbox_accounts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invoice_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."invoices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."oauth_applications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."short_links" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tracker_entries" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tracker_project_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tracker_projects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tracker_reports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transaction_attachments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transaction_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transaction_enrichments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transaction_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."transactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_invites" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."extract_product_names"("products_json" json) TO "anon";
GRANT ALL ON FUNCTION "public"."extract_product_names"("products_json" json) TO "authenticated";
GRANT ALL ON FUNCTION "public"."extract_product_names"("products_json" json) TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_inbox"("count_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."generate_inbox"("count_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_inbox"("count_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_inbox_fts"("display_name" "text", "product_names" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_inbox_fts"("display_name" "text", "product_names" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_inbox_fts"("display_name" "text", "product_names" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_bank_account_currencies"("team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_bank_account_currencies"("team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_bank_account_currencies"("team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_burn_rate_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_burn_rate_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_burn_rate_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_expenses"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_expenses"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_expenses"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_next_invoice_number"("team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_invoice_number"("team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_invoice_number"("team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_payment_score"("team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_payment_score"("team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_payment_score"("team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_profit_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_profit_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_profit_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_revenue_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_revenue_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_revenue_v3"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_runway_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_runway_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_runway_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_spending_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_spending_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_spending_v4"("team_id" "uuid", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "currency" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_team_bank_accounts_balances"("team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_team_bank_accounts_balances"("team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_team_bank_accounts_balances"("team_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON TABLE "public"."api_keys" TO "anon";
GRANT ALL ON TABLE "public"."api_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."api_keys" TO "service_role";



GRANT ALL ON TABLE "public"."apps" TO "anon";
GRANT ALL ON TABLE "public"."apps" TO "authenticated";
GRANT ALL ON TABLE "public"."apps" TO "service_role";



GRANT ALL ON TABLE "public"."bank_accounts" TO "anon";
GRANT ALL ON TABLE "public"."bank_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."bank_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."bank_connections" TO "anon";
GRANT ALL ON TABLE "public"."bank_connections" TO "authenticated";
GRANT ALL ON TABLE "public"."bank_connections" TO "service_role";



GRANT ALL ON TABLE "public"."customer_tags" TO "anon";
GRANT ALL ON TABLE "public"."customer_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."customer_tags" TO "service_role";



GRANT ALL ON TABLE "public"."customers" TO "anon";
GRANT ALL ON TABLE "public"."customers" TO "authenticated";
GRANT ALL ON TABLE "public"."customers" TO "service_role";



GRANT ALL ON TABLE "public"."document_tag_assignments" TO "anon";
GRANT ALL ON TABLE "public"."document_tag_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."document_tag_assignments" TO "service_role";



GRANT ALL ON TABLE "public"."document_tag_embeddings" TO "anon";
GRANT ALL ON TABLE "public"."document_tag_embeddings" TO "authenticated";
GRANT ALL ON TABLE "public"."document_tag_embeddings" TO "service_role";



GRANT ALL ON TABLE "public"."document_tags" TO "anon";
GRANT ALL ON TABLE "public"."document_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."document_tags" TO "service_role";



GRANT ALL ON TABLE "public"."documents" TO "anon";
GRANT ALL ON TABLE "public"."documents" TO "authenticated";
GRANT ALL ON TABLE "public"."documents" TO "service_role";



GRANT ALL ON TABLE "public"."exchange_rates" TO "anon";
GRANT ALL ON TABLE "public"."exchange_rates" TO "authenticated";
GRANT ALL ON TABLE "public"."exchange_rates" TO "service_role";



GRANT ALL ON TABLE "public"."inbox" TO "anon";
GRANT ALL ON TABLE "public"."inbox" TO "authenticated";
GRANT ALL ON TABLE "public"."inbox" TO "service_role";



GRANT ALL ON TABLE "public"."inbox_accounts" TO "anon";
GRANT ALL ON TABLE "public"."inbox_accounts" TO "authenticated";
GRANT ALL ON TABLE "public"."inbox_accounts" TO "service_role";



GRANT ALL ON TABLE "public"."invoice_comments" TO "anon";
GRANT ALL ON TABLE "public"."invoice_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."invoice_comments" TO "service_role";



GRANT ALL ON TABLE "public"."invoice_templates" TO "anon";
GRANT ALL ON TABLE "public"."invoice_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."invoice_templates" TO "service_role";



GRANT ALL ON TABLE "public"."invoices" TO "anon";
GRANT ALL ON TABLE "public"."invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."invoices" TO "service_role";



GRANT ALL ON TABLE "public"."oauth_access_tokens" TO "anon";
GRANT ALL ON TABLE "public"."oauth_access_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."oauth_access_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."oauth_applications" TO "anon";
GRANT ALL ON TABLE "public"."oauth_applications" TO "authenticated";
GRANT ALL ON TABLE "public"."oauth_applications" TO "service_role";



GRANT ALL ON TABLE "public"."oauth_authorization_codes" TO "anon";
GRANT ALL ON TABLE "public"."oauth_authorization_codes" TO "authenticated";
GRANT ALL ON TABLE "public"."oauth_authorization_codes" TO "service_role";



GRANT ALL ON TABLE "public"."reports" TO "anon";
GRANT ALL ON TABLE "public"."reports" TO "authenticated";
GRANT ALL ON TABLE "public"."reports" TO "service_role";



GRANT ALL ON TABLE "public"."short_links" TO "anon";
GRANT ALL ON TABLE "public"."short_links" TO "authenticated";
GRANT ALL ON TABLE "public"."short_links" TO "service_role";



GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";



GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";



GRANT ALL ON TABLE "public"."tracker_entries" TO "anon";
GRANT ALL ON TABLE "public"."tracker_entries" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_entries" TO "service_role";



GRANT ALL ON TABLE "public"."tracker_project_tags" TO "anon";
GRANT ALL ON TABLE "public"."tracker_project_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_project_tags" TO "service_role";



GRANT ALL ON TABLE "public"."tracker_projects" TO "anon";
GRANT ALL ON TABLE "public"."tracker_projects" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_projects" TO "service_role";



GRANT ALL ON TABLE "public"."tracker_reports" TO "anon";
GRANT ALL ON TABLE "public"."tracker_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."tracker_reports" TO "service_role";



GRANT ALL ON TABLE "public"."transaction_attachments" TO "anon";
GRANT ALL ON TABLE "public"."transaction_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."transaction_attachments" TO "service_role";



GRANT ALL ON TABLE "public"."transaction_categories" TO "anon";
GRANT ALL ON TABLE "public"."transaction_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."transaction_categories" TO "service_role";



GRANT ALL ON TABLE "public"."transaction_enrichments" TO "anon";
GRANT ALL ON TABLE "public"."transaction_enrichments" TO "authenticated";
GRANT ALL ON TABLE "public"."transaction_enrichments" TO "service_role";



GRANT ALL ON TABLE "public"."transaction_tags" TO "anon";
GRANT ALL ON TABLE "public"."transaction_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."transaction_tags" TO "service_role";



GRANT ALL ON TABLE "public"."transactions" TO "anon";
GRANT ALL ON TABLE "public"."transactions" TO "authenticated";
GRANT ALL ON TABLE "public"."transactions" TO "service_role";



GRANT ALL ON TABLE "public"."user_invites" TO "anon";
GRANT ALL ON TABLE "public"."user_invites" TO "authenticated";
GRANT ALL ON TABLE "public"."user_invites" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";



GRANT ALL ON TABLE "public"."users_on_team" TO "anon";
GRANT ALL ON TABLE "public"."users_on_team" TO "authenticated";
GRANT ALL ON TABLE "public"."users_on_team" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






RESET ALL;
