import { defineConfig } from "@trigger.dev/sdk/v3";

export default defineConfig({
  project: process.env.TRIGGER_PROJECT_ID || "proj_zfhegaqlpfenezykfvur",
  runtime: "node",
  logLevel: "log",
  maxDuration: 60,
  extensions: [
    {
      name: "syncEnvVars",
      envVars: [
        "RESEND_API_KEY",
        "RESEND_AUDIENCE_ID",
        "NOVU_API_KEY",
        "NOVU_SECRET_KEY",
        "SLACK_CLIENT_SECRET",
        "SLACK_SIGNING_SECRET",
        "SLACK_STATE_SECRET",
        "SUPABASE_URL",
        "NEXT_PUBLIC_SUPABASE_URL",
        "SUPABASE_SERVICE_KEY"
      ]
    }
  ],
  retries: {
    enabledInDev: false,
    default: {
      maxAttempts: 3,
      minTimeoutInMs: 1000,
      maxTimeoutInMs: 10000,
      factor: 2,
      randomize: true,
    },
  },
  
  build: {
    external: ["sharp", "canvas"],
  },
  dirs: ["./src/tasks"],
});
