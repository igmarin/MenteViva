# Jev proxy (Cloudflare Worker)

1. `npx wrangler login` — once, with the owner's Cloudflare account.
2. `npx wrangler secret put TYPESAFE_AI_KEY` — paste the key when prompted; it is never printed or committed.
3. `npx wrangler deploy --name menteviva-jev-proxy proxy/worker.js`
4. Set `JEV_PROXY_URL` to `https://menteviva-jev-proxy.<account>.workers.dev/jev` in the app config.

Local beta instead of deploying: `TYPESAFE_AI_KEY=… npx wrangler dev proxy/worker.js` → use the printed local URL + `/jev`.
Never put the key in code, plist, or git — `wrangler secret` is the only place it lives.
