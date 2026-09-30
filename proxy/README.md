# Jev proxy (Cloudflare Worker)

Validates `POST /jev` (shared-secret header, size cap, model + question-key
allowlist, per-IP rate limit) and forwards it to TypeSafe Jev with the API key
added server-side. Anything else gets 404/405/4xx; upstream trouble gets a warm 502.
The app falls back to its offline plan on any non-2xx.

## Deploy (owner's Cloudflare account)

1. `npx wrangler login` — once.
2. `cd proxy && npx wrangler secret put TYPESAFE_AI_KEY` — paste the Jev key.
3. `npx wrangler secret put APP_SHARED_SECRET` — paste a long random string
   (`openssl rand -hex 32`).
4. `npx wrangler deploy` (uses `wrangler.toml`; it holds no secrets).
5. Set `JEV_PROXY_URL` to `https://menteviva-jev-proxy.<account>.workers.dev/jev`
   and the same secret as the app's `X-MenteViva-Key` header value, both in the
   git-ignored xcconfig. (App-side header is a separate change.)

Local: put both secrets in `proxy/.dev.vars` (git-ignored), then `npx wrangler dev`.

## Tests

`node --test 'proxy/*.test.js'` — no dependencies, fetch is mocked.

## Honest limits

A shared secret shipped inside the app is a speed bump, not real auth: anyone
who extracts it from the binary can call the proxy. The rate limit and size/schema
checks cap the damage. The real upgrade is App Attest, once a paid Apple
Developer account exists. Rotate the secret (and ship an app update) if it leaks.
