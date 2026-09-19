# ARCShield Pre-Deployment

ARCShield is a simulated financial environment. It does not connect to NPCI, UPI rails, or a real bank core, and it cannot freeze real money without a bank or payment-provider integration.

## Release layout

- Frontend: Vercel using `vercel.json`
- API: Render using `render.yaml` and Python 3.11
- Data and realtime: Supabase, configured separately
- Mobile push: Firebase Admin credentials configured only on the API service

## Required environment variables

Copy `.env.example` for local setup. Never commit `.env`, service-account JSON, Supabase service-role keys, JWT secrets, or database credentials.

### Vercel

- `VITE_API_URL`: public Render API URL, for example `https://arcshield-api.onrender.com`
- `VITE_SUPABASE_URL`: Supabase project URL
- `VITE_SUPABASE_ANON_KEY`: Supabase anonymous browser key

### Render

- `CORS_ORIGINS`: comma-separated Vercel origin(s)
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_SECRET`
- `DATABASE_URL`
- `FIREBASE_SERVICE_ACCOUNT_PATH` when push notifications are enabled

## Local release checks

```powershell
npm ci
npm run build
pytest -q
```

Start the API with `uvicorn api.main:app --reload --port 8000` and the dashboard with `npm run dev`. In local development, the Vite `/api` proxy is used when `VITE_API_URL` is unset.

## Deployment order

1. Apply the SQL schema, triggers, seed data, and RLS policies in Supabase.
2. Create the Render API service from `render.yaml` and set its environment variables.
3. Confirm Render `/health` is healthy.
4. Create the Vercel project from the repository and set the Vite variables.
5. Set the Render `CORS_ORIGINS` value to the deployed Vercel origin.
6. Run the five-scenario demonstration against the deployed API and verify the quarantine balance and spend guard.

## Operational checks before handoff

- Confirm `/health` reports the expected model version.
- Confirm warm scoring latency remains under the 200 ms target.
- Confirm quarantine moves funds from available to held and blocks spending.
- Confirm case status actions and federated aggregation return successful API responses.
- Confirm Supabase realtime is connected in the dashboard.
- Confirm Firebase credentials are absent from client-side build output.