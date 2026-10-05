// Run: node --test proxy/worker.test.js   (no dependencies; global fetch is mocked)
import { test, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import worker from "./worker.js";

const env = { TYPESAFE_AI_KEY: "test-upstream", APP_SHARED_SECRET: "test-secret" };
const good = () => ({
  model: "jev-latest",
  state: { played: 3 },
  questions: { include_stroop: { type: "noul" }, difficulty_quick_eyes: { type: "score" } },
});
const req = (body, { method = "POST", path = "/jev", headers = {} } = {}) =>
  new Request(`https://p.example${path}`, {
    method,
    headers: { "X-MenteViva-Key": "test-secret", ...headers },
    body: method === "GET" ? undefined : typeof body === "string" ? body : JSON.stringify(body),
  });

const realFetch = globalThis.fetch;
let upstreamCalls;
beforeEach(() => {
  upstreamCalls = [];
  globalThis.fetch = async (u, init) => {
    upstreamCalls.push({ u, init });
    return new Response('{"answers":{}}', { status: 200, headers: { "Content-Type": "application/json" } });
  };
});
afterEach(() => { globalThis.fetch = realFetch; });

test("missing secret header -> 401, no upstream call", async () => {
  const r = await worker.fetch(req(good(), { headers: { "X-MenteViva-Key": "" } }), env);
  assert.equal(r.status, 401);
  assert.equal(upstreamCalls.length, 0);
});

test("wrong secret -> 401", async () => {
  const r = await worker.fetch(req(good(), { headers: { "X-MenteViva-Key": "nope" } }), env);
  assert.equal(r.status, 401);
});

test("server secrets unset -> 500 without leaking", async () => {
  const r = await worker.fetch(req(good()), { APP_SHARED_SECRET: "test-secret" });
  assert.equal(r.status, 500);
  assert.doesNotMatch(await r.text(), /TYPESAFE|KEY/);
});

test("oversize body -> 413", async () => {
  const b = good();
  b.state = { pad: "x".repeat(20000) };
  assert.equal((await worker.fetch(req(b), env)).status, 413);
});

test("bad JSON -> 400", async () => {
  assert.equal((await worker.fetch(req("{nope"), env)).status, 400);
});

test("bad model -> 400", async () => {
  const b = good(); b.model = "gpt-x";
  assert.equal((await worker.fetch(req(b), env)).status, 400);
});

test("missing state -> 400", async () => {
  const b = good(); delete b.state;
  assert.equal((await worker.fetch(req(b), env)).status, 400);
});

test("unknown question key -> 400", async () => {
  const b = good(); b.questions.evil_prompt = { type: "noul" };
  assert.equal((await worker.fetch(req(b), env)).status, 400);
});

test("real app payload: include_ for all 6 games, difficulty_ only for levelled ones -> 200", async () => {
  // What JevService.makeRequest actually sends: include_ per GameID.allCases,
  // difficulty_ only where GameID.hasLevels is true (reminiscence is false).
  const games = ["memory_match", "stroop", "category_fluency", "math_streaks", "quick_eyes", "reminiscence"];
  const b = good();
  b.questions = {};
  for (const g of games) {
    b.questions[`include_${g}`] = { type: "noul" };
    if (g !== "reminiscence") b.questions[`difficulty_${g}`] = { type: "score" };
  }
  const r = await worker.fetch(req(b), env);
  assert.equal(r.status, 200);
  assert.equal(upstreamCalls.length, 1);
  assert.deepEqual(JSON.parse(upstreamCalls[0].init.body), b);
});

test("difficulty_reminiscence -> 400 (reminiscence has no levels)", async () => {
  const b = good();
  b.questions.difficulty_reminiscence = { type: "score" };
  assert.equal((await worker.fetch(req(b), env)).status, 400);
  assert.equal(upstreamCalls.length, 0);
});

test("GET -> 405; other path -> 404", async () => {
  assert.equal((await worker.fetch(req(null, { method: "GET" }), env)).status, 405);
  assert.equal((await worker.fetch(req(good(), { path: "/x" }), env)).status, 404);
});

test("rate limited -> 429", async () => {
  const limited = { ...env, RATE_LIMITER: { limit: async () => ({ success: false }) } };
  assert.equal((await worker.fetch(req(good()), limited)).status, 429);
});

test("upstream failure -> warm 502", async () => {
  globalThis.fetch = async () => { throw new Error("boom"); };
  const r = await worker.fetch(req(good()), env);
  assert.equal(r.status, 502);
  assert.doesNotMatch(await r.text(), /boom|error|fail/i);
});

test("happy path forwards body with Bearer key", async () => {
  const b = good();
  const r = await worker.fetch(req(b), env);
  assert.equal(r.status, 200);
  assert.deepEqual(await r.json(), { answers: {} });
  assert.equal(upstreamCalls.length, 1);
  assert.equal(upstreamCalls[0].init.headers.Authorization, "Bearer test-upstream");
  assert.deepEqual(JSON.parse(upstreamCalls[0].init.body), b);
});
