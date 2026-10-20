// MenteViva Jev proxy — validates POST /jev, then forwards it to the TypeSafe Jev API
// with the Bearer key added server-side (env TYPESAFE_AI_KEY). No body logging, no state.
// Reference implementation for docs/jev-integration.md §Server-side proxy requirement.
// A shared secret embedded in the app is a speed bump, not real auth (see README).

const UPSTREAM = "https://api.typesafe.ai/v1/systemone";
const MAX_BODY_BYTES = 16 * 1024;
const UPSTREAM_TIMEOUT_MS = 8000;
const MODELS = new Set(["jev-latest"]);
// Mirrors GameID in MenteViva/Models/GameID.swift — keep in sync.
// LEVELLESS mirrors GameID.hasLevels: those games send no difficulty_ key.
const GAMES = ["memory_match", "stroop", "category_fluency", "math_streaks", "quick_eyes", "reminiscence", "sudoku"];
const LEVELLESS = new Set(["reminiscence"]);
const QUESTION_KEYS = new Set(
  GAMES.flatMap((g) => (LEVELLESS.has(g) ? [`include_${g}`] : [`include_${g}`, `difficulty_${g}`])),
);

const json = (status, message) =>
  new Response(JSON.stringify({ message }), { status, headers: { "Content-Type": "application/json" } });

// Length-independent compare of two strings, without early exit.
function safeEqual(a, b) {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  for (let i = 0; i < Math.max(x.length, y.length); i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

function validBody(b) {
  if (!b || typeof b !== "object" || Array.isArray(b)) return false;
  if (!MODELS.has(b.model)) return false;
  if (!b.state || typeof b.state !== "object") return false;
  const q = b.questions;
  if (!q || typeof q !== "object" || Array.isArray(q)) return false;
  const keys = Object.keys(q);
  return keys.length > 0 && keys.every((k) => QUESTION_KEYS.has(k));
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== "/jev") return json(404, "Not found");
    if (request.method !== "POST") return json(405, "Method not allowed");

    // Misconfigured deploy: say nothing about which secret is missing.
    if (!env.TYPESAFE_AI_KEY || !env.APP_SHARED_SECRET) return json(500, "Server not configured");

    const provided = request.headers.get("X-MenteViva-Key") ?? "";
    if (!safeEqual(provided, env.APP_SHARED_SECRET)) return json(401, "Unauthorized");

    if (env.RATE_LIMITER) {
      const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
      const { success } = await env.RATE_LIMITER.limit({ key: ip });
      if (!success) return json(429, "Too many requests");
    }

    const declared = Number(request.headers.get("Content-Length"));
    if (declared > MAX_BODY_BYTES) return json(413, "Request too large");
    const text = await request.text();
    if (new TextEncoder().encode(text).length > MAX_BODY_BYTES) return json(413, "Request too large");

    let body;
    try {
      body = JSON.parse(text);
    } catch {
      return json(400, "Invalid request");
    }
    if (!validBody(body)) return json(400, "Invalid request");

    try {
      const upstream = await fetch(UPSTREAM, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${env.TYPESAFE_AI_KEY}` },
        body: text,
        signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
      });
      return new Response(upstream.body, {
        status: upstream.status,
        headers: { "Content-Type": upstream.headers.get("Content-Type") ?? "application/json" },
      });
    } catch {
      return json(502, "Jev is resting for a moment. Please try again soon.");
    }
  },
};
