import { pgTable, unique, uuid, text, timestamp, jsonb, boolean, numeric, smallint, vector, date, bigint, json, varchar, pgPolicy, primaryKey, pgEnum } from "drizzle-orm/pg-core"
import { sql } from "drizzle-orm"

export const accountType = pgEnum("account_type", ['depository', 'credit', 'other_asset', 'loan', 'other_liability'])
export const bankProviders = pgEnum("bank_providers", ['gocardless', 'plaid', 'teller', 'enablebanking'])
export const connectionStatus = pgEnum("connection_status", ['disconnected', 'connected', 'unknown'])
export const documentProcessingStatus = pgEnum("document_processing_status", ['pending', 'processing', 'completed', 'failed'])
export const inboxAccountProviders = pgEnum("inbox_account_providers", ['gmail', 'outlook'])
export const inboxStatus = pgEnum("inbox_status", ['processing', 'pending', 'archived', 'new', 'deleted', 'done'])
export const inboxType = pgEnum("inbox_type", ['invoice', 'expense'])
export const invoiceDeliveryType = pgEnum("invoice_delivery_type", ['create', 'create_and_send', 'scheduled'])
export const invoiceSize = pgEnum("invoice_size", ['a4', 'letter'])
export const invoiceStatus = pgEnum("invoice_status", ['draft', 'overdue', 'paid', 'unpaid', 'canceled', 'scheduled'])
export const plans = pgEnum("plans", ['trial', 'starter', 'pro'])
export const reportTypes = pgEnum("reportTypes", ['profit', 'revenue', 'burn_rate', 'expense'])
export const teamRoles = pgEnum("teamRoles", ['owner', 'member'])
export const trackerStatus = pgEnum("trackerStatus", ['in_progress', 'completed'])
export const transactionCategories = pgEnum("transactionCategories", ['travel', 'office_supplies', 'meals', 'software', 'rent', 'income', 'equipment', 'transfer', 'internet_and_telephone', 'facilities_expenses', 'activity', 'uncategorized', 'taxes', 'other', 'salary', 'fees'])
export const transactionMethods = pgEnum("transactionMethods", ['payment', 'card_purchase', 'card_atm', 'transfer', 'other', 'unknown', 'ach', 'interest', 'deposit', 'wire', 'fee'])
export const transactionStatus = pgEnum("transactionStatus", ['posted', 'pending', 'excluded', 'completed', 'archived'])
export const transactionFrequency = pgEnum("transaction_frequency", ['weekly', 'biweekly', 'monthly', 'semi_monthly', 'annually', 'irregular', 'unknown'])


export const apiKeys = pgTable("api_keys", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	keyEncrypted: text("key_encrypted").notNull(),
	name: text().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	userId: uuid("user_id").notNull(),
	teamId: uuid("team_id").notNull(),
	keyHash: text("key_hash"),
	scopes: text().array().default([""]).notNull(),
	lastUsedAt: timestamp("last_used_at", { withTimezone: true, mode: 'string' }),
}, (table) => [
	unique("api_keys_key_unique").on(table.keyHash),
]);

export const apps = pgTable("apps", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	teamId: uuid("team_id").defaultRandom(),
	config: jsonb(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	appId: text("app_id").notNull(),
	createdBy: uuid("created_by").defaultRandom(),
	settings: jsonb(),
}, (table) => [
	unique("unique_app_id_team_id").on(table.teamId, table.appId),
]);

export const bankAccounts = pgTable("bank_accounts", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	createdBy: uuid("created_by").notNull(),
	teamId: uuid("team_id").notNull(),
	name: text(),
	currency: text(),
	bankConnectionId: uuid("bank_connection_id"),
	enabled: boolean().default(true).notNull(),
	accountId: text("account_id").notNull(),
	balance: numeric({ precision: 10, scale:  2 }).default('0'),
	manual: boolean().default(false),
	type: accountType(),
	baseCurrency: text("base_currency"),
	baseBalance: numeric({ precision: 10, scale:  2 }),
	errorDetails: text("error_details"),
	errorRetries: smallint("error_retries"),
	accountReference: text("account_reference"),
});

export const bankConnections = pgTable("bank_connections", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	institutionId: text("institution_id").notNull(),
	expiresAt: timestamp("expires_at", { withTimezone: true, mode: 'string' }),
	teamId: uuid("team_id").notNull(),
	name: text().notNull(),
	logoUrl: text("logo_url"),
	accessToken: text("access_token"),
	enrollmentId: text("enrollment_id"),
	provider: bankProviders().notNull(),
	lastAccessed: timestamp("last_accessed", { withTimezone: true, mode: 'string' }),
	referenceId: text("reference_id"),
	status: connectionStatus().default('connected'),
	errorDetails: text("error_details"),
	errorRetries: smallint("error_retries").default(sql`'0'`),
}, (table) => [
	unique("unique_bank_connections").on(table.institutionId, table.teamId),
]);

export const customerTags = pgTable("customer_tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	customerId: uuid("customer_id").notNull(),
	teamId: uuid("team_id").notNull(),
	tagId: uuid("tag_id").notNull(),
}, (table) => [
	unique("unique_customer_tag").on(table.customerId, table.tagId),
]);

export const customers = pgTable("customers", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	name: text().notNull(),
	email: text().notNull(),
	billingEmail: text(),
	country: text(),
	addressLine1: text("address_line_1"),
	addressLine2: text("address_line_2"),
	city: text(),
	state: text(),
	zip: text(),
	note: text(),
	teamId: uuid("team_id").defaultRandom().notNull(),
	website: text(),
	phone: text(),
	vatNumber: text("vat_number"),
	countryCode: text("country_code"),
	token: text().default(').notNull(),
	contact: text(),
	// TODO: failed to parse database type 'tsvector'
	fts: unknown("fts").notNull().generatedAlwaysAs(sql`to_tsvector('english'::regconfig, ((((((((((((((((((COALESCE(name, ''::text) || ' '::text) || COALESCE(contact, ''::text)) || ' '::text) || COALESCE(phone, ''::text)) || ' '::text) || COALESCE(email, ''::text)) || ' '::text) || COALESCE(address_line_1, ''::text)) || ' '::text) || COALESCE(address_line_2, ''::text)) || ' '::text) || COALESCE(city, ''::text)) || ' '::text) || COALESCE(state, ''::text)) || ' '::text) || COALESCE(zip, ''::text)) || ' '::text) || COALESCE(country, ''::text)))`),
});

export const documentTagEmbeddings = pgTable("document_tag_embeddings", {
	slug: text().primaryKey().notNull(),
	embedding: vector({ dimensions: 1024 }),
	name: text().notNull(),
});

export const documentTags = pgTable("document_tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	name: text().notNull(),
	slug: text().notNull(),
	teamId: uuid("team_id").notNull(),
}, (table) => [
	unique("unique_slug_per_team").on(table.slug, table.teamId),
]);

export const documents = pgTable("documents", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: text(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	metadata: jsonb(),
	pathTokens: text("path_tokens").array(),
	teamId: uuid("team_id"),
	parentId: text("parent_id"),
	objectId: uuid("object_id"),
	ownerId: uuid("owner_id"),
	tag: text(),
	title: text(),
	body: text(),
	// TODO: failed to parse database type 'tsvector'
	fts: unknown("fts").notNull().generatedAlwaysAs(sql`to_tsvector('english'::regconfig, ((title || ' '::text) || body))`),
	summary: text(),
	content: text(),
	date: date(),
	language: text(),
	processingStatus: documentProcessingStatus("processing_status").default('pending'),
	// TODO: failed to parse database type 'tsvector'
	ftsSimple: unknown("fts_simple"),
	// TODO: failed to parse database type 'tsvector'
	ftsEnglish: unknown("fts_english"),
	// TODO: failed to parse database type 'tsvector'
	ftsLanguage: unknown("fts_language"),
});

export const exchangeRates = pgTable("exchange_rates", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	base: text(),
	rate: numeric({ precision: 10, scale:  2 }),
	target: text(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }),
}, (table) => [
	unique("unique_rate").on(table.base, table.target),
]);

export const inbox = pgTable("inbox", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	teamId: uuid("team_id"),
	filePath: text("file_path").array(),
	fileName: text("file_name"),
	transactionId: uuid("transaction_id"),
	amount: numeric({ precision: 10, scale:  2 }),
	currency: text(),
	contentType: text("content_type"),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	size: bigint({ mode: "number" }),
	attachmentId: uuid("attachment_id"),
	date: date(),
	forwardedTo: text("forwarded_to"),
	referenceId: text("reference_id"),
	meta: json(),
	status: inboxStatus().default('new'),
	website: text(),
	displayName: text("display_name"),
	// TODO: failed to parse database type 'tsvector'
	fts: unknown("fts").notNull().generatedAlwaysAs(sql`generate_inbox_fts(display_name, extract_product_names((meta -> 'products'::text)))`),
	type: inboxType(),
	description: text(),
	baseAmount: numeric("base_amount", { precision: 10, scale:  2 }),
	baseCurrency: text("base_currency"),
	taxAmount: numeric("tax_amount", { precision: 10, scale:  2 }),
	taxRate: numeric("tax_rate", { precision: 10, scale:  2 }),
	taxType: text("tax_type"),
}, (table) => [
	unique("inbox_reference_id_key").on(table.referenceId),
]);

export const inboxAccounts = pgTable("inbox_accounts", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	email: text().notNull(),
	accessToken: text("access_token").notNull(),
	refreshToken: text("refresh_token").notNull(),
	teamId: uuid("team_id").notNull(),
	lastAccessed: timestamp("last_accessed", { withTimezone: true, mode: 'string' }).notNull(),
	provider: inboxAccountProviders().notNull(),
	externalId: text("external_id").notNull(),
	expiryDate: timestamp("expiry_date", { withTimezone: true, mode: 'string' }).notNull(),
	scheduleId: text("schedule_id"),
}, (table) => [
	unique("inbox_accounts_email_key").on(table.email),
	unique("inbox_accounts_external_id_key").on(table.externalId),
]);

export const invoiceComments = pgTable("invoice_comments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
});

export const invoiceTemplates = pgTable("invoice_templates", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	teamId: uuid("team_id").notNull(),
	customerLabel: text("customer_label"),
	fromLabel: text("from_label"),
	invoiceNoLabel: text("invoice_no_label"),
	issueDateLabel: text("issue_date_label"),
	dueDateLabel: text("due_date_label"),
	descriptionLabel: text("description_label"),
	priceLabel: text("price_label"),
	quantityLabel: text("quantity_label"),
	totalLabel: text("total_label"),
	vatLabel: text("vat_label"),
	taxLabel: text("tax_label"),
	paymentLabel: text("payment_label"),
	noteLabel: text("note_label"),
	logoUrl: text("logo_url"),
	currency: text(),
	paymentDetails: jsonb("payment_details"),
	fromDetails: jsonb("from_details"),
	size: invoiceSize().default('a4'),
	dateFormat: text("date_format"),
	includeVat: boolean("include_vat"),
	includeTax: boolean("include_tax"),
	taxRate: numeric("tax_rate", { precision: 10, scale:  2 }),
	deliveryType: invoiceDeliveryType("delivery_type").default('create').notNull(),
	discountLabel: text("discount_label"),
	includeDiscount: boolean("include_discount"),
	includeDecimals: boolean("include_decimals"),
	includeQr: boolean("include_qr"),
	totalSummaryLabel: text("total_summary_label"),
	title: text(),
	vatRate: numeric("vat_rate", { precision: 10, scale:  2 }),
	includeUnits: boolean("include_units"),
	subtotalLabel: text("subtotal_label"),
	includePdf: boolean("include_pdf"),
	sendCopy: boolean("send_copy"),
}, (table) => [
	unique("invoice_templates_team_id_key").on(table.teamId),
]);

export const invoices = pgTable("invoices", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	dueDate: timestamp("due_date", { withTimezone: true, mode: 'string' }),
	invoiceNumber: text("invoice_number"),
	customerId: uuid("customer_id"),
	amount: numeric({ precision: 10, scale:  2 }),
	currency: text(),
	lineItems: jsonb("line_items"),
	paymentDetails: jsonb("payment_details"),
	customerDetails: jsonb("customer_details"),
	companyDatails: jsonb("company_datails"),
	note: text(),
	internalNote: text("internal_note"),
	teamId: uuid("team_id").notNull(),
	paidAt: timestamp("paid_at", { withTimezone: true, mode: 'string' }),
	// TODO: failed to parse database type 'tsvector'
	fts: unknown("fts").notNull().generatedAlwaysAs(sql`to_tsvector('english'::regconfig, ((COALESCE((amount)::text, ''::text) || ' '::text) || COALESCE(invoice_number, ''::text)))`),
	vat: numeric({ precision: 10, scale:  2 }),
	tax: numeric({ precision: 10, scale:  2 }),
	url: text(),
	filePath: text("file_path").array(),
	status: invoiceStatus().default('draft').notNull(),
	viewedAt: timestamp("viewed_at", { withTimezone: true, mode: 'string' }),
	fromDetails: jsonb("from_details"),
	issueDate: timestamp("issue_date", { withTimezone: true, mode: 'string' }),
	template: jsonb(),
	noteDetails: jsonb("note_details"),
	customerName: text("customer_name"),
	token: text().default(').notNull(),
	sentTo: text("sent_to"),
	reminderSentAt: timestamp("reminder_sent_at", { withTimezone: true, mode: 'string' }),
	discount: numeric({ precision: 10, scale:  2 }),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	fileSize: bigint("file_size", { mode: "number" }),
	userId: uuid("user_id"),
	subtotal: numeric({ precision: 10, scale:  2 }),
	topBlock: jsonb("top_block"),
	bottomBlock: jsonb("bottom_block"),
	sentAt: timestamp("sent_at", { withTimezone: true, mode: 'string' }),
	scheduledAt: timestamp("scheduled_at", { withTimezone: true, mode: 'string' }),
	scheduledJobId: text("scheduled_job_id"),
}, (table) => [
	unique("invoices_scheduled_job_id_key").on(table.scheduledJobId),
]);

export const oauthAccessTokens = pgTable("oauth_access_tokens", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	token: text().notNull(),
	refreshToken: text("refresh_token"),
	applicationId: uuid("application_id").notNull(),
	userId: uuid("user_id").notNull(),
	teamId: uuid("team_id").notNull(),
	scopes: text().array().notNull(),
	expiresAt: timestamp("expires_at", { withTimezone: true, mode: 'string' }).notNull(),
	refreshTokenExpiresAt: timestamp("refresh_token_expires_at", { withTimezone: true, mode: 'string' }),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	lastUsedAt: timestamp("last_used_at", { withTimezone: true, mode: 'string' }),
	revoked: boolean().default(false),
	revokedAt: timestamp("revoked_at", { withTimezone: true, mode: 'string' }),
}, (table) => [
	unique("oauth_access_tokens_token_unique").on(table.token),
	unique("oauth_access_tokens_refresh_token_unique").on(table.refreshToken),
]);

export const oauthApplications = pgTable("oauth_applications", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	name: text().notNull(),
	slug: text().notNull(),
	description: text(),
	overview: text(),
	developerName: text("developer_name"),
	logoUrl: text("logo_url"),
	website: text(),
	installUrl: text("install_url"),
	screenshots: text().array().default([""]),
	redirectUris: text("redirect_uris").array().notNull(),
	clientId: text("client_id").notNull(),
	clientSecret: text("client_secret").notNull(),
	scopes: text().array().default([""]).notNull(),
	teamId: uuid("team_id").notNull(),
	createdBy: uuid("created_by").notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	updatedAt: timestamp("updated_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	isPublic: boolean("is_public").default(false),
	active: boolean().default(true),
	status: text().default('draft'),
}, (table) => [
	unique("oauth_applications_slug_unique").on(table.slug),
	unique("oauth_applications_client_id_unique").on(table.clientId),
]);

export const oauthAuthorizationCodes = pgTable("oauth_authorization_codes", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	code: text().notNull(),
	applicationId: uuid("application_id").notNull(),
	userId: uuid("user_id").notNull(),
	teamId: uuid("team_id").notNull(),
	scopes: text().array().notNull(),
	redirectUri: text("redirect_uri").notNull(),
	expiresAt: timestamp("expires_at", { withTimezone: true, mode: 'string' }).notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	used: boolean().default(false),
	codeChallenge: text("code_challenge"),
	codeChallengeMethod: text("code_challenge_method"),
}, (table) => [
	unique("oauth_authorization_codes_code_unique").on(table.code),
]);

export const reports = pgTable("reports", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	linkId: text("link_id"),
	teamId: uuid("team_id"),
	shortLink: text("short_link"),
	from: timestamp({ withTimezone: true, mode: 'string' }),
	to: timestamp({ withTimezone: true, mode: 'string' }),
	type: reportTypes(),
	expireAt: timestamp("expire_at", { withTimezone: true, mode: 'string' }),
	currency: text(),
	createdBy: uuid("created_by"),
});

export const trackerEntries = pgTable("tracker_entries", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	duration: bigint({ mode: "number" }),
	projectId: uuid("project_id"),
	start: timestamp({ withTimezone: true, mode: 'string' }),
	stop: timestamp({ withTimezone: true, mode: 'string' }),
	assignedId: uuid("assigned_id"),
	teamId: uuid("team_id"),
	description: text(),
	rate: numeric({ precision: 10, scale:  2 }),
	currency: text(),
	billed: boolean().default(false),
	date: date().defaultNow(),
});

export const shortLinks = pgTable("short_links", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	shortId: text("short_id").notNull(),
	url: text().notNull(),
	type: text(),
	size: numeric({ precision: 10, scale:  2 }),
	mimeType: text("mime_type"),
	fileName: text("file_name"),
	teamId: uuid("team_id").notNull(),
	userId: uuid("user_id").notNull(),
	expiresAt: timestamp("expires_at", { withTimezone: true, mode: 'string' }),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
}, (table) => [
	unique("short_links_short_id_unique").on(table.shortId),
]);

export const tags = pgTable("tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	teamId: uuid("team_id").notNull(),
	name: text().notNull(),
}, (table) => [
	unique("unique_tag_name").on(table.teamId, table.name),
]);

export const teams = pgTable("teams", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	name: text(),
	logoUrl: text("logo_url"),
	inboxId: text("inbox_id").default('generate_inbox(10)'),
	email: text(),
	inboxEmail: text("inbox_email"),
	inboxForwarding: boolean("inbox_forwarding").default(true),
	baseCurrency: text("base_currency"),
	countryCode: text("country_code"),
	documentClassification: boolean("document_classification").default(false),
	flags: text().array(),
	canceledAt: timestamp("canceled_at", { withTimezone: true, mode: 'string' }),
	plan: plans().default('trial').notNull(),
}, (table) => [
	unique("teams_inbox_id_key").on(table.inboxId),
]);

export const trackerProjectTags = pgTable("tracker_project_tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	trackerProjectId: uuid("tracker_project_id").notNull(),
	tagId: uuid("tag_id").notNull(),
	teamId: uuid("team_id").notNull(),
}, (table) => [
	unique("unique_project_tag").on(table.trackerProjectId, table.tagId),
]);

export const trackerProjects = pgTable("tracker_projects", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	teamId: uuid("team_id"),
	rate: numeric({ precision: 10, scale:  2 }),
	currency: text(),
	status: trackerStatus().default('in_progress').notNull(),
	description: text(),
	name: text().notNull(),
	billable: boolean().default(false),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	estimate: bigint({ mode: "number" }),
	customerId: uuid("customer_id"),
	// TODO: failed to parse database type 'tsvector'
	fts: unknown("fts").notNull().generatedAlwaysAs(sql`to_tsvector('english'::regconfig, ((COALESCE(name, ''::text) || ' '::text) || COALESCE(description, ''::text)))`),
});

export const trackerReports = pgTable("tracker_reports", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	linkId: text("link_id"),
	shortLink: text("short_link"),
	teamId: uuid("team_id").defaultRandom(),
	projectId: uuid("project_id").defaultRandom(),
	createdBy: uuid("created_by"),
});

export const transactionAttachments = pgTable("transaction_attachments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	type: text(),
	transactionId: uuid("transaction_id"),
	teamId: uuid("team_id"),
	// You can use { mode: "bigint" } if numbers are exceeding js number limitations
	size: bigint({ mode: "number" }),
	name: text(),
	path: text().array(),
});

export const transactionEnrichments = pgTable("transaction_enrichments", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	name: text(),
	teamId: uuid("team_id"),
	categorySlug: text("category_slug"),
	system: boolean().default(false),
}, (table) => [
	unique("unique_team_name").on(table.name, table.teamId),
]);

export const transactionTags = pgTable("transaction_tags", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	teamId: uuid("team_id").notNull(),
	tagId: uuid("tag_id").notNull(),
	transactionId: uuid("transaction_id").notNull(),
}, (table) => [
	unique("unique_tag").on(table.tagId, table.transactionId),
]);

export const transactions = pgTable("transactions", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	date: date().notNull(),
	name: text().notNull(),
	method: transactionMethods().notNull(),
	amount: numeric({ precision: 10, scale:  2 }).notNull(),
	currency: text().notNull(),
	teamId: uuid("team_id").notNull(),
	assignedId: uuid("assigned_id"),
	note: varchar(),
	bankAccountId: uuid("bank_account_id"),
	internalId: text("internal_id").notNull(),
	status: transactionStatus().default('posted'),
	category: transactionCategories(),
	balance: numeric({ precision: 10, scale:  2 }),
	manual: boolean().default(false),
	notified: boolean().default(false),
	internal: boolean().default(false),
	description: text(),
	categorySlug: text("category_slug"),
	baseAmount: numeric({ precision: 10, scale:  2 }),
	counterpartyName: text("counterparty_name"),
	baseCurrency: text("base_currency"),
	taxRate: numeric({ precision: 10, scale:  2 }),
	taxType: text("tax_type"),
	recurring: boolean(),
	frequency: transactionFrequency(),
	// TODO: failed to parse database type 'tsvector'
	ftsVector: unknown("fts_vector").notNull().generatedAlwaysAs(sql`to_tsvector('english'::regconfig, ((COALESCE(name, ''::text) || ' '::text) || COALESCE(description, ''::text)))`),
}, (table) => [
	unique("transactions_internal_id_key").on(table.internalId),
]);

export const userInvites = pgTable("user_invites", {
	id: uuid().defaultRandom().primaryKey().notNull(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow().notNull(),
	teamId: uuid("team_id"),
	email: text(),
	role: teamRoles(),
	code: text().default('nanoid(24)'),
	invitedBy: uuid("invited_by"),
}, (table) => [
	unique("unique_team_invite").on(table.teamId, table.email),
	unique("user_invites_code_key").on(table.code),
]);

export const users = pgTable("users", {
	id: uuid().primaryKey().notNull(),
	fullName: text("full_name"),
	avatarUrl: text("avatar_url"),
	email: text(),
	teamId: uuid("team_id"),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	locale: text().default('en'),
	weekStartsOnMonday: boolean("week_starts_on_monday").default(false),
	timezone: text(),
	timezoneAutoSync: boolean("timezone_auto_sync").default(true),
	timeFormat: numeric("time_format").default('24'),
	dateFormat: text("date_format"),
}, (table) => [
	pgPolicy("Users can insert own profile", { as: "permissive", for: "insert", to: ["public"], withCheck: sql`(auth.uid() = id)`  }),
	pgPolicy("Users can update own profile", { as: "permissive", for: "update", to: ["public"] }),
	pgPolicy("Users can view own profile", { as: "permissive", for: "select", to: ["public"] }),
	pgPolicy("Service role can access all users", { as: "permissive", for: "all", to: ["public"] }),
]);

export const documentTagAssignments = pgTable("document_tag_assignments", {
	documentId: uuid("document_id").notNull(),
	tagId: uuid("tag_id").notNull(),
	teamId: uuid("team_id").notNull(),
}, (table) => [
	primaryKey({ columns: [table.documentId, table.tagId], name: "document_tag_assignments_pkey"}),
]);

export const transactionCategories = pgTable("transaction_categories", {
	id: uuid().defaultRandom().notNull(),
	name: text().notNull(),
	teamId: uuid("team_id").notNull(),
	color: text(),
	createdAt: timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow(),
	system: boolean().default(false),
	slug: text().notNull(),
	taxRate: numeric("tax_rate", { precision: 10, scale:  2 }),
	taxType: text("tax_type"),
	description: text(),
	embedding: vector({ dimensions: 384 }),
	parentId: uuid("parent_id"),
}, (table) => [
	primaryKey({ columns: [table.teamId, table.slug], name: "transaction_categories_pkey"}),
]);
