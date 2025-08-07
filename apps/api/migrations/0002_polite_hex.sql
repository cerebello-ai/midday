ALTER TYPE "public"."invoice_status" ADD VALUE 'scheduled';--> statement-breakpoint
CREATE TABLE "api_keys" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"key_encrypted" text NOT NULL,
	"name" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"user_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"key_hash" text,
	"scopes" text[] DEFAULT '{}'::text[] NOT NULL,
	"last_used_at" timestamp with time zone,
	CONSTRAINT "api_keys_key_unique" UNIQUE("key_hash")
);
--> statement-breakpoint
CREATE TABLE "oauth_access_tokens" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"token" text NOT NULL,
	"refresh_token" text,
	"application_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"scopes" text[] NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"refresh_token_expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_used_at" timestamp with time zone,
	"revoked" boolean DEFAULT false,
	"revoked_at" timestamp with time zone,
	CONSTRAINT "oauth_access_tokens_token_unique" UNIQUE("token"),
	CONSTRAINT "oauth_access_tokens_refresh_token_unique" UNIQUE("refresh_token")
);
--> statement-breakpoint
CREATE TABLE "oauth_applications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	"slug" text NOT NULL,
	"description" text,
	"overview" text,
	"developer_name" text,
	"logo_url" text,
	"website" text,
	"install_url" text,
	"screenshots" text[] DEFAULT '{}'::text[],
	"redirect_uris" text[] NOT NULL,
	"client_id" text NOT NULL,
	"client_secret" text NOT NULL,
	"scopes" text[] DEFAULT '{}'::text[] NOT NULL,
	"team_id" uuid NOT NULL,
	"created_by" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"is_public" boolean DEFAULT false,
	"active" boolean DEFAULT true,
	"status" text DEFAULT 'draft',
	CONSTRAINT "oauth_applications_slug_unique" UNIQUE("slug"),
	CONSTRAINT "oauth_applications_client_id_unique" UNIQUE("client_id")
);
--> statement-breakpoint
ALTER TABLE "oauth_applications" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "oauth_authorization_codes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" text NOT NULL,
	"application_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"team_id" uuid NOT NULL,
	"scopes" text[] NOT NULL,
	"redirect_uri" text NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"used" boolean DEFAULT false,
	"code_challenge" text,
	"code_challenge_method" text,
	CONSTRAINT "oauth_authorization_codes_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "short_links" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"short_id" text NOT NULL,
	"url" text NOT NULL,
	"type" text,
	"size" numeric(10, 2),
	"mime_type" text,
	"file_name" text,
	"team_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "short_links_short_id_unique" UNIQUE("short_id")
);
--> statement-breakpoint
ALTER TABLE "short_links" ENABLE ROW LEVEL SECURITY;--> statement-breakpoint
CREATE TABLE "auth.users" (
	"instance_id" uuid,
	"id" uuid NOT NULL,
	"aud" varchar(255),
	"role" varchar(255),
	"email" varchar(255),
	"encrypted_password" varchar(255),
	"email_confirmed_at" timestamp with time zone,
	"invited_at" timestamp with time zone,
	"confirmation_token" varchar(255),
	"confirmation_sent_at" timestamp with time zone,
	"recovery_token" varchar(255),
	"recovery_sent_at" timestamp with time zone,
	"email_change_token_new" varchar(255),
	"email_change" varchar(255),
	"email_change_sent_at" timestamp with time zone,
	"last_sign_in_at" timestamp with time zone,
	"raw_app_meta_data" jsonb,
	"raw_user_meta_data" jsonb,
	"is_super_admin" boolean,
	"created_at" timestamp with time zone,
	"updated_at" timestamp with time zone,
	"phone" text DEFAULT null::character varying,
	"phone_confirmed_at" timestamp with time zone,
	"phone_change" text DEFAULT ''::character varying,
	"phone_change_token" varchar(255) DEFAULT ''::character varying,
	"phone_change_sent_at" timestamp with time zone,
	"confirmed_at" timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
	"email_change_token_current" varchar(255) DEFAULT ''::character varying,
	"email_change_confirm_status" smallint DEFAULT 0,
	"banned_until" timestamp with time zone,
	"reauthentication_token" varchar(255) DEFAULT ''::character varying,
	"reauthentication_sent_at" timestamp with time zone,
	"is_sso_user" boolean DEFAULT false NOT NULL,
	"deleted_at" timestamp with time zone,
	"is_anonymous" boolean DEFAULT false NOT NULL,
	CONSTRAINT "users_pkey" PRIMARY KEY("id"),
	CONSTRAINT "users_phone_key" UNIQUE("phone"),
	CONSTRAINT "confirmation_token_idx" UNIQUE("confirmation_token"),
	CONSTRAINT "email_change_token_current_idx" UNIQUE("email_change_token_current"),
	CONSTRAINT "email_change_token_new_idx" UNIQUE("email_change_token_new"),
	CONSTRAINT "reauthentication_token_idx" UNIQUE("reauthentication_token"),
	CONSTRAINT "recovery_token_idx" UNIQUE("recovery_token"),
	CONSTRAINT "users_email_partial_key" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "invoice_comments" DISABLE ROW LEVEL SECURITY;--> statement-breakpoint
ALTER TABLE "transactions" RENAME COLUMN "base_amount" TO "baseAmount";--> statement-breakpoint
ALTER TABLE "bank_accounts" RENAME COLUMN "base_balance" TO "baseBalance";--> statement-breakpoint
ALTER TABLE "transaction_categories" RENAME COLUMN "vat" TO "tax_rate";--> statement-breakpoint
ALTER TABLE "users" DROP CONSTRAINT "users_id_fkey";
--> statement-breakpoint
ALTER TABLE "bank_connections" ALTER COLUMN "provider" SET DATA TYPE text;--> statement-breakpoint
DROP TYPE "public"."bank_providers";--> statement-breakpoint
CREATE TYPE "public"."bank_providers" AS ENUM('gocardless', 'plaid', 'teller', 'enablebanking');--> statement-breakpoint
ALTER TABLE "bank_connections" ALTER COLUMN "provider" SET DATA TYPE "public"."bank_providers" USING "provider"::"public"."bank_providers";--> statement-breakpoint
ALTER TABLE "transactions" ALTER COLUMN "amount" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "transactions" ALTER COLUMN "balance" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "transactions" ALTER COLUMN "fts_vector" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "transactions" drop column "fts_vector";--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "fts_vector" "tsvector" GENERATED ALWAYS AS (
				to_tsvector(
					'english',
					(
						(COALESCE(name, ''::text) || ' '::text) || COALESCE(description, ''::text)
					)
				)
			) STORED NOT NULL;--> statement-breakpoint
ALTER TABLE "tracker_entries" ALTER COLUMN "rate" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "bank_accounts" ALTER COLUMN "balance" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "invoices" ALTER COLUMN "amount" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "invoices" ALTER COLUMN "fts" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "invoices" drop column "fts";--> statement-breakpoint
ALTER TABLE "invoices" ADD COLUMN "fts" "tsvector" GENERATED ALWAYS AS (
        to_tsvector(
          'english',
          (
            (COALESCE((amount)::text, ''::text) || ' '::text) || COALESCE(invoice_number, ''::text)
          )
        )
      ) STORED NOT NULL;--> statement-breakpoint
ALTER TABLE "invoices" ALTER COLUMN "vat" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "invoices" ALTER COLUMN "tax" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "invoices" ALTER COLUMN "discount" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "invoices" ALTER COLUMN "subtotal" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "customers" ALTER COLUMN "fts" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "customers" drop column "fts";--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "fts" "tsvector" GENERATED ALWAYS AS (
				to_tsvector(
					'english'::regconfig,
					COALESCE(name, ''::text) || ' ' ||
					COALESCE(contact, ''::text) || ' ' ||
					COALESCE(phone, ''::text) || ' ' ||
					COALESCE(email, ''::text) || ' ' ||
					COALESCE(address_line_1, ''::text) || ' ' ||
					COALESCE(address_line_2, ''::text) || ' ' ||
					COALESCE(city, ''::text) || ' ' ||
					COALESCE(state, ''::text) || ' ' ||
					COALESCE(zip, ''::text) || ' ' ||
					COALESCE(country, ''::text)
				)
			) STORED NOT NULL;--> statement-breakpoint
ALTER TABLE "exchange_rates" ALTER COLUMN "rate" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "bank_connections" ALTER COLUMN "provider" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "user_invites" ALTER COLUMN "code" SET DEFAULT 'nanoid(24)';--> statement-breakpoint
ALTER TABLE "teams" ALTER COLUMN "inbox_id" SET DEFAULT 'generate_inbox(10)';--> statement-breakpoint
ALTER TABLE "documents" ALTER COLUMN "fts" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "invoice_templates" ALTER COLUMN "tax_rate" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "invoice_templates" ALTER COLUMN "vat_rate" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "users" ALTER COLUMN "time_format" SET DEFAULT 24;--> statement-breakpoint
ALTER TABLE "tracker_projects" ALTER COLUMN "rate" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "tracker_projects" ALTER COLUMN "fts" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "tracker_projects" drop column "fts";--> statement-breakpoint
ALTER TABLE "tracker_projects" ADD COLUMN "fts" "tsvector" GENERATED ALWAYS AS (
          to_tsvector(
            'english'::regconfig,
            (
              (COALESCE(name, ''::text) || ' '::text) || COALESCE(description, ''::text)
            )
          )
        ) STORED NOT NULL;--> statement-breakpoint
ALTER TABLE "inbox" ALTER COLUMN "amount" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "inbox" ALTER COLUMN "fts" SET NOT NULL;--> statement-breakpoint
ALTER TABLE "inbox" ALTER COLUMN "base_amount" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "inbox" ALTER COLUMN "tax_amount" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "inbox" ALTER COLUMN "tax_rate" SET DATA TYPE numeric(10, 2);--> statement-breakpoint
ALTER TABLE "transaction_categories" ALTER COLUMN "team_id" DROP DEFAULT;--> statement-breakpoint
ALTER TABLE "transaction_categories" ALTER COLUMN "slug" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "counterparty_name" text;--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "taxRate" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "transactions" ADD COLUMN "tax_type" text;--> statement-breakpoint
ALTER TABLE "customers" ADD COLUMN "billingEmail" text;--> statement-breakpoint
ALTER TABLE "teams" ADD COLUMN "country_code" text;--> statement-breakpoint
ALTER TABLE "invoice_templates" ADD COLUMN "send_copy" boolean;--> statement-breakpoint
ALTER TABLE "users" ADD COLUMN "timezone_auto_sync" boolean DEFAULT true;--> statement-breakpoint
ALTER TABLE "transaction_categories" ADD COLUMN "tax_type" text;--> statement-breakpoint
ALTER TABLE "transaction_categories" ADD COLUMN "parent_id" uuid;--> statement-breakpoint
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "api_keys" ADD CONSTRAINT "api_keys_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."oauth_applications"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_access_tokens" ADD CONSTRAINT "oauth_access_tokens_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_applications" ADD CONSTRAINT "oauth_applications_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_applications" ADD CONSTRAINT "oauth_applications_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_authorization_codes" ADD CONSTRAINT "oauth_authorization_codes_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."oauth_applications"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_authorization_codes" ADD CONSTRAINT "oauth_authorization_codes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "oauth_authorization_codes" ADD CONSTRAINT "oauth_authorization_codes_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "short_links" ADD CONSTRAINT "short_links_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "short_links" ADD CONSTRAINT "short_links_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "api_keys_key_idx" ON "api_keys" USING btree ("key_hash" text_ops);--> statement-breakpoint
CREATE INDEX "api_keys_user_id_idx" ON "api_keys" USING btree ("user_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "api_keys_team_id_idx" ON "api_keys" USING btree ("team_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "oauth_access_tokens_token_idx" ON "oauth_access_tokens" USING btree ("token" text_ops);--> statement-breakpoint
CREATE INDEX "oauth_access_tokens_refresh_token_idx" ON "oauth_access_tokens" USING btree ("refresh_token" text_ops);--> statement-breakpoint
CREATE INDEX "oauth_access_tokens_application_id_idx" ON "oauth_access_tokens" USING btree ("application_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "oauth_access_tokens_user_id_idx" ON "oauth_access_tokens" USING btree ("user_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "oauth_applications_team_id_idx" ON "oauth_applications" USING btree ("team_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "oauth_applications_client_id_idx" ON "oauth_applications" USING btree ("client_id" text_ops);--> statement-breakpoint
CREATE INDEX "oauth_applications_slug_idx" ON "oauth_applications" USING btree ("slug" text_ops);--> statement-breakpoint
CREATE INDEX "oauth_authorization_codes_code_idx" ON "oauth_authorization_codes" USING btree ("code" text_ops);--> statement-breakpoint
CREATE INDEX "oauth_authorization_codes_application_id_idx" ON "oauth_authorization_codes" USING btree ("application_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "oauth_authorization_codes_user_id_idx" ON "oauth_authorization_codes" USING btree ("user_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "short_links_short_id_idx" ON "short_links" USING btree ("short_id" text_ops);--> statement-breakpoint
CREATE INDEX "short_links_team_id_idx" ON "short_links" USING btree ("team_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "short_links_user_id_idx" ON "short_links" USING btree ("user_id" uuid_ops);--> statement-breakpoint
CREATE INDEX "users_instance_id_email_idx" ON "auth.users" USING btree ("instance_id",lower((email)::text));--> statement-breakpoint
CREATE INDEX "users_instance_id_idx" ON "auth.users" USING btree ("instance_id");--> statement-breakpoint
CREATE INDEX "users_is_anonymous_idx" ON "auth.users" USING btree ("is_anonymous");--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_categories" ADD CONSTRAINT "transaction_categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "public"."transaction_categories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "transaction_categories_parent_id_idx" ON "transaction_categories" USING btree ("parent_id" uuid_ops);--> statement-breakpoint
CREATE POLICY "OAuth applications can be managed by team members" ON "oauth_applications" AS PERMISSIVE FOR ALL TO public USING ((team_id IN ( SELECT private.get_teams_for_authenticated_user() AS get_teams_for_authenticated_user)));--> statement-breakpoint
CREATE POLICY "Short links can be created by a member of the team" ON "short_links" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((team_id IN ( SELECT private.get_teams_for_authenticated_user() AS get_teams_for_authenticated_user)));--> statement-breakpoint
CREATE POLICY "Short links can be selected by a member of the team" ON "short_links" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((team_id IN ( SELECT private.get_teams_for_authenticated_user() AS get_teams_for_authenticated_user)));--> statement-breakpoint
CREATE POLICY "Short links can be updated by a member of the team" ON "short_links" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((team_id IN ( SELECT private.get_teams_for_authenticated_user() AS get_teams_for_authenticated_user)));--> statement-breakpoint
CREATE POLICY "Short links can be deleted by a member of the team" ON "short_links" AS PERMISSIVE FOR DELETE TO "authenticated" USING ((team_id IN ( SELECT private.get_teams_for_authenticated_user() AS get_teams_for_authenticated_user)));--> statement-breakpoint
DROP TYPE "public"."bankProviders";